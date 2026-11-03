#!/usr/bin/env bash
# Installs or updates the shared Claude setup on macOS / Linux.
# Safe to run again any time: it pulls the latest version and refreshes everything.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TARGET_DIR="$CLAUDE_DIR/claude-setup"
IMPORT_LINE="@~/.claude/claude-setup/CLAUDE.md"

echo "==> Updating repo"
if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO_DIR" pull --ff-only || echo "    Couldn't pull; using the local copy."
fi

echo "==> Installing shared CLAUDE.md"
mkdir -p "$TARGET_DIR"
cp "$REPO_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
touch "$CLAUDE_DIR/CLAUDE.md"
if ! grep -qxF "$IMPORT_LINE" "$CLAUDE_DIR/CLAUDE.md"; then
  printf '\n%s\n' "$IMPORT_LINE" >> "$CLAUDE_DIR/CLAUDE.md"
  echo "    Linked it from ~/.claude/CLAUDE.md (your own content there is untouched)."
fi

echo "==> Installing plugins"
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add dandoonian/claude-setup >/dev/null 2>&1 \
    || claude plugin marketplace update dandoonian || true
  claude plugin install claude-setup@dandoonian || true
  # CLAUDE.md asks for /code-review before every push; this provides it.
  claude plugin install code-review@claude-plugins-official || true
else
  echo "    Claude Code not found. Install it, then run this script again."
fi

echo "==> Done. Restart Claude Code to load the changes."
