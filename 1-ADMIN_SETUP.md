# 관리자 세팅 가이드

팀 프로젝트 레포에 브랜치 전략 자동화를 도입하는 가이드입니다. **레포 admin 권한이 필요**합니다.

총 3단계이며, Step 1~2는 필수, Step 3은 선택이지만 주기능입니다.

---

## 사전 준비

- 대상 GitHub repo의 **admin 권한**
- 로컬에 클론된 대상 repo
- 이 키트를 별도 폴더에 클론
- **GitHub CLI (`gh`) 설치 + 인증** — Step 2-3에서 PR 생성에 필수

```bash
git clone https://github.com/Seongyul-Lee/branch-strategy-kit.git ~/branch-strategy-kit
cd <your-team-repo>

# gh 설치 확인 + 인증 (한 번만)
gh --version || echo "→ https://cli.github.com/ 에서 설치"
gh auth status || gh auth login
```

> 💡 `gh`가 아직 없다면 키트의 `./scripts/bootstrap.sh`로 일괄 설치 가능합니다 (Step 3 참고). 다만 Step 2-3에서 `gh pr create`를 호출하므로 그 전에 설치되어 있어야 합니다.

### OS별 `gh` 설치 가이드

**macOS** (터미널에서 실행, Homebrew):
```bash
brew install gh
```

**Windows** — **`gh` 설치 + `gh auth login`까지만 PowerShell에서 실행**하고, 이후 모든 작업(Step 1~3 및 데일리 워크플로우)은 **Git Bash**에서 진행하세요. 셋 중 택1:
```powershell
# winget (Windows 10/11 기본 탑재)
winget install --id GitHub.cli

# Scoop
scoop install gh

# Chocolatey
choco install gh
```
> 설치 후 **Git Bash를 새로 열어야** `gh`가 PATH에 잡힙니다.

**Linux**:
```bash
# Debian/Ubuntu
sudo apt install gh

# Fedora/RHEL
sudo dnf install gh

# Arch
sudo pacman -S github-cli
```
> apt 저장소 버전이 오래된 경우 공식 설치 방법: <https://github.com/cli/cli/blob/trunk/docs/install_linux.md>

설치 후 인증:
```bash
gh auth login
```

---

## Step 1 — GitHub 서버 설정 (5분)

팀원이 추가 작업 없이 즉시 적용되는 서버 설정입니다.

### 1-1. Branch Protection Rule

GitHub repo → **Settings → Branches → Add branch protection rule**:

- **Branch name pattern**: `main`
- ☑ **Require a pull request before merging**
  - ☑ Require approvals: `1` (**1인 repo면 이 체크박스를 OFF** — GitHub UI는 카운트 0을 허용하지 않습니다)
  - ☑ Dismiss stale pull request approvals when new commits are pushed
- ☑ **Require status checks to pass before merging**
  - ☑ Require branches to be up to date before merging
  - (Step 2 완료 후) 필수 체크에 `check-branch-name`, `validate-pr-title` 추가
- ☑ **Require linear history**
- ☑ **Require conversation resolution before merging**
- ☑ **Do not allow bypassing the above settings**
- ☐ Allow force pushes → **반드시 OFF**
- ☐ Allow deletions → **반드시 OFF**

→ **Save changes** 클릭.

> ⚠️ **1인 repo 주의**
>
> GitHub는 PR 작성자의 self-approval을 허용하지 않습니다. 1인 저장소에서 `Require approvals`를 켜두면 본인이 만든 PR을 영원히 머지할 수 없습니다.
> - ✅ 1인 repo → **`Require approvals` 체크박스 OFF** (카운트 0은 GitHub UI에서 입력 불가)
> - ✅ 팀원이 추가되면 → 체크박스 ON + 카운트 `1` 이상
>
> 이미 막혔다면: Settings → Branches → main 규칙 Edit에서 `Require approvals` 체크를 해제한 뒤 저장.

### 1-2. 머지 옵션 통일

GitHub repo → **Settings → General → Pull Requests**:

- ☑ **Allow squash merging** (only)
  - Default commit message: **"Pull request title"** 권장
- ☐ Allow merge commits → **OFF**
- ☐ Allow rebase merging → **OFF**
- ☑ **Always suggest updating pull request branches**
- ☑ **Automatically delete head branches**

### ✅ Step 1 검증

main에 직접 push가 차단되는지 확인합니다:

```bash
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

롤백 후 다음 단계로:
```bash
git reset --hard HEAD~1
```

---

## Step 2 — CI 워크플로우 추가 (10분)

PR 단계에서 잘못된 브랜치명·PR 제목을 자동 차단하는 workflow를 추가합니다.

### 2-1. 파일 복사

```bash
cd <your-team-repo>
mkdir -p .github/workflows

cp ~/branch-strategy-kit/.github/workflows/branch-name-check.yml .github/workflows/
cp ~/branch-strategy-kit/.github/workflows/pr-title-check.yml .github/workflows/
cp ~/branch-strategy-kit/.github/workflows/stale-branches.yml .github/workflows/
cp ~/branch-strategy-kit/.github/pull_request_template.md .github/

# .gitattributes — Windows 팀원의 CRLF/LF "유령 modified" 방지
# (이미 .gitattributes가 있다면 키트 버전의 규칙을 머지: *.sh, *.yml, *.yaml, *.bash → eol=lf)
cp ~/branch-strategy-kit/.gitattributes .
```

> ⚠️ **`.gitattributes`를 누락하면 어떻게 되나**
>
> Windows의 `core.autocrlf=true`(기본값)와 충돌해 `.yml`/`.sh` 파일이 수정한 적 없는데도 `git status`에 `M`으로 뜨는 **"유령 modified"** 현상이 발생합니다. `git add` 후엔 사라지지만 다음 git 작업 때 또 등장하며, `git fb`가 "main 대비 커밋이 없습니다"로 실패할 수 있습니다. **반드시 함께 복사하세요.**

### 2-2. 커밋 + 푸시 (PR로 도입)

```bash
git checkout -b chore/add-branch-strategy-automation
git add .github/ .gitattributes
git commit -m "chore: branch strategy CI automation 도입"
git push -u origin chore/add-branch-strategy-automation
gh pr create --title "chore: branch strategy CI automation 도입" --body "브랜치 전략 CI 자동화 도입"
```

PR 리뷰·**squash merge** 완료 후, 로컬을 최신화하고 작업 브랜치를 삭제합니다:

```bash
git checkout main
git pull --ff-only
git branch -D chore/add-branch-strategy-automation   # squash merge는 -d로 감지되지 않아 -D 사용
```

> 💡 원격 브랜치는 Step 1-2에서 켠 **Automatically delete head branches** 설정에 의해 자동으로 삭제됩니다. 로컬만 수동 정리하면 됩니다.

### 2-3. Branch Protection에 status check 추가

PR 머지 후 → **Settings → Branches → main 규칙 편집**:
- **Require status checks** 섹션에서 `check-branch-name`, `validate-pr-title` 검색 후 추가
- Save

> 💡 workflow가 한 번도 실행되지 않은 상태에서는 검색 결과에 잡히지 않습니다. 2-2에서 만든 PR로 workflow가 1회 실행된 뒤 다시 검색하세요.

### ✅ Step 2 검증

잘못된 브랜치명과 PR 제목이 차단되는지 확인합니다:

```bash
git checkout -b WrongName
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

## Step 3 — 로컬 훅·헬퍼 스크립트 추가 (선택, 5분)

로컬에서 push 전에 브랜치명·커밋 메시지를 검증하고, 브랜치 생성·PR·정리를 자동화하는 스크립트를 추가합니다.

### 3-1. 파일 복사

```bash
cd <your-team-repo>

# 1. 파일 복사
cp ~/branch-strategy-kit/lefthook.yml .
cp -r ~/branch-strategy-kit/scripts .

# 2. 로컬 working tree 실행 권한
#    - Unix(macOS/Linux): 로컬에서 직접 ./scripts/*.sh 실행 시 필요
#    - Windows Git Bash: 파일시스템이 exec bit을 보존하지 않아 사실상 no-op (무해)
chmod +x scripts/*.sh
```

### 3-2. 커밋 + 푸시

```bash
# 1. 작업 브랜치 생성
git checkout -b chore/add-lefthook-and-scripts

# 2. lefthook.yml 일반 추가
git add lefthook.yml

# 3. scripts/*.sh — git 인덱스 등록 + 실행 권한(100755) 한 번에
git add --chmod=+x scripts/*.sh

# 4. (권장) 인덱스 모드 검증 — "new file mode 100755" 가 보이면 정상
git diff --cached scripts/bootstrap.sh | head -3

 # 5. 커밋 · 푸시 · PR
git commit -m "chore: lefthook 및 헬퍼 스크립트 추가"
git push -u origin chore/add-lefthook-and-scripts
gh pr create --fill
```

PR 리뷰·**squash merge** 완료 후, 로컬을 최신화하고 작업 브랜치를 삭제:

```bash
git checkout main
git pull --ff-only
git branch -D chore/add-lefthook-and-scripts   # squash merge는 -d로 감지되지 않아 -D 사용
```

> 💡 이 PR 머지 이후에는 `./scripts/bootstrap.sh` 한 번 실행하면 `git cleanup` alias가 등록되어, **앞으로는 머지 후 정리를 `git cleanup` 한 줄로** 할 수 있습니다.

관리자 본인의 로컬 환경 세팅:
```bash
./scripts/bootstrap.sh
```

### ✅ Step 3 관리자 세팅 완료, 팀원에게 가이드 공유

PR을 머지한 뒤, 팀원에게 [2-MEMBER_SETUP.md](./2-MEMBER_SETUP.md)를 공유하세요.

---

## 세팅 완료 후 할 일

1. **팀원에게 [2-MEMBER_SETUP.md](./2-MEMBER_SETUP.md) 링크를 공유**하세요. 팀원은 이 문서만 읽으면 됩니다.
2. `gh auth status`로 GitHub CLI 인증 여부를 확인하고, 미인증이면 `gh auth login`을 실행하세요.
2. 일상 워크플로우는 [3-DAILY_WORKFLOW.md](./3-DAILY_WORKFLOW.md)를 참조하세요.
