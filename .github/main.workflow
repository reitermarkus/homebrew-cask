workflow "Auto-merge PRs" {
  resolves = ["check success"]
  on = "status"
}

action "check success" {
  uses = "actions/bin/filter@46ffca7632504e61db2d4cb16be1e80f333cb859"
  args = "env | sort; jq . \"$GITHUB_EVENT_PATH\"; [ \"$(jq -r .context \"$GITHUB_EVENT_PATH\")\" = 'continuous-integration/travis-ci/prcontinuous-integration/travis-ci/pr' ]"
  secrets = ["GITHUB_TOKEN"]
}
