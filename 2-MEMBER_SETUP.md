# 팀원 온보딩 가이드

프로젝트에 합류한 팀원이 **딱 한 번** 실행하면 되는 가이드입니다. 5분이면 끝납니다.

---

## 관리자가 이미 해둔 것

걱정하지 마세요. 다음은 이미 설정되어 있습니다:

- ✅ main 브랜치 보호 (직접 push 차단)
- ✅ CI 자동 검증 (브랜치명·PR 제목 규칙 위반 시 차단)
- ✅ PR 템플릿
- ✅ `.gitattributes` (Windows CRLF/LF 문제 방지)
- ✅ 헬퍼 스크립트 및 lefthook 설정 파일

당신은 **로컬 환경 세팅만** 하면 됩니다.

---

## 온보딩 (1회)

### 1. 레포 클론

```bash
git clone <repo-url>
cd <repo-name>
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
- Git alias 4개 등록 (`git nb`, `git fb`, `git cleanup`, `git bootstrap`)

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

> ⚠️ `gh auth login`을 하지 않으면 `git fb` (PR 생성)와 `git cleanup` (PR 상태 조회)이 동작하지 않습니다.

### 4. 완료!

세팅이 끝났습니다. 이제 [3-DAILY_WORKFLOW.md](./3-DAILY_WORKFLOW.md)를 읽고 작업을 시작하세요.

> ⚠️ **첫 commit 전에 알아두면 좋은 것**
>
> lefthook의 `commit-msg` 훅이 커밋 메시지 형식을 자동 검증합니다. 다음 형식을 어기면 commit 자체가 차단됩니다:
> ```
> <type>: <설명>
> # 예: feat: add order router
> ```
> `<type>`은 `feat | fix | refactor | docs | research | data | chore` 중 하나여야 합니다. 자세한 규칙은 [3-DAILY_WORKFLOW.md §3 커밋 메시지 규칙](./3-DAILY_WORKFLOW.md#3-커밋-메시지-규칙) 참조.

---

## Windows 사용자

bash 스크립트(`scripts/*.sh`)는 다음 환경에서만 동작합니다:

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
git config --local --get-regexp '^alias\.(nb|fb|cleanup|bootstrap)$'
# → 4줄이 출력되면 OK

# 3. gh 인증이 되어 있는가?
gh auth status
# → "Logged in to github.com" 이 보이면 OK

# 4. .gitattributes가 존재하는가?
grep "eol=lf" .gitattributes
# → *.sh, *.yml 등에 eol=lf 규칙이 보이면 OK
```

문제가 있으면 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)를 참조하세요.
