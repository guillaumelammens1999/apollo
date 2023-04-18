autodoc_build:
  image: 826481595599.dkr.ecr.eu-west-1.amazonaws.com/autodoc:latest
  stage: autodoc_build
  only:
    refs:
      - master
  artifacts:
    paths:
      - auto-doc
  script:
    - if [[ ! -d "stacks/skeleton/documentation" ]] && [[ ! -d "stacks/infrastructure/documentation" ]]; then exit 0; fi # only run if we have a stacks/skeleton/documentation stack
    - echo "Setting up autodocs"
    - cp -r /var/task/* .
    - ls -alh
    - cd auto-doc
    - ls -alh
    - |
      for ENV_KEY in SSV ACC PRD; do
        export MY_ACCESS_KEY="AWS_ACCESS_KEY_ID_${ENV_KEY}"
        export MY_SECRET_KEY="AWS_SECRET_ACCESS_KEY_${ENV_KEY}"
        export AWS_ACCESS_KEY_ID=${!MY_ACCESS_KEY};
        export AWS_SECRET_ACCESS_KEY=${!MY_SECRET_KEY};
        export MYREGION="AWS_DEFAULT_REGION_${ENV_KEY}"
        export WORKSPACE=${!ENV_KEY}
        export AWS_DEFAULT_REGION=${!MYREGION}
        python autodoc_collector.py $AWS_DEFAULT_REGION $WORKSPACE $CUSTOMER;
      done
    - mkdocs new project
    - python3 autodoc_generator.py
    - cd project
    - cp -r ../overrides ./overrides
    - cp -r ../docs .
    - | 
      if [ -d "../../stacks/skeleton/documentation" ]; then
        cp -r ../../stacks/skeleton/documentation/templates ../templates
        cp -r ../../stacks/skeleton/documentation/images ../docs/assets/images
        cp -r ../../stacks/skeleton/documentation/scripts ../scripts
      elif [ -d "../../stacks/infrastructure/documentation" ]; then
        cp -r ../../stacks/infrastructure/documentation/templates ../templates
        cp -r ../../stacks/infrastructure/documentation/images ../docs/assets/images
        cp -r ../../stacks/infrastructure/documentation/scripts ../scripts
      fi
    - mkdocs build
  variables:
%%AUTODOC_ENVIRONMENT%%

auto-doc-publisher:
  image: 826481595599.dkr.ecr.eu-west-1.amazonaws.com/wikipusher:latest
  stage: autodoc_publish
  dependencies:
    - autodoc_build
  only:
    refs:
      - master
  artifacts:
    paths:
      - auto-doc
  script:
    - |
      if [[ -d "stacks/skeleton/documentation" ]] || [[ -d "../../stacks/infrastructure/documentation" ]] ; then 
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_PRD
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_PRD
        cd auto-doc
        ls
        export BUCKET=$(aws s3 ls |grep s3-doc- | awk -F ' ' '{print $3}')
        aws s3 sync ./project/site s3://$BUCKET
      fi
