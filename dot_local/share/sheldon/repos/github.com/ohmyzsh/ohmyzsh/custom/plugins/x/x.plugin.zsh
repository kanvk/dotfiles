# Activates env
function x() {
  # Exit if env is already active
  if [[ ! -z $X_ENV ]]; then
      if [[ $X_ENV == $1  ]]; then
        echo "$X_ENV already active" 1>&2
      else
        echo "$X_ENV is active, deactivate it first" 1>&2
      fi
      return 1
  fi

  # Exit if no env was provided
  if [[ -z $1 ]]; then
    echo "No environment provided" 1>&2
    return 1
  fi

  # Temporarily store current directory
  X_ACTIVATE_PATH_TMP=$(pwd)

  # vv8-crawler-slim
  if [[ $1 == "vv8" ]]; then
    workon vv8
    cd ~/Documents/git/vv8-crawler-slim/
  # triton
  elif [[ $1 == "triton" ]]; then
    conda activate triton
    cd ~/Documents/git/triton
  elif [[ $1 == "base" ]]; then
    conda activate base
  elif [[ $1 == "modin" ]]; then
    conda activate modin
  elif [[ $1 == "pytorch" ]]; then
    conda activate pytorch
  elif [[ $1 == "sklearn" ]]; then
    conda activate sklearn
  elif [[ $1 == "tf" ]]; then
    conda activate tf
    
  # Env not found
  else
    echo "$1 not found" 1>&2
    unset X_ACTIVATE_PATH_TMP
    return 1
  fi

  # Set env vars
  X_ENV=$1
  X_ACTIVATE_PATH=$X_ACTIVATE_PATH_TMP
  unset X_ACTIVATE_PATH_TMP
}

# Deactivates env
function xd() {
  # Exit if no env is active
  if [[ -z $X_ENV ]]; then
    echo "No environment active" 1>&2
    return 1
  fi

  # vv8-crawler-slim
  if [[ $X_ENV == "vv8" ]]; then
    deactivate
    cd $X_ACTIVATE_PATH
  # triton
  elif [[ $X_ENV == "triton" ]]; then
    conda deactivate
    cd $X_ACTIVATE_PATH
  elif [[ $X_ENV == "base" ]]; then
    conda deactivate
  elif [[ $X_ENV == "modin" ]]; then
    conda deactivate
  elif [[ $X_ENV == "pytorch" ]]; then
    conda deactivate
  elif [[ $X_ENV == "sklearn" ]]; then
    conda deactivate
  elif [[ $X_ENV == "tf" ]]; then
    conda deactivate

  # Env not found
  else
    echo "Unable to deactivate. $X_ENV not found" 1>&2
    return 1
  fi
  
  # Unset environment variables
  xc
}

# Clears environment variables
function xc() {
  unset X_ENV
  unset X_ACTIVATE_PATH
}