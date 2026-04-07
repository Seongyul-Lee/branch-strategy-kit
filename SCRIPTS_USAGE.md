# SCRIPTS USAGE — 헬퍼 스크립트 사용법

`scripts/` 디렉터리의 헬퍼 스크립트 3개의 사용법을 정리합니다. 모두 bash 스크립트로, **Linux/macOS의 기본 셸 또는 Windows의 Git Bash**에서 실행됩니다.

## 사전 준비

- Git 2.30+
- bash 4+ (Git Bash 포함)
- (`finish-branch.sh` 한정) GitHub CLI [`gh`](https://cli.github.com/) — `gh auth login` 완료 상태

스크립트 실행 권한 부여 (1회):
```bash
chmod +x scripts/*.sh
```

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

### 예시

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

### 동작 단계

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
