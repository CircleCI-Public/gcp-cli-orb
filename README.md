# GCP CLI Orb [![CircleCI Build Status](https://circleci.com/gh/CircleCI-Public/gcp-cli-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/CircleCI-Public/gcp-cli-orb) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/circleci/gcp-cli)](https://circleci.com/orbs/registry/orb/circleci/gcp-cli) [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/CircleCI-Public/gcp-cli-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

Easily install and configure the Google Cloud CLI in your CircleCI jobs.
## Quick Start guide
1 - Use CircleCI version 2.1 at the top of your .circleci/config.yml file.
```yaml
version: 2.1
```
If you do not already have Pipelines enabled, you'll need to go to Project Settings -> Advanced Settings and turn it on.

2 - Add the _orbs_ stanza below your version, invoking the orb:
```yaml
orbs:
  gcp-cli: circleci/gcp-cli@1.8.2
```

3 - Use gcp-cli elements in your existing workflows and jobs.

## Usage
_For full usage guidelines, see the [orb registry listing](http://circleci.com/orbs/registry/orb/circleci/gcp-cli)._

### Simple usage example
_Install the gcloud CLI, if not available_
```yaml
orbs:
  gcp-cli: circleci/gcp-cli@1.0.0
version: 2.1
workflows:
  install_and_configure_cli:
    jobs:
      - gcp-cli/install_and_initialize_cli:
          context: myContext
          executor: gcp-cli/default
```
## Contributing

We welcome [issues](https://github.com/CircleCI-Public/gcp-cli-orb/issues) to and [pull requests](https://github.com/CircleCI-Public/gcp-cli-orb/pulls) against this repository!

For further questions/comments about this or other orbs, visit [CircleCI's orbs discussion forum](https://discuss.circleci.com/c/orbs).
