# NVIDIA HPC SDK env — only active if the SDK is installed at its default path.
if [ -d /opt/nvidia/hpc_sdk ]; then
  NVVER=2026
  NVARCH="$(uname -s)_$(uname -m)"
  export NVARCH
  NVCOMPILERS=/opt/nvidia/hpc_sdk
  export NVCOMPILERS
  if [ -d "$NVCOMPILERS/$NVARCH/$NVVER" ]; then
    MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/$NVVER/compilers/man
    export MANPATH
    export PATH="$NVCOMPILERS/$NVARCH/$NVVER/compilers/bin:$PATH"
    # MPI
    export PATH="$NVCOMPILERS/$NVARCH/$NVVER/comm_libs/mpi/bin:$PATH"
    export MANPATH="$MANPATH:$NVCOMPILERS/$NVARCH/$NVVER/comm_libs/mpi/man"
  fi
fi
