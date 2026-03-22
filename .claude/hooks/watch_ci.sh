#!/bin/bash
# Post-tool-use hook: watches GitHub Actions after git push origin and surfaces failures to Claude.
#
# Triggered automatically by Claude Code after every Bash tool call.
# Reads tool input from stdin (JSON), exits 0 silently for non-push commands.
# If CI fails, outputs failure logs to stdout (Claude sees them) and exits 1.

set -euo pipefail

REPO="fkelledy2/smart-menu-rails"

# Read tool input JSON from stdin
INPUT=$(cat)

# Only act on git push commands that target origin
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
if [[ "$COMMAND" != *"git push"*"origin"* ]] && [[ "$COMMAND" != *"push origin"* ]]; then
  exit 0
fi

echo "🔍 Waiting for GitHub Actions run to register..." >&2
sleep 8

# Get the latest run ID
RUN_ID=$(gh run list --repo "$REPO" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null)
if [[ -z "$RUN_ID" ]]; then
  echo "ℹ️  Could not find a GitHub Actions run to watch." >&2
  exit 0
fi

echo "👀 Watching run $RUN_ID (this may take a few minutes)..." >&2

# Watch until complete; exit-status makes it exit non-zero if the run fails
if gh run watch "$RUN_ID" --repo "$REPO" --exit-status 2>/dev/null; then
  echo "" >&2
  echo "✅ GitHub Actions CI passed for run $RUN_ID" >&2
  exit 0
fi

# Run failed — fetch logs and surface them to Claude
echo "" >&2
echo "❌ GitHub Actions run $RUN_ID FAILED. Fetching failure details..." >&2

FAILED_LOGS=$(gh run view "$RUN_ID" --repo "$REPO" --log-failed 2>&1)

# Print to stdout so Claude sees this as hook feedback
cat <<EOF

## GitHub Actions CI Failure — Run $RUN_ID

The following steps failed. Please review the errors below and fix them, then commit and push again.

\`\`\`
$FAILED_LOGS
\`\`\`
EOF

exit 1
