#!/bin/bash

### Script version. Change these values if you make changes to the script. It's the only way to keep track of what version the automation script is
VERSION=1
MAJOR=2
MINOR="6"

#Base Variables
SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_DIR="$( cd "$(dirname "$0")/../" >/dev/null 2>&1 ; pwd -P )"
STACKS_DIR="$( cd "$(dirname "$0")/../stacks" >/dev/null 2>&1 ; pwd -P )"
CONFIG_FILE="${SCRIPT_DIR}/config.yml"

# Include the functions to keep script readability
source ${SCRIPT_DIR}/scripts/functions.sh
source ${SCRIPT_DIR}/scripts/ci_functions.sh


## I hate this part right here
FIND=find
SED="sed"
if [ "$(isMac)" == "1" ] ; then
  FIND="gfind"
  SED="gsed"
fi

## end of this part

##### GENERAL CONFIGURATION #####
# These are central functions, BASH Colors, generic variables and initial info output

## General thoughts
# Maybe it would be more functionally practical to build a JSON file and convert it to a YAML
# Building this file using python is probably functionally more practical than using bash...


### COLOR DEFINITION ###
YELLOW="\x1B[33m"
WHITE="\x1B[39m"
PURPLE="\x1B[38;5;99m"
RED="\x1B[38;5;196m"
LIGHT_RED="\x1B[38;5;160m"

### Font Weights
BOLD="\x1B[1m"
RESET="\x1B[0m"

#Base validation
validateConfig ${CONFIG_FILE}


#find all stacks except for the "skeleton" stack!
STACKS=$(${FIND} ${PROJECT_DIR}/stacks -maxdepth 1 -mindepth 0 -type d -not -path ${PROJECT_DIR}/stacks/skeleton -not -path ${PROJECT_DIR}/stacks -printf "%f ")
#find all substacks in the "skeleton" stack
SKELETON_STACKS=$(getSkeletonStacks ${CONFIG_FILE})
ENVIRONMENTS=( $(getEnvironments ${CONFIG_FILE}) )
ENVIRONMENT_KEYS=( $(getEnvironmentKeys ${CONFIG_FILE}) )
IGNORE_STACKS=( $(getStacksToIgnore ${CONFIG_FILE}) )
TYPE=$(getType $1)
IMAGE=$(getImage ${CONFIG_FILE})



echo -e " ${BOLD}${PURPLE}-----VARIABLES-----${RESET}"
echo -e " ${BOLD} SCRIPT DIRECTORY:${RESET}  ${SCRIPT_DIR}"
echo -e " ${BOLD} CONFIG FILE:${RESET}       ${CONFIG_FILE}"
echo -e " ${BOLD} PROJECT DIRECTORY:${RESET} ${PROJECT_DIR}"
echo -e " ${BOLD} IGNORED STACKS:${RESET}    ${IGNORE_STACKS[@]}"
echo -e " ${BOLD} STACKS:${RESET}            ${STACKS}"
echo -e " ${BOLD} SKELETON STACKS:${RESET}   ${SKELETON_STACKS[@]}"
echo -e " ${BOLD} ENVIRONMENTS:${RESET}      ${ENVIRONMENTS[@]}"
echo -e " ${BOLD} PIPELINE TYPE:${RESET}     ${TYPE}"
echo -e " ${BOLD} ENVIRONMENT_KEYS:${RESET}  ${ENVIRONMENT_KEYS[@]}"
echo -e " ${BOLD} IMAGE:${RESET}             ${IMAGE}"
echo -e " ${BOLD} VERSION:${RESET}           ${VERSION}.${MAJOR}.${MINOR}"
printBlankLines 2


echo -e "${BOLD}${PURPLE}-----SCRIPT EXECUTION-----${RESET}"
echo "Generating the .gitlab-ci.yml file..."

cp ${SCRIPT_DIR}/templates/${TYPE}/gitlab-ci.tpl ${SCRIPT_DIR}/.gitlab-ci.yml
${SED} -i "s/%%IMAGE%%/${IMAGE//\//\\/}/g" ${SCRIPT_DIR}/.gitlab-ci.yml

COUNT_ENVS=${#ENVIRONMENTS[*]}

for (( i=0; i<${COUNT_ENVS}; i++ )); do
  ENVIRONMENT=${ENVIRONMENTS[${i}]}
  ENVIRONMENT_KEY=${ENVIRONMENT_KEYS[${i}]}

  echo "Environment: ${ENVIRONMENT}"

  addEnvironmentToBeforeScript ${ENVIRONMENT} ${ENVIRONMENT_KEY}
  echo "  Stack: Skeleton"

  ARTIFACT_PATH=()

  addStage plan_skeleton_${ENVIRONMENT}
  addStage apply_skeleton_${ENVIRONMENT}

  SKELETON_TEMPLATE_ADDED=false

  for SKELETON_SUBSTACK in ${SKELETON_STACKS}; do
    ##Skip skeleton job if there is no environment file for it
    if [ ! -f ${STACKS_DIR}/skeleton/${SKELETON_SUBSTACK}/${ENVIRONMENT}.tfvars ] ; then
      continue
    fi
    if [[ false = $SKELETON_TEMPLATE_ADDED ]]; then
        cat ${SCRIPT_DIR}/templates/${TYPE}/skeleton.tpl  >> ${SCRIPT_DIR}/.gitlab-ci.yml
        ${SED} -i "s/%%SKELETON_STACKS%%/${SKELETON_STACKS}/g" ${SCRIPT_DIR}/.gitlab-ci.yml
        SKELETON_TEMPLATE_ADDED=true
    fi

    ARTIFACT_PATH=$(${SED} 's#/#\\/#g' <<< "stacks/skeleton/${SKELETON_SUBSTACK}/\${WORKSPACE}.tfplan")
    ${SED} -i "s/%%SKELETON_ARTIFACTS%%/      - ${ARTIFACT_PATH}\n%%SKELETON_ARTIFACTS%%/g"  ${SCRIPT_DIR}/.gitlab-ci.yml

    ${SED} -i "s/%%SUBSTACK%%/${SKELETON_SUBSTACK}/g" ${SCRIPT_DIR}/.gitlab-ci.yml
    addDependenciesForSubstack "${SKELETON_SUBSTACK}"
    ${SED} -i "s/%%ENVIRONMENT%%/${ENVIRONMENT}/g" ${SCRIPT_DIR}/.gitlab-ci.yml
  done
  ${SED} -i "s/%%SKELETON_ARTIFACTS%%//g"  ${SCRIPT_DIR}/.gitlab-ci.yml
  ${SED} -i "s/%%DEPENDENCIES%%//g"  ${SCRIPT_DIR}/.gitlab-ci.yml

  for STACK in ${STACKS} ; do
    SUBSTACKS=$(${FIND} ${PROJECT_DIR}/stacks/${STACK} -maxdepth 1 -mindepth 0 -type d -not -path ${PROJECT_DIR}/stacks/${STACK} -printf "%f ")
    if [ "${SUBSTACKS}" == "" ] ; then
      continue
    fi
    PRINTSTACK=0

    for SUBSTACK in ${SUBSTACKS}; do
      if [ ! -f ${STACKS_DIR}/${STACK}/${SUBSTACK}/${ENVIRONMENT}.tfvars ] ; then
        continue
      fi

      if [[ " ${IGNORE_STACKS[*]} " =~ " ${STACK}/${SUBSTACK} " ]]; then
          continue
      fi

        if [ "$PRINTSTACK" == "0" ] ; then
          PRINTSTACK=1
          echo "  Stack: ${STACK}"
          #add stage for environment plan/apply
          addStage plan_${STACK}_${ENVIRONMENT}
          addStage apply_${STACK}_${ENVIRONMENT}
        fi
        echo "    - ${SUBSTACK}"
        cat ${SCRIPT_DIR}/templates/${TYPE}/stack.tpl  >> ${SCRIPT_DIR}/.gitlab-ci.yml

        ${SED} -i "s/%%SUBSTACK%%/${SUBSTACK}/g" ${SCRIPT_DIR}/.gitlab-ci.yml
    done
    ${SED} -i "s/%%STACK%%/${STACK}/g" ${SCRIPT_DIR}/.gitlab-ci.yml
  done
  ${SED} -i "s/%%ENVIRONMENT%%/${ENVIRONMENT}/g" ${SCRIPT_DIR}/.gitlab-ci.yml
done

printBlankLines 2
echo -e "${BOLD}${PURPLE}-----Adding autodoc at the end-----${RESET}"

addStage "autodoc_build"
addStage "autodoc_publish"

cat ${SCRIPT_DIR}/templates/${TYPE}/documentation.tpl  >> ${SCRIPT_DIR}/.gitlab-ci.yml
KEYS=${ENVIRONMENT_KEYS[@]}

${SED} -i "s#%%ENVIRONMENT_KEYS%%#${KEYS}#g" ${SCRIPT_DIR}/.gitlab-ci.yml
for KEY in ${KEYS}; do
  ${SED} -i "s/%%AUTODOC_ENVIRONMENT%%/    $KEY: $(getEnvironmentForKey $KEY)\n%%AUTODOC_ENVIRONMENT%%/g" ${SCRIPT_DIR}/.gitlab-ci.yml
done

echo -e "   Done!"

printBlankLines 2
echo -e "${BOLD}${PURPLE}-----CLEAN UP-----${RESET}"
echo "  removing lingering placeholders"
${SED} -i "s/%%STAGES%%//g" ${SCRIPT_DIR}/.gitlab-ci.yml
${SED} -i "s/%%BEFORE_SCRIPT_ENVIRONMENT%%//g" ${SCRIPT_DIR}/.gitlab-ci.yml
${SED} -i "s/%%AUTODOC_ENVIRONMENT%%//g" ${SCRIPT_DIR}/.gitlab-ci.yml

mv ${SCRIPT_DIR}/.gitlab-ci.yml ${PROJECT_DIR}/.gitlab-ci.yml