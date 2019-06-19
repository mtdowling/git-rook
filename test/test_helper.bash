#!/bin/bash
export TEST_REPO="$BATS_TMPDIR/test-repo"

delete_repo() {
  rm -rf $TEST_REPO || true
}

setup_repo() {
  delete_repo
  mkdir -p $TEST_REPO
  cd $TEST_REPO
  git init --template bogus_template_dir_that_doesnt_exist
  cd -
}

repo_run() {
  cmd="$1"
  shift
  cd "${TEST_REPO}"
  run "${BATS_TEST_DIRNAME}/../${cmd}" $@
  cd -
}
