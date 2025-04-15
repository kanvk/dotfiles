NVVER=2025
# Nvidia HPC SDK Config
NVARCH=`uname -s`_`uname -m`; export NVARCH
NVCOMPILERS=/opt/nvidia/hpc_sdk; export NVCOMPILERS
MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/$NVVER/compilers/man; export MANPATH
PATH=$NVCOMPILERS/$NVARCH/$NVVER/compilers/bin:$PATH; export PATH
# MPI Exports for Nvidia HPC SDK
export PATH=$NVCOMPILERS/$NVARCH/$NVVER/comm_libs/mpi/bin:$PATH
export MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/$NVVER/comm_libs/mpi/man
