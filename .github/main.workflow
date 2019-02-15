workflow "Auto-merge PRs" {
  resolves = ["check success"]
  on = "status"
}

action "check success" {
  uses = "actions/bin/filter@master"
  args = "env | sort; jq . \"$GITHUB_EVENT_PATH\"; [ \"$(jq -r .context \"$GITHUB_EVENT_PATH\")\" = 'continuous-integration/travis-ci/prcontinuous-integration/travis-ci/pr' ]; echo $?"
  secrets = ["GITHUB_TOKEN"]
}
