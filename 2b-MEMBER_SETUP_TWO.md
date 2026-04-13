# 팀원 온보딩 가이드 (Two-branch 모드)

프로젝트에 합류한 팀원이 **딱 한 번** 실행하면 되는 가이드입니다. 5분이면 끝납니다.

> ⚠️ **실행 환경**: Windows는 **Git Bash**에서, macOS는 **터미널**에서 진행하세요. (CMD/PowerShell ❌)

---

## 팀 프로젝트 관리자가 이미 해둔 것

아래는 이미 팀 프로젝트에 설정되어 있습니다:

- ✅ main 브랜치 보호 (직접 push 차단)
- ✅ develop 브랜치 보호 (직접 push 차단)
- ✅ .kit-config에 DEFAULT_BRANCH=develop 설정
- ✅ CI 자동 검증 (브랜치명·PR 제목 규칙 위반 시 차단)
- ✅ PR 템플릿
- ✅ `.gitattributes` (Windows CRLF/LF 문제 방지)
- ✅ 헬퍼 스크립트 및 lefthook 설정 파일

당신은 **로컬 환경 세팅만** 하면 됩니다.

---

## 온보딩 (1회)

### 1. 레포 준비

팀 repo의 로컬 상태에 따라 둘 중 하나를 수행합니다.

**a. 로컬에 팀 레포가 아직 없다면** — 클론:

```bash
git clone <your-team-repo-url>
cd <your-team-repo>
```

> 💡 `<your-team-repo-url>`는 팀 repo의 원격 URL입니다 (예: `https://github.com/myorg/myrepo.git`).

**b. 이미 로컬에 팀 레포가 있다면** — develop 최신화:

```bash
cd <your-team-repo>
git checkout develop
git pull origin develop
```

### 2. bootstrap 실행

```bash
./scripts/bootstrap.sh
```

이 스크립트가 자동으로 처리하는 것:
- `gh` (GitHub CLI) 설치 여부 확인 및 설치
- `lefthook` 설치 여부 확인 및 설치
- `lefthook install` 실행 (git hook 등록)
- `.gitattributes` 점검 (누락 또는 핵심 `eol=lf` 규칙 누락 시 경고)
- Git alias 5개 등록 (`git nb`, `git fb`, `git cleanup`, `git bootstrap`, `git sync-main`)

> 💡 여러 번 실행해도 안전합니다 (idempotent).
>
> ⚠️ **Linux 사용자**: bootstrap이 `gh`/`lefthook`을 설치할 때 `sudo dnf install ...`처럼 sudo 명령을 호출할 수 있습니다. 비밀번호 입력이 필요할 수 있으니 비대화형 환경(SSH 자동화 등)에서 실행 시 주의하세요.

### 3. GitHub CLI 인증

bootstrap이 끝나면 `gh`가 GitHub 계정에 연결되어 있어야 합니다. 아래 명령어로 인증 상태를 확인하세요:

```bash
gh auth status
```

**인증이 안 되어 있다면** (처음 `gh`를 설치한 경우):

```bash
gh auth login
```

대화형 프롬프트가 나타납니다:

```
? Where do you use GitHub?  GitHub.com
? What is your preferred protocol for Git operations?  HTTPS
? Authenticate Git with your GitHub credentials?  Yes
? How would you like to authenticate GitHub CLI?  Login with a web browser
```

브라우저가 열리면 GitHub에 로그인하고 인증을 승인하세요.

### 4. 완료!

세팅이 끝났습니다. 이제 [3b-DAILY_WORKFLOW_TWO.md](./3b-DAILY_WORKFLOW_TWO.md)를 읽고 작업을 시작하세요.

> ⚠️ **첫 commit 전에 알아두면 좋은 것**
>
> lefthook의 `commit-msg` 훅이 커밋 메시지 형식을 자동 검증합니다. 다음 형식을 어기면 commit 자체가 차단됩니다:
> ```
> <type>: <설명>
> # 예: feat: basic enemy AI movement 구현
> #     fix: door trigger 오류 수정
> #     remove: unused asset 및 테스트 코드 삭제
> ```
> `<type>`은 `feat | fix | refactor | docs | research | data | chore | remove` 중 하나. subject는 **한국어/영문/혼용 모두 허용** (첫 글자만 A-Z 대문자 금지). 자세한 규칙은 [3b-DAILY_WORKFLOW_TWO.md §3 커밋 메시지 규칙](./3b-DAILY_WORKFLOW_TWO.md#3-커밋-메시지-규칙) 참조.

---

## Windows 사용자

bash 스크립트(실전 명령어)는 다음 환경에서만 동작합니다:

- **Git Bash** (Git for Windows에 기본 포함) — [다운로드](https://git-scm.com/download/win)
- **WSL** (Windows Subsystem for Linux)

CMD / PowerShell에서는 실행되지 않습니다. 시작 메뉴에서 "Git Bash"를 실행한 뒤 레포로 이동하세요.

---

## 검증 체크리스트

모든 세팅이 올바른지 확인하려면:

```bash
# 1. lefthook 훅이 등록되었는가?
ls .git/hooks/pre-push
# → 파일이 존재하면 OK

# 2. Git alias가 등록되었는가?
git config --local --get-regexp '^alias\.(nb|fb|cleanup|bootstrap|sync-main)$'
# → 5줄이 출력되면 OK

# 3. gh 인증이 되어 있는가?
gh auth status
# → "Logged in to github.com" 이 보이면 OK

# 4. .gitattributes가 존재하는가?
grep "eol=lf" .gitattributes
# → *.sh, *.yml 등에 eol=lf 규칙이 보이면 OK
```

문제가 있으면 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)를 참조하세요.
