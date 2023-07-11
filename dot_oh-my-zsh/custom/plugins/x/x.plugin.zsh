# Activates env
function x() {
  # Set environment variables
  X_ENV=$1
  X_ACTIVATE_PATH=$(pwd)

  # Already in env
  if [[ -z $X_ENV ]]; then
    echo "$X_ENV already active" 1>&2
    return 1
  # vv8-crawler-slim
  elif [[ $X_ENV == "vv8" ]]; then
    workon vv8
  # triton
  elif [[ $X_ENV == "triton" ]]; then
    conda activate triton
    cd ~/Documents/git/triton
  # Env not found
  else
    echo "$X_ENV not found" 1>&2
    unset X_ENV
    unset X_ACTIVATE_PATH
    return 1
  fi
}

# Deactivates env
function xd() {
  # vv8-crawler-slim
  if [[ $X_ENV == "vv8" ]]; then
    deactivate
    cd $X_ACTIVATE_PATH
  # triton
  elif [[ $X_ENV == "triton" ]]; then
    conda deactivate
    cd $X_ACTIVATE_PATH
  # No env active
  elif [[ $X_ENV == "" ]]; then
    echo "No environment active" 1>&2
    return 1
  # Env not found
  else
    echo "Unable to deactivate. $X_ENV not found" 1>&2
    return 1
  fi
  
  # Unset environment variables
  unset X_ENV
  unset X_ACTIVATE_PATH
}

# Clears environment variables
function xc() {
  unset X_ENV
  unset X_ACTIVATE_PATH
}
