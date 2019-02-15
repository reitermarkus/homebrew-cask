#!/bin/sh

set -e

export HOMEBREW_GITHUB_ACTION="$GITHUB_ACTION"
export HOMEBREW_GITHUB_ACTOR="$GITHUB_ACTOR"
export HOMEBREW_GITHUB_EVENT_NAME="$GITHUB_EVENT_NAME"
export HOMEBREW_GITHUB_EVENT_PATH="$GITHUB_EVENT_PATH"
export HOMEBREW_GITHUB_REPOSITORY="$GITHUB_REPOSITORY"
export HOMEBREW_GITHUB_SHA="$GITHUB_SHA"
export HOMEBREW_GITHUB_TOKEN="$GITHUB_TOKEN"
export HOMEBREW_GITHUB_WORKFLOW="$GITHUB_WORKFLOW"
export HOMEBREW_GITHUB_WORKSPACE="$GITHUB_WORKSPACE"

export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN"

brew ruby /automerge.rb
