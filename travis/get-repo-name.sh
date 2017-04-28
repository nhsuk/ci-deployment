#!/bin/bash

echo "$TRAVIS_REPO_SLUG" | cut -d "/" -f 2-
