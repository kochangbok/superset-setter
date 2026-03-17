# Superset 자동 bootstrap 끄는 법

현재 자동화는 아래 LaunchAgent로 동작합니다.

- Label: `com.george.superset.auto-bootstrap`
- plist: `~/Library/LaunchAgents/com.george.superset.auto-bootstrap.plist`
- watcher script: `~/.superset/bin/ensure-superset-project-bootstrap`

## 1) 일시적으로 끄기

아래 명령을 실행하면 자동 bootstrap 감시만 중지됩니다.

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.george.superset.auto-bootstrap.plist"
```

확인:

```bash
launchctl print "gui/$(id -u)/com.george.superset.auto-bootstrap"
```

중지된 상태라면 에러가 나거나 서비스 정보가 나오지 않습니다.

## 2) 다시 켜기

```bash
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.george.superset.auto-bootstrap.plist"
launchctl kickstart -k "gui/$(id -u)/com.george.superset.auto-bootstrap"
```

## 3) 완전히 제거하기

자동 bootstrap 자체를 아예 없애려면:

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.george.superset.auto-bootstrap.plist" || true
rm -f "$HOME/Library/LaunchAgents/com.george.superset.auto-bootstrap.plist"
rm -f "$HOME/.superset/bin/ensure-superset-project-bootstrap"
```

선택적으로 템플릿/헬퍼도 같이 지울 수 있습니다.

```bash
rm -rf "$HOME/.superset/templates/repo-bootstrap"
rm -f "$HOME/.superset/bin/apply-superset-bootstrap"
```

## 4) 주의사항

- 이미 생성된 repo 안의 `.superset/config.json`, `setup.sh`, `teardown.sh`, `.gitignore` 변경은 자동으로 되돌아가지 않습니다.
- `~/.superset/.env.local` 파일도 삭제되지 않습니다.
- 자동화를 꺼도 기존 repo/workspace는 그대로 유지됩니다.
