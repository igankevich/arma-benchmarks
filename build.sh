#!/bin/sh

set -e
ROOT=$(pwd)

get_repository() {
	repo=git@github.com:igankevich/arma.git
	rev=1c4c387efcefa5d70bb8be07b0334e792c178e31
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
	echo "Building $framework source code..."
	options="-Dreal_type=double -Dprofile=true -Dopencl_srcdir=$(pwd)/src/kernels"
	if ! test -d $framework
	then
		meson --buildtype=release . $framework
	fi
	mesonconf $framework $options -Dframework=$framework 
	ninja -C $framework
	ninja -C $framework test
}

generate_input_files() {
	out_grid="(200,40,40)"
	cat >/tmp/velocity << EOF
velocity_potential_solver = high_amplitude {
	wnmax = from (0,0) to (0,0.25) npoints (2,2)
	depth = 12
	domain = from (10,-12) to (10,3) npoints (1,128)
}
EOF
	cat >/tmp/ar_model << EOF
model = AR {
	out_grid = $out_grid
	acf = {
		func = standing_wave
		grid = (10,10,10) : (2.5,5,5)
	}
	least_squares = 0
	order = (7,7,7)
	output = surface
}
EOF
	cat >/tmp/ma_model << EOF
model = MA {
	out_grid = $out_grid
	acf = {
		func = propagating_wave
		grid = (20,10,10) : (10,5,5)
	}
	order = (20,10,10)
	algorithm = fixed_point_iteration
	max_iterations = 1000
	eps = 1e-5
	min_var_wn = 1e-6
	output = surface
}
EOF
	cat >/tmp/lh_model << EOF
model = LH {
	out_grid = $out_grid : (100,400,400)
	spec_domain = from (0.3,-1.5708) to (1.5708,1.5708) npoints (40,40)
	spec_subdomain = (50,50)
	wave_height = 4
	output = surface
}
EOF
}

run_benchmarks() {
	framework=$1
	echo "Running $framework benchmarks..."
	root=$(pwd)
	cd $framework
	for model in ar ma lh
	do
		echo "Running model=$model,framework=$framework"
		cat /tmp/${model}_model /tmp/velocity > /tmp/input
		ln -sfn $ROOT/mt.dat
		mkdir -p $ROOT/output/$framework/$model
		./src/arma /tmp/input >$ROOT/output/$framework/$model/$(date +%s%N).log 2>&1
	done
	cd $root
}

get_repository
build_arma openmp
build_arma opencl
generate_input_files
run_benchmarks openmp
run_benchmarks opencl
