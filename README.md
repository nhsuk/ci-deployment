# CI Deployment Scripts

This repo contains deployment scripts executed during project builds on [Travis CI](https://travis-ci.org) and [Gitlab CI](https://about.gitlab.com/features/gitlab-ci-cd/)

The scripts should work across a number of repos that include a `Dockerfile` and a `docker-compose.production.yml` file. They are intended to be included as a [Git submodule](https://git-scm.com/docs/git-submodule) within the code repo.

Including this repo within your own (as detailed below) will:
* Build and tag the Docker image as detailed in the repo's `Dockerfile`. This happens on PR creation/update, tagging (including releases), and commits to the `master` branch
* Push the image to the appropriate docker repo (`nhsuk/$REPO_STUB`)
* If the build has been triggered by a PR a new stack will be created within the `nhsuk-dev` environment on the Rancher server based on the `docker-compose.yml` and `rancher-compose.yml` files found in the `rancher-config/` directory.
* If the build was triggered by a check-in to `master` a deployment will be made to the `nhsuk-dev` environment.
* A publicly accessible URL to the stack will be published as a comment on the PR.

## Setup in code repo (Travis)

1. Add this repo as a submodule into a `scripts` directory of another repo (the target) using `git submodule add https://github.com/nhsuk/ci-deployment.git scripts/ci-deployment`.
2. Add a `docker-compose.yml` and optional `rancher-compose.yml` file to a `rancher-config` directory in your repo.
3. Update the target repo's `.travis.yml` to include the sections included within the example `.travis.yml` in this repo. Note if `scripts\ci-deployment` is not used as the path for `git submodule add` then the scripts in the target repo `.travis.yml` will need to reflect this change.
4. Setup Travis for the repo. Include all [environment variables](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings) not already available within the Travis environment (described below)

## Environment variables

As the scripts are intended to be run within the Travis CI environment they use a number of environment variables available within that environment by default. The table below highlights those that are used along with additional ones that need to be added to the environment. Additional information about Travis environment variables can be found in the Travis [docs](https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables)

| Variable               | Secret | Description| Example | Add to Travis? | Add to Gitlab CI? |
|:---|:---|:---|:---|:---|:---|
| `DOCKER_USERNAME` | NO | A username that has permissions to push images | | YES | |
| `DOCKER_PASSWORD` | YES | The password of the username | | YES | |
| `GITHUB_ACCESS_TOKEN` | YES | OAUTH token with [public repo access](https://developer.github.com/v3/oauth/#scopes) | | YES | |
| `RANCHER_ACCESS_KEY` | NO | The 'user name' part of the API credentials for Rancher access [Rancher API tokens](https://docs.rancher.com/rancher/v1.1/en/api/v1/api-keys/) | | YES | |
| `RANCHER_SECRET_KEY` | YES | The 'password' part of the API credentials for Rancher access [Rancher API tokens](https://docs.rancher.com/rancher/v1.1/en/api/v1/api-keys/) | | YES | |
| `RANCHER_SERVER` | NO | The URL of the Rancher environment | rancher.nhschoices.net | YES | |
| `RANCHER_ENVIRONMENT` | NO | The URL of the Rancher environment | nhsuk-dev | YES | |
| `TRAVIS` | NO | Indicates if the environment is `TRAVIS` | | NO | |
| `TRAVIS_PULL_REQUEST` | NO | PR number | | NO | |
| `TRAVIS_BRANCH` | NO | Branch name triggering the build | | NO | |
| `TRAVIS_TAG` | NO | Name of tag triggering the build | | NO | |

There is a [utility script](./configure-travis-env.sh) to set the non-Travis environment variables from the command line.
It assumes you have the Travis CLI installed and you are already logged into Travis.

### Finally

It is worth noting that it is possible to run the PR script locally by setting the environment variables. For example:

 `TRAVIS=true TRAVIS_REPO_SLUG=nhsuk/connecting-to-services TRAVIS_PULL_REQUEST=<PR number of an image which still exists>  GITHUB_ACCESS_TOKEN=<personal access token> RANCHER_ENVIRONMENT=<rancher env name> ./deploy.sh`
