# Superset 프로젝트 경로 마이그레이션 실행 체크리스트

목표:

- 원본 repo: `~/.superset/projects` → `~/projects`
- worktree: 계속 `~/.superset/worktrees` 유지

## 왜 Superset 안에서 하면 안 되나

현재 Superset 세션/터미널 자체가 `~/.superset/worktrees/...` 아래에서 실행 중일 수 있습니다.

마이그레이션은 아래를 동시에 건드립니다.

- 원본 repo 경로 이동
- Superset DB 경로 갱신
- `git worktree repair`
- 자동 bootstrap watcher 재설정

그래서 **Superset 앱을 끄고, iTerm2 또는 Terminal에서 실행하는 것이 안전합니다.**

## 실행 전 체크

- [ ] 변경사항이 모두 커밋되었는지 확인
- [ ] Superset 앱 종료
- [ ] Superset이 열어둔 터미널/IDE도 가능하면 종료
- [ ] 새 터미널(iTerm2/Terminal) 열기
- [ ] 작업 위치를 Superset 경로 바깥으로 이동

```bash
cd ~
```

## 1) dry-run

```bash
/Users/george/.superset/worktrees/superset-setter/kochangbok/init/.superset/migrate-projects-to-home-projects.sh
```

확인할 것:

- [ ] 이동 대상 repo 개수가 예상과 맞는지
- [ ] from/to 경로가 맞는지
- [ ] DB 백업 / 경로 갱신 / worktree repair / watcher 변경 예정이 출력되는지

## 2) 실제 적용

```bash
/Users/george/.superset/worktrees/superset-setter/kochangbok/init/.superset/migrate-projects-to-home-projects.sh --apply
```

## 3) 적용 후 확인

### DB 경로 확인

```bash
sqlite3 "$HOME/.superset/local.db" \
  "select name, main_repo_path from projects where main_repo_path like '$HOME/projects/%';"
```

### worktree 정상 동작 확인

예시:

```bash
cd "$HOME/.superset/worktrees/superset-setter/kochangbok/init"
git status --short --branch
```

가능하면 다른 worktree도 1~2개 더 확인:

```bash
cd "$HOME/.superset/worktrees/readme-reader/kochangbok/omx"
git status --short --branch
```

### watcher 확인

```bash
launchctl print "gui/$(id -u)/com.george.superset.auto-bootstrap"
```

## 4) 완료 후

- [x] Superset 다시 실행
- [ ] 프로젝트 목록이 정상적으로 열리는지 확인
- [ ] 새 workspace 생성이 되는지 확인
- [ ] 자동 bootstrap이 계속 되는지 확인

## 롤백이 필요하면

DB 백업은 아래에 생성됩니다.

```text
~/.superset/backups/local.db.YYYYMMDD-HHMMSS.bak
```

역방향 예시:

```bash
/Users/george/.superset/worktrees/superset-setter/kochangbok/init/.superset/migrate-projects-to-home-projects.sh \
  --apply \
  --from "$HOME/projects" \
  --to "$HOME/.superset/projects"
```
