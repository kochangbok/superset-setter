#!/usr/bin/env bash

set -u

log() {
  printf '[superset teardown] %s\n' "$1"
}

run_if_available() {
  local cmd
  cmd="$1"
  shift

  if command -v "$cmd" >/dev/null 2>&1; then
    "$@"
  else
    log "skip: $cmd not found"
  fi
}

{
  printf '%s\n' "."
  find . \
    \( -path './.git' -o -path './.omx' -o -path './.superset' -o -path './node_modules' -o -path './.venv' -o -path './venv' -o -path './target' \) -prune \
    -o -type f \
    \( -name 'docker-compose.yml' -o -name 'compose.yaml' \) \
    -exec dirname {} \;
} | awk '!seen[$0]++' | while IFS= read -r dir; do
  if [ -f "$dir/docker-compose.yml" ] || [ -f "$dir/compose.yaml" ]; then
    if [ "$dir" = "." ]; then
      log "docker compose down -v -> root"
    else
      log "docker compose down -v -> $dir"
    fi
    (cd "$dir" && run_if_available docker docker compose down -v) || true
  fi
done

find . \
  \( -path './.git' -o -path './.omx' -o -path './.superset' -o -path './node_modules' \) -prune \
  -o -type d \
  \( -name 'temp_cache' -o -name '.pytest_cache' -o -name '__pycache__' \) \
  -exec rm -rf {} + 2>/dev/null || true

log "cache cleanup complete"
