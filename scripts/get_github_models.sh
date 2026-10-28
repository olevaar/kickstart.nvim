#!/usr/bin/env bash
# Lists the models available to your GitHub Copilot account. Requires being
# signed in with copilot.lua (:Copilot auth) and jq.
set -euo pipefail

token=$(jq -r 'to_entries[0].value.oauth_token' ~/.config/github-copilot/apps.json)

# Pass the token on stdin so it does not show up in the process list.
printf 'Authorization: Bearer %s\n' "$token" |
  curl -fsS https://api.githubcopilot.com/models \
    -H @- \
    -H "Content-Type: application/json" \
    -H "Copilot-Integration-Id: vscode-chat" |
  jq -r '.data[].id'
