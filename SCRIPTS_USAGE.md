# SCRIPTS USAGE — 헬퍼 스크립트 사용법

`scripts/` 의 사용자용 스크립트 4개: `bootstrap.sh`, `new-branch.sh`, `finish-branch.sh`, `cleanup-merged.sh`.

모두 bash 스크립트입니다. **Linux/macOS 기본 셸** 또는 **Windows의 Git Bash / WSL**에서 실행하세요. CMD/PowerShell에서는 동작하지 않습니다.

이 외에 lefthook이 내부적으로 호출하는 검증 스크립트(`check-branch.sh`, `check-commit-msg.sh`)가 있습니다 — [§4 내부 검증 스크립트](#4-내부-검증-스크립트-lefthook이-자동-호출) 참조.

## 사전 준비

- Git 2.30+
- bash 4+ (Git Bash 포함)
- GitHub CLI [`gh`](https://cli.github.com/) + `gh auth login` 완료 — `finish-branch.sh` 필수, `cleanup-merged.sh` 선택
- [lefthook](https://github.com/evilmartians/lefthook) — 클라이언트 hook 사용 시

> 💡 한 번에 설치: [`./scripts/bootstrap.sh`](#0-bootstrapsh--의존성-일괄-설치-1회-실행)

실행 권한 부여 (1회):
```bash
chmod +x scripts/*.sh
```

---

## 0. `bootstrap.sh` — 의존성 일괄 설치 (1회 실행)

`gh`, `lefthook` 설치 + `lefthook install`까지 자동으로 처리합니다. **1회성 셋업 전용**입니다. idempotent하므로 여러 번 실행해도 안전합니다.

### Usage
```bash
./scripts/bootstrap.sh              # 대화형 — 각 설치 단계마다 [y/N] 확인
./scripts/bootstrap.sh --yes        # 비대화형 — 모든 설치 자동 승인
./scripts/bootstrap.sh -y           # --yes 의 축약형
```

### 자동 설치 매트릭스

| Tool | brew | winget | scoop | dnf | pacman | apt |
|---|---|---|---|---|---|---|
| `gh` | ✅ | ✅ | ✅ | ✅ | ✅ | URL 안내 |
| `lefthook` | ✅ | ✅ | ✅ | URL 안내 | URL 안내 | URL 안내 |

**URL 안내** 셀은 자동 설치하지 않고 공식 가이드 링크만 출력합니다. 사용자가 직접 설치하세요.

### 에러 케이스

```bash
$ ./scripts/bootstrap.sh foo
❌ 알 수 없는 인자: foo
Usage: ./scripts/bootstrap.sh [--yes]

$ ./scripts/bootstrap.sh    # 패키지 매니저 미감지
❌ gh: 설치되어 있지 않습니다.
   감지된 환경(PM=unknown)에 자동 설치 명령이 없습니다.
   수동 설치 가이드: https://cli.github.com/

$ ./scripts/bootstrap.sh    # 사용자가 거절
❌ lefthook: 설치되어 있지 않습니다.
   설치 명령: brew install lefthook
   이 명령을 실행하시겠습니까? [y/N]: n
   취소됨.

$ ./scripts/bootstrap.sh    # winget 설치 후 PATH 미갱신
⚠️  설치는 끝났지만 현재 셸에서 'lefthook'을 찾지 못합니다.
   새 터미널을 열거나 셸을 재시작한 뒤 다시 실행하세요.
```

### 종료 코드

- `0` — 모든 의존성 OK + lefthook 훅 설치 완료
- `1` — 한 가지라도 누락/거절/PATH 미갱신. 새 셸에서 재실행하면 대부분 OK가 됩니다.

---

## 1. `new-branch.sh` — 새 작업 브랜치 생성

main을 최신화한 뒤 `<type>/<name>` 형식의 새 브랜치를 만들고 체크아웃합니다.

### Usage
```bash
./scripts/new-branch.sh                    # 인터랙티브 모드 (TTY 필요)
./scripts/new-branch.sh <type>             # name만 프롬프트로 입력
./scripts/new-branch.sh <type> <name>      # 인자 모드 (CI/스크립트 호환)
```

### 인터랙티브 모드

인자 없이 실행하면:

1. 화살표 키(↑↓)로 type 선택 → Enter
2. `브랜치 이름을 입력하세요: ` 프롬프트에 이름 입력

```text
$ ./scripts/new-branch.sh
브랜치 type을 선택하세요 (↑↓ 이동, Enter 확정):
  ▶ feat
    fix
    refactor
    docs
    research
    data
    chore
브랜치 이름을 입력하세요: order router
✅ 새 브랜치 생성: feat/order-router
```

`Ctrl+C`로 중단해도 터미널 커서가 자동 복구됩니다. CI/파이프 등 비-TTY 환경에서는 인자 형식을 쓰세요.

### 인자

- `<type>` — 아래 7개 중 하나 (생략 시 메뉴 선택):
  - `feat` — 신규 기능
  - `fix` — 버그 수정
  - `refactor` — 동작 변경 없는 리팩터
  - `docs` — 문서만 변경
  - `research` — 탐색·실험·리서치
  - `data` — 데이터 관련 작업 (DB 스키마, 마이그레이션, fixture 등)
  - `chore` — 빌드/CI/설정 변경
- `<name>` — 브랜치 이름. 대문자 → 소문자, 공백/언더스코어 → 하이픈으로 자동 변환됩니다. 생략 시 입력 프롬프트.

### 예시

```bash
# 인터랙티브 (type + name 모두 생략)
./scripts/new-branch.sh

# type만 지정
./scripts/new-branch.sh feat
브랜치 이름을 입력하세요: order router
# → feat/order-router 생성

# 인자 모드
./scripts/new-branch.sh feat order-router
./scripts/new-branch.sh data orderbook-v3-migration
./scripts/new-branch.sh fix "WebSocket Reconnect"    # → fix/websocket-reconnect
```

### 에러 케이스

```bash
$ ./scripts/new-branch.sh < /dev/null    # 비-TTY 환경에서 인자 생략
❌ 인터랙티브 모드는 TTY가 필요합니다.
   인자를 직접 지정하세요: ./scripts/new-branch.sh <type> <name>

$ ./scripts/new-branch.sh wrongtype foo
❌ type 'wrongtype'은 허용되지 않습니다.
   허용: feat | fix | refactor | docs | research | data | chore

$ ./scripts/new-branch.sh feat ""
❌ name을 빈 문자열로 지정할 수 없습니다.
```

---

## 2. `finish-branch.sh` — PR 생성

현재 브랜치를 원격에 push하고 `gh pr create --fill`로 PR을 자동 생성합니다.

### Usage
```bash
./scripts/finish-branch.sh
```
(인자 없음)

### 예시

```bash
# feat/order-router 브랜치에서
git add .
git commit -m "feat: add order router"

./scripts/finish-branch.sh
# → push + PR 생성 + PR URL 출력
```

### 에러 케이스

```bash
$ ./scripts/finish-branch.sh    # main 브랜치에서 실행
❌ main 브랜치에서는 실행할 수 없습니다.
   먼저 작업 브랜치로 전환하세요: ./scripts/new-branch.sh <type> <name>

$ ./scripts/finish-branch.sh    # gh CLI 미설치
❌ GitHub CLI(gh)가 설치되어 있지 않습니다.
   설치: https://cli.github.com/

$ ./scripts/finish-branch.sh    # 커밋되지 않은 변경 있음
⚠️  커밋되지 않은 변경 사항이 있습니다:
    M src/foo.py
   계속하려면 먼저 커밋하세요.
```

---

## 3. `cleanup-merged.sh` — 머지된 로컬 브랜치 정리

머지된 로컬 브랜치 + 원격에서 사라진 브랜치 + GitHub에서 MERGED 상태인 PR의 로컬 브랜치를 한 번에 정리합니다. squash merge 및 GitHub auto-delete 미동작 케이스까지 감지합니다.

### Usage
```bash
./scripts/cleanup-merged.sh
```
(인자 없음)

### 예시

```bash
$ ./scripts/cleanup-merged.sh
🔍 main 브랜치 최신화 중...
🔍 원격 추적 정보 정리 중 (git fetch -p)...
🔍 GitHub PR 상태 확인 중 (gh)...

다음 브랜치들이 삭제됩니다:
  feat/order-router
  fix/websocket-reconnect
  data/schema-v3

진행하시겠습니까? [y/N]: y
✅ feat/order-router 삭제 완료 (merged)
   🌐 원격 브랜치도 삭제: origin/fix/websocket-reconnect
✅ fix/websocket-reconnect 삭제 완료 (PR merged on GitHub)
✅ data/schema-v3 삭제 완료 (gone from remote)
```

삭제 사유 태그 3종:

- `(merged)` — 일반 merge commit으로 main에 흡수된 브랜치
- `(gone from remote)` — 원격 브랜치가 사라진 추적 브랜치 (squash merge + auto-delete 정상 동작)
- `(PR merged on GitHub)` — `gh pr list --state merged`로 감지. 원격 브랜치가 남아 있으면 함께 삭제. `gh` CLI 필수.

### gh CLI 미설치/미인증

경고 후 `(merged)` + `(gone from remote)` 두 종류만 정리합니다. 스크립트는 정상 실행됩니다.

```bash
$ ./scripts/cleanup-merged.sh
⚠️  gh CLI 미설치 또는 미인증 — PR 상태 검사를 건너뜁니다.
   (gh CLI를 설치하면 auto-delete가 동작하지 않은 머지된 브랜치도 정리됩니다)
```

### 에러 케이스

```bash
$ ./scripts/cleanup-merged.sh    # 삭제할 브랜치 없음
✅ 정리할 머지된 브랜치가 없습니다.
```

---

## 4. 내부 검증 스크립트 (lefthook이 자동 호출)

`scripts/check-branch.sh`와 `scripts/check-commit-msg.sh`는 lefthook 훅에서 호출되는 검증 스크립트입니다. **사용자가 직접 호출할 필요는 없습니다** — `lefthook install` 한 번으로 자동 등록되어 `git push` / `git commit` 시점에 실행됩니다.

### `check-branch.sh` — pre-push 훅

```bash
bash scripts/check-branch.sh no-main-push   # main/master 직접 push 차단
bash scripts/check-branch.sh name           # 브랜치명 정규식 검증
```

### `check-commit-msg.sh` — commit-msg 훅

Conventional Commits 형식을 검증합니다.

```bash
bash scripts/check-commit-msg.sh <commit-msg-file>
```

### lefthook에 새 검증을 추가할 때

별도 스크립트 파일 + `lefthook.yml`에서는 `bash scripts/check-*.sh ...` 한 줄 호출 패턴을 반드시 따르세요 (인라인 `run: |` 블록 사용 금지). type 목록/정규식을 바꾸면 `CLAUDE.md`의 "일관성 불변식" 9군데를 함께 갱신해야 합니다.

---

## 자주 묻는 질문

### Q. `new-branch.sh`가 main을 pull하다가 실패해요.
A. 로컬 main에 커밋되지 않은 변경이 있거나 머지 충돌이 발생한 경우입니다. stash 또는 커밋 후 재시도하세요.

### Q. `finish-branch.sh`가 PR 본문을 잘못 채웠어요.
A. `--fill`은 마지막 커밋 메시지를 PR 제목/본문으로 사용합니다. `gh pr edit <번호>`로 수정하거나, 직접 호출하세요:
```bash
gh pr create --title "feat: ..." --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```

### Q. Windows CMD/PowerShell에서 실행 안 돼요.
A. **Git Bash**(Git for Windows에 포함) 또는 **WSL**을 사용하세요.

### Q. lefthook과 헬퍼 스크립트의 차이는?
A. lefthook = **검증**(잘못된 브랜치명 차단). 헬퍼 스크립트 = **편의 자동화**(타이핑 최소화). 보완 관계입니다.

### Q. `cleanup-merged.sh`가 머지된 브랜치를 못 잡아요.
A. `gh` CLI가 설치 + 인증되어 있는지 확인하세요. `gh auth status`로 확인 후 필요하면 `gh auth login`. 그 후 다시 실행.
