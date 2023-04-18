%%STACK%%-%%SUBSTACK%%-plan-%%ENVIRONMENT%%:
  extends: .before_script_template
  stage: plan_%%STACK%%_%%ENVIRONMENT%%
  except:
    - tags
  only:
    refs:
      - master
      - merge_requests
    changes:
      - stacks/%%STACK%%/%%SUBSTACK%%/*.tf
      - stacks/%%STACK%%/%%SUBSTACK%%/**/*.{json,sh}
      - stacks/%%STACK%%/%%SUBSTACK%%/%%ENVIRONMENT%%.tfvars
      - stacks/skeleton/**/*.tf
      - stacks/skeleton/**/%%ENVIRONMENT%%.tfvars
  allow_failure: false
  artifacts:
    paths:
      - stacks/%%STACK%%/%%SUBSTACK%%/%%ENVIRONMENT%%.tfplan
  <<: *validate_plan
  variables:
    WORKSPACE: %%ENVIRONMENT%%
    VARIABLES_FILE: %%ENVIRONMENT%%.tfvars
    STACK: %%STACK%%
    SUBSTACK: %%SUBSTACK%%

%%STACK%%-%%SUBSTACK%%-apply-%%ENVIRONMENT%%:
  extends: .before_script_template
  stage: apply_%%STACK%%_%%ENVIRONMENT%%
  only:
    refs:
      - master
    changes:
      - stacks/%%STACK%%/%%SUBSTACK%%/*.tf
      - stacks/%%STACK%%/%%SUBSTACK%%/**/*.{json,sh}
      - stacks/%%STACK%%/%%SUBSTACK%%/%%ENVIRONMENT%%.tfvars
      - stacks/skeleton/**/*.tf
      - stacks/skeleton/**/%%ENVIRONMENT%%.tfvars
  dependencies:
    - %%STACK%%-%%SUBSTACK%%-plan-%%ENVIRONMENT%%
  when: manual
  allow_failure: false
  <<: *apply
  variables:
    WORKSPACE: %%ENVIRONMENT%%
    VARIABLES_FILE: %%ENVIRONMENT%%.tfvars
    STACK: %%STACK%%
    SUBSTACK: %%SUBSTACK%%

