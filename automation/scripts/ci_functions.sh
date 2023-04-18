# Add a stage to the .gitlab-ci.yml file
#
# Parameters:
# $1: Stage name
#
function addStage(){
  STAGENAME=$1

  ${SED} -i "s/%%STAGES%%/  - ${STAGENAME}\n%%STAGES%%/g" ${SCRIPT_DIR}/.gitlab-ci.yml
}

# Set the on-change for the skeleton stack to the current skeleton stack and all the previous ones.
# Changing the last skeleton stack will only trigger the job for the last skeleton stack and everything that follows
#
# Parameters:
# $1: The array of substacks it needs to create a dependency on
function addDependenciesForSubstack(){
  local SUBSTACK=$1

    ${SED} -i "s/%%DEPENDENCIES%%/      - stacks\/skeleton\/${SUBSTACK}\/*.tf\n%%DEPENDENCIES%%/g"  ${SCRIPT_DIR}/.gitlab-ci.yml
    ${SED} -i "s/%%DEPENDENCIES%%/      - stacks\/skeleton\/${SUBSTACK}\/%%ENVIRONMENT%%.tfvars\n%%DEPENDENCIES%%/g"  ${SCRIPT_DIR}/.gitlab-ci.yml
}

# The before script needs to know which AWS keys to export as "default".
# This function adds the block below per environment through search and replace
#
#    *"${ENVIRONMENT}")
#    export WORKSPACE_NAME="${ENVIRONMENT}"
#    export KEY="${ENVIRONMENT_KEY}"
#    ;;
#
# Parameters:
# $1: ENVIRONMENT       Name of the environment
# $2: ENVIRONMENT_KEY   Key of the environment
#
function addEnvironmentToBeforeScript(){
  ENVIRONMENT=$1
  ENVIRONMENT_KEY=$2
  ${SED} -i "s/%%BEFORE_SCRIPT_ENVIRONMENT%%/\n\
      \*\"_${ENVIRONMENT}\")\n\
      export WORKSPACE_NAME=\"${ENVIRONMENT}\"\n\
      export KEY=\"${ENVIRONMENT_KEY}\"\n\
      ;;%%BEFORE_SCRIPT_ENVIRONMENT%%/g" ${SCRIPT_DIR}/.gitlab-ci.yml
}

