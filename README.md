# Branch Strategy Kit

팀 프로젝트에 GitHub Flow 기반 단명 브랜치 전략을 빠르게 도입하기 위한 **재사용 가능한 도구 키트**입니다. 전략 문서, CI workflow, PR 템플릿, git hook, 헬퍼 스크립트를 한 곳에 모아두었습니다.

이 키트는 자체적으로도 자신의 규칙을 따릅니다(self-dogfooding) — 키트 저장소 자체에 lefthook과 GitHub Actions가 적용되어 있어 실제 동작 예시로도 사용할 수 있습니다.

## 누가 이 키트를 사용하나

- **팀 리드**: 새 프로젝트나 기존 프로젝트에 일관된 브랜치 전략을 도입하고 싶을 때
- **신규 팀원**: 워크플로우와 명령어를 학습할 때
- **개인 개발자**: 1인 프로젝트에도 동일한 자동화를 적용하고 싶을 때

## Quick Start

목적별 진입점:

| 목적 | 읽을 문서 |
|---|---|
| 브랜치 전략 자체가 궁금하다 | [BRANCH_STRATEGY.md](./BRANCH_STRATEGY.md) |
| 우리 팀 repo에 도입하고 싶다 | [SETUP_GUIDE.md](./SETUP_GUIDE.md) |
| 헬퍼 스크립트 사용법이 알고 싶다 | [SCRIPTS_USAGE.md](./SCRIPTS_USAGE.md) |

## 디렉터리 구조

```
branch-strategy-kit/
├── README.md                       # 이 파일
├── BRANCH_STRATEGY.md              # 브랜치 전략 본문
├── SETUP_GUIDE.md                  # 팀 repo 도입 가이드 (3-Phase)
├── SCRIPTS_USAGE.md                # 헬퍼 스크립트 사용법
├── lefthook.yml                    # 클라이언트 측 git hook 설정
├── scripts/
│   ├── bootstrap.sh                # 의존성(gh, lefthook) + lefthook 훅 1회 셋업
│   ├── new-branch.sh               # 새 브랜치 생성 헬퍼
│   ├── finish-branch.sh            # PR 생성 헬퍼
│   └── cleanup-merged.sh           # 머지된 로컬 브랜치 정리
└── .github/
    ├── pull_request_template.md    # PR 템플릿
    └── workflows/
        ├── branch-name-check.yml   # 브랜치명 정규식 검증
        ├── pr-title-check.yml      # Conventional Commits 검증
        └── stale-branches.yml      # 30일 이상 비활성 브랜치 자동 정리
```

## 핵심 자동화 (3계층)

```
Tier 1: 서버 강제      GitHub branch protection (수동 설정, 5분)
Tier 2: CI 검증        .github/workflows/ (파일 복사로 자동)
Tier 3: 클라이언트 보조 lefthook + scripts/ (팀원 1회 install)
```

자세한 도입 절차는 [SETUP_GUIDE.md](./SETUP_GUIDE.md)를 참조하세요.

## 요구 사항

- Git 2.30+
- bash (Linux/macOS 기본 / Windows는 Git Bash)
- (선택) [GitHub CLI (`gh`)](https://cli.github.com/) — `finish-branch.sh` 사용 시
- (선택) [lefthook](https://github.com/evilmartians/lefthook) — 클라이언트 훅 사용 시

> 💡 위 선택 의존성은 [`./scripts/bootstrap.sh`](./SCRIPTS_USAGE.md#0-bootstrapsh--의존성-일괄-설치-1회-실행)로 환경에 맞춰 한 번에 설치할 수 있습니다.
