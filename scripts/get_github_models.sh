#!/bin/bash
curl -s https://api.githubcopilot.com/models \
  -H "Authorization: Bearer $(cat ~/.config/github-copilot/apps.json | jq -r 'to_entries[0].value.oauth_token')" \
  -H "Content-Type: application/json" \
  -H "Copilot-Integration-Id: vscode-chat" | jq -r '.data[].id'
