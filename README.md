# CI Deployment Scripts

This repo contains deployment scripts executed during project builds on [Travis CI](https://travis-ci.org)

The scripts should work across a number of repos that include a `Dockerfile`. They are intended to be included as a [Git submodule](https://git-scm.com/docs/git-submodule) within the code repo.

Including this repo within your own (as detailed below) will:
* Build and tag the Docker image as detailed in the repo's `Dockerfile`. This happens on PR, Tag and change to `master` branch.
* Push the image to the docker repo
* If the Travis build has been triggered by a PR a new stack will be created within the dev environment in Rancher. The URL to thatstack will be published in the PR's comments


## Setup in code repo

1. Add this repo as a submodule `git submodule add https://github.com/nhsuk/ci-deployment.git` (note if the submodule is added in a path other than the default the path to the scripts in `.travis.yml` will need updating to that same path)
1. Update that repo's `.travis.yml` to include the sections included within this repo's `.travis.yml` i.e. the ability to run docker, the `after_success` section and the global environment variables
1. Setup Travis for the repo. Include any private [environment variables](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings) not already available within the Travis environment (described below)
1. Run a build via a PR, TAG, Branch and check everything is working


## Environment variables

As the scripts are intended to be run from within the Travis CI environment they use a number of environment variables available within that environment. The table below highlights those that are used along with any additional ones that need to be added to the environment. Additional information about Travis environment variables can be found https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables. To help setting up Travis all of the non-secret env vars have been added to the example `.travis.yml`

| Variable               | Secret | Description                                                                                                                                         | Add to Travis? |
|:-----------------------|:-------|:----------------------------------------------------------------------------------------------------------------------------------------------------|:---------------|
| `DOCKER_REPO`          | NO     | The docker repo where the built image should be pushed e.g. [nhsuk/profiles](https://hub.docker.com/r/nhsuk/profiles/)                              | NO             |
| `DOCKER_USERNAME`      | NO     | A username that has permissions to push images                                                                                                      | NO             |
| `DOCKER_PASSWORD`      | YES    | The password of the username                                                                                                                        | YES            |
| `GITHUB_ACCESS_TOKEN`  | YES    | OAUTH token with [public repo access](https://developer.github.com/v3/oauth/#scopes)                                                                | YES            |
| `RANCHER_ACCESS_KEY`   | NO     | The 'user name' part of the API credentials for Rancher access [Rancher API tokens](https://docs.rancher.com/rancher/v1.1/en/api/v1/api-keys/) | NO             |
| `RANCHER_SECRET_KEY`   | YES     | The 'password' part of the API credentials for Rancher access [Rancher API tokens](https://docs.rancher.com/rancher/v1.1/en/api/v1/api-keys/)  | NO             |
| `RANCHER_ENVIRONMENT`  | NO     | The environment within Rancher where the stack will be deployed to                                                                                  | NO             |
| `RANCHER_TEMPLATE_NAME`| NO     | Name of directory where Rancher config is stored in [nhsuk-rancher-templates](https://github.com/nhsuk/nhsuk-rancher-templates) e.g. `c2s-profiles` | NO             |
| `RANCHER_URL`          | NO     | The URL of the Rancher environment                                                                                                                  | NO             |
| `SPLUNK_HEC_TOKEN`     | YES    | [HTTP Event Collector token](http://dev.splunk.com/view/event-collector/SP-CAAAE7C)                                                                 | YES            |
| `TRAVIS`               | NO     | Indicates if the environment is `TRAVIS`                                                                                                            | NO             |
| `TRAVIS_PULL_REQUEST`  | NO     | PR number                                                                                                                                           | NO             |
| `TRAVIS_BRANCH`        | NO     | Branch name triggering the build                                                                                                                    | NO             |
| `TRAVIS_TAG`           | NO     | Name of tag triggering the build                                                                                                                    | NO             |
There is a utility script [here](./configure-travis-env.sh) to set the non-Travis environment variables from the command line.
It assumes you have the Travis CLI installed and you are already logged into Travis.

Finally, it is worth noting that it is possible to run the scripts locally by setting the envirionment variables. For example:

 `TRAVIS=true RANCHER_TEMPLATE_NAME=c2s-pharmacy-finder TRAVIS_REPO_SLUG=nhsuk/connecting-to-services TRAVIS_PULL_REQUEST=<PR number of an image which still exists> SPLUNK_HEC_TOKEN=<splunk token> GITHUB_ACCESS_TOKEN=<personal access token> ./rancher_pr_deploy.sh nearby-services-api`
