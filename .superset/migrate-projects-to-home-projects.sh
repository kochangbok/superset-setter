#!/usr/bin/env bash

set -euo pipefail

OLD_ROOT="${SUPERSET_PROJECTS_OLD_ROOT:-$HOME/.superset/projects}"
NEW_ROOT="${SUPERSET_PROJECTS_NEW_ROOT:-$HOME/projects}"
DB_PATH="${SUPERSET_DB_PATH:-$HOME/.superset/local.db}"
WATCHER_SCRIPT="${SUPERSET_WATCHER_SCRIPT:-$HOME/.superset/bin/ensure-superset-project-bootstrap}"
LAUNCH_AGENT_PLIST="${SUPERSET_WATCHER_PLIST:-$HOME/Library/LaunchAgents/com.george.superset.auto-bootstrap.plist}"
LAUNCH_AGENT_LABEL="com.george.superset.auto-bootstrap"
DRY_RUN=1

usage() {
  cat <<'USAGE'
Usage: ./.superset/migrate-projects-to-home-projects.sh [--apply] [--from PATH] [--to PATH]

Default behavior is dry-run.

Examples:
  ./.superset/migrate-projects-to-home-projects.sh
  ./.superset/migrate-projects-to-home-projects.sh --apply
  ./.superset/migrate-projects-to-home-projects.sh --apply --from "$HOME/.superset/projects" --to "$HOME/projects"
USAGE
}

log() {
  printf '[migrate-projects] %s\n' "$1"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --apply)
      DRY_RUN=0
      shift
      ;;
    --from)
      OLD_ROOT="$2"
      shift 2
      ;;
    --to)
      NEW_ROOT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ "$OLD_ROOT" = "$NEW_ROOT" ]; then
  echo "Old root and new root are the same: $OLD_ROOT" >&2
  exit 1
fi

if [ ! -d "$OLD_ROOT" ]; then
  echo "Old root does not exist: $OLD_ROOT" >&2
  exit 1
fi

mkdir -p "$NEW_ROOT"

declare -a REPOS
for repo_dir in "$OLD_ROOT"/*; do
  [ -d "$repo_dir" ] || continue
  [ -d "$repo_dir/.git" ] || continue
  REPOS+=("$repo_dir")
done

if [ "${#REPOS[@]}" -eq 0 ]; then
  log "No git repositories found under $OLD_ROOT"
  exit 0
fi

for repo_dir in "${REPOS[@]}"; do
  target_dir="$NEW_ROOT/$(basename "$repo_dir")"
  if [ -e "$target_dir" ] && [ "$repo_dir" != "$target_dir" ]; then
    echo "Target already exists, aborting: $target_dir" >&2
    exit 1
  fi
done

log "Mode: $( [ "$DRY_RUN" -eq 1 ] && printf 'dry-run' || printf 'apply' )"
log "Move repos: $OLD_ROOT -> $NEW_ROOT"
log "Repo count: ${#REPOS[@]}"

for repo_dir in "${REPOS[@]}"; do
  log "repo: $repo_dir -> $NEW_ROOT/$(basename "$repo_dir")"
done

if [ "$DRY_RUN" -eq 1 ]; then
  log "Would backup DB: $DB_PATH"
  log "Would update projects.main_repo_path in $DB_PATH"
  log "Would run git worktree repair in each moved repo"
  log "Would retarget watcher script/plist to: $NEW_ROOT"
  exit 0
fi

if [ ! -f "$DB_PATH" ]; then
  echo "Superset DB not found: $DB_PATH" >&2
  exit 1
fi

BACKUP_DIR="$HOME/.superset/backups"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
DB_BACKUP_PATH="$BACKUP_DIR/local.db.$TIMESTAMP.bak"
mkdir -p "$BACKUP_DIR"
cp "$DB_PATH" "$DB_BACKUP_PATH"
log "DB backup created: $DB_BACKUP_PATH"

launch_agent_was_loaded=0
if launchctl print "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1; then
  launch_agent_was_loaded=1
  launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT_PLIST" >/dev/null 2>&1 || true
  log "Stopped launch agent: $LAUNCH_AGENT_LABEL"
fi

for repo_dir in "${REPOS[@]}"; do
  target_dir="$NEW_ROOT/$(basename "$repo_dir")"
  if [ "$repo_dir" != "$target_dir" ]; then
    mv "$repo_dir" "$target_dir"
    log "Moved: $repo_dir -> $target_dir"
  fi
done

python3 - "$DB_PATH" "$OLD_ROOT" "$NEW_ROOT" <<'PY'
import sqlite3
import sys

db_path, old_root, new_root = sys.argv[1:]

def replace_prefix(value: str | None) -> str | None:
    if value is None:
        return None
    prefix = old_root + "/"
    if value.startswith(prefix):
        return new_root + value[len(old_root):]
    return value

conn = sqlite3.connect(db_path)
cur = conn.cursor()
rows = cur.execute(
    "select id, main_repo_path, worktree_base_dir from projects"
).fetchall()

updated = 0
for project_id, main_repo_path, worktree_base_dir in rows:
    new_main_repo_path = replace_prefix(main_repo_path)
    new_worktree_base_dir = replace_prefix(worktree_base_dir)
    if new_main_repo_path != main_repo_path or new_worktree_base_dir != worktree_base_dir:
        cur.execute(
            "update projects set main_repo_path = ?, worktree_base_dir = ? where id = ?",
            (new_main_repo_path, new_worktree_base_dir, project_id),
        )
        updated += 1

conn.commit()
conn.close()
print(updated)
PY

for repo_dir in "${REPOS[@]}"; do
  target_dir="$NEW_ROOT/$(basename "$repo_dir")"
  git -C "$target_dir" worktree repair >/dev/null 2>&1 || true
  log "Repaired worktrees from: $target_dir"
done

if [ -f "$WATCHER_SCRIPT" ]; then
  python3 - "$WATCHER_SCRIPT" "$NEW_ROOT" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
new_root = sys.argv[2]
text = path.read_text()
text = re.sub(
    r'PROJECTS_DIR="\$\{SUPERSET_PROJECTS_DIR:-[^"]+\}"',
    f'PROJECTS_DIR="${{SUPERSET_PROJECTS_DIR:-{new_root}}}"',
    text,
    count=1,
)
path.write_text(text)
PY
  chmod +x "$WATCHER_SCRIPT"
  log "Updated watcher script: $WATCHER_SCRIPT"
fi

if [ -f "$LAUNCH_AGENT_PLIST" ]; then
  plutil -replace WatchPaths.0 -string "$NEW_ROOT" "$LAUNCH_AGENT_PLIST"
  log "Updated launch agent WatchPaths: $LAUNCH_AGENT_PLIST"
fi

if [ "$launch_agent_was_loaded" -eq 1 ] && [ -f "$LAUNCH_AGENT_PLIST" ]; then
  launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_PLIST"
  launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL"
  log "Restarted launch agent: $LAUNCH_AGENT_LABEL"
fi

log "Migration complete"
log "DB backup: $DB_BACKUP_PATH"
