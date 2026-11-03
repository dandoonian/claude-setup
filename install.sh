#!/usr/bin/env bash
# Installs or updates the shared Claude setup on macOS / Linux.
# Safe to run again any time: it pulls the latest version and refreshes everything.
#
# Usage:  ./install.sh                 ask what to do if you already have a CLAUDE.md
#         ./install.sh --merge         keep your CLAUDE.md and add the shared notes
#         ./install.sh --replace       back up your CLAUDE.md and use only the shared notes
#         ./install.sh --abort         stop if you already have a CLAUDE.md
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TARGET_DIR="$CLAUDE_DIR/claude-setup"
USER_MD="$CLAUDE_DIR/CLAUDE.md"
SHARED_MD="$REPO_DIR/CLAUDE.md"
IMPORT_LINE="@~/.claude/claude-setup/CLAUDE.md"

MODE=""
case "${1:-}" in
  "")        ;;
  --merge)   MODE=merge ;;
  --replace) MODE=replace ;;
  --abort)   MODE=abort ;;
  *) echo "Unknown option: $1 (use --merge, --replace or --abort)"; exit 1 ;;
esac

echo "==> Updating repo"
if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$REPO_DIR" pull --ff-only || echo "    Couldn't pull; using the local copy."
fi

# ---------- CLAUDE.md ----------
echo "==> Shared CLAUDE.md"
mkdir -p "$CLAUDE_DIR"

if [ -s "$USER_MD" ] && grep -qxF "$IMPORT_LINE" "$USER_MD"; then
  ACTION=refresh                      # already set up: just refresh the shared copy
elif [ ! -s "$USER_MD" ]; then
  ACTION=merge                        # no file or empty file: nothing to protect
else
  # Warn if their file already contains lines from the shared notes
  OVERLAP=$(grep -v '^[[:space:]]*$' "$SHARED_MD" | grep -cxFf - "$USER_MD" || true)
  echo "    You already have ~/.claude/CLAUDE.md ($(wc -l < "$USER_MD" | tr -d ' ') lines)."
  if [ "$OVERLAP" -gt 0 ]; then
    echo "    Note: $OVERLAP line(s) of the shared notes are already in it. After merging,"
    echo "    remove those from your own file so they don't appear twice."
  fi

  ACTION="$MODE"
  if [ -z "$ACTION" ]; then
    if [ -t 0 ]; then
      while [ -z "$ACTION" ]; do
        echo
        echo "    What do you want to do?"
        echo "      [m] Merge:   keep your file and add the shared notes (recommended)"
        echo "      [r] Replace: back up your file and use only the shared notes"
        echo "      [d] Diff:    show your file vs. the shared notes"
        echo "      [a] Abort:   change nothing"
        read -r -p "    Choice [m/r/d/a]: " CHOICE
        case "$CHOICE" in
          m|M|"") ACTION=merge ;;
          r|R)    ACTION=replace ;;
          a|A)    ACTION=abort ;;
          d|D)    git --no-pager diff --no-index -- "$USER_MD" "$SHARED_MD" || true ;;
          *)      echo "    Please type m, r, d or a." ;;
        esac
      done
    else
      ACTION=merge                    # not interactive: the safe default
    fi
  fi
fi

case "$ACTION" in
  abort)
    echo "    Aborted. Nothing was changed."
    exit 0 ;;
  replace)
    BACKUP="$USER_MD.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$USER_MD" "$BACKUP"
    printf '%s\n' "$IMPORT_LINE" > "$USER_MD"
    echo "    Replaced. Your old file is saved as $BACKUP" ;;
  merge)
    printf '\n%s\n' "$IMPORT_LINE" >> "$USER_MD"
    echo "    Merged. Your own content is untouched; the shared notes load alongside it." ;;
  refresh)
    echo "    Already linked; refreshing the shared notes." ;;
esac

mkdir -p "$TARGET_DIR"
cp "$SHARED_MD" "$TARGET_DIR/CLAUDE.md"

# ---------- Plugins ----------
echo "==> Installing plugins"
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add dandoonian/claude-setup >/dev/null 2>&1 \
    || claude plugin marketplace update dandoonian || true
  claude plugin install claude-setup@dandoonian || true
  # CLAUDE.md asks for /code-review before every push; this provides it.
  claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 || true
  claude plugin install code-review@claude-plugins-official || true
else
  echo "    Claude Code not found. Install it, then run this script again."
fi

echo "==> Done. Restart Claude Code to load the changes."
