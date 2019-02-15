workflow "Auto-merge PRs" {
  resolves = ["check success"]
  on = "pull_request"
}

action "check success" {
  uses = "actions/bin/filter@46ffca7632504e61db2d4cb16be1e80f333cb859"
  args = "env | sort; echo \"'$@'\"; cat \"$GITHUB_EVENT_PATH\"; cat \"$GITHUB_EVENT_PATH\" | jq"
  secrets = ["GITHUB_TOKEN"]
}
