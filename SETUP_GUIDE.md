# SETUP GUIDE — 팀 repo 도입 가이드

이 가이드는 **기존 GitHub repo에 이 키트의 자산을 단계적으로 도입**하는 방법을 설명합니다. Phase 1만 적용해도 효과의 80%를 얻을 수 있고, 팀 거부감을 최소화하기 위해 Phase 단위로 점진 도입할 수 있습니다.

## 사전 준비

- 대상 GitHub repo의 Settings 권한 (admin)
- 로컬에 클론된 대상 repo
- 이 키트를 별도 폴더에 클론 (자산 복사 소스)

```bash
git clone <branch-strategy-kit-url> ~/branch-strategy-kit
cd <your-team-repo>
```

---

## Phase 1 — GitHub 서버 측 강제 (5분)

**효과**: 80% — 이것만 해도 main 직접 커밋이 막히고 머지 방식이 통일됩니다.
**팀원 액션**: 0 (1회 서버 설정만)

### 1-1. Branch Protection Rule

> ⚠️ **1인 repo 주의사항 — Require approvals는 반드시 `0`**
>
> GitHub는 PR 작성자의 self-approval을 허용하지 않습니다. 1인 저장소(혼자 작업)에서 `Require approvals`를 `1` 이상으로 두면, 본인이 만든 PR을 **영원히 머지할 수 없습니다** (승인해줄 다른 사람이 없기 때문).
>
> - ✅ 1인 repo → `Require approvals: 0`
> - ✅ 팀원이 추가되면 그때 `1` 이상으로 올리면 됩니다.
>
> 이미 `1` 이상으로 설정한 상태로 막혔다면: **Settings → Branches → main 규칙 Edit**에서 `Require approvals` 카운트를 `0`으로 내린 뒤 저장.

GitHub repo → **Settings → Branches → Add branch protection rule**:

- **Branch name pattern**: `main`
- ☑ **Require a pull request before merging**
  - ☑ Require approvals: `1` (**1인 repo면 반드시 `0`** — 위 주의사항 참조)
  - ☑ Dismiss stale pull request approvals when new commits are pushed
- ☑ **Require status checks to pass before merging**
  - ☑ Require branches to be up to date before merging
  - (Phase 2 완료 후) 필수 체크에 `branch-name-check`, `pr-title-check` 추가
- ☑ **Require linear history** ← squash/rebase 강제, merge commit 차단
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
- ☑ **Automatically delete head branches** ← 머지 직후 원격 브랜치 자동 삭제

### Phase 1 main push 차단 검증

```bash
cd <your-team-repo>
git checkout main
echo "test" >> README.md
git commit -am "test direct push"
git push
```

→ 다음과 같이 거부되면 성공:
```
remote: error: GH006: Protected branch update failed for refs/heads/main.
 ! [remote rejected] main -> main (protected branch hook declined)
```

테스트 후 변경 사항을 되돌립니다:
```bash
git reset --hard HEAD~1
```

---

## Phase 2 — CI 검증 자동화 (10분)

**효과**: PR 단계에서 잘못된 브랜치명/제목 자동 차단.
**팀원 액션**: 0 (파일 복사만)

### 2-1. 파일 복사

```bash
cd <your-team-repo>
mkdir -p .github/workflows

cp ~/branch-strategy-kit/.github/workflows/branch-name-check.yml .github/workflows/
cp ~/branch-strategy-kit/.github/workflows/pr-title-check.yml .github/workflows/
cp ~/branch-strategy-kit/.github/workflows/stale-branches.yml .github/workflows/
cp ~/branch-strategy-kit/.github/pull_request_template.md .github/
```

### 2-2. 첫 2주 "경고만" 모드 (선택, 거부감 완화)

팀원이 새 규칙에 익숙해질 수 있도록 첫 2주는 차단 대신 경고만 표시할 수 있습니다.

`.github/workflows/branch-name-check.yml`을 열어 검증 step에 다음을 추가:

```yaml
      - name: Validate branch name
        continue-on-error: true   # ← 추가: 빨간 X가 떠도 머지는 가능
        run: |
          ...
```

`pr-title-check.yml`도 동일하게 처리. 2주 후 `continue-on-error: true` 줄을 제거하여 차단 모드로 전환합니다.

### 2-3. 커밋 + 푸시 (PR로 도입)

```bash
git checkout -b chore/add-branch-strategy-automation
git add .github/
git commit -m "chore: add branch strategy CI automation"
git push -u origin chore/add-branch-strategy-automation
gh pr create --title "chore: add branch strategy CI automation" --body "Phase 2 도입"
```

### 2-4. Branch Protection에 status check 추가

PR이 머지된 후 → **Settings → Branches → main 규칙 편집**:
- **Require status checks** 섹션에서 `branch-name-check`, `Validate PR title` 검색 후 추가
- Save

### Phase 2 검증

```bash
git checkout -b WrongName    # 잘못된 형식 (대문자, 접두어 없음)
git commit --allow-empty -m "test"
git push -u origin WrongName
gh pr create --title "Wrong Title" --body "test"
```

→ PR 페이지에서 다음 두 체크가 빨간 X로 실패해야 성공:
- `branch-name-check`
- `Validate PR title`

테스트 PR과 브랜치를 정리:
```bash
gh pr close --delete-branch
```

---

## Phase 3 — 클라이언트 측 보조 (선택, 팀원당 5분)

**효과**: push 전에 차단되므로 CI 빨간불을 미연에 방지.
**팀원 액션**: 1회 lefthook 설치.

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
> 아래 OS별 수동 설치 대신, 키트의 부트스트랩 스크립트로 한 번에 처리할 수 있습니다:
>
> ```bash
> chmod +x scripts/bootstrap.sh
> ./scripts/bootstrap.sh
> ```
>
> 환경(OS + 패키지 매니저)을 자동 감지하여 `gh`, `lefthook` 설치 + `lefthook install`까지 한 번에 수행합니다. 자세한 동작은 [SCRIPTS_USAGE.md §0](./SCRIPTS_USAGE.md#0-bootstrapsh--의존성-일괄-설치-1회-실행) 참조.
>
> 아래 수동 단계는 부트스트랩이 자동 설치를 지원하지 않는 환경(예: Linux apt)이거나 직접 설치를 관리하고 싶을 때 사용합니다.

**Linux/macOS**:
```bash
brew install lefthook    # macOS
# 또는 https://github.com/evilmartians/lefthook 설치 가이드 참조
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

→ `.git/hooks/`에 훅이 자동 배치됩니다.

### 3-3. 커밋 + 푸시

```bash
git checkout -b chore/add-lefthook
git add lefthook.yml scripts/
git commit -m "chore: add lefthook and helper scripts"
git push -u origin chore/add-lefthook
gh pr create --fill
```

### Phase 3 검증

```bash
git checkout main
git commit --allow-empty -m "test"
git push
```

→ lefthook이 다음과 같이 차단해야 성공:
```
❌ main 브랜치에 직접 push 금지. 새 브랜치를 만드세요.
```

---

## Windows 팀원을 위한 안내

bash 스크립트(`scripts/*.sh`)는 다음 환경에서 실행됩니다:

- **Git Bash** (Git for Windows에 기본 포함)
- **WSL** (Windows Subsystem for Linux)

Git Bash 사용 권장:
1. https://git-scm.com/download/win 에서 Git for Windows 설치
2. 시작 메뉴에서 "Git Bash" 실행
3. repo로 이동 후 `./scripts/new-branch.sh feat my-feature` 실행

CMD/PowerShell에서는 직접 실행되지 않습니다. Git Bash 또는 WSL을 사용하세요.

---

## 도입 후 운영 팁

1. **첫 2주는 경고만 모드**로 시작하여 팀원 학습 시간 확보
2. **CONTRIBUTING.md**(또는 README)에 워크플로우 5단계 요약 추가
3. **stale-branches.yml은 `dry-run: true`로 시작** → 1주 모니터링 후 `false`로 전환
4. **PR Size 라벨이 자주 XL이 되면** 팀에 "더 작은 PR" 가이드 공지
5. **에러 메시지에 해결법 포함**되도록 workflow를 커스터마이징 (이 키트는 이미 적용됨)

---

## 트러블슈팅

### "Required status check is expected" 에러로 PR 머지 불가

→ Phase 2 workflow가 `pull_request` 트리거로 1회 이상 실행되어야 status check이 등록됩니다. 빈 커밋 PR을 한 번 만들어 workflow를 실행시킨 뒤 branch protection 설정에 추가하세요.

### lefthook 설치 후에도 훅이 동작하지 않음

→ `lefthook install`을 실행했는지 확인. `.git/hooks/pre-push` 파일이 생성되었는지 확인.

### Git Bash에서 스크립트 실행 시 "permission denied"

→ `chmod +x scripts/*.sh` 실행. Windows에서는 git이 실행 권한을 보존하지 않을 수 있으므로 `git update-index --chmod=+x scripts/*.sh`로 git 자체에도 실행 권한을 기록하세요.

### CRLF 관련 에러 (Windows)

→ `.gitattributes`에 다음 추가:
```
*.sh text eol=lf
```
이미 커밋된 파일은 `git add --renormalize .` 후 재커밋.
