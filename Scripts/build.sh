#!/bin/bash

set -o pipefail

PARENT_DIRECTORY_PATH=$(cd ../ && pwd)

#############
# FUNCTIONS #
#############

function test_locally {
  echo "$1 is 1"
  # Load and source variables from .env
  source ../.env.development
  export DESTINATION="OS=12.4,name=iPhone Xs"
  export BUILD_NUMBER=$TRAVIS_BUILD_NUMBER
  run_tests $1
}

function setup_bundler {
  # Make sure to use 2.0
  bundle update --bundler

  echo "Installing bundler and gems..."
  gem install bundler; bundle install
}

function run_tests {
  if [ $# = 1 ] ; then
    cd $1
  else
    echo "you must provide the path to run xcbuild."
  fi

  xcodebuild -version -sdk
  xcodebuild clean build test -workspace "$WORKSPACE" \
                              -scheme "$SCHEME" \
                              -sdk "$SDK" \
                              -destination "$DESTINATION" \
                              -enableCodeCoverage YES \
                              -configuration Debug ENABLE_TESTABILITY=YES \
                              ONLY_ACTIVE_ARCH=NO CODE_SIGNING_REQUIRED=NO | bundle exec xcpretty -c;
}

function test_ci {
  if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    echo ""
    echo "This is a PR. No deployment will be done."

    run_tests $1

    exit $?
  fi
}

# -------| Travis

########
# Main #
########

function main() {
  echo ""
  echo "Starting test script."
  echo ""
  echo $#
  echo $1

  if [ -t 1 ] ; then
    test_locally $1
  else
    # Travis-CI
    test_ci $1
  fi
}

main $PARENT_DIRECTORY_PATH/Example
