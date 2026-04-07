# SETUP GUIDE — 팀 repo 도입 가이드

기존 GitHub repo에 이 키트를 단계적으로 도입하는 절차입니다. Phase 단위로 점진 도입할 수 있습니다.

## 사전 준비

- 대상 GitHub repo의 **admin 권한**
- 로컬에 클론된 대상 repo
- 이 키트를 별도 폴더에 클론 (자산 복사 소스)

```bash
git clone <branch-strategy-kit-url> ~/branch-strategy-kit
cd <your-team-repo>
```

---

## Phase 1 — GitHub 서버 측 강제 (5분)

팀원이 추가 액션 없이 적용되는 서버 설정. main 직접 커밋 차단 + 머지 방식 통일.

### 1-1. Branch Protection Rule

> ⚠️ **1인 repo 주의 — Require approvals는 반드시 `0`**
>
> GitHub는 PR 작성자의 self-approval을 허용하지 않습니다. 1인 저장소에서 `Require approvals`를 `1` 이상으로 두면 본인이 만든 PR을 **영원히 머지할 수 없습니다**.
>
> - ✅ 1인 repo → `Require approvals: 0`
> - ✅ 팀원 추가 후 `1` 이상으로 올리기
>
> 이미 막혔다면: Settings → Branches → main 규칙 Edit에서 카운트를 `0`으로 내린 뒤 저장.

GitHub repo → **Settings → Branches → Add branch protection rule**:

- **Branch name pattern**: `main`
- ☑ **Require a pull request before merging**
  - ☑ Require approvals: `1` (**1인 repo면 반드시 `0`**)
  - ☑ Dismiss stale pull request approvals when new commits are pushed
- ☑ **Require status checks to pass before merging**
  - ☑ Require branches to be up to date before merging
  - (Phase 2 완료 후) 필수 체크에 `check-branch-name`, `validate-pr-title` 추가
- ☑ **Require linear history**
- ☑ **Require conversation resolution before merging**
- ☑ **Do not allow bypassing the above settings**
- ☐ Allow force pushes (반드시 OFF)
- ☐ Allow deletions (반드시 OFF)

→ **Save changes** 클릭.

### 1-2. 머지 옵션 통일

GitHub repo → **Settings → General → Pull Requests**:

- ☑ **Allow squash merging** (only)
  - Default commit message: **"Pull request title"** 권장
- ☐ Allow merge commits ← OFF
- ☐ Allow rebase merging ← OFF
- ☑ **Always suggest updating pull request branches**
- ☑ **Automatically delete head branches**

### 1-3. 검증 — main 직접 push가 차단되는지

```bash
cd <your-team-repo>
git checkout main
echo "test" >> README.md
git commit -am "test direct push"
git push
```

다음처럼 거부되면 성공:
```
remote: error: GH006: Protected branch update failed for refs/heads/main.
 ! [remote rejected] main -> main (protected branch hook declined)
```

롤백:
```bash
git reset --hard HEAD~1
```

---

## Phase 2 — CI 검증 자동화 (10분)

PR 단계에서 잘못된 브랜치명 / PR 제목을 자동 차단하는 workflow 추가.

### 2-1. 파일 복사

```bash
cd <your-team-repo>
mkdir -p .github/workflows

cp ~/branch-strategy-kit/.github/workflows/branch-name-check.yml .github/workflows/
cp ~/branch-strategy-kit/.github/workflows/pr-title-check.yml .github/workflows/
cp ~/branch-strategy-kit/.github/workflows/stale-branches.yml .github/workflows/
cp ~/branch-strategy-kit/.github/pull_request_template.md .github/
```

### 2-2. (선택) 첫 2주 "경고만" 모드

팀원이 새 규칙에 익숙해지도록 첫 2주는 경고만 표시하고 머지는 허용할 수 있습니다.

`.github/workflows/branch-name-check.yml`을 열어 검증 step에 `continue-on-error: true` 추가:

```yaml
      - name: Validate branch name
        continue-on-error: true   # ← 추가: 빨간 X가 떠도 머지는 가능
        run: |
          ...
```

`pr-title-check.yml`도 동일하게 처리. 2주 후 `continue-on-error: true` 줄을 제거하여 차단 모드로 전환.

### 2-3. 커밋 + 푸시 (PR로 도입)

```bash
git checkout -b chore/add-branch-strategy-automation
git add .github/
git commit -m "chore: add branch strategy CI automation"
git push -u origin chore/add-branch-strategy-automation
gh pr create --title "chore: add branch strategy CI automation" --body "Phase 2 도입"
```

### 2-4. Branch Protection에 status check 추가

PR 머지 후 → **Settings → Branches → main 규칙 편집**:
- **Require status checks** 섹션에서 `check-branch-name`, `validate-pr-title` 검색 후 추가
- Save

> 💡 workflow가 한 번도 실행되지 않은 상태에서는 검색 결과에 잡히지 않습니다. 2-3에서 만든 PR로 workflow가 1회 실행된 뒤 다시 검색하세요.

### 2-5. 검증 — 잘못된 브랜치명/제목이 막히는지

```bash
git checkout -b WrongName    # 잘못된 형식 (대문자, 접두어 없음)
git commit --allow-empty -m "test"
git push -u origin WrongName
gh pr create --title "Wrong Title" --body "test"
```

PR 페이지에서 다음 두 체크가 빨간 X로 실패해야 성공:
- `check-branch-name`
- `validate-pr-title`

정리:
```bash
gh pr close --delete-branch
```

---

## Phase 3 — 클라이언트 측 보조 (선택, 팀원당 5분)

로컬에서 push 전에 브랜치명/커밋 메시지를 검증하여 CI 빨간불을 미연에 방지합니다.

### 3-1. 파일 복사

```bash
cd <your-team-repo>
cp ~/branch-strategy-kit/lefthook.yml .
cp -r ~/branch-strategy-kit/scripts .
chmod +x scripts/*.sh
```

### 3-2. 팀원 안내 (각자 1회 실행)

> 💡 **권장 — bootstrap 스크립트 사용**
>
> OS별 수동 설치 대신 키트의 부트스트랩 스크립트 한 번으로 처리:
>
> ```bash
> chmod +x scripts/bootstrap.sh
> ./scripts/bootstrap.sh
> ```
>
> 환경을 자동 감지해 `gh`, `lefthook` 설치 + `lefthook install` + **Git alias 4개 등록** (`git nb` / `git fb` / `git cleanup` / `git bootstrap`)까지 한 번에 수행합니다. 자세한 동작: [SCRIPTS_USAGE.md §0](./SCRIPTS_USAGE.md#0-bootstrapsh--의존성-일괄-설치-1회-실행)
>
> 아래 수동 단계는 bootstrap이 자동 설치를 지원하지 않는 환경(예: apt)에서 사용하세요.

**Linux/macOS**:
```bash
brew install lefthook    # macOS
# 또는 https://github.com/evilmartians/lefthook 참조
```

**Windows**:
```powershell
scoop install lefthook
# 또는 winget install evilmartians.lefthook
```

**Node 프로젝트**:
```bash
npm install -D lefthook
```

설치 후 repo에서:
```bash
lefthook install
```

→ `.git/hooks/`에 훅이 배치됩니다.

### 3-3. 커밋 + 푸시

```bash
git checkout -b chore/add-lefthook
git add lefthook.yml scripts/
git commit -m "chore: add lefthook and helper scripts"
git push -u origin chore/add-lefthook
gh pr create --fill
```

### 3-4. 검증 — 로컬에서 main push가 차단되는지

```bash
git checkout main
git commit --allow-empty -m "test"
git push
```

다음처럼 차단되면 성공:
```
❌ main 브랜치에 직접 push 금지. 새 브랜치를 만드세요.
```

### 3-5. 검증 — Git alias 동작

```bash
git config --local --get-regexp '^alias\.(nb|fb|cleanup|bootstrap)$'
```

다음 4줄이 출력되면 성공:
```
alias.nb !bash ./scripts/new-branch.sh
alias.fb !bash ./scripts/finish-branch.sh
alias.cleanup !bash ./scripts/cleanup-merged.sh
alias.bootstrap !bash ./scripts/bootstrap.sh
```

이후 데일리 워크플로우는 `git nb feat xxx` / `git fb` / `git cleanup`으로 짧게 호출할 수 있습니다.

---

## Windows 팀원 안내

bash 스크립트(`scripts/*.sh`)는 다음 환경에서만 동작합니다:

- **Git Bash** (Git for Windows에 기본 포함)
- **WSL** (Windows Subsystem for Linux)

CMD/PowerShell에서는 실행되지 않습니다.

Git Bash 사용:
1. https://git-scm.com/download/win 에서 Git for Windows 설치
2. 시작 메뉴에서 "Git Bash" 실행
3. repo로 이동 후 `./scripts/new-branch.sh feat my-feature` 실행

---

## 트러블슈팅

### "Required status check is expected" 에러로 PR 머지 불가

→ Phase 2 workflow가 `pull_request` 트리거로 1회 이상 실행되어야 status check이 등록됩니다. 빈 커밋 PR을 한 번 만들어 workflow를 실행시킨 뒤 branch protection 설정에 추가하세요.

### Branch protection에 status check 이름을 검색해도 안 뜸

→ workflow가 실행된 적이 있어야 합니다. 백틱이나 콤마 같은 장식 문자 없이 정확한 **job 이름**(`check-branch-name`, `validate-pr-title`)을 한 번에 하나씩 검색하세요.

### validate-pr-title이 "Expected — Waiting for status to be reported"에서 멈춤

→ PR 브랜치에 push할 때마다 workflow가 재실행되어야 합니다. `pr-title-check.yml`의 트리거에 `synchronize`가 포함되어 있는지 확인하세요. 임시 우회: PR 제목을 살짝 수정하면 `edited` 이벤트로 재실행됩니다.

### lefthook 설치 후에도 훅이 동작하지 않음

→ `lefthook install` 실행 여부 확인. `.git/hooks/pre-push` 파일이 생성되었는지 확인.

### Git Bash에서 "permission denied"

→ `chmod +x scripts/*.sh`. Windows에서는 git이 실행 권한을 보존하지 않을 수 있으므로:
```bash
git update-index --chmod=+x scripts/*.sh
```
로 git 자체에도 실행 권한을 기록하세요.

### CRLF 관련 에러 (Windows)

→ `.gitattributes`에 다음 추가:
```
*.sh text eol=lf
```
이미 커밋된 파일은 `git add --renormalize .` 후 재커밋.

### cleanup-merged.sh가 머지된 브랜치를 못 잡음

→ `gh auth status`로 gh CLI 인증 확인. 필요하면 `gh auth login`. 그 후 다시 실행하면 `gh pr list --state merged`로 감지합니다. 자세한 동작: [SCRIPTS_USAGE.md §3](./SCRIPTS_USAGE.md#3-cleanup-mergedsh--머지된-로컬-브랜치-정리)
