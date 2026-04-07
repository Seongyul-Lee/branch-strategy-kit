# Branch Strategy Kit

팀 프로젝트에 GitHub Flow 기반 단명 브랜치 전략을 빠르게 도입하기 위한 **재사용 가능한 도구 키트**입니다. 전략 문서, CI workflow, PR 템플릿, git hook, 헬퍼 스크립트를 한 곳에 모아두었습니다.

이 키트는 자체적으로도 자신의 규칙을 따릅니다(self-dogfooding) — 키트 저장소 자체에 lefthook과 GitHub Actions가 적용되어 있어 실제 동작 예시로도 사용할 수 있습니다.

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

<details>
<summary>왜 이런 전략을 쓰나요?</summary>

- **linear history**: squash merge + linear history 강제로 main의 커밋 로그가 깔끔합니다.
- **충돌 최소화**: 브랜치 수명이 짧으면 다른 팀원 작업과 겹칠 확률이 줄어듭니다.
- **자동화 친화적**: 브랜치 네이밍 규칙이 일관되면 CI/CD 파이프라인 분기가 쉬워집니다.
- **릴리스 = Git tag**: 릴리스 브랜치 없이 `git tag v1.2.3`으로 표시합니다.

</details>

---

## 핵심 자동화 (3계층)

```
Tier 1: 서버 강제      GitHub branch protection (관리자가 1회 설정)
Tier 2: CI 검증        .github/workflows/ (관리자가 파일 복사)
Tier 3: 클라이언트 보조 lefthook + scripts/ (팀원 각자 1회 install)
```

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
- bash (Linux/macOS 기본 / Windows는 Git Bash 또는 WSL)
- (선택) [GitHub CLI (`gh`)](https://cli.github.com/) — PR 생성·정리 시 필수
- (선택) [lefthook](https://github.com/evilmartians/lefthook) — 클라이언트 훅 사용 시

> 💡 위 선택 의존성은 [`bootstrap.sh`](./2-MEMBER_SETUP.md)로 한 번에 설치할 수 있습니다.
