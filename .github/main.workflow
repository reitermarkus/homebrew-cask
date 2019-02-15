workflow "Auto-merge PRs" {
  on = "status"
  resolves = ["Filter successful Travis CI builds."]
}

action "Filter successful Travis CI builds." {
  uses = "actions/bin/filter@master"
  args = "env | sort; jq . \"$GITHUB_EVENT_PATH\"; [ \"$(jq -r .context \"$GITHUB_EVENT_PATH\")\" = 'continuous-integration/travis-ci/pr' ] && [ \"$(jq -r .state \"$GITHUB_EVENT_PATH\")\" = 'success' ]"
  secrets = ["GITHUB_TOKEN"]
}
