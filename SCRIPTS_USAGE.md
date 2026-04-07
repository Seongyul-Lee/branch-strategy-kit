# SCRIPTS USAGE — 헬퍼 스크립트 사용법

`scripts/` 디렉터리의 **사용자용 스크립트 4개**(`bootstrap.sh`, `new-branch.sh`, `finish-branch.sh`, `cleanup-merged.sh`)의 사용법을 정리합니다. 모두 bash 스크립트로, **Linux/macOS의 기본 셸 또는 Windows의 Git Bash**에서 실행됩니다.

이 외에 lefthook이 내부적으로 호출하는 검증 스크립트(`check-branch.sh`, `check-commit-msg.sh`)가 있습니다 — [§4 내부 검증 스크립트](#4-내부-검증-스크립트-lefthook이-자동-호출) 참조.

## 사전 준비

- Git 2.30+
- bash 4+ (Git Bash 포함)
- GitHub CLI [`gh`](https://cli.github.com/) — `finish-branch.sh` 한정, `gh auth login` 완료 상태
- [lefthook](https://github.com/evilmartians/lefthook) — 클라이언트 hook 사용 시

> 💡 위 의존성을 한 번에 설치하려면 [`./scripts/bootstrap.sh`](#0-bootstrapsh--의존성-일괄-설치-1회-실행)를 실행하세요.

스크립트 실행 권한 부여 (1회):
```bash
chmod +x scripts/*.sh
```

---

## 0. `bootstrap.sh` — 의존성 일괄 설치 (1회 실행)

### 한 줄 요약
환경(OS + 패키지 매니저)을 감지해 `gh`, `lefthook`을 한 번에 설치하고 `lefthook install`까지 자동 수행합니다. **1회성 셋업 전용** — 데일리 워크플로우에는 사용하지 않습니다.

### Usage
```bash
./scripts/bootstrap.sh [--yes]
```

### 인자
- `--yes`, `-y` (선택) — 모든 확인 프롬프트를 자동 승인 (CI/비대화형 환경용)

### 예시

```bash
# 대화형 (기본) — 각 설치 단계마다 [y/N] 확인
./scripts/bootstrap.sh

# 비대화형 — 모든 설치를 자동 승인
./scripts/bootstrap.sh --yes
```

### 동작 단계

1. 인자 파싱 (`--yes` / `-y` 처리)
2. OS 감지 (`macOS` / `Linux` / `WSL` / `Windows-Git-Bash`)
3. 패키지 매니저 감지 (`brew` / `winget` / `scoop` / `dnf` / `pacman` / `apt`)
4. `gh` 설치 여부 확인 → 미설치면 설치 명령 안내 + 사용자 확인 → 실행 → 사후 검증
5. `lefthook` 설치 여부 확인 → 동일 절차
6. `lefthook install` 자동 실행 (git repo + lefthook 존재 시)
7. 결과 요약 표 출력 + 다음 단계 안내

스크립트는 **idempotent**합니다. 두 번 실행해도 안전하며, 이미 설치된 항목은 "이미 설치됨"으로 표시하고 건너뜁니다.

### 자동 설치 매트릭스

| Tool | brew | winget | scoop | dnf | pacman | apt |
|---|---|---|---|---|---|---|
| `gh` | ✅ | ✅ | ✅ | ✅ | ✅ | URL 안내 |
| `lefthook` | ✅ | ✅ | ✅ | URL 안내 | URL 안내 | URL 안내 |

**URL 안내** 셀은 자동 설치를 시도하지 않고 공식 가이드 링크만 출력합니다. 외부 저장소 등록(예: apt 환경의 GitHub repo 추가)이 필요한 경우 키트가 강제하지 않으며, 사용자가 직접 처리해야 합니다.

### 에러 케이스

```bash
$ ./scripts/bootstrap.sh foo
❌ 알 수 없는 인자: foo
Usage: ./scripts/bootstrap.sh [--yes]

$ ./scripts/bootstrap.sh    # 패키지 매니저 미감지 환경
🔍 환경 감지 중...
   OS: linux
   PM: unknown
🔍 의존성 확인 중...
❌ gh: 설치되어 있지 않습니다.
   감지된 환경(PM=unknown)에 자동 설치 명령이 없습니다.
   수동 설치 가이드: https://cli.github.com/

$ ./scripts/bootstrap.sh    # 사용자가 거절
❌ lefthook: 설치되어 있지 않습니다.
   설치 명령: brew install lefthook
   이 명령을 실행하시겠습니까? [y/N]: n
   취소됨.

$ ./scripts/bootstrap.sh    # winget 설치 후 PATH 미갱신
   설치 명령: winget install --id evilmartians.lefthook -e --accept-source-agreements --accept-package-agreements
   이 명령을 실행하시겠습니까? [y/N]: y
   ...
⚠️  설치는 끝났지만 현재 셸에서 'lefthook'을 찾지 못합니다.
   새 터미널을 열거나 셸을 재시작한 뒤 다시 실행하세요.
```

### 종료 코드

- `0` — 모든 의존성이 설치되어 있고 lefthook 훅까지 설치됨
- `1` — 누락/거절/PATH 미갱신/git repo 아님 등 한 가지라도 OK가 아닐 때

`exit 1`은 "재실행이 필요하다"는 신호이지 치명적 실패가 아닙니다. 새 셸을 열고 다시 실행하면 대부분 OK가 됩니다.

---

## 1. `new-branch.sh` — 새 작업 브랜치 생성

### 한 줄 요약
main 브랜치를 최신화한 뒤 `<type>/<name>` 형식의 새 브랜치를 만들고 체크아웃합니다.

### Usage
```bash
./scripts/new-branch.sh <type> <name>
```

### 인자
- `<type>` — 브랜치 타입. 다음 중 하나:
  - `feat` — 신규 기능
  - `fix` — 버그 수정
  - `refactor` — 동작 변경 없는 리팩터
  - `docs` — 문서만 변경
  - `research` — 탐색·실험·리서치
  - `data` — 데이터 관련 작업 (DB 스키마, 마이그레이션, 데이터 파이프라인 등)
  - `chore` — 빌드/CI/설정 변경
- `<name>` — 브랜치 이름. 자동으로 kebab-case로 변환됨 (대문자→소문자, 공백/언더스코어→하이픈).

### 예시 3개

```bash
# 신규 기능
./scripts/new-branch.sh feat order-router
# → feat/order-router 생성

# 데이터 스키마 마이그레이션
./scripts/new-branch.sh data orderbook-v3-migration
# → data/orderbook-v3-migration 생성

# 대문자/공백 자동 변환
./scripts/new-branch.sh fix "WebSocket Reconnect"
# → fix/websocket-reconnect 생성
```

### 동작 단계

1. 인자 검증 (`type`, `name` 둘 다 필수)
2. `type`이 허용 목록에 있는지 검증
3. `name`을 kebab-case로 정규화
4. 정규화된 이름이 빈 문자열이 아닌지 검증
5. `git checkout main` → `git pull` (main 최신화)
6. `git checkout -b <type>/<normalized-name>` (새 브랜치 생성 + 체크아웃)
7. 성공 메시지 출력

### 에러 케이스

```bash
$ ./scripts/new-branch.sh
❌ Usage: ./scripts/new-branch.sh <type> <name>
   type: feat | fix | refactor | docs | research | data | chore
   name: kebab-case (자동 변환)

$ ./scripts/new-branch.sh wrongtype foo
❌ type 'wrongtype'은 허용되지 않습니다.
   허용: feat | fix | refactor | docs | research | data | chore

$ ./scripts/new-branch.sh feat ""
❌ name을 빈 문자열로 지정할 수 없습니다.
```

---

## 2. `finish-branch.sh` — PR 생성

### 한 줄 요약
현재 브랜치를 원격에 push하고 GitHub PR을 자동으로 생성합니다.

### Usage
```bash
./scripts/finish-branch.sh
```

(인자 없음)

### 예시

```bash
# feat/order-router 브랜치에서 작업 후
git add .
git commit -m "feat: add order router"

./scripts/finish-branch.sh
# → push + gh pr create --fill 실행
# → 브라우저에 PR URL 출력
```

### 내부 동작 단계

1. `gh` CLI 설치 여부 확인 (없으면 안내 메시지 출력 후 종료)
2. 현재 브랜치명 확인
3. main 브랜치에서 실행 시도 시 거부
4. 커밋되지 않은 변경 사항 확인 (있으면 경고)
5. `git push -u origin <current-branch>`
6. `gh pr create --fill` (커밋 메시지 기반 PR 자동 생성)
7. PR URL 출력

### 에러 케이스

```bash
$ ./scripts/finish-branch.sh    # main 브랜치에서 실행
❌ main 브랜치에서는 실행할 수 없습니다.
   먼저 작업 브랜치로 전환하세요: ./scripts/new-branch.sh <type> <name>

$ ./scripts/finish-branch.sh    # gh CLI 미설치
❌ GitHub CLI(gh)가 설치되어 있지 않습니다.
   설치: https://cli.github.com/
   또는 수동 PR 생성:
     git push -u origin <current-branch>
     # 그 후 GitHub 웹 UI에서 PR 생성

$ ./scripts/finish-branch.sh    # 커밋되지 않은 변경 있음
⚠️  커밋되지 않은 변경 사항이 있습니다:
    M src/foo.py
   계속하려면 먼저 커밋하세요.
```

---

## 3. `cleanup-merged.sh` — 머지된 로컬 브랜치 정리

### 한 줄 요약
원격에 머지(squash merge 포함)된 로컬 브랜치들을 일괄 삭제합니다.

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

다음 브랜치들이 삭제됩니다:
  feat/order-router
  fix/websocket-reconnect
  data/schema-v3

진행하시겠습니까? [y/N]: y
✅ feat/order-router 삭제 완료
✅ fix/websocket-reconnect 삭제 완료
✅ data/schema-v3 삭제 완료
```

### 동작 단계

1. `git checkout main` → `git pull`
2. `git fetch -p` (원격에서 삭제된 브랜치의 추적 정보 정리)
3. 머지된 로컬 브랜치 목록 수집 (main 제외)
4. 삭제 대상이 없으면 종료
5. 목록을 사용자에게 보여주고 확인 프롬프트 (`y/N`)
6. 확인 시 일괄 삭제, 거부 시 종료

### Squash merge 대응

GitHub의 squash merge는 원본 브랜치 커밋이 main에 직접 머지되지 않아 `git branch --merged`로는 감지되지 않을 수 있습니다. 이 경우 다음 대안을 사용하세요:

```bash
# 원격에서 이미 삭제된 브랜치를 추적하던 로컬 브랜치 일괄 삭제
git fetch -p
git branch -vv | awk '/: gone]/{print $1}' | xargs -r git branch -D
```

이 패턴은 `cleanup-merged.sh` 내부에 추가 단계로 포함되어 있습니다.

### 에러 케이스

```bash
$ ./scripts/cleanup-merged.sh    # 삭제할 브랜치 없음
✅ 정리할 머지된 브랜치가 없습니다.
```

---

## 4. 내부 검증 스크립트 (lefthook이 자동 호출)

`scripts/check-branch.sh`와 `scripts/check-commit-msg.sh`는 lefthook 훅에서 호출되는 검증 스크립트입니다. **사용자가 직접 호출할 필요는 없습니다** — `lefthook install` 한 번으로 자동 등록되어 `git push` / `git commit` 시점에 알아서 실행됩니다.

### `check-branch.sh` — pre-push 훅

두 가지 모드를 지원합니다.

```bash
bash scripts/check-branch.sh no-main-push   # main/master 직접 push 차단
bash scripts/check-branch.sh name           # 브랜치명 정규식 검증
```

### `check-commit-msg.sh` — commit-msg 훅

Conventional Commits 형식을 검증합니다.

```bash
bash scripts/check-commit-msg.sh <commit-msg-file>
```

### 왜 별도 파일로 분리했나

lefthook의 `run: |` 인라인 multi-line 블록은 **Git Bash on Windows**에서 큰따옴표/백슬래시 이스케이프가 mangle되는 버그가 있습니다. 검증 로직을 `scripts/` 파일로 추출하여 `lefthook.yml`에는 `bash scripts/check-*.sh ...` 한 줄 호출만 남기는 방식으로 우회합니다.

**lefthook에 새 검증을 추가할 때도 반드시 이 패턴을 따르세요** — 인라인 multi-line `run: |` 블록은 사용하지 말 것.

type 목록/정규식이 변경되면 이 두 파일도 함께 수정해야 합니다 (`CLAUDE.md`의 "일관성 불변식" 9군데 목록 참조).

---

## 자주 묻는 질문

### Q. `new-branch.sh`가 main을 pull하다가 실패하면?
A. 로컬 main에 커밋되지 않은 변경이 있거나 머지 충돌이 발생한 경우입니다. 먼저 stash 또는 커밋 후 재시도하세요.

### Q. `finish-branch.sh`가 PR 본문을 잘못 채웠어요.
A. `--fill` 옵션은 마지막 커밋 메시지를 PR 제목/본문으로 사용합니다. PR 생성 후 GitHub UI에서 수정하거나, `gh pr edit <number>` 명령으로 수정하세요. 더 정교하게 채우려면 스크립트를 직접 호출하세요:
```bash
gh pr create --title "feat: ..." --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```

### Q. Windows CMD에서 실행 안 돼요.
A. CMD/PowerShell에서는 직접 실행되지 않습니다. **Git Bash**(Git for Windows에 포함) 또는 **WSL**을 사용하세요.

### Q. lefthook과 헬퍼 스크립트의 차이는?
A. lefthook은 **검증**(잘못된 브랜치명 차단), 헬퍼 스크립트는 **편의 자동화**(타이핑 최소화)입니다. 둘은 보완 관계로, lefthook이 안전망 역할을 하고 헬퍼 스크립트는 평소 워크플로우를 단순화합니다.
