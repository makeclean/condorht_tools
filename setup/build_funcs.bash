#!/bin/bash

# Check to see if the installed package tarball already exists
# If it does, get and unpack the tarball
# If not, build the package from source
function ensure_build() {
  name=$1
  eval version=\$"$name"_version
  folder=$name-$version
  echo $folder
  if [ -f $copy_dir/install_$folder.tar.gz ] ; then
    cd $install_dir
    tar -xzvf $copy_dir/install_$folder.tar.gz
  else
    echo Building $name-$version ...
    build_$name
  fi
}

# Setup steps before build
function setup_build() {
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ "$1" == "tar" ]; then
    if [ ! -f $dist_dir/$tarball ]; then
      wget $url -P $dist_dir
    fi
    if [ "${tarball: -7}" == ".tar.gz" ]; then
      tar_string="tar -xzvf"
    elif [ "${tarball: -4}" == ".tgz" ]; then
      tar_string="tar -xzvf"
    elif [ "${tarball: -8}" == ".tar.bz2" ]; then
      tar_string="tar -xjvf"
    elif [ "${tarball: -4}" == ".zip" ]; then
      tar_string="unzip"
    fi
    echo "tar_string" $tar_string 
    echo "dist_dir" $dist_dir 
    echo "tarball" $tarball

    $tar_string $dist_dir/$tarball
    ln -s $tar_f src
  elif [ "$1" == "repo" ]; then
    git clone $repo -b $branch
    ln -s $name src
  fi
  if [ "$2" == "auto" ]; then
    if [ "$1" == "tar" ]; then
      cd $tar_f
    elif [ "$1" == "repo" ]; then
      cd $name
    fi
    autoreconf -fi
    cd ..
  elif [ "$2" == "python" ]; then
    mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  fi
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir/$folder
}

# Finalize a build
function finalize_build() {
  cd $install_dir
  if [ $make_install_tarballs = true ]; then
    tar -czvf install_$folder.tar.gz $name*
    mv install_$folder.tar.gz $copy_dir
  fi
  cd $build_dir
}

# Build GMP
function build_gmp() {
  name=gmp
  version=$gmp_version
  folder=$name-$version
  tarball=$name-$version.tar.bz2
  tar_f=$name-$version
  url=https://gmplib.org/download/gmp/$tarball

  setup_build tar

  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build MPFR
function build_mpfr() {
  name=mpfr
  version=$mpfr_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.mpfr.org/mpfr-current/$tarball

  setup_build tar

  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build MPC
function build_mpc() {
  name=mpc
  version=$mpc_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=ftp://ftp.gnu.org/gnu/mpc/$tarball

  setup_build tar

  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build GCC
function build_gcc() {
  name=gcc
  version=$gcc_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.netgull.com/gcc/releases/gcc-$version/$tarball

  setup_build tar

  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--with-mpc=$install_dir/mpc
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# build ld
function build_binutils() {
  name=binutils
  version=$binutils_version
  echo "version" $version
  folder=$name
  tarball=$name-$version.tar.bz2
  tar_f=$name-$version
  echo "folder" $folder
  #repo=git://sourceware.org/git/binutils-gdb.git
  url=ftp://sourceware.org/pub/binutils/snapshots/binutils-2.28.90.tar.bz2

  setup_build tar

  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--with-mpc=$install_dir/mpc
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install
 
  finalize_build
}

# Build OpenMPI
function build_openmpi() {
  name=openmpi
  version=$openmpi_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.open-mpi.org/software/ompi/v1.10/downloads/$tarball

  setup_build tar

  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build CMake
function build_cmake() {
  name=cmake
  version=$cmake_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.cmake.org/files/v3.4/$tarball

  setup_build tar

  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build Python
function build_python() {
  name=python
  version=$python_version
  folder=$name-$version
  tarball=Python-$version.tgz
  tar_f=Python-$version
  url=https://www.python.org/ftp/python/$version/$tarball

  setup_build tar

  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build HDF5
function build_hdf5() {
  name=hdf5
  minor=1.8
  version=$hdf5_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$minor/hdf5-$version/src/$tarball

  setup_build tar

  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build LAPACK
function build_lapack() {
  name=lapack
  version=$lapack_version
  folder=$name-$version
  tarball=$name-$version.tgz
  tar_f=$name-$version
  url=http://www.netlib.org/lapack/$tarball

  setup_build tar

  cmake_string=
  cmake_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder

  cd bld
  cmake ../src $cmake_string
  make -j $jobs
  make install

  finalize_build
}

# Build Setuptools
function build_setuptools() {
  name=setuptools
  version=$setuptools_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://pypi.python.org/packages/source/s/setuptools/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build Cython
function build_cython() {
  name=cython
  version=$cython_version
  folder=$name-$version
  tarball=Cython-$version.tar.gz
  tar_f=Cython-$version
  url=http://cython.org/release/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build NumPy
function build_numpy() {
  name=numpy
  version=$numpy_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://downloads.sourceforge.net/project/numpy/NumPy/$version/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py build -j $jobs install $setup_string

  finalize_build
}

# Build SciPy
function build_scipy() {
  name=scipy
  version=$scipy_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://downloads.sourceforge.net/project/scipy/scipy/$version/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py build -j $jobs install $setup_string

  finalize_build
}

# Build NumExpr
function build_numexpr() {
  name=numexpr
  version=$numexpr_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://pypi.python.org/packages/source/n/numexpr/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build PyTables
function build_pytables() {
  name=pytables
  version=$pytables_version
  folder=$name-$version
  tarball=tables-$version.tar.gz
  tar_f=tables-$version
  url=http://downloads.sourceforge.net/project/pytables/pytables/$version/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--hdf5=$install_dir/hdf5
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build Nose
function build_nose() {
  name=nose
  version=$nose_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://pypi.python.org/packages/source/n/nose/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build CUBIT
function build_cubit() {
  name=cubit
  version=$cubit_version
  folder=$name-$version
  tarball=Cubit_LINUX64.$version.tar.gz

  cd $install_dir
  ln -snf $folder $name
  mkdir $folder
  cd $folder
  tar -xzvf $dist_dir/$tarball

  finalize_build
}

# Build CGM
function build_cgm() {
  name=cgm
  version=$cgm_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=cgm$version

  setup_build repo auto

  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  if [[ " ${packages[@]} " =~ " cubit " ]]; then
    config_string+=" "--with-cubit=$install_dir/cubit
  fi
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build MOAB
function build_moab() {
  name=moab
  version=$moab_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=Version$version

  setup_build repo auto

  config_string=
  config_string+=" "--enable-dagmc
  config_string+=" "--enable-fbigeom
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-hdf5=$install_dir/hdf5
  if [[ " ${packages[@]} " =~ " cgm " ]]; then
    config_string+=" "--with-cgm=$install_dir/cgm
    config_string+=" "--enable-irel
  fi
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build MeshKit
function build_meshkit() {
  name=meshkit
  version=$meshkit_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=MeshKitv$version
  if [ "$version" = "master" ]; then branch=master; fi

  setup_build repo auto

  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-igeom=$install_dir/cgm
  config_string+=" "--with-imesh=$install_dir/moab
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build PyTAPS
function build_pytaps() {
  name=pytaps
  version=$pytaps_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=$version

  setup_build repo python

  setup_string=
  if [[ " ${packages[@]} " =~ " cgm " ]]; then
    setup_string+=" "--iGeom-path=$install_dir/cgm
  fi
  setup_string+=" "--iMesh-path=$install_dir/moab
  setup_string_2=
  setup_string_2+=" "--prefix=$install_dir/$folder

  cd $name
  python setup.py $setup_string install $setup_string_2

  finalize_build
}

# Build MCNP5
function build_mcnp5() {
  # build MCNP5 when we build DAGMC
  :
}

# Build Geant4
function build_geant4() {
  name=geant4
  version=$geant4_version
  folder=$name-$version
  tarball=$name.$version.tar.gz
  tar_f=$name.$version
  url=http://geant4.cern.ch/support/source/$tarball

  setup_build tar

  cmake_string=
  cmake_string+=" "-DGEANT4_USE_SYSTEM_EXPAT=OFF
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  cmake_string+=" "-DGEANT4_INSTALL_DATADIR=$install_dir/$folder
  cmake_string+=" "-DGEANT4_INSTALL_DATA=ON
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder

  cd bld
  cmake ../src $cmake_string
  make -j $jobs
  make install

  finalize_build
}

# Build FLUKA
function build_fluka() {
  name=fluka
  version=$fluka_version
  folder=$name-$version
  tarball=fluka$version-linux-gfor64bitAA.tar.gz

  cd $install_dir
  ln -snf $folder $name
  mkdir -p $folder/bin
  cd $folder/bin
  tar -xzvf $dist_dir/$tarball
  export FLUFOR=gfortran
  export FLUPRO=$PWD

  make
  bash flutil/ldpmqmd

  finalize_build
}

# Build DAGMC
function build_dagmc() {
  name=dagmc
  version=$dagmc_version
  folder=$name-$version
  repo=https://github.com/makeclean/$name
#  branch=nasa_specific
#  repo=https://github.com/svalinn/dagmc
  branch=add_g4hier
  mcnp5_tarball=mcnp5_dist.tgz

  setup_build repo

  if [[ " ${packages[@]} " =~ " mcnp5 " ]]; then
    cd $name/mcnp/mcnp5
    tar -xzvf $dist_dir/$mcnp5_tarball Source
    patch -p0 < patch/dagmc.patch.5.1.60
    cd ../../..
  fi
  if [[ " ${packages[@]} " =~ " fluka " ]]; then
    if [ ! -x $install_dir/fluka/bin/flutil/rfluka.orig ]; then
      patch -Nb $install_dir/fluka/bin/flutil/rfluka $name/fluka/rfluka.patch
    fi
  fi

  cmake_string=
  if [[ " ${packages[@]} " =~ " mcnp5 " ]]; then
    cmake_string+=" "-DBUILD_MCNP5=ON
    cmake_string+=" "-DMCNP5_DATAPATH=$DATAPATH
    cmake_string+=" "-DBUILD_SOURCES=ON
    if [[ " ${packages[@]} " =~ " openmpi " ]]; then
      cmake_string+=" "-DMPI_BUILD=ON
    fi
  fi
  if [[ " ${packages[@]} " =~ " geant4 " ]]; then
    cmake_string+=" "-DBUILD_GEANT4=ON
    cmake_string+=" "-DGEANT4_DIR=$install_dir/geant4
    cmake_string+=" "-DGEANT4_CMAKE_CONFIG:PATH=$install_dir/geant4/lib64/Geant4-10.2.0
  fi
  if [[ " ${packages[@]} " =~ " fluka " ]]; then
    cmake_string+=" "-DBUILD_FLUKA=ON
    cmake_string+=" "-DFLUKA_DIR=$install_dir/fluka/bin
  fi
  #cmake_string+=" "-DNASA=ON
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  cmake_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_LINKER=$install_dir/binutils-gdb/bin/ld
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder
  cmake_string+=" "$build_dir/$folder/src

  cd bld
  cmake ../. $cmake_string
  make -j $jobs
  make install

  finalize_build
}

# Build PyNE
function build_pyne() {
  name=pyne
  version=dev
  folder=$name-$version
  repo=https://github.com/pyne/$name
  branch=develop

  setup_build repo python

  setup_string=
  setup_string+=" "-DMOAB_INCLUDE_DIR=$install_dir/moab/include
  setup_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  setup_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  setup_string_2=
  #setup_string_2+=" "--bootstrap
  setup_string_2+=" "--prefix=$install_dir/$folder

  cd $name
  python setup.py $setup_string install $setup_string_2 -j $jobs
  nuc_data_make

  finalize_build
}

# Build SRAG
function build_srag() {
  folder=srag

  repo=https://github.com/makeclean/SRAGCodes.git 
  branch=update_build

  pwd
  cd $build_dir
  pwd
  mkdir srag
  cd srag
  mkdir bld

  git clone $repo $folder
  cd srag
  git checkout $branch
  cd ../bld
  pwd
  CXX=/tmp/adavis23/opt/gcc/bin/g++ cmake ../srag -DCMAKE_INSTALL_PREFIX=$install_dir/$folder/
  export LD_LIBRARY_PATH=$install_dir/$folder/lib:$LD_LIBRARY_PATH
  export SRAGCODE_DIR=$install_dir/$folder/
  make
#  make test
  make install
  cp -r ../srag/* $install_dir/$folder/.
  ls $install_dir
  ls $install_dir/$folder
  cd ..
  cd srag
  pwd
  echo $install_dir/hdf5
  ./build_fluka $install_dir/hdf5
  cp flukahp $install_dir/$folder/.
  name=srag
  finalize_build
}
