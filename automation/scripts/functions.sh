## Print $1 blank lines
function printBlankLines(){
  local AMOUNT=$1

  if [ "$AMOUNT" == "" ] ; then
    AMOUNT=1
  fi
  for i in $(seq 1 $AMOUNT); do
    echo ""
  done
}

## Determine the type of pipeline to generate
function getType(){
  local TYPE=$1

  #Only support single pipeline for now
  echo "single"
}

# Validate if the required config properties are present
function validateConfig(){
  local CONFIG_FILE=$1
  local REQUIRED_KEYS=""environments" "skeleton" "image""
  local KEY=

  ##Check if file exists
  if [ ! -e ${CONFIG_FILE} ]; then
    echo -e "${RED}${BOLD}Error:${RESET}${LIGHT_RED} Config file ${CONFIG_FILE} does not exist for project.${RESET}"
    exit 100
  fi

  ##Check if valid yaml
  yq e ${CONFIG_FILE} > /dev/null 2>&1
  if [ "${?}" != "0" ]; then
    echo -e "${RED}${BOLD}Error:${RESET}${LIGHT_RED} Config file ${CONFIG_FILE} is not valid.${RESET}"
    yq e ${CONFIG_FILE}
    exit 100
  fi

  ##Check if necessary keys are present
  for KEY in ${KEYS}; do
    if [ $(yq e ". | has(\"${KEY}\")") == "true" ]  ; then
      echo -e "${RED}${BOLD}Error:${RESET}${LIGHT_RED} Required key \`${KEY}\` is not present in the config file.${RESET}"
      exit 100
    fi
  done

  if [[ "$(getEnvironments ${CONFIG_FILE})" == *"_"*  ]] ; then
    echo -e "${RED}${BOLD}Error:${RESET}${LIGHT_RED} Environments can not contain the following character: \`_\`${RESET}"
    echo "Aborting....."
    exit 100
  fi

  #check if values are all strings
}

# Get the environment names from the config yaml file
#
# Parameters:
# $1: Path to the config file
#
function getEnvironments(){
  CONFIG_FILE=$1
  echo $(yq e -o=json ${CONFIG_FILE} | jq -r '.environments | join(" ")')
}

# Get environment name based on the key $1
function getEnvironmentForKey(){
  TEMP_KEY=$1
  echo $(yq e -o=json ${CONFIG_FILE} | jq -r ".environments.${TEMP_KEY}")
}

# Get the docker image name from the config yaml file
#
# Parameters:
# $1: Path to the config file
#
function getImage(){
  CONFIG_FILE=$1
  echo $(yq e -o=json ${CONFIG_FILE} | jq -r '.image')
}

# Get the environment keys from the config yaml file
#
# Parameters:
# $1: Path to the config file
#
function getEnvironmentKeys(){
  CONFIG_FILE=$1
  echo $(yq e -o=json ${CONFIG_FILE} | jq '.environments' | jq -r 'keys_unsorted | join(" ")')
}

# Get the skeleton stacks from the config yaml file
#
# Parameters:
# $1: Path to the config file
#
function getSkeletonStacks(){
  CONFIG_FILE=$1
  yq e -o=json ${CONFIG_FILE} | jq -r '.skeleton | join(" ")'
}

function isMac(){
  if [[ "$OSTYPE" == "darwin"* ]] ; then
    echo "1"
  else
    echo "0"
  fi
}

# Get the skeleton stacks from the config yaml file
#
# Parameters:
# $1: Path to the config file
#
function getStacksToIgnore(){
  CONFIG_FILE=$1
  echo $(yq e -o=json ${CONFIG_FILE} | jq -r '.ignore_stacks | join(" ")?')
}
