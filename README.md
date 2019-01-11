# GCP CLI Orb

Easily install and configure the Google Cloud CLI in your CircleCI jobs.

## Usage

See [this orb's listing in CircleCI's orb registry](https://circleci.com/orbs/registry/orb/circleci/gcp-cli) for details on usage, or see setup notes below:

## Setup

In order to use this orb, the following environment variables must be available in your CircleCI job (they can be stored as [Contexts](https://circleci.com/docs/2.0/contexts) resources or as [project-level environment variables](https://circleci.com/docs/2.0/env-vars/#setting-an-environment-variable-in-a-project)):

* `GCLOUD_SERVICE_KEY`: environment variable for GCP login

Parameter values:
* `GOOGLE_PROJECT_ID`
* `GOOGLE_COMPUTE_ZONE`

## Example

```yaml
version: 2.1

orbs:
  gcp-cli: circleci/gcp-cli@1.0.2

workflows:
  install_and_configure_cli:
    # optionally determine executor to use
    executor: default
    jobs:
      - gcp-cli/install_and_initialize_cli:
          context: myContext # store your gCloud service key via Contexts,
          # or project-level environment variables
          # the below two environment variables may also be stored as environment variables,
          # or else manually passed in as string arguments
          google-project-id: myGoogleProjectId
          google-compute-zone: myGoogleComputeZone
```
