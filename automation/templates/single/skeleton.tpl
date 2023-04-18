##########################################
#             %%ENVIRONMENT%%
##########################################
plan_skeleton_%%ENVIRONMENT%%:
  extends: .before_script_template
  stage: plan_skeleton_%%ENVIRONMENT%%
  artifacts:
    paths:
%%SKELETON_ARTIFACTS%%
  except:
    - tags
  only:
    refs:
      - merge_requests
      - master
    changes:
%%DEPENDENCIES%%
  <<: *plan_skeleton
  variables:
    WORKSPACE: %%ENVIRONMENT%%
    VARIABLES_FILE: %%ENVIRONMENT%%.tfvars
    STACK: skeleton
    SUBSTACK: %%SUBSTACK%%

apply_skeleton_%%ENVIRONMENT%%:
  extends: .before_script_template
  stage: apply_skeleton_%%ENVIRONMENT%%
  when: manual
  <<: *apply_skeleton
  dependencies:
    - plan_skeleton_%%ENVIRONMENT%%
  only:
    refs:
      - master
    changes:
%%DEPENDENCIES%%
  allow_failure: false
  variables:
    WORKSPACE: %%ENVIRONMENT%%
    VARIABLES_FILE: %%ENVIRONMENT%%.tfvars
    STACK: skeleton
    SUBSTACK: %%SUBSTACK%%

