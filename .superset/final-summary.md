# Superset 설정 최종 요약

기준 시점: 2026-03-19 (Asia/Seoul)

## 1) 이 repo에 추가된 파일

- `.superset/config.json`
- `.superset/setup.sh`
- `.superset/teardown.sh`
- `.superset/config.local.json`
- `.superset/disable-auto-bootstrap.md`
- `.superset/migrate-projects-to-home-projects.sh`
- `.superset/migrate-projects-to-home-projects.md`
- `.superset/migration-execution-checklist.md`
- `.gitignore`

## 2) 현재 workspace bootstrap 동작

이 repo/workspace에서는 Superset이 아래 스크립트를 사용합니다.

- setup: `./.superset/setup.sh`
- teardown: `./.superset/teardown.sh`

`setup.sh`가 하는 일:

- `~/.superset/.env.local` → workspace `.env.local` 복사
- 루트/하위 디렉토리에서 아래 스택 자동 탐지
  - `package.json`
  - `requirements.txt`
  - `pyproject.toml`
  - `go.mod`
  - `Cargo.toml`
  - `docker-compose.yml`
  - `compose.yaml`
- `omx`, `omc`, `ccusage` 확인

`teardown.sh`가 하는 일:

- docker compose down
- 캐시 디렉토리 정리

## 3) 전역 자동 bootstrap 상태

현재 새 repo 자동 bootstrap은 **켜져 있음**.

- watcher script:
  - `~/.superset/bin/ensure-superset-project-bootstrap`
- helper:
  - `~/.superset/bin/apply-superset-bootstrap`
- template:
  - `~/.superset/templates/repo-bootstrap`
- LaunchAgent:
  - `~/Library/LaunchAgents/com.george.superset.auto-bootstrap.plist`

현재 watcher 감시 경로:

- `/Users/george/projects`

즉 새 git repo가 `~/projects` 아래 생기면 자동으로:

- `.superset/config.json`
- `.superset/setup.sh`
- `.superset/teardown.sh`
- `.gitignore` 추천 항목

이 들어가도록 구성되어 있습니다.

## 4) env / 토큰 상태

공용 env 파일:

- `~/.superset/.env.local`

현재 이 파일에는 아래 키가 들어가도록 정리되어 있습니다.

- `GITHUB_TOKEN`
- `GH_TOKEN`
- `VERCEL_TOKEN`

따라서 bootstrap이 적용된 repo/workspace에서는 위 토큰들이 `.env.local` 복사 시 같이 들어옵니다.

## 5) 프로젝트 경로 마이그레이션 상태

완료 상태:

- 원본 repo 루트:
  - `~/.superset/projects` → `~/projects`
- worktree 루트:
  - 계속 `~/.superset/worktrees`

확인된 상태:

- Superset DB(`~/.superset/local.db`)의 `projects.main_repo_path` 갱신 완료
- `git worktree repair` 반영 완료
- auto-bootstrap watcher도 `~/projects` 기준으로 재설정 완료

참고:

- `~/.superset/projects` 아래에 **git repo가 아닌 잔여 폴더**는 남을 수 있습니다.

## 6) 운영 문서

- 자동 bootstrap 끄는 법:
  - `.superset/disable-auto-bootstrap.md`
- 프로젝트 경로 마이그레이션 설명:
  - `.superset/migrate-projects-to-home-projects.md`
- 실제 실행 체크리스트:
  - `.superset/migration-execution-checklist.md`

## 7) Git / GitHub 상태

GitHub repo:

- `https://github.com/kochangbok/superset-setter`

최근 주요 커밋:

- `fe3150a` — Superset workspace bootstrap scripts 추가
- `b9024f9` — auto bootstrap disable 문서 추가
- `cfa33c4` — project-root migration tooling 추가
- `8d3fade` — migration execution checklist 추가

## 8) 한 줄 결론

현재 상태는:

- **새 repo는 `~/projects` 아래서 자동 bootstrap**
- **worktree는 계속 `~/.superset/worktrees`에서 사용**
- **GitHub / Vercel 토큰은 공용 env에서 자동 복사**
- **필요 시 disable / migration 문서까지 준비 완료**
