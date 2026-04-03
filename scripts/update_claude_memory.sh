#!/usr/bin/env bash
# Weekly Claude memory updater — updates project_mellow_overview.md
# Run by launchd weekly; logs to /tmp/claude_memory_update.log

set -euo pipefail

REPO_DIR="/Users/ferguskelledy/MENU/rails/smart-menu"
MEMORY_DIR="/Users/ferguskelledy/.claude/projects/-Users-ferguskelledy-MENU-rails-smart-menu/memory"
LOG="/tmp/claude_memory_update.log"

echo "[$(date)] Starting memory update" >> "$LOG"

cd "$REPO_DIR"

/Users/ferguskelledy/.local/bin/claude \
  --dangerously-skip-permissions \
  -p "You are updating the mellow.menu project memory file. The working directory is /Users/ferguskelledy/MENU/rails/smart-menu.

Your task:
1. Run \`git log --oneline --since='2 weeks ago'\` to see recent commits.
2. Read \`docs/features/todo/PRIORITY_INDEX.md\` to understand current priorities.
3. Check for any files in \`docs/features/completed/\` added or modified in the last 2 weeks.
4. Read the current memory overview at \`$MEMORY_DIR/project_mellow_overview.md\`.
5. Update \`$MEMORY_DIR/project_mellow_overview.md\` to reflect any new features shipped (add rows to the feature table), any resolved issues, and any new outstanding concerns. Do NOT remove existing content unless it is factually incorrect — only add or correct.
6. If the MEMORY.md index at \`$MEMORY_DIR/MEMORY.md\` needs updating (e.g. a one-line summary changed), update it too.

Keep changes minimal and accurate. Only update what has genuinely changed. Do not speculate.
Today's date is $(date '+%Y-%m-%d')." \
  >> "$LOG" 2>&1

echo "[$(date)] Memory update complete" >> "$LOG"
