# CI Deployment Scripts

This repo contains deployment scripts that are intended to be executed during the build stage on either [Travis CI](https://travis-ci.org) or [Gitlab CI](https://about.gitlab.com/features/gitlab-ci-cd/).

In order for the scripts to function correctly a number of steps must be taken to configure the repo which is to make use of the deployment scripts. Steps include adding this repo as a [Git submodule](https://git-scm.com/docs/git-submodule) along with configuration of a number of files.

Including this repo within your own will:
* Build and tag the Docker image as detailed in the repo's `Dockerfile`. This happens on PR creation/update, tagging (including releases), and commits to the `master` branch
* Push the image to the appropriate docker repo (`nhsuk/$REPO_STUB`)
* If the build has been triggered by a PR a new stack will be created within the `nhsuk-dev` environment on the Rancher server based on the `docker-compose.yml` and `rancher-compose.yml` files found in `./rancher-config/`
* If the build was triggered by a check-in to `master` a deployment will be made to the `nhsuk-dev` environment
* A publicly accessible URL to the stack will be published as a comment on the PR

## Setup in code repo

1. Add this repo as a submodule into `./scripts/` (if the directory doesn't exist, it will need to be created). To include the submodule run `git submodule add https://github.com/nhsuk/ci-deployment.git scripts/ci-deployment`
2. Add a `docker-compose.yml` and optionally, a `rancher-compose.yml` file to `./rancher-config/`, located in the root of the project
3. **(Travis only)** Update the target repo's `.travis.yml` to include the sections included within the example `.travis.yml` in this repo
    - Setup Travis for the repo. Include all [environment variables](https://docs.travis-ci.com/user/environment-variables/#Defining-Variables-in-Repository-Settings) not already available within the Travis environment (described below)
4. **(GitlabCI only)** Update the target repo's `.gitlab-ci.yml` to include the sections included with the example `.gitlab-ci.yml` in this repo
    - Setup Gitlab CI for the repo. Include all [environment variables](https://docs.gitlab.com/ee/ci/variables/)

## Environment variables

As the scripts are intended to be run within the context of a CI environment they are able to use any environment variables already available in that environment by default.
For environment variables that are not CI specific an instance of [Vault](https://www.vaultproject.io/) is available to store and retrieve them. In order to utilise the Vault, two environment variables must be set:

| Variable       | Secret | Description                | Default                | Add to Travis? | Add to Gitlab CI? |
| :---           | :---   | :---                       | :---                   | :---           | :---              |
| `VAULT_SERVER` | NO     | DNS name for vault server  | `vault.nhschoices.net` | YES            | YES               |
| `VAULT_TOKEN`  | YES    | Token used to access Vault |                        | YES            | YES               |

Within the Vault each repo must have all environment variables the scripts require. They are:

| Variable              | Description                                                                                                                                    |
| :---                  | :---                                                                                                                                           |
| `DOCKER_USERNAME`     | A username that has permissions to push images                                                                                                 |
| `DOCKER_PASSWORD`     | The password of the username                                                                                                                   |
| `GITHUB_ACCESS_TOKEN` | OAUTH token with [public repo access](https://developer.github.com/v3/oauth/#scopes), used to post comments to PRs                             |
| `SLACK_HOOK_URL`      | Slack webhook URL for posting updates to                                                                                                       |
| `SLACK_CHANNEL`       | Slack channel to post update to                                                                                                                |
| `RANCHER_ACCESS_KEY`  | The 'user name' part of the API credentials for Rancher access [Rancher API tokens](https://docs.rancher.com/rancher/v1.1/en/api/v1/api-keys/) |
| `RANCHER_SECRET_KEY`  | The 'password' part of the API credentials for Rancher access [Rancher API tokens](https://docs.rancher.com/rancher/v1.1/en/api/v1/api-keys/)  |
| `RANCHER_SERVER`      | The URL of the Rancher environment                                                                                                             |
| `RANCHER_ENVIRONMENT` | The environment which the application will get deployed to                                                                                     |

## Variable Precedence

Within the Vault, variables are loaded in a certain order. If there are multiple variables defined with the same key, the last one defined takes precedence. The order of loading is as following:

| Order | Source                                                          | Used for?                                                                                                                                                                                                           | Example                                                    |
| :---  | :---                                                            | :---                                                                                                                                                                                                                | :---                                                       |
| 1     | TRAVIS/GITLABCI defined vars                                    | Really only needed for VAULT variables or if Vault is unavailable                                                                                                                                                   | VAULT_TOKEN                                                |
| 2     | CI Specific generated values (`$/gitlab/answers/10-defaults.sh` | Scripts in this repo, which generate answers from the variables generated by the CI (see [Gitlab CI](https://docs.gitlab.com/ee/ci/variables/), [Travis CI](https://docs.travis-ci.com/user/environment-variables/) ) | `TRAVIS_PULL_REQUEST=23`  becomes `DOCKER_IMAGE_TAG=pr-23` |
| 3     | VAULT (`defaults`)                                              | common variables for all `nhsuk` applications                                                                                                                                                                       | RANCHER_SERVER                                             |
| 4     | VAULT (`$ENVIRONMENT/defaults`)                                 | Deployment environment specific variables                                                                                                                                                                            | RANCHER_ENV, RANCHER_ACCESS_KEY                            |
| 5     | VAULT (`$APP_NAME/defaults`)                                    | Variables that are common across all deployments of a single application                                                                                                                                            | GOOGLE_ANALYTICS_ID                                        |
| 6     | VAULT (`$ENVIRONMENT/$APP_NAME`)                                | Variables that are specific to an application AND an environment                                                                                                                                                    | DB_HOST, DB_PASS                                           |
| 7     | Repo Specific Answers (`/scripts/answers/*`)                    | Runs all scripts in the application repos `answers` directory. Can be used to overwrite static variables for Review environments.                                                                                   | PR envs have custom `DB_NAME`                              |

### Finally

There is a [utility script](./configure-travis-env.sh) to set the non-Travis environment variables from the command line.
It assumes you have the Travis CLI installed and you are already logged into Travis.

It is worth noting that it is possible to run the PR script locally by setting the environment variables. For example:

`TRAVIS=true TRAVIS_REPO_SLUG=nhsuk/connecting-to-services TRAVIS_PULL_REQUEST=<PR number of an image which still exists>  GITHUB_ACCESS_TOKEN=<personal access token> RANCHER_ENVIRONMENT=<rancher env name> ./deploy.sh`
