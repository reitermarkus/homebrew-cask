workflow "Auto-merge PRs" {
  on = "status"
  resolves = ["Filter version bumps.", "Show environment.", "Show event info."]
}

action "Filter successful Travis CI builds." {
  uses = "actions/bin/filter@master"
  args = "[ \"$(jq -r .context \"$GITHUB_EVENT_PATH\")\" = 'continuous-integration/travis-ci/pr' ] && [ \"$(jq -r .state \"$GITHUB_EVENT_PATH\")\" = 'success' ]"
  secrets = ["GITHUB_TOKEN"]
}

action "Filter version bumps." {
  uses = "actions/bin/filter@master"
  needs = ["Filter successful Travis CI builds."]
  args = "jq . \"$GITHUB_EVENT_PATH\""
}

action "Show environment." {
  uses = "actions/bin/filter@46ffca7632504e61db2d4cb16be1e80f333cb859"
  args = "env | sort"
}

action "Show event info." {
  uses = "actions/bin/filter@46ffca7632504e61db2d4cb16be1e80f333cb859"
  args = "jq . \"$GITHUB_EVENT_PATH\""
}
