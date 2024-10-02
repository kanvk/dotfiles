# Activates env
function x() {
  # Exit if env is already active
  if [[ ! -z $X_ENV ]]; then
      if [[ $X_ENV == $1  ]]; then
        echo "$X_ENV already active" 1>&2
      else
        echo "$X_ENV is active" 1>&2
      fi
      return 0
  fi

  # Exit if no env was provided
  if [[ -z $1 ]]; then
    echo "No environment active" 1>&2
    return 0
  fi

  # Temporarily store current directory
  X_ACTIVATE_PATH_TMP=$(pwd)

  if [[ $1 == "vv8" ]]; then
    cd ~/dev/36_vv8_phishing
  elif [[ $1 == "base" ]]; then
    conda activate base
  elif [[ $1 == "tf" ]]; then
    conda activate tf
  elif [[ $1 == "base-win" ]]; then
    pwsh.exe -noexit -Command 'cd ~; conda activate base'
  elif [[ $1 == "pdl-win" ]]; then
    pwsh.exe -noexit -Command 'cd ~; conda activate pdl'
  elif [[ $1 == "echolab" ]]; then
    cd ~/dev/echolab
    
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
function xx() {
  # Exit if no env is active
  if [[ -z $X_ENV ]]; then
    echo "No environment active" 1>&2
    return 1
  fi

  if [[ $X_ENV == "vv8" ]]; then
    # Do nothing
    cd $X_ACTIVATE_PATH
  elif [[ $X_ENV == "base" ]]; then
    conda deactivate
  elif [[ $X_ENV == "tf" ]]; then
    conda deactivate
  elif [[ $X_ENV == "base-win" ]]; then
    # Do nothing
  elif [[ $X_ENV == "pdl-win" ]]; then
    # Do nothing
  elif [[ $X_ENV == "echolab" ]]; then
    # Do nothing

  # Env not found
  else
    echo "Unable to deactivate. $X_ENV not found" 1>&2
    return 1
  fi
  
  # cd back and unset environment variables
  cd $X_ACTIVATE_PATH
  xc
}

# Clears environment variables
function xc() {
  unset X_ENV
  unset X_ACTIVATE_PATH
}
