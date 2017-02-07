# CI Deployment Scripts

This repo contains deployment scripts executed during project builds on [Travis CI](https://travis-ci.org)

The scripts should work across a number of repos that include a `Dockerfile`. They are intended to be included as a [Git submodule](https://git-scm.com/docs/git-submodule) within the code repo.

Including this repo within your own (as detailed below) will:
* Build and tag the Docker image as detailed in the repo's `Dockerfile`. This happens on PR, Tag and change to `master` branch.
* Push the image to the docker repo
* If the Travis build has been triggered by a PR a new stack will be created within the dev environment in Rancher. The URL to thatstack will be published in the PR's comments

## Setup in code repo

1. Add this repo as a submodule
1. Update that repo's `.travis.yml` to include the sections included within this repo's `.travis.yml` i.e. the ability to run docker and the `after_success` section
1. Setup Travis for the repo. Include the [environment variables](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings) not already available within the Travis environment (described below)
1. Run a build via a PR, TAG, Branch and check everything is working

## Environment variables

As the scripts are intended to be by Travis they use a number of environment variables that are available within that environment. The table below highlights those that are used along with any additional ones that need to be added to the environment. Additional information about Travis environment variables can be found https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables

| Variable              | Description                                                                         | Included in Travis environment? |
|:----------------------|:------------------------------------------------------------------------------------|:----------------------------------------|
| `DOCKER_REPO`         | The docker repo where the built image should be pushed e.g. nhsuk/docker-image      | NO               |
| `DOCKER_USERNAME`     | A username that has permissions to push images                                      | NO               |
| `DOCKER_PASSWORD`     | The password of the username                                                        | NO               |
| `SPLUNK_HEC_TOKEN`    | [HTTP Event Collector token](http://dev.splunk.com/view/event-collector/SP-CAAAE7C) | NO               |
| `RANCHER_STACK_NAME`  | Name of directory where rancher config is stored in [nhsuk-rancher-templates](https://github.com/nhsuk/nhsuk-rancher-templates) | NO              |
| `TRAVIS`              | Indicates if the environment is `TRAVIS`                                            | YES              |
| `TRAVIS_PULL_REQUEST` | PR number                                                                           | YES              |
| `TRAVIS_BRANCH`       | Branch name triggering the build                                                    | YES              |
| `TRAVIS_TAG`          | Name of tag triggering the build                                                    | YES              |

