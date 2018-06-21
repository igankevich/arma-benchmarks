#!/bin/sh

root=$(pwd)
for testname in \
    propagating_wave \
    standing_wave \
    plain_wave_linear_solver \
    plain_wave_high_amplitude_solver
do
    wd=$root/verification-orig/$testname
    rm -rf $wd
    mkdir -p $wd
    cd $wd
    cp $root/input/mt.dat .
    arma -c $root/input/$testname
done

function generate_surface() {
  none=$1
  gcs=$2
  sn=$3
  testcase=$4

  wd=$root/build/$testcase
  rm -rf $wd
  mkdir -p $wd
  cd $wd
  cp $root/config/mt.dat .

  # run linear case
  arma -c $root/config/$none
  cp -v zeta.csv zeta-none.csv

  # run Gram---Charlier case
  arma -c $root/config/$gcs
  cp -v zeta.csv zeta-gramcharlier.csv

  # run skew normal case
  arma -c $root/config/$sn
  cp -v zeta.csv zeta-skewnormal.csv
}

echo "NIT for propagating waves"
generate_surface \
  nit-propagating-none \
  nit-propagating-gramcharlier \
  nit-propagating-skewnormal \
  nit-propagating

echo "NIT for standing waves"
generate_surface \
  nit-standing-none \
  nit-standing-gramcharlier \
  nit-standing-skewnormal \
  nit-standing
