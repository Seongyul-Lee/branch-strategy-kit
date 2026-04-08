# Branch Strategy Kit

[![Release](https://img.shields.io/github/v/release/Seongyul-Lee/branch-strategy-kit?display_name=tag&sort=semver)](https://github.com/Seongyul-Lee/branch-strategy-kit/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Branch name check](https://github.com/Seongyul-Lee/branch-strategy-kit/actions/workflows/branch-name-check.yml/badge.svg)](https://github.com/Seongyul-Lee/branch-strategy-kit/actions/workflows/branch-name-check.yml)
[![PR title check](https://github.com/Seongyul-Lee/branch-strategy-kit/actions/workflows/pr-title-check.yml/badge.svg)](https://github.com/Seongyul-Lee/branch-strategy-kit/actions/workflows/pr-title-check.yml)

> **GitHub Flow 기반 단명 브랜치 전략을, 복사 한 번으로 팀에 도입하기 위한 재사용 가능한 키트.**

전략 문서, GitHub Actions workflow, PR 템플릿, lefthook 훅, 헬퍼 스크립트를 한 묶음으로 제공합니다. 새 프로젝트든 기존 프로젝트든, 관리자 15분 + 팀원 5분이면 동일한 규칙으로 자동화 할 수 있습니다.

이 저장소는 자체 키트 규칙을 따릅니다(self-dogfooding)

> ⚠️ **실행 환경 제약**
>
> 이 키트의 모든 명령어(`bootstrap.sh`, `git nb/fb/cleanup`, 문서 내 bash 블록)는 아래 환경에서만 정상 동작합니다. **혼용 시 동작을 보장하지 않습니다.**
>
> - **macOS / Linux** → 기본 **터미널** (bash/zsh)
> - **Windows** → **Git Bash** ([Git for Windows](https://git-scm.com/download/win)에 기본 포함). CMD/PowerShell에서는 동작하지 않습니다.
>   - 단, **`gh` 설치와 `gh auth login`만** PowerShell에서 실행하고(→ [1-ADMIN_SETUP.md](./1-ADMIN_SETUP.md) 참조), **이후 모든 작업은 Git Bash**에서 진행하세요.

---

## 이 키트가 필요한 사람

- 팀 repo가 `develop`, `staging`, `feature/long-lived-...` 같은 브랜치로 어지러워진 사람
- main에 직접 push하는 팀원을 막고, PR + squash merge를 강제하고 싶은 사람
- 브랜치 네이밍/PR 제목/커밋 메시지 규칙을 **문서가 아니라 자동화로** 강제하고 싶은 사람
- 한국어 가이드 문서로 팀원을 빠르게 온보딩시키고 싶은 사람

---

## 30초 미리보기

```bash
# 팀원 1회 셋업 (의존성 + lefthook + git alias 등록)
./scripts/bootstrap.sh

# 작업 흐름 — 자주 쓰는 3개 명령
git nb feat login-form     # 새 브랜치 생성 (검증된 네이밍 자동 적용)
# ... 작업 + 커밋 ...
git fb                     # push + PR 생성 (gh CLI)
# ... 리뷰 + squash merge ...
git cleanup                # 머지된 로컬 브랜치 정리
```

브랜치명·커밋 메시지·PR 제목은 push/CI 단계에서 자동 검증되므로, 규칙을 외울 필요가 없습니다.

---

## 시작하기

| 역할 | 읽을 문서 | 소요 시간 |
|---|---|---|
| 팀 프로젝트에 키트를 **도입하려는 관리자** | [1-ADMIN_SETUP.md](./1-ADMIN_SETUP.md) | ~15분 |
| 관리자가 세팅을 마친 프로젝트에 **합류한 팀원** | [2-MEMBER_SETUP.md](./2-MEMBER_SETUP.md) | ~5분 |
| 세팅이 끝났고, **매일 쓰는 워크플로우**가 궁금함 | [3-DAILY_WORKFLOW.md](./3-DAILY_WORKFLOW.md) | 레퍼런스 |
| **에러**가 났다 | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | 필요할 때 |

---

## 핵심 전략 요약

> `main` 단일 trunk + 작업마다 단명 브랜치 생성 → squash merge → 즉시 삭제.

- **`main`이 유일한 영구 브랜치**. `develop`, `staging` 같은 long-lived 브랜치를 만들지 않습니다.
- **모든 작업은 단명 브랜치에서 시작**. 브랜치 수명 최대 1~2일.
- **모든 변경은 PR을 거칩니다**. squash merge만 허용.
- **머지 직후 브랜치 즉시 삭제** (로컬 + 원격).
- **릴리스는 브랜치가 아닌 Git tag**로 표시 (`git tag v1.2.3`).

허용되는 브랜치 type: `feat`, `fix`, `refactor`, `docs`, `research`, `data`, `chore`, `remove`.

<details>
<summary>왜 이런 전략을 쓰나요?</summary>

- **linear history**: squash merge + linear history 강제로 main의 커밋 로그가 깔끔합니다.
- **충돌 최소화**: 브랜치 수명이 짧으면 다른 팀원 작업과 겹칠 확률이 줄어듭니다.
- **자동화 친화적**: 브랜치 네이밍 규칙이 일관되면 CI/CD 파이프라인 분기가 쉬워집니다.
- **릴리스 = Git tag**: 릴리스 브랜치 없이 `git tag v1.2.3`으로 표시합니다.

</details>

---

## 핵심 자동화 (3계층 방어선)

| Tier | 자산 | 강제력 | 우회 가능성 |
|---|---|---|---|
| **1. 서버** | GitHub branch protection | main 직접 push 차단, squash merge 강제, linear history | 없음 |
| **2. CI** | `.github/workflows/*.yml` | 브랜치명·PR 제목 검증, stale 브랜치 자동 정리 | 없음 (required check) |
| **3. 클라이언트** | `lefthook.yml` + `scripts/*.sh` | push 전 로컬 차단, 헬퍼 스크립트 제공 | `--no-verify`로 우회 가능 |

Tier 3은 안전망이고, 진짜 강제는 Tier 1+2에서 이루어집니다.

---

## 디렉터리 구조

```
branch-strategy-kit/
├── README.md                        # 이 파일
├── 1-ADMIN_SETUP.md                 # 관리자 세팅 가이드
├── 2-MEMBER_SETUP.md                # 팀원 온보딩 가이드
├── 3-DAILY_WORKFLOW.md              # 일상 워크플로우 레퍼런스
├── TROUBLESHOOTING.md               # 트러블슈팅 통합
├── .gitattributes                   # CRLF/LF 정규화 (Windows 유령 modified 방지)
├── lefthook.yml                     # 클라이언트 측 git hook 설정
├── scripts/
│   ├── bootstrap.sh                 # 의존성 + lefthook + alias + .gitattributes 점검
│   ├── new-branch.sh                # 새 브랜치 생성 헬퍼
│   ├── finish-branch.sh             # PR 생성 헬퍼
│   ├── cleanup-merged.sh            # 머지된 로컬 브랜치 정리
│   ├── check-branch.sh              # (내부) lefthook용 브랜치명 검증
│   └── check-commit-msg.sh          # (내부) lefthook용 커밋 메시지 검증
└── .github/
    ├── pull_request_template.md     # PR 템플릿
    └── workflows/
        ├── branch-name-check.yml    # 브랜치명 정규식 검증
        ├── pr-title-check.yml       # PR 제목 형식(Conventional Commits) 검증
        └── stale-branches.yml       # 30일 이상 비활성 브랜치 자동 정리
```

---

## 요구 사항

- Git 2.30+
- bash (Linux/macOS 기본 / Windows는 **Git Bash 또는 WSL 필수** — CMD/PowerShell 미지원)
- (선택) [GitHub CLI (`gh`)](https://cli.github.com/) — PR 생성·정리 시 필수
- (선택) [lefthook](https://github.com/evilmartians/lefthook) — 클라이언트 훅 사용 시

> 💡 위 선택 의존성은 [`bootstrap.sh`](./2-MEMBER_SETUP.md)로 한 번에 설치할 수 있습니다.

---

## License

MIT — 자유롭게 복사해서 팀 repo에 가져다 쓰세요.
