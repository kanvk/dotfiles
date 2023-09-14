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

  if [[ $1 == "vv8" ]]; then
    workon vv8
    cd ~/Documents/git/vv8-crawler-slim/
  elif [[ $1 == "base" ]]; then
    conda activate base
  elif [[ $1 == "rapids" ]]; then
    conda activate rapids-23.06
  elif [[ $1 == "base-win" ]]; then
    pwsh.exe -noexit -Command 'cd ~; conda activate base'
  elif [[ $1 == "pdl-win" ]]; then
    pwsh.exe -noexit -Command 'cd ~; conda activate pdl'
  elif [[ $1 == "sdp-las-win" ]]; then
    pwsh.exe -noexit -Command 'cd C:\Users\kanvk\Documents\git\2023FallTeam22-LAS-1; conda activate sdp-las'
    
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

  if [[ $X_ENV == "vv8" ]]; then
    deactivate
    cd $X_ACTIVATE_PATH
  elif [[ $X_ENV == "base" ]]; then
    conda deactivate
  elif [[ $X_ENV == "rapids" ]]; then
    conda deactivate
  elif [[ $X_ENV == "base-win" ]]; then
    # Do nothing
  elif [[ $X_ENV == "pdl-win" ]]; then
    # Do nothing
  elif [[ $X_ENV == "sdp-las-win" ]]; then
    # Do nothing

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
