#!/usr/bin/env bats
load test_helper
INITIAL_PATH="${PATH}"

setup() {
  TEMPLATE_DIR="${BATS_TMPDIR}/template"
  setup_repo
  [ -d "${TEMPLATE_DIR}" ] && rm -rf "${TEMPLATE_DIR}"
  export PATH="${BATS_TEST_DIRNAME}/..:${INITIAL_PATH}"
}

teardown() {
  delete_repo
  export PATH="${INITIAL_PATH}"
}

@test "shows help when no arguments" {
  repo_run git-rook
  [ $status -eq 0 ]
  echo "$output" | grep 'usage'
}

@test "-h prints help" {
  repo_run git-rook -h
  [ $(expr "${lines[0]}" : "usage") -ne 0 ]
}

@test "fails on unknown option" {
  run git-rook --foo bar
  [ $status -eq 129 ]
}

@test "fails on unknown command" {
  run git-rook foo
  [ $status -eq 1 ]
  [ $(expr "${lines[0]}" : "Unknown option") -ne 0 ]
}

@test "can install hooks to current repo" {
  repo_run git-rook --install
  [ $status -eq 0 ]
  [ -f "${TEST_REPO}/.git/hooks/pre-commit" ]
  [ -d "${TEST_REPO}/.git/hooks/pre-commit.d" ]
  [ -f "${TEST_REPO}/.git/hooks/commit-msg" ]
  [ -d "${TEST_REPO}/.git/hooks/commit-msg.d" ]
}

@test "can install hooks to specific repo" {
  repo_run git-rook --install "${TEST_REPO}"
  [ $status -eq 0 ]
  echo "$output" | grep 'git rook installed hooks at'
  [ -f "${TEST_REPO}/.git/hooks/pre-commit" ]
  [ -d "${TEST_REPO}/.git/hooks/pre-commit.d" ]
  [ -f "${TEST_REPO}/.git/hooks/commit-msg" ]
  [ -d "${TEST_REPO}/.git/hooks/commit-msg.d" ]
}

@test "fails when no -f and existing hook" {
  repo_run git-rook --install
  repo_run git-rook --install
  [ $status -eq 1 ]
  echo "$output" | grep 'exists (use -f to force)'
}

@test "can overwrite existing hooks with -f" {
  repo_run git-rook --install
  repo_run git-rook --install -f
  [ $status -eq 0 ]
  echo "$output" | grep 'git rook installed hooks at'
  echo "$output" | grep 'Overwriting'
}

@test "can install hooks to a template directory" {
  repo_run git-rook --install ${TEMPLATE_DIR}/template
  [ $status -eq 0 ]
  echo "$output" | grep 'git rook installed hooks at'
  [ -f "${TEMPLATE_DIR}/template/hooks/pre-commit" ]
  [ -d "${TEMPLATE_DIR}/template/hooks/pre-commit.d" ]
  [ -f "${TEMPLATE_DIR}/template/hooks/commit-msg" ]
  [ -d "${TEMPLATE_DIR}/template/hooks/commit-msg.d" ]
}

@test "can skip hook using comma separated list of hook names" {
  cd "${TEST_REPO}"
  repo_run git-rook --install
  echo '#!/usr/bin/env bash' > "${TEST_REPO}/.git/hooks/pre-commit.d/a.sh"
  echo -e 'echo "Fail"; exit 1' >> "${TEST_REPO}/.git/hooks/pre-commit.d/a.sh"
  chmod +x "${TEST_REPO}/.git/hooks/pre-commit.d/a.sh"
  echo '#!/usr/bin/env bash' > "${TEST_REPO}/.git/hooks/commit-msg.d/b"
  echo -e 'echo "Fail"; exit 1' >> "${TEST_REPO}/.git/hooks/commit-msg.d/b"
  chmod +x "${TEST_REPO}/.git/hooks/commit-msg.d/b"
  echo 'test' > 'foo.txt'
  git add -A
  output="$(SKIP=a.sh,b git commit -m 'Test' 2>&1)"
  [ "$?" == 0 ]
  echo $output > /tmp/output
  echo "$output" | grep '(pre-commit) skipping a.sh'
  echo "$output" | grep '(commit-msg) skipping b'
}

@test "fails when any hooks fail" {
  repo_run git-rook --install
  echo '#!/usr/bin/env bash' > "${TEST_REPO}/.git/hooks/pre-commit.d/a.sh"
  echo -e 'echo "ABC"; exit 1' >> "${TEST_REPO}/.git/hooks/pre-commit.d/a.sh"
  chmod +x "${TEST_REPO}/.git/hooks/pre-commit.d/a.sh"
  cd "${TEST_REPO}"
  echo 'test' > 'foo.txt'
  git add -A && run git commit -m 'Test'
  [ "$status" -eq 1 ]
  echo "$output" | grep '(pre-commit) a.sh exit code 1, output:'
  echo "$output" | grep '  ABC'
}

@test "--init calls git init and executes post-init hook" {
  repo_run git-rook --install ${TEMPLATE_DIR}
  echo '#!/usr/bin/env bash' > "${TEMPLATE_DIR}/hooks/post-init.d/test"
  echo -e 'git config --local --add foo.bar baz' >> "${TEMPLATE_DIR}/hooks/post-init.d/test"
  chmod +x "${TEMPLATE_DIR}/hooks/post-init.d/test"
  cd "${TEST_REPO}"
  run git rook --init ${TEMPLATE_DIR}
  [ "$status" -eq 0 ]
  echo "$output" | grep '(post-init)'
  [ "$(git config --local --get foo.bar)" == 'baz' ]
}

@test "--init saves template to config" {
  repo_run git-rook --install ${TEMPLATE_DIR}
  cd "${TEST_REPO}"
  run git rook --init ${TEMPLATE_DIR}
  [ "$status" -eq 0 ]
  run git rook --init
  [ "$status" -eq 0 ]
  [ "$(git config --local --get init.templateDir)" == $TEMPLATE_DIR ]
}

@test "--init can prevent remembering template with -n" {
  repo_run git-rook --install ${TEMPLATE_DIR}
  cd "${TEST_REPO}"
  run git rook --init -n ${TEMPLATE_DIR}
  [ "$status" -eq 0 ]
  [ -z "$(git config --local --get init.templateDir)" ]
}

@test "--init can force copy hooks with -n" {
  repo_run git-rook --install ${TEMPLATE_DIR}
  cd "${TEST_REPO}"
  run git rook --init -f ${TEMPLATE_DIR}
  [ "$status" -eq 0 ]
  echo "$output" | grep 'syncing with Git template'
  echo "$output" | grep 'force copying hooks'
}

@test "--list lists hooks" {
  cd "${TEST_REPO}"
  repo_run git-rook --install
  echo '#!/usr/bin/env bash' > "${TEST_REPO}/.git/hooks/pre-commit.d/a"
  echo '#!/usr/bin/env bash' > "${TEST_REPO}/.git/hooks/commit-msg.d/b"
  echo '#!/usr/bin/env bash' > "${TEST_REPO}/.git/hooks/commit-msg.d/c.sh"
  repo_run git-rook --list
  [ "$status" -eq 0 ]
  echo "$output" | grep -E 'pre\-commit\.d/a'
  echo "$output" | grep -E 'commit\-msg\.d/b'
  echo "$output" | grep -E 'commit\-msg\.d/c\.sh'
}
