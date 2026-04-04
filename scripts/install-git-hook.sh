#!/bin/sh
set -e

# Installs hooks/post-commit into the repository's .git/hooks directory.
# Usage: ./scripts/install-git-hook.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_NAME="post-commit"
HOOK_SRC="$REPO_ROOT/hooks/$HOOK_NAME"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Not a git repository (run this from inside your repo)."
  exit 1
fi

GIT_HOOK_DIR="$(git rev-parse --git-dir)/hooks"
HOOK_DST="$GIT_HOOK_DIR/$HOOK_NAME"

if [ ! -f "$HOOK_SRC" ]; then
  echo "Hook source not found: $HOOK_SRC"
  exit 1
fi

mkdir -p "$GIT_HOOK_DIR"
cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"

echo "Installed $HOOK_NAME -> $HOOK_DST"
echo "You can now commit; the hook will try to push after each commit."
