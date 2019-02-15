workflow "Auto-merge PRs" {
  on = "status"
  resolves = ["check success"]
}

action "check success" {
  uses = "actions/bin/filter@46ffca7632504e61db2d4cb16be1e80f333cb859"
  args = "env | sort; echo \"'$@'\"; cat \"$GITHUB_EVENT_PATH\""
  secrets = ["GITHUB_TOKEN"]
}
