# gcp-cli-orb
Orb for interacting with Google Cloud Platform from within a CircleCI
build job via the gcloud SDK.

## View in the orb registry
See the [gcp-cli-orb in the registry](https://circleci.com/orbs/registry/orb/circleci/gcp-cli)
for more the full details of jobs, commands, and executors available in this
orb.

## Setup required to use this orb
The following **required** dependencies must be configured in CircleCI in order to
use this orb:
* GCLOUD_SERVICE_KEY - environment variable for GCP login

If set, the following **optional** environment variables will serve as default 
parameter values:
* GOOGLE_PROJECT_ID
* GOOGLE_COMPUTE_ZONE

See CircleCI documentation for instructions on storing environment variables
in either your Project settings or a Context:
* [Setting environment variables in CircleCI](https://circleci.com/docs/2.0/env-vars)

## Sample use in CircleCI config.yml
This example uses the `circleci/gcp-cli` orb to build a docker image based on 
a Dockerfile in the root directory and push it to Google Container Registry,
based on the parameters provided to the `gcp-gcr/build_and_push_image` job:

```yaml
version: 2.1

orbs:
  gcp-cli: circleci/gcp-cli@1.0.0

workflows:
  install_and_initialize_gcloud:
    jobs:
      - gcp-cli/install_and_initialize_cli:
          context: myContext
          google-project-id: myProject
          google-compute-zone: us-west1-b
```
