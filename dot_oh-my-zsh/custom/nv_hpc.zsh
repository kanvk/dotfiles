# Nvidia HPC SDK Config
NVARCH=`uname -s`_`uname -m`; export NVARCH
NVCOMPILERS=/opt/nvidia/hpc_sdk; export NVCOMPILERS
MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/23.1/compilers/man; export MANPATH
PATH=$NVCOMPILERS/$NVARCH/23.1/compilers/bin:$PATH; export PATH
# MPI Exports for Nvidia HPC SDK
export PATH=$NVCOMPILERS/$NVARCH/23.1/comm_libs/mpi/bin:$PATH
export MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/23.1/comm_libs/mpi/man