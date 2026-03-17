# `~/.superset/projects` → `~/projects` 안전 마이그레이션

이 문서는 **프로젝트 원본 repo는 `~/projects`로 옮기고**,  
**worktree는 계속 `~/.superset/worktrees` 아래 유지**하려는 경우를 위한 가이드입니다.

## 왜 그냥 `mv` 하면 안 되나

- 기존 worktree의 `.git` 파일은 원본 repo의 **절대 경로**를 가리킵니다.
- Superset DB(`~/.superset/local.db`)의 `projects.main_repo_path`도 기존 경로를 저장합니다.
- 자동 bootstrap watcher도 현재 `~/.superset/projects`를 감시합니다.

즉, 단순 이동만 하면:
- 기존 worktree가 깨질 수 있고
- Superset이 프로젝트 원본을 못 찾을 수 있고
- 새 repo 자동 bootstrap이 멈출 수 있습니다.

## 준비된 스크립트

- 스크립트: `./.superset/migrate-projects-to-home-projects.sh`
- 기본값:
  - from: `~/.superset/projects`
  - to: `~/projects`
- 기본 모드: **dry-run**

## 권장 순서

1. Superset 앱을 종료
2. 관련 터미널/IDE를 닫기
3. dry-run 확인
4. 실제 적용
5. 몇 개 worktree에서 `git status` 확인

## 1) dry-run

```bash
./.superset/migrate-projects-to-home-projects.sh
```

확인 포인트:
- 몇 개 repo가 이동 대상인지
- 어느 경로로 이동되는지
- DB / watcher / worktree repair까지 어떤 작업을 할지

## 2) 실제 적용

```bash
./.superset/migrate-projects-to-home-projects.sh --apply
```

적용 시 자동으로 하는 일:
- `~/.superset/local.db` 백업 생성
- repo 디렉토리 이동
- `projects.main_repo_path` 갱신
- 각 repo에서 `git worktree repair`
- auto-bootstrap watcher 경로를 `~/projects`로 변경
- LaunchAgent 재시작

## DB 백업 위치

적용 시 아래 위치에 백업이 생성됩니다.

```text
~/.superset/backups/local.db.YYYYMMDD-HHMMSS.bak
```

## 적용 후 확인

예시:

```bash
sqlite3 "$HOME/.superset/local.db" \
  "select name, main_repo_path from projects where main_repo_path like '$HOME/projects/%';"

cd "$HOME/.superset/worktrees/superset-setter/kochangbok/init"
git status --short --branch
```

또는 임의의 worktree 몇 개에서 `git status`가 정상 동작하는지 확인하면 됩니다.

## 롤백

1. repo를 다시 원래 위치로 이동
2. DB 백업 복원
3. 필요하면 스크립트를 역방향으로 실행

예시:

```bash
cp "$HOME/.superset/backups/local.db.20260318-000000.bak" "$HOME/.superset/local.db"
./.superset/migrate-projects-to-home-projects.sh --apply --from "$HOME/projects" --to "$HOME/.superset/projects"
```

## 주의

- 현재 열려 있는 worktree/IDE/앱이 많으면 경로 캐시 때문에 혼란이 생길 수 있습니다.
- LaunchAgent 자동화는 이 스크립트가 `~/projects` 기준으로 다시 맞춰줍니다.
- `~/.superset/.env.local`과 토큰 자동 복사는 그대로 유지됩니다.
