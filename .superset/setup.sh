#!/usr/bin/env bash

set -u

log() {
  printf '[superset setup] %s\n' "$1"
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

copy_root_env() {
  if [ -f "$HOME/.superset/.env.local" ]; then
    cp "$HOME/.superset/.env.local" .env.local || true
    log "copied shared env to .env.local"
  else
    log "skip: shared env file not found at \$HOME/.superset/.env.local"
  fi
}

copy_nested_env_if_needed() {
  local dir
  dir="$1"

  if [ "$dir" = "." ]; then
    return 0
  fi

  if [ -f "$HOME/.superset/.env.local" ] && [ ! -f "$dir/.env.local" ]; then
    cp "$HOME/.superset/.env.local" "$dir/.env.local" || true
    log "copied shared env to $dir/.env.local"
  fi
}

run_stack_setup() {
  local dir
  local label
  dir="$1"

  if [ "$dir" = "." ]; then
    label="root"
  else
    label="$dir"
  fi

  if [ -f "$dir/package.json" ]; then
    log "bun install -> $label"
    (cd "$dir" && run_if_available bun bun install) || true
  fi

  if [ -f "$dir/requirements.txt" ]; then
    log "pip install -r requirements.txt -> $label"
    (cd "$dir" && run_if_available pip pip install -r requirements.txt) || true
  fi

  if [ -f "$dir/pyproject.toml" ]; then
    log "uv sync -> $label"
    (cd "$dir" && run_if_available uv uv sync) || true
  fi

  if [ -f "$dir/go.mod" ]; then
    log "go mod download -> $label"
    (cd "$dir" && run_if_available go go mod download) || true
  fi

  if [ -f "$dir/Cargo.toml" ]; then
    log "cargo fetch -> $label"
    (cd "$dir" && run_if_available cargo cargo fetch) || true
  fi

  if [ -f "$dir/docker-compose.yml" ] || [ -f "$dir/compose.yaml" ]; then
    log "docker compose up -d -> $label"
    (cd "$dir" && run_if_available docker docker compose up -d) || true
  fi
}

copy_root_env

{
  printf '%s\n' "."
  find . \
    \( -path './.git' -o -path './.omx' -o -path './.superset' -o -path './node_modules' -o -path './.venv' -o -path './venv' -o -path './target' -o -path './__pycache__' \) -prune \
    -o -type f \
    \( -name 'package.json' -o -name 'requirements.txt' -o -name 'pyproject.toml' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'docker-compose.yml' -o -name 'compose.yaml' \) \
    -exec dirname {} \;
} | awk '!seen[$0]++' | while IFS= read -r dir; do
  copy_nested_env_if_needed "$dir"
  run_stack_setup "$dir"
done

run_if_available omx omx --version || true
run_if_available omc omc --version || true
if command -v ccusage >/dev/null 2>&1; then
  log "ccusage available"
else
  log "skip: ccusage not found"
fi
