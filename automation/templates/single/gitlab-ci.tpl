stages:
%%STAGES%%

image: %%IMAGE%%

.before_script_template:
  before_script:
    ## ADD KEY FOR GIT ACCESS
    # run ssh-agent
    - "eval $(ssh-agent -s)"
    # add ssh key stored in SSH_PRIVATE_KEY variable to the agent store
    - echo "$GITLAB_CI_SSH_KEY" > /tmp/gitlab_ci_ssh
    - chmod 600 /tmp/gitlab_ci_ssh
    - ssh-add /tmp/gitlab_ci_ssh
    - case "$CI_JOB_STAGE" in%%BEFORE_SCRIPT_ENVIRONMENT%%
        *)
      echo "-- FAILED - NO VALID WORKSPACE >> echo $WORKSPACE_NAME";
      exit 1
      ;;
      esac
    - |+
      export MYKEY="AWS_ACCESS_KEY_ID_${KEY}"
      export MYSECRET="AWS_SECRET_ACCESS_KEY_${KEY}"
      export MYREGION="AWS_DEFAULT_REGION_${KEY}"
      export AWS_ACCESS_KEY_ID=${!MYKEY}
      export AWS_SECRET_ACCESS_KEY=${!MYSECRET}
      export AWS_DEFAULT_REGION=${!MYREGION}

## Templates

.plan: &validate_plan
  cache:
    key: ${CI_COMMIT_BRANCH}-${CI_JOB_NAME}
    paths:
      - stacks/${STACK}/${SUBSTACK}/.terraform/providers
  allow_failure: false
  script:
    - |
      cd stacks/${STACK}/${SUBSTACK};
      rm -rf .terraform/;
      echo -e "* \n** \n**** Planning stack: ${STACK}/${SUBSTACK} \n** \n* "
      terraform init -no-color -input=false
      terraform workspace select ${WORKSPACE} -no-color || terraform workspace new ${WORKSPACE} -no-color
      terraform plan -out=${WORKSPACE}.tfplan -var-file=${WORKSPACE}.tfvars -input=false -lock=true

.apply: &apply
  cache:
    key: ${CI_COMMIT_BRANCH}-${CI_JOB_NAME}
    paths:
      - stacks/${STACK}/${SUBSTACK}/.terraform/providers
  allow_failure: false
  script:
    - |
      cd stacks/${STACK}/${SUBSTACK};
      rm -rf .terraform/;
      echo -e "* \n** \n**** Applying stack: ${STACK}/${SUBSTACK} \n** \n* "
      terraform init -no-color -input=false
      terraform workspace select ${WORKSPACE} -no-color || terraform workspace new ${WORKSPACE} -no-color
      terraform apply -input=false -lock=true -auto-approve ${WORKSPACE}.tfplan

.plan_skeleton: &plan_skeleton
  script:
    - |
      cd stacks/skeleton;
      for stack in %%SKELETON_STACKS%%
      do
        cd $stack;
        if [ -e ${WORKSPACE}.tfvars ] ; then
          rm -rf .terraform/
          echo -e "* \n** \n**** Validate stack: skeleton/$stack \n** \n* "
          terraform init -input=false
          terraform workspace select ${WORKSPACE} -no-color || terraform workspace new ${WORKSPACE} -no-color
          terraform validate
          terraform plan -out=${WORKSPACE}.tfplan -var-file=${WORKSPACE}.tfvars -input=false -lock=true
        fi
        cd ../
      done

.apply_skeleton: &apply_skeleton
  script:
    - |
      cd stacks/skeleton
      for stack in %%SKELETON_STACKS%%; do
        cd $stack
        if [ -e ${WORKSPACE}.tfvars ] ; then
          echo -e "* \n** \n**** Applying stack: skeleton/$stack \n** \n* "
          terraform init -no-color -input=false
          terraform workspace select ${WORKSPACE} -no-color || terraform workspace new ${WORKSPACE} -no-color
          terraform apply -input=false -lock=true -auto-approve ${WORKSPACE}.tfplan
        fi
        cd ../
      done

