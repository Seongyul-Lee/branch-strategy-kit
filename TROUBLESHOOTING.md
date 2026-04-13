# 트러블슈팅

증상별로 정리된 문제 해결 가이드입니다.

---

## 주의사항

- **새로 `git clone`한 직후에는 반드시 `./scripts/bootstrap.sh`를 다시 실행하세요.**
  Git alias(`git nb`/`fb`/`cleanup`/`bootstrap`)와 lefthook 훅은 **`.git/config`와 `.git/hooks/`에만** 등록되는데, 이 두 경로는 clone 시 새로 생성되므로 **이전 레포에서 bootstrap을 한 적이 있어도 새 clone에는 이어지지 않습니다**. 같은 레포를 두 번째·세 번째 clone할 때도 동일합니다.
- `bootstrap.sh`는 **idempotent(멱등)** 합니다. 이미 설치·등록된 항목은 건너뛰므로 **몇 번을 실행해도 안전**하고 부작용이 없습니다. "혹시 뭔가 빠졌나?" 싶을 때 그냥 다시 돌리면 됩니다.
- bootstrap을 건너뛴 상태에서 `git nb`/`git fb`가 "command not found" 또는 `git: 'nb' is not a git command`로 실패한다면, 높은 확률로 이 케이스입니다. `./scripts/bootstrap.sh`를 한 번 실행하면 복구됩니다.

---

## 세팅 관련

### "Required status check is expected" 에러로 PR 머지 불가

**원인:** workflow가 `pull_request` 트리거로 1회 이상 실행되어야 branch protection 설정 화면의 검색 결과에 status check이 등록됩니다.

**해결:** 빈 커밋 PR을 만들어 workflow를 1회 실행시킨 뒤, branch protection 설정에 status check을 추가하세요.

```bash
git checkout -b chore/trigger-ci
git commit --allow-empty -m "chore: trigger CI to register status checks"
git push -u origin chore/trigger-ci
gh pr create --fill-first
# → workflow가 1회 실행된 뒤 Settings → Branches → main 규칙 편집에서
#   check-branch-name, validate-pr-title 검색 후 추가
# 그 다음 PR 닫기 + 브랜치 삭제
gh pr close --delete-branch
```

---

### Branch Protection에 status check 이름이 검색해도 안 뜸

**원인:** workflow가 실행된 적이 없습니다.

**해결:** 정확한 job 이름(`check-branch-name`, `validate-pr-title`)을 한 번에 하나씩, 장식 문자 없이 검색하세요. workflow가 최소 1회 실행된 후에 검색 가능합니다.

---

### validate-pr-title이 "Expected — Waiting for status to be reported"에서 멈춤

**원인:** PR 브랜치에 push할 때마다 workflow가 재실행되어야 하는데, 트리거에 `synchronize`가 빠져 있을 수 있습니다.

**해결:**
1. `pr-title-check.yml`의 트리거에 `synchronize`가 포함되어 있는지 확인
2. 임시 우회: PR 제목을 살짝 수정하면 `edited` 이벤트로 재실행됩니다

---

## bootstrap / 설치 관련

### lefthook 설치 후에도 훅이 동작하지 않음

**원인:** `lefthook install`이 실행되지 않았습니다.

**해결:**
```bash
lefthook install
ls .git/hooks/pre-push    # 파일이 존재하는지 확인
```

---

### bootstrap.sh 실행 후에도 gh를 찾을 수 없음

**원인:** 패키지 매니저(특히 winget)로 설치 후 현재 셸의 PATH가 갱신되지 않았습니다.

**해결:** 새 터미널을 열거나 셸을 재시작한 뒤 다시 실행하세요.

---

### gh auth status에서 "not logged in" 표시

**원인:** gh가 설치되었지만 GitHub 인증이 되지 않았습니다.

**해결:**
```bash
gh auth login
```
대화형 프롬프트를 따라 인증하세요. 자세한 절차는 [2a-MEMBER_SETUP_SINGLE.md](./2a-MEMBER_SETUP_SINGLE.md#3-github-cli-인증)를 참조하세요.

> 💡 gh 없이 push만 하고 싶다면: `git fb --no-pr`

---

### bootstrap.sh에서 ".gitattributes 파일이 없습니다" 경고

**원인:** 관리자가 키트 도입 시 `.gitattributes`를 복사하지 않았습니다.

**해결:** 관리자에게 [1-ADMIN_SETUP.md Step 2-1](./1-ADMIN_SETUP.md#2-1-파일-복사)을 확인해달라고 요청하세요. 직접 해결하려면:
```bash
cp ~/branch-strategy-kit/.gitattributes .
git add .gitattributes
git commit -m "chore: CRLF 정규화를 위한 gitattributes 추가"
```

---

### bootstrap.sh에서 ".gitattributes에 다음 규칙이 누락되었습니다" 경고

**원인:** `.gitattributes` 파일은 있지만, `*.sh`, `*.yml`, `*.yaml`, `*.bash`에 대한 `eol=lf` 규칙이 빠져 있습니다.

**해결:** 키트의 `.gitattributes`에서 누락된 규칙을 추가하거나, 키트 버전으로 교체하세요:
```bash
cp ~/branch-strategy-kit/.gitattributes .
git add .gitattributes
git commit -m "chore: gitattributes에 누락된 eol=lf 규칙 추가"
```

---

## 스크립트 관련

### `new-branch.sh`가 main을 pull하다가 실패

**원인:** 로컬 main에 커밋되지 않은 변경이 있거나 머지 충돌이 발생했습니다.

**해결:** stash 또는 커밋 후 재시도하세요.
```bash
git stash
git nb feat my-feature
git stash pop    # 필요 시
```

---

### `finish-branch.sh`가 PR 본문을 잘못 채움

**원인:** `finish-branch.sh`는 `gh pr create --fill-first`를 사용합니다 — **첫 번째 커밋 메시지**를 PR 제목/본문으로 자동 채움. 커밋이 여러 개라면 두 번째 이후 커밋의 의도가 누락될 수 있습니다.

> 💡 왜 `--fill`이 아니라 `--fill-first`인가: `gh pr create --fill`은 multi-commit PR에서 브랜치명을 Conventional Commits가 아닌 형식으로 변환해 PR 제목 검증(`pr-title-check.yml`)이 실패하는 버그가 있어, 키트는 `--fill-first`로 통일했습니다.

**해결:** 머지 전에 PR 본문을 보강하세요. 두 가지 방법:

```bash
# 1) gh CLI로 즉시 수정
gh pr edit <번호> --body "## Summary
..."

# 2) GitHub 웹 UI에서 PR 본문 직접 편집
```

근본적으로 PR 본문이 자동으로 잘 채워지길 원한다면, **첫 번째 커밋 메시지의 본문(body)** 을 풍부하게 작성하세요 (`git commit -m "feat: ..." -m "상세 설명..."`).

---

### `git fb` (또는 `finish-branch.sh`)가 "대비 커밋이 없습니다"로 실패

**증상:** `git fb` 실행 시 다음 메시지로 중단되고 PR이 생성되지 않음:
```
❌ (DEFAULT_BRANCH) 대비 커밋이 없습니다. 먼저 작업을 커밋하세요.
```

**원인 — 가능한 3가지를 순서대로 확인:**

1. **정말 커밋이 없는 경우** — 작업은 했는데 `git commit`을 안 했거나, 다른 브랜치에 커밋했을 수 있음.
   ```bash
   git log main..HEAD --oneline    # 비어 있으면 커밋 0개
   git status                       # untracked / modified 확인
   ```

2. **유령 modified가 흡수된 경우** (Windows) — `git status`에 `M`으로 떴다가 `git add` 후 사라진 파일이 있다면, 실제로는 변경 내용이 없음. → 아래 "유령 modified" 항목 참조 후 `.gitattributes`를 도입하세요.

3. **변경 파일이 `.gitignore`된 경우** — 작업한 파일이 git ignore 규칙에 걸리면 `git add`가 무시. 흔한 함정: `scripts/` 같은 디렉터리가 의도치 않게 ignore되어 있는 경우.
   ```bash
   git check-ignore -v <파일경로>   # 어느 ignore 규칙에 걸리는지 확인
   git ls-files                     # 추적 중인 파일만 표시
   ```
   ignore 규칙이 잘못 들어가 있다면 `.gitignore`에서 해당 줄을 제거한 뒤 다시 `git add`.

---

### `cleanup-merged.sh`가 머지된 브랜치를 못 잡음

**원인:** `gh` CLI가 미설치이거나 미인증 상태입니다.

**해결:**
```bash
gh auth status         # 인증 상태 확인
gh auth login          # 필요 시 인증
./scripts/cleanup-merged.sh   # 다시 실행
```

### `git branch-move`가 번호 입력 모드로만 동작함 (fzf 권장)

**원인:** `fzf`가 설치되어 있지 않습니다. 키트의 필수 의존성은 아니므로 fallback으로 번호 입력 모드가 동작합니다.

**해결 (선택):**
```bash
# macOS
brew install fzf
# Windows
winget install fzf
# Debian/Ubuntu
sudo apt install fzf
```
설치 후 새 셸에서 `git branch-move` 실행하면 자동으로 fzf UI가 사용됩니다.

---

## Windows 관련

### 수정한 적 없는 `.yml`/`.sh` 파일이 `git status`에 `M`으로 뜸 (유령 modified)

**증상:** `git status`에 수정한 적 없는 `.yml`/`.sh` 파일이 `M`으로 뜨고, `git add` 후엔 변경 없음으로 사라지지만 다음 git 작업(checkout, pull, hook 실행 등) 때 또 등장합니다. `git fb`가 "main 대비 커밋이 없습니다"로 실패할 수도 있습니다.

**원인:** Windows의 `core.autocrlf=true`(기본값)와 `.gitattributes` 부재의 충돌입니다. 키트의 `.sh`/`.yml` 자산은 LF로 저장되어야 하는데(Linux GitHub Actions runner에서 실행), git이 working tree를 CRLF로 가정해서 불일치를 보고합니다.

**해결:**

1. 키트의 `.gitattributes` 복사 (관리자에게 요청하거나 직접):
   ```bash
   cp ~/branch-strategy-kit/.gitattributes .
   ```
   키트 버전은 `*.sh`, `*.yml`, `*.yaml`, `*.bash`에 `eol=lf`를 강제합니다.

2. 이미 잘못된 상태로 커밋된 파일이 있다면 정규화:
   ```bash
   git add --renormalize .
   git commit -m "chore: 줄바꿈 재정규화"
   ```

> `bootstrap.sh`를 실행하면 `.gitattributes` 누락 또는 핵심 규칙 누락을 자동으로 감지하여 경고를 출력합니다.

---

### Git Bash에서 "permission denied"

**해결:**
```bash
chmod +x scripts/*.sh
```

Windows에서는 git이 실행 권한을 보존하지 않을 수 있으므로:
```bash
git update-index --chmod=+x scripts/*.sh
```
로 git 자체에도 실행 권한을 기록하세요.

---

### CMD / PowerShell에서 스크립트가 실행되지 않음

bash 스크립트는 CMD/PowerShell에서 동작하지 않습니다.

**해결:** 다음 중 하나를 사용하세요:
- **Git Bash** — Git for Windows에 기본 포함 ([다운로드](https://git-scm.com/download/win))
- **WSL** — Windows Subsystem for Linux

시작 메뉴에서 "Git Bash"를 검색하여 실행한 뒤, 레포 디렉터리로 이동하세요.

---

## Two-branch 모드 관련

### `git sync-main` 실행 시 "Single-trunk 모드에서는 사용할 수 없습니다" 에러

**원인:** `.kit-config`의 `DEFAULT_BRANCH`가 `main`으로 설정되어 있습니다.

**해결:** Two-branch 모드를 사용하려면 `.kit-config`를 열고 `DEFAULT_BRANCH=develop`으로 변경하세요.

---

### `git nb` 실행 시 "로컬에 develop 브랜치가 없어 원격에서 가져옵니다" 메시지

**원인:** 정상 동작입니다. 처음 clone 후 develop을 로컬에 체크아웃한 적이 없으면 자동으로 원격에서 가져옵니다.

---

### develop 브랜치가 원격에 없음

**원인:** 관리자가 develop 브랜치를 아직 생성하지 않았습니다.

**해결:** 관리자에게 [1-ADMIN_SETUP.md](./1-ADMIN_SETUP.md)의 "1-3. Two-branch 모드 설정"을 참조해달라고 요청하세요.

---

## 그 외

### 비-TTY 환경에서 `new-branch.sh` 인터랙티브 모드 에러

```
❌ 인터랙티브 모드는 TTY가 필요합니다.
```

**해결:** CI나 파이프 환경에서는 인자를 직접 지정하세요:
```bash
./scripts/new-branch.sh feat my-feature
```

---

### lefthook과 헬퍼 스크립트의 차이가 뭔가요?

- **lefthook** = 검증 (잘못된 브랜치명·커밋 메시지를 push/commit 시점에 차단)
- **헬퍼 스크립트** = 편의 자동화 (타이핑 최소화, 규칙에 맞는 브랜치 자동 생성)

두 가지는 보완 관계입니다. lefthook은 실수를 막고, 스크립트는 올바른 방식을 쉽게 만들어줍니다.
