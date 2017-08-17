#!/bin/sh

set -e
ROOT=$(pwd)

get_repository() {
	repo=https://github.com/igankevich/arma
	rev=f20fb9686aa657f5234f6372d8c7c24a70cb7c4d
	if ! test -d arma
	then
		echo "Cloning repository..."
		git clone -q $repo arma
	fi
	cd arma
	git checkout master
	git pull
	git checkout -q $rev
	echo "Repository: $(git remote get-url origin)"
	echo "Revision: $(git rev-parse HEAD)"
}

build_arma() {
	framework=$1
	dir=$2
	if test -z "$dir"
	then
		dir=$framework
	fi
	more_options=$3
	echo "Building $framework source code..."
	options="-Dreal_type=double -Dprofile=true -Dopencl_srcdir=$(pwd)/src/kernels"
	if test -n "$more_options"
	then
		options="$options $more_options"
	fi
	if ! test -d $dir
	then
		meson --buildtype=release . $dir
	fi
	mesonconf $dir $options -Dframework=$framework 
	ninja -C $dir
	ninja -C $dir test
}

generate_input_files() {
	nt=$1
	m=$2
	if test -z "$m"
	then
		m=128
	fi
	out_grid="($nt,40,40)"
	cat >/tmp/velocity << EOF
velocity_potential_solver = high_amplitude {
	wnmax = from (0,0) to (0,0.25) npoints (2,2)
	depth = 12
	domain = from (10,-12) to (10,3) npoints (1,$m)
}
EOF
	cat >/tmp/velocity-realtime << EOF
velocity_potential_solver = high_amplitude_realtime {
	wnmax = from (0,0) to (0,0.25) npoints (2,2)
	depth = 12
	domain = from (10,-12) to (10,3) npoints (1,$m)
}
EOF
	cat >/tmp/nit << EOF
transform = nit {
	distribution = gram_charlier {
		skewness=3.25
		kurtosis=2.4
	}
	interpolation_nodes = 100
	max_interpolation_order = 10
	max_expansion_order = 20
	cdf_solver = {
		interval = [-5,5]
	}
	acf_solver = {
		interval = [-10,10]
	}
}
EOF
	cat >/tmp/ar_model << EOF
model = AR {
	out_grid = $out_grid
	$(cat /tmp/nit)
	acf = {
		func = standing_wave
		grid = (10,10,10) : (2.5,5,5)
	}
	least_squares = 0
	order = (7,7,7)
	output = surface,binary
}
EOF
	cat >/tmp/ma_model << EOF
model = MA {
	out_grid = $out_grid
	$(cat /tmp/nit)
	acf = {
		func = propagating_wave
		grid = (7,7,7) : (10,5,5)
	}
	order = (7,7,7)
	algorithm = fixed_point_iteration
	max_iterations = 1000
	eps = 1e-5
	min_var_wn = 1e-6
	output = surface,binary
}
EOF
	cat >/tmp/lh_model << EOF
model = LH {
	out_grid = $out_grid : (100,400,400)
	spec_domain = from (0.3,-1.5708) to (1.5708,1.5708) npoints (40,40)
	spec_subdomain = (50,50)
	wave_height = 4
	output = surface,binary
}
EOF
}

run_benchmarks() {
	framework=$1
	nt=$2
	attempt=$3
	workdir=$4
	host=$(hostname)
	echo "Running $framework benchmarks..."
	root=$(pwd)
	cd $framework
	mkdir -p $workdir
	cd $workdir
	cp $ROOT/input/mt.dat .
	export XDG_CACHE_HOME=/tmp/arma-cache
	export CLFFT_CACHE_PATH=/tmp/arma-cache
	mkdir -p $XDG_CACHE_HOME $CLFFT_CACHE_PATH
#	for model in ar ma lh
	for model in ar
	do
		if test "$model" = "ma" && test "$framework" = "opencl"
		then
			echo "Skipping model=$model,framework=$framework,nt=$nt"
		else
			echo "Running model=$model,framework=$framework,nt=$nt"
			cat /tmp/${model}_model /tmp/velocity > /tmp/input
			outdir="$ROOT/output/$host/$attempt/$nt/$framework/$model"
			outfile="$(date +%s).log"
			mkdir -p $outdir
			$ROOT/arma/$framework/src/arma /tmp/input >$outfile 2>&1
			cp $outfile $outdir
		fi
	done
	cd $root
}

run_benchmarks_varying_size() {
	framework=$1
	nt=$2
	attempt=$3
	workdir=$4
	dir=$5
	suffix=$6
	if test -n "$suffix"
	then
		suffix="-$suffix"
	fi
	model=lh
	host=$(hostname)
	echo "Running $dir benchmarks..."
	root=$(pwd)
	cd $dir
	mkdir -p $workdir
	cd $workdir
	cp $ROOT/input/mt.dat .
	export XDG_CACHE_HOME=/tmp/arma-cache
	export CLFFT_CACHE_PATH=/tmp/arma-cache
	mkdir -p $XDG_CACHE_HOME $CLFFT_CACHE_PATH
	for m in 128 256 512 1024 2048 4096 8192 16384
	do
		echo "Running model=$model,framework=$framework,nt=$nt,m=$m"
		generate_input_files $nt $m
		cat /tmp/${model}_model /tmp/velocity$suffix > /tmp/input
		outdir="$ROOT/output/$host/$attempt-$m/$nt/$framework/$model"
		outfile="$(date +%s).log"
		mkdir -p $outdir
		$ROOT/arma/$dir/src/arma$suffix /tmp/input >$outfile 2>&1
		cp $outfile $outdir
	done
	cd $root
}

produce_verification_data() {
	dir=$1
	root=$(pwd)
	for testname in \
		propagating_wave \
		standing_wave \
		plain_wave_linear_solver \
		plain_wave_high_amplitude_solver
	do
		echo "Running dir=$dir,input=$testname"
		wd=$ROOT/verification/$testname
		rm -rf $wd
		mkdir -p $wd
		cd $wd
		ln -sfn $ROOT/input/mt.dat .
		$ROOT/arma/$dir/src/arma $ROOT/input/$testname >$testname.log 2>&1
		rm mt.dat
	done
	cd $root
}

get_repository
build_arma openmp
#build_arma opencl
#build_arma opencl realtime "-Dwith_high_amplitude_realtime_solver=true"


produce_verification_data openmp
exit

nt=100
workdir_xfs=/var/tmp/arma
workdir_nfs=$HOME/tmp/arma
workdir_gfs=/gfs$HOME/tmp/arma
attempt=a6
for i in $(seq 9)
do
	echo "Iteration #$i"
	run_benchmarks_varying_size opencl $nt $attempt $workdir_xfs realtime realtime
	run_benchmarks_varying_size openmp $nt $attempt $workdir_xfs openmp
done
exit

generate_input_files $nt
for fs in xfs nfs gfs
do
	attempt=a5-$fs-events
	eval workdir="\$workdir_$fs"
	echo "attempt=$attempt,workdir=$workdir"
	run_benchmarks openmp $nt $attempt $workdir
	#run_benchmarks opencl $nt $attempt $workdir
done
