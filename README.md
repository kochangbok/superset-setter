# superset-setter

Superset workspace bootstrap and migration notes.

## What this repo provides

- Shared `.superset/config.json`
- Conditional `setup.sh` / `teardown.sh`
- Auto-bootstrap notes for new repos under `~/projects`
- Migration tooling for moving repo roots from `~/.superset/projects` to `~/projects`
- Disable / recovery / execution checklist docs

## Current operating model

- Project repos live under `~/projects`
- Superset worktrees stay under `~/.superset/worktrees`
- Shared env comes from `~/.superset/.env.local`
- New repos under `~/projects` are auto-bootstrapped with `.superset/` files

## Key docs

- Final summary: `.superset/final-summary.md`
- Disable auto-bootstrap: `.superset/disable-auto-bootstrap.md`
- Migration guide: `.superset/migrate-projects-to-home-projects.md`
- Migration checklist: `.superset/migration-execution-checklist.md`

## GitHub

- Private repo: `https://github.com/kochangbok/superset-setter`
