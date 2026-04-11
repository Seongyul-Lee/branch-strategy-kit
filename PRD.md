# branch-strategy-kit — Product Requirements Document

> 최종 수정: 2026-04-11
> 작성 기준: 코드베이스 `6489063` + 프로젝트 문서
> 상태: 초안
> PRD 작성자: Seongyul-Lee (이성율) — 기획·구현·문서
> 킷 버전: v1.0.0 (VERSION 파일 기준)
> 라이선스: MIT
> 저장소: github.com/Seongyul-Lee/branch-strategy-kit
> 목차: §1~§24 + 부록 A~D

---

## 1. 개요 (Executive Summary)

**branch-strategy-kit**은 GitHub Flow 기반의 단명 브랜치 + Squash Merge 전략을 팀 프로젝트에 즉시 도입할 수 있는 재사용 가능한 자동화 킷이다. 셸 스크립트 7개, GitHub Actions 워크플로우 3개, lefthook 설정, PR 템플릿, 가이드 문서 5종으로 구성되며, 관리자가 15분, 팀원이 5분이면 전체 환경을 갖출 수 있다.

이 킷은 브랜치명, 커밋 메시지, PR 제목에 대한 규칙을 문서가 아닌 **코드로 강제**한다. 서버(GitHub branch protection) → CI(GitHub Actions) → 클라이언트(lefthook) 3계층 방어선을 구축하여, Git/GitHub 숙련도와 무관하게 팀 전체가 일관된 워크플로우를 따르도록 보장한다.

빌드 시스템, 테스트 러너, 패키지 매니저에 의존하지 않는 순수 bash 기반 킷으로, 파일 복사만으로 어떤 프로젝트든 적용할 수 있다. 킷 자체도 자신의 규칙을 따르는 self-dogfooding 구조이다.

---

## 2. 문제 정의 (Problem Statement)

### 2.1 해결하려는 문제

언리얼 엔진 기반 C++ 팀 프로젝트(SACHO) 진행 초기에 다음 문제들이 발견되었다:

1. **main 단독 운영의 혼란**: 여러 팀원이 작업 브랜치 없이 main에 직접 push하면서 충돌, 불완전한 코드 유입, 히스토리 오염이 빈번하게 발생
2. **Squash Merge 미숙**: Squash Merge를 도입했으나, 이 방식이 처음인 작업자들이 올바르게 사용하지 못하는 문제
3. **Git/GitHub 숙련도 편차**: 팀원 간 Git 사용 경험 차이로 인해 브랜치 생성, PR 작성, 머지 후 정리 등 기본 워크플로우가 일관되지 않음
4. **규칙의 형해화**: 구두/문서로 합의한 브랜치/커밋/Push/PR 규칙이 기술적 강제 없이 쉽게 무시됨
5. **반복 수작업**: 브랜치 생성 → main 최신화 → PR 작성 → 머지 후 정리의 반복 과정에서 실수와 비효율 발생
6. **리뷰어의 수동적 리뷰**: 기존에는 팀원들이 코드 작성 후, 현장에서 리뷰어가 작업자의 코드를 직접 검토한 후 main 브랜치에 push하도록 하는 수동적인 구조로 인해 비효율 존재

### 2.2 기존 대안과 한계

시장에는 Git 워크플로우의 **개별 영역**을 담당하는 도구가 풍부하지만, 브랜치 네이밍 + 커밋 메시지 + PR 제목 + 워크플로우 자동화 + 로컬 훅 + CI + 가이드 문서를 **하나의 복사 가능한 킷**으로 묶은 프로젝트는 사실상 존재하지 않는다.

#### 개별 도구 비교

| 대안 | 영역 | 한계 |
|------|------|------|
| **commitlint** (★18.4k, Node.js) | 커밋 메시지 검증 | 커밋 메시지만 담당. 브랜치 네이밍, PR 제목, 워크플로우 스크립트 미제공. Node.js 의존 필수 |
| **Husky** (★34k, Node.js) | Git 훅 매니저 | 훅 "매니저"일 뿐 검증 규칙 자체를 제공하지 않음. commitlint 등과 조합 필요. Node.js 의존 |
| **Cocogitto** (★1.1k, Rust) | 커밋 검증 + 버전 범프 | 브랜치 네이밍/생성/정리 스크립트 미제공. 버전 범프·CHANGELOG에 특화 |
| **Commitizen** (★3.4k, Python) | 인터랙티브 커밋 위저드 | 커밋 작성에만 집중. 브랜치/PR 워크플로우 미제공. Python 의존 |
| **action-branch-name** (★86) | 브랜치명 CI 검증 | 브랜치명만 담당. 로컬 훅 없음. 커밋 메시지/PR 제목 미검증 |
| **action-semantic-pull-request** (★1.3k) | PR 제목 CI 검증 | PR 제목만 담당. 브랜치 네이밍/커밋 메시지/워크플로우 미제공 |
| **nvie/gitflow** (★26.9k, 아카이브) | 브랜치 전략 CLI | develop/release/hotfix 장수명 브랜치 모델. 소규모 팀에 과도한 복잡성. CI 검증 없음 |
| **pre-commit** (★14.9k, Python) | 훅 프레임워크 | 플러그인 조합 필요. 브랜치 전략·워크플로우 스크립트 미제공. Python 의존 |

#### branch-strategy-kit의 차별점

| 관점 | branch-strategy-kit | 기존 도구들 |
|------|---------------------|-------------|
| **커버리지** | 브랜치 네이밍 + 커밋 메시지 + PR 제목 + 생성/종료/정리 스크립트 + CI + 로컬 훅을 올인원으로 제공 | 각 도구가 1~2개 영역만 담당하므로 3~4개 조합 필요 |
| **의존성** | 순수 bash 기반. Node.js/Python/Rust 런타임 불필요 | commitlint(Node.js), Commitizen(Python), Cocogitto(Rust) 등 런타임 의존 |
| **도입 방식** | 파일 복사 + `bootstrap.sh` 한 번 실행으로 완료 | 패키지 설치 + 설정 파일 작성 + 워크플로우 별도 구축 필요 |
| **3계층 방어** | 서버(branch protection) → CI(Actions) → 클라이언트(lefthook) 통합 설계 | 대부분 단일 계층(훅만 또는 CI만) |
| **워크플로우 자동화** | `git nb`/`git fb`/`git cleanup`으로 전체 사이클 커버 | 대부분 검증만 제공하고 브랜치 생성/PR/정리는 수동 |
| **온보딩 문서** | 역할별(관리자/팀원) 한국어 가이드 5종 내장 | 영어 README 수준, 역할별 분리 없음 |

> **요약**: 기존 도구들이 "커밋 메시지 린터", "훅 매니저", "PR 제목 체커"처럼 한 가지 역할에 특화되어 있다면, branch-strategy-kit은 이 모든 것을 **하나의 일관된 전략 아래 통합**하여 파일 복사만으로 즉시 적용할 수 있는 올인원 킷이다.

---

## 3. 타겟 사용자 (Target Users)

| 역할 | 설명 | 주요 작업 | 관련 문서 |
|------|------|-----------|-----------|
| **관리자** (repo admin) | 킷을 팀 레포에 처음 도입하는 사람. GitHub repo admin 권한 보유 | branch protection 설정, CI/스크립트 파일 복사, 팀에 공유 | `1-ADMIN_SETUP.md` |
| **팀원** (contributor) | 킷이 적용된 프로젝트에서 매일 작업하는 개발자. Git/GitHub 숙련도 편차 있음 | bootstrap 실행, 일상 워크플로우(브랜치 생성→커밋→PR→정리) | `2-MEMBER_SETUP.md`, `3-DAILY_WORKFLOW.md` |

---

## 4. 핵심 전략 / 설계 철학 (Design Philosophy)

이 킷은 **GitHub Flow의 엄격한 구현체**로, 다음 원칙을 따른다:

1. **main 단일 trunk**: 영구 브랜치는 main 하나뿐. 릴리스는 Git tag로 표시
2. **단명 브랜치 강제**: 모든 작업은 1~2일 이내에 완료되는 `type/name` 브랜치에서 진행
3. **Squash Merge 전일화**: merge commit, rebase merge를 금지하고 squash merge만 허용하여 linear history 유지
4. **규칙의 코드화**: 규칙을 문서가 아닌 자동화(훅, CI, protection rule)로 강제. "규칙을 모르면 자동으로 거부됨"
5. **3계층 방어**: 서버 → CI → 클라이언트 순서로 규칙을 검증하여, 어느 한 계층이 우회되어도 다른 계층에서 차단
6. **복사 기반 이식**: npm/pip 등 패키지 매니저 없이, 파일 복사만으로 어떤 프로젝트든 적용 가능
7. **개발자 경험 우선**: 최소 타이핑(`git nb`, `git fb`, `git cleanup`)으로 전체 워크플로우를 커버

<details>
<summary>설계 결정의 근거</summary>

- **왜 GitHub Flow인가**: Git Flow의 develop/release/hotfix 브랜치는 소규모~중규모 팀에게 과도한 관리 부담. main 하나로 충분한 프로젝트가 대부분
- **왜 Squash Merge 전일화인가**: merge commit은 히스토리를 오염시키고, rebase merge는 중급 이상 Git 지식이 필요. Squash merge는 "PR 1개 = 커밋 1개"로 가장 단순
- **왜 3계층인가**: branch protection만으로는 브랜치명/커밋 메시지 규칙 불가. CI만으로는 push 후 피드백이 늦음. 클라이언트 훅만으로는 `--no-verify` 우회 가능. 세 계층이 상호 보완
- **왜 bash인가**: 모든 OS(macOS/Linux/Windows Git Bash)에서 추가 런타임 없이 실행 가능. Node.js/Python 의존성 없이 킷의 진입 장벽을 최소화

</details>

---

## 5. 기능 요구사항 — 스크립트 (Functional Requirements: Scripts)

| FR-ID | 스크립트 | 기능 | 사용법 | 구현 상태 |
|-------|----------|------|--------|-----------|
| FR-001 | `scripts/bootstrap.sh` | 초기 환경 설정 | `./scripts/bootstrap.sh [--yes]` / `git bootstrap` | ✅ 구현됨 |
| FR-002 | `scripts/new-branch.sh` | 인터랙티브 브랜치 생성 | `./scripts/new-branch.sh [type] [name]` / `git nb` | ✅ 구현됨 |
| FR-003 | `scripts/finish-branch.sh` | push + PR 자동 생성 | `./scripts/finish-branch.sh [--no-pr]` / `git fb` | ✅ 구현됨 |
| FR-004 | `scripts/cleanup-merged.sh` | 머지된 브랜치 정리 | `./scripts/cleanup-merged.sh [--exclude pat]` / `git cleanup` | ✅ 구현됨 |
| FR-005 | `scripts/check-branch.sh` | pre-push 브랜치명 검증 | `bash scripts/check-branch.sh <mode>` | ✅ 구현됨 |
| FR-006 | `scripts/check-commit-msg.sh` | commit-msg Conventional Commits 검증 | `bash scripts/check-commit-msg.sh <file>` | ✅ 구현됨 |
| FR-007 | `scripts/branch-move.sh` | 인터랙티브 브랜치 전환 | `./scripts/branch-move.sh` / `git branch-move` | ✅ 구현됨 |

---

### FR-001: 초기 환경 설정 (bootstrap)

- **스크립트**: `scripts/bootstrap.sh` (477줄)
- **용도**: 킷의 필수 의존성 설치 및 로컬 환경 일괄 구성. 팀원 온보딩의 단일 진입점
- **사용법**: `./scripts/bootstrap.sh` (대화형) 또는 `./scripts/bootstrap.sh --yes` (CI/자동화)
- **입력**: `--yes` 플래그 (선택, 모든 확인 프롬프트 자동 승인)
- **출력/부수 효과**:
  - `gh` (GitHub CLI) 설치 (미설치 시)
  - `lefthook` 설치 및 `.git/hooks/*` 등록
  - Git alias 5개 등록: `nb`, `fb`, `cleanup`, `branch-move`, `bootstrap`
  - `.gitattributes` 규칙 검증 (Windows CRLF 방지)
  - 최종 요약 리포트 출력 (상태별: already/installed/failed 등)
- **의존성**: OS별 패키지 매니저 (`brew`, `apt`, `dnf`, `pacman`, `winget`, `scoop`)
- **에러 처리**: `set -euo pipefail`, 각 단계별 상태 추적, 설치 실패 시 수동 설치 안내
- **특이사항**: idempotent — 여러 번 실행해도 안전. OS/PM 자동 감지 (macOS, Linux, WSL, Windows)

### FR-002: 인터랙티브 브랜치 생성

- **스크립트**: `scripts/new-branch.sh` (166줄)
- **용도**: main 최신화 후 `type/name` 형식의 새 작업 브랜치 생성
- **사용법**:
  - `git nb` — 완전 인터랙티브 (화살표 키로 type 선택 + name 입력)
  - `git nb feat` — type 지정, name만 프롬프트
  - `git nb feat my-feature` — 완전 자동 (CI 호환)
- **입력**: type (8종 중 택 1), name (소문자/숫자/하이픈)
- **출력/부수 효과**:
  - `git checkout main && git pull --ff-only`
  - `git checkout -b type/name`
- **의존성**: `git`
- **에러 처리**: `set -euo pipefail`, 대소문자/공백/언더스코어 자동 정규화, 브랜치 중복 검사, TTY 감지
- **특이사항**: ANSI 커서 제어로 터미널 UI 직접 구현 (fzf 미의존)

### FR-003: PR 자동 생성

- **스크립트**: `scripts/finish-branch.sh` (109줄)
- **용도**: 현재 브랜치를 원격에 push하고 GitHub PR 자동 생성
- **사용법**: `git fb` 또는 `git fb --no-pr` (push만 수행)
- **입력**: `--no-pr` 플래그 (선택)
- **출력/부수 효과**:
  - `git push -u origin <branch>`
  - `gh pr create --fill-first` (첫 커밋 메시지를 PR 제목/본문으로 사용)
- **의존성**: `git`, `gh`
- **에러 처리**: main 브랜치 차단, 미커밋 변경 차단, 기존 PR 중복 감지, 브랜치명 재검증
- **특이사항**: `gh` 미설치 시 push만 수행하고 수동 PR 생성 안내

### FR-004: 머지된 브랜치 정리

- **스크립트**: `scripts/cleanup-merged.sh` (225줄)
- **용도**: 머지 완료된 로컬 브랜치 및 원격에서 삭제된 브랜치 일괄 정리
- **사용법**: `git cleanup` 또는 `git cleanup --exclude 'feat/*'`
- **입력**: `--exclude <pattern>` (선택, 복수 가능, bash glob 문법)
- **출력/부수 효과**:
  - 로컬 브랜치 삭제 (`git branch -d` 또는 `-D`)
  - PR 머지 브랜치는 원격도 삭제 (`git push origin --delete`)
- **의존성**: `git`, `gh` (선택적 — 없으면 3번째 신호 생략)
- **에러 처리**: 보호 브랜치(main/master/develop) 항상 제외, 삭제 전 사용자 확인, 검출 사유 표시
- **특이사항**: **3-signal 검출** — ① `git branch --merged` ② `git branch -vv`의 `gone` ③ `gh pr list --state merged`. Squash merge로 인해 ①만으로는 감지 불가한 브랜치를 ②③으로 보완

### FR-005: 브랜치명 검증 (pre-push 훅)

- **스크립트**: `scripts/check-branch.sh` (45줄)
- **용도**: pre-push 훅에서 브랜치명 규칙 검증
- **사용법**: `bash scripts/check-branch.sh no-main-push` 또는 `bash scripts/check-branch.sh name`
- **입력**: mode (`no-main-push` | `name`)
- **출력**: 규칙 위반 시 exit 1로 push 차단 + 에러 메시지
- **의존성**: `git`
- **검증 규칙**: `^(feat|fix|refactor|docs|research|data|chore|remove)/[a-z0-9][a-z0-9-]*$`
- **특이사항**: Git Bash on Windows에서 lefthook 인라인 스크립트의 문자열 mangle 버그를 우회하기 위해 별도 파일로 추출

### FR-006: 커밋 메시지 검증 (commit-msg 훅)

- **스크립트**: `scripts/check-commit-msg.sh` (45줄)
- **용도**: commit-msg 훅에서 Conventional Commits 형식 검증
- **사용법**: `bash scripts/check-commit-msg.sh <MSG_FILE>`
- **입력**: 커밋 메시지 파일 경로 (Git이 자동 전달)
- **출력**: 형식 위반 시 exit 1로 커밋 차단 + 예제 포함 안내 메시지
- **의존성**: 없음 (grep만 사용)
- **검증 규칙**: `^(feat|fix|refactor|docs|research|data|chore|remove)(\(.+\))?!?: .+`
- **특이사항**: Merge/Revert 자동 생성 메시지는 통과. 한글 subject 완벽 지원 (첫 글자 대문자 시작만 금지)

### FR-007: 인터랙티브 브랜치 전환

- **스크립트**: `scripts/branch-move.sh` (141줄)
- **용도**: 로컬 브랜치를 인터랙티브로 선택해 빠르게 checkout
- **사용법**: `git branch-move`
- **입력**: 없음 (인터랙티브)
- **출력/부수 효과**: 선택한 브랜치로 `git checkout`
- **의존성**: `git`, `fzf` (선택적 — 없으면 번호 입력 fallback)
- **에러 처리**: 미커밋 변경 차단, 브랜치 1개 이하 시 안내, 이미 현재 브랜치 선택 시 정보 메시지
- **특이사항**: fzf 있으면 fuzzy 검색 UI, 없으면 번호 입력 TUI. 최근 커밋 순서로 정렬, 현재 브랜치 상단 고정

---

## 6. 자동화 요구사항 — CI/Hooks (Automation Requirements)

### 6.1 방어 계층 구조

| 계층 | 구현체 | 강제력 | 우회 가능성 |
|------|--------|--------|-------------|
| **Tier 1: 서버** | GitHub branch protection (외부 설정) | main 직접 push 차단, squash merge 강제, linear history 강제 | 불가 (admin도 적용) |
| **Tier 2: CI** | `.github/workflows/*.yml` | 브랜치명·PR 제목 검증, stale 브랜치 정리 | required check 설정 시 불가 |
| **Tier 3: 클라이언트** | `lefthook.yml` + `scripts/*.sh` | push 전 로컬 차단, 커밋 메시지 검증 | `--no-verify`로 우회 가능 |

> **설계 원칙**: Tier 3(클라이언트)는 빠른 피드백을 위한 편의 기능이고, 실질적 강제력은 Tier 1+2에서 담보한다. 새 검증 규칙 추가 시 반드시 Tier 2(CI)에도 구현해야 실효성이 보장된다.

### 6.2 CI 워크플로우

| AR-ID | 워크플로우 | 트리거 | 검증 내용 |
|-------|------------|--------|-----------|
| AR-001 | `branch-name-check.yml` | PR opened/edited/synchronize/reopened | 소스 브랜치명이 `^(feat\|fix\|refactor\|docs\|research\|data\|chore\|remove)/[a-z0-9][a-z0-9-]*$` 패턴 일치 여부 |
| AR-002 | `pr-title-check.yml` | PR opened/edited/synchronize/reopened | PR 제목이 Conventional Commits 형식 준수 여부 (외부 액션 `amannn/action-semantic-pull-request@v5` 사용) |
| AR-003 | `stale-branches.yml` | cron 매주 월요일 00:00 UTC + 수동 dispatch | 30일 이상 비활성 브랜치 감지 및 정리 (기본 dry-run, 수동으로 실제 삭제 전환 가능) |

### 6.3 Git Hooks (lefthook)

| 훅 이벤트 | 실행 스크립트 | 검증 내용 |
|-----------|-------------|-----------|
| pre-push (parallel) | `scripts/check-branch.sh no-main-push` | main/master 직접 push 차단 |
| pre-push (parallel) | `scripts/check-branch.sh name` | 브랜치명 정규식 패턴 검증 |
| commit-msg | `scripts/check-commit-msg.sh {1}` | Conventional Commits 형식 검증 |

---

## 7. 온보딩 요구사항 (Onboarding Requirements)

### 7.1 초기 설정 (Setup)

| 단계 | 역할 | 소요 시간 | 작업 내용 | 관련 문서 |
|------|------|-----------|-----------|-----------|
| 1 | 관리자 | ~5분 | GitHub branch protection 설정 (main 보호, squash only, linear history) | `1-ADMIN_SETUP.md` Step 1 |
| 2 | 관리자 | ~10분 | CI 워크플로우·`.gitattributes`·PR 템플릿 파일 복사 및 PR 제출 | `1-ADMIN_SETUP.md` Step 2 |
| 3 | 관리자 | ~5분 | lefthook 설정 + 스크립트 복사 (선택) | `1-ADMIN_SETUP.md` Step 3 |
| 4 | 팀원 | ~5분 | `./scripts/bootstrap.sh` 실행 (gh, lefthook, alias, hooks 일괄 설정) | `2-MEMBER_SETUP.md` |

### 7.2 일상 사용 (Daily Workflow)

```
git nb feat login-form       # 1. 새 브랜치 생성 (main 최신화 + checkout)
# ... 작업 + 커밋 ...        # 2. 커밋 (자동 메시지 검증)
git fb                       # 3. push + PR 생성
# ... 리뷰어가 Squash Merge ... # 4. 리뷰 및 머지
git cleanup                  # 5. 머지된 로컬 브랜치 정리
```

보조 명령어:
- `git branch-move` — 로컬 브랜치 간 빠른 전환
- `git bootstrap` — 환경 재설정 (idempotent)

---

## 8. 비기능 요구사항 (Non-Functional Requirements)

### 8.1 호환성

| 항목 | 요구사항 | 근거 |
|------|----------|------|
| OS | macOS, Linux (Ubuntu/Fedora/Arch), Windows (Git Bash 또는 WSL만) | `bootstrap.sh`의 OS/PM 감지 로직, `2-MEMBER_SETUP.md`에 명시 |
| 셸 | bash 4+ 필수. POSIX sh/zsh/dash 미지원 | `CLAUDE.md`에 명시, 스크립트 shebang `#!/usr/bin/env bash` |
| Git 버전 | 2.30+ | `README.md`에 명시 |
| 줄바꿈 | LF 강제 (`.gitattributes`로 `*.sh`, `*.yml` 등에 `eol=lf` 적용) | CRLF 혼입 시 CI 깨짐 |

### 8.2 외부 의존성

| 도구 | 필수/선택 | 용도 | 설치 방법 |
|------|-----------|------|-----------|
| `git` | 필수 | 버전 관리 전체 | OS별 기본 설치 |
| `gh` (GitHub CLI) | 선택 (PR 자동 생성 시 필수) | PR 생성/조회, 인증 | `bootstrap.sh`로 자동 설치 |
| `lefthook` | 선택 (클라이언트 훅 시 필수) | Git hook 관리 | `bootstrap.sh`로 자동 설치 |
| `fzf` | 선택 | `branch-move` fuzzy 검색 UI | 수동 설치 (없으면 번호 입력 fallback) |

### 8.3 이식성 (Portability)

이 킷을 다른 프로젝트에 적용하려면:

1. **파일 복사**: `scripts/`, `.github/workflows/`, `lefthook.yml`, `.gitattributes`, `.github/pull_request_template.md`를 대상 레포에 복사
2. **실행 권한**: `git update-index --chmod=+x scripts/*.sh` (Windows에서 필수)
3. **서버 설정**: GitHub branch protection rule 수동 구성 (`1-ADMIN_SETUP.md` Step 1)
4. **팀원 온보딩**: 각 팀원이 `./scripts/bootstrap.sh` 실행

패키지 매니저, 빌드 도구, 런타임에 의존하지 않으므로 언어/프레임워크에 무관하게 적용 가능하다.

---

## 9. 일관성 불변식 (Consistency Invariant)

브랜치 타입 목록(`feat|fix|refactor|docs|research|data|chore|remove`)과 네이밍 정규식이 **10곳에 중복 정의**되어 있다. 타입 추가/제거/변경 시 반드시 **모두** 동기화해야 한다:

| # | 파일 | 동기화 대상 |
|---|------|-------------|
| 1 | `scripts/check-branch.sh` | `PATTERN` 정규식 |
| 2 | `scripts/check-commit-msg.sh` | `PATTERN` 정규식 |
| 3 | `.github/workflows/branch-name-check.yml` | `PATTERN` 정규식 |
| 4 | `.github/workflows/pr-title-check.yml` | `types:` 목록 |
| 5 | `scripts/new-branch.sh` | `ALLOWED_TYPES` 배열 + 안내 문구 |
| 6 | `scripts/finish-branch.sh` | `PATTERN` 정규식 |
| 7 | `3-DAILY_WORKFLOW.md` | 네이밍 표 + Quick Reference 표 + 예시 |
| 8 | `.github/pull_request_template.md` | 변경 유형 체크리스트 |
| 9 | `README.md` | "허용되는 브랜치 type" 문장 (line 72) |
| 10 | `2-MEMBER_SETUP.md` | 커밋 메시지 형식 안내 (line 101) |

> 이 불변식 위반은 "특정 타입이 로컬에서는 통과하지만 CI에서 실패" 같은 혼란을 유발하므로 최우선 주의 사항이다.

---

## 10. 성공 지표 (Success Metrics)

| 지표 | 목표 | 측정 방법 |
|------|------|-----------|
| SACHO 프로젝트 팀원 만족도 | 팀원들이 워크플로우에 만족 | 팀원 피드백 [정성적] |
| main 직접 push 차단율 | 100% | branch protection 로그 |
| 브랜치명 규칙 위반율 | 0% (CI 통과 기준) | `branch-name-check.yml` 실패 로그 |
| PR 제목 규칙 위반율 | 0% (CI 통과 기준) | `pr-title-check.yml` 실패 로그 |
| 30일 이상 비활성 브랜치 수 | 0개 | `stale-branches.yml` 리포트 |
| 팀원 온보딩 소요 시간 | 5분 이내 | `bootstrap.sh` 실행 완료 시간 |

---

## 11. 제약사항 및 가정 (Constraints & Assumptions)

### 11.1 기술적 제약

- **bash 전용**: POSIX sh, zsh, dash에서 동작하지 않음. Windows는 Git Bash 또는 WSL 필수
- **GitHub 전용**: GitHub branch protection, GitHub Actions, `gh` CLI에 의존. GitLab, Bitbucket 등 미지원
- **LF 강제**: `.gitattributes`가 `*.sh`, `*.yml` 등에 `eol=lf` 적용. CRLF 혼입 시 CI 깨짐
- **인라인 스크립트 회피**: lefthook에서 bash 스크립트를 인라인으로 작성하면 Git Bash on Windows에서 문자열 mangle 버그 발생. 반드시 `bash scripts/*.sh` 호출 패턴 사용

### 11.2 운영 제약

- **GitHub repo admin 권한 필수**: branch protection rule 설정에 필요 (관리자만)
- **1인 레포 주의**: `Require approvals` 설정 시 자기 PR을 자기가 머지할 수 없으므로 OFF 권장
- **CI 워크플로우 최초 1회 실행 필수**: branch protection에서 required status check로 등록하려면 해당 워크플로우가 한 번은 실행되어야 검색 가능

### 11.3 가정

- 타겟 프로젝트가 GitHub에 호스팅되어 있다 [전제]
- 팀원이 터미널(bash) 기본 사용이 가능하다 [전제]
- Squash Merge가 팀의 합의된 머지 전략이다 [전제]
- 킷 도입 대상 프로젝트에 기존 branch protection 규칙이 없거나 호환된다

---

## 12. 향후 계획 (Roadmap)

| 우선순위 | 계획 | 상세 |
|---------|------|------|
| 높음 | **Two-branch 운영 모드 지원** | 현재 main 단독 운영 외에, main + develop 이중 브랜치 운영을 선택 가능하도록 확장 |
| 중간 | **`git branch-move` 개선** | 기능 및 인터페이스 개선 (UX 향상) |
| 중간 | **관리자 세팅 간소화** | 도입 시간 단축, 설정 단계 자동화 확대 |

---

## 표기 규약 (Notation)

§13~§24 및 부록 D는 본문 §1~§12 이후 추가된 보강 섹션이며, 다음 태그를 사용한다. 기존 §10~§11의 `[전제]`/`[추론]`은 그대로 유지.

| 태그 | 의미 |
|------|------|
| `[가정]` | 페르소나/시나리오 가상 사례. 실제 사용자 데이터 아님 |
| `[관찰]` | Seongyul-Lee 본인이 직접 경험·검증한 사실 |
| `[계획]` | 현재 미구현, 향후 추가 예정 |
| `[미확인]` | 검증되지 않음, 추가 조사 필요 |
| `[사후 기록]` | 결정 시점이 아닌 PRD 작성 시점에 정리 |

**원번호 ↔ 배치 §번호 매핑**: 사용자가 원래 지정한 번호와 본 PRD의 배치 §번호는 논리 흐름상 다르다. (1→§20, 3→§21, 4→§13, 6→§23, 8→§18, 9→§16, 11→§15, 12→§14, 15→§17, 16→§19, 21→부록 D, 22→§22, 24→§24)

---

## 13. 핵심 사용 사례 (Key Use Cases)

> **가정 시나리오 안내**: 본 섹션의 페르소나는 모두 가상이다. SACHO 프로젝트는 킷 도입은 완료했으나 본격 작업이 **2026-05** 시작 예정이라 외부 사용자 데이터가 아직 없다. 5개 UC는 다양한 사용자가 킷을 도입했을 때 얻는 이점을 보이는 가상 시나리오다. 모두 `[가정]` 태그.

### 13.1 UC-1: 신입 팀원의 첫 PR `[가정]`

- **Actor**: Junior Dev "지호" — Git 6개월차, Conventional Commits 처음
- **Trigger**: 신규 기능 "로그인 폼" 작업 지시
- **관련 FR**: FR-002, FR-003, FR-006 / AR-001, AR-002

**Flow**: ① `git nb` → 인터랙티브 화면에서 `feat` 선택, name `login-form` 입력 ② 코드 작성 후 `git commit -m "로그인 폼 추가"` → commit-msg 훅이 `❌ Conventional Commits 형식이 아닙니다` 거부 ③ 안내 메시지 보고 `git commit -m "feat: 로그인 폼 추가"` 재시도 → 성공 ④ `git fb` → PR 자동 생성, CI 통과

**이점**: Conventional Commits 형식을 외우지 않아도 첫 실패에서 즉시 학습. type/name 정규식을 의식할 필요 없이 인터랙티브 UI가 안내. 첫 PR 30분 내 생성 가능.

---

### 13.2 UC-2: main 직접 push 차단 → 학습 `[가정]`

- **Actor**: Senior Backend "민영" — 타 프로젝트에서 main 단독 운영에 익숙
- **Trigger**: 무의식적으로 `git push origin main` 입력
- **관련 FR**: FR-005 / AR(Tier 1+3)

**Flow**: ① main 체크아웃 상태에서 코드 수정 후 `git push origin main` ② lefthook pre-push 훅이 `❌ main 브랜치에 직접 push 금지` 즉시 거부 ③ `git nb fix payment-bug` → 새 브랜치 생성 후 변경분 이동 ④ `git fb` → 정상 PR 생성

**이점**: Tier 3(클라이언트 훅)가 가장 빠른 피드백 제공. 사용자가 `--no-verify`로 우회를 시도해도 Tier 1(branch protection)이 서버에서 거부하여 main 손상 방지. 3계층 방어의 보완성을 사용자가 체감.

---

### 13.3 UC-3: 휴가 복귀 후 stale 정리 `[가정]`

- **Actor**: Designer-turned-Dev "예린" — 2주 휴가 복귀, 미머지 브랜치 5개 보유
- **Trigger**: 복귀 첫 날 로컬 정리
- **관련 FR**: FR-004 / AR-003

**Flow**: ① `git checkout main && git pull` → 최신 상태 ② `git cleanup` 실행 → 3-signal(merged + gone + PR-merged) 검출 ③ 검출된 브랜치 목록과 사유 표시 → 사용자 확인 ④ 일괄 삭제, 미머지 1개만 잔존

**이점**: Squash merge로 인해 `git branch --merged`만으로는 감지되지 않는 브랜치를 GitHub PR API로 보완. 휴가 복귀 정리에 5분 이하 소요. stale-branches.yml과 함께 작동해 30일 비활성 브랜치는 별도 알림.

---

### 13.4 UC-4: Squash Merge 직후 정리 루틴 `[가정]`

- **Actor**: Veteran Dev "현우" — Git Flow 출신, Squash 멘탈 모델 적응 중
- **Trigger**: 본인 PR이 squash merge된 직후, 다음 작업 시작 직전
- **관련 FR**: FR-002, FR-004

**Flow**: ① GitHub UI에서 PR squash merge 확인 ② `git nb feat next-feature` → 자동으로 main 최신화 + 새 브랜치 생성 ③ 필요 시 `git cleanup`으로 직전 머지 브랜치 정리 ④ 새 브랜치에서 작업 재개

**이점**: "PR 1개 = 커밋 1개"의 멘탈 모델로 자연스럽게 전환. main 최신화를 별도 명령으로 기억할 필요 없음. Git Flow의 release/develop 마찰이 사라짐.

---

### 13.5 UC-5: 기존 레포에 킷 신규 도입 `[가정]` (일부 `[관찰]`)

- **Actor**: Tech Lead "주현" — 기존 GitHub 레포의 admin
- **Trigger**: 팀 합류로 워크플로우 표준화 필요
- **관련 FR**: FR-001 / AR-001~003

**Flow**: ① `1-ADMIN_SETUP.md` Step 1: branch protection 수동 설정 (~5분) ② Step 2: `.github/workflows/`·`.gitattributes`·PR 템플릿을 PR로 도입 (~10분) ③ Step 3: `lefthook.yml` + `scripts/` 추가 (~5분) ④ 팀원에게 `2-MEMBER_SETUP.md` 공유 → 각자 `bootstrap.sh` 실행

**이점**: 도입 총 ~20분, 팀원당 ~5분. 규칙이 코드로 강제되어 "구두 합의 → 형해화" 사이클 차단. SACHO 프로젝트에서 절차 검증 `[관찰]`.

---

## 14. 사용자 여정 (User Journey)

> §13 UC가 단발 스냅샷이라면, §14는 같은 사용자가 시간 흐름에 따라 거치는 **감정·숙련도 변화**를 추적한다. 5단계 모두 `[가정]`.

### 14.1 단계 개요

| 단계 | 기간 | 핵심 감정 | 주요 활동 | 관련 UC |
|------|------|-----------|-----------|---------|
| Day 0 | 도입일 | 기대/약간 부담 | `bootstrap.sh` 실행, alias 등록 | UC-5 |
| Day 1 | 첫 작업일 | 낯섦, 첫 마찰 | 첫 브랜치, 첫 commit 거부 경험 | UC-1 |
| Week 1 | 1~7일 | 익숙함 | `git nb`/`git fb` 손에 익음 | UC-2 |
| Month 1 | 8~30일 | 신뢰 | cleanup 루틴 정착, stale 알림 대응 | UC-3, UC-4 |
| Break | 위반·실수 | 좌절→학습 | 3계층 방어로 차단 → 복구 | UC-2 |

### 14.2 Day 0 — 도입

관리자(UC-5)가 1회 세팅을 마치면, 팀원은 `bootstrap.sh` 한 번으로 gh·lefthook·alias·hooks를 일괄 설치한다. 이 단계의 마찰점은 **gh PATH 미갱신**(새 터미널 필요) 및 **gh auth login 1회 인증**이며, TROUBLESHOOTING.md에 대응 절차가 정리되어 있다.

### 14.3 Day 1 — 첫 마찰

대부분의 사용자는 첫 commit에서 형식 거부를 경험한다(`❌ Conventional Commits 형식이 아닙니다`). 이것이 곧 **킷의 가장 강력한 학습 기점**이다. 한 번의 실패 메시지가 type 8종과 형식을 동시에 가르치며, 두 번째 commit부터는 형식 오류율이 급감한다 `[가정]`.

### 14.4 Week 1 — 내재화

`git nb`/`git fb`/`git cleanup` 3개 alias가 손에 익으면 워크플로우가 무의식화된다. type 선택의 미세한 고민(refactor vs chore 등)은 남지만 구조적 마찰은 사라진다. 사용자는 "형식 강제"를 부담이 아닌 **명료성**으로 받아들이기 시작한다.

### 14.5 Month 1 — 유지 루틴

`git cleanup`이 주 1~2회의 자연스러운 루틴이 된다. stale-branches.yml이 30일 비활성 브랜치를 자동 알림하므로 사용자는 능동적 추적 부담이 없다. PR 회전이 빨라지고 main의 linear history가 시각적으로 정리된다.

### 14.6 Break & Recover — 위반과 학습

규칙 위반(main 직접 push, 잘못된 브랜치명, 첫 글자 대문자 PR 제목)은 3계층 방어 중 가장 빠른 계층에서 차단된다. **차단 = 학습 기회**라는 메커니즘이 §4 원칙 4("규칙의 코드화")의 실행 결과다. 사용자는 거부 메시지를 통해 규칙의 존재를 의식하고, 다음 시도에서 자연스럽게 따른다.

---

## 15. 에러 UX 및 메시지 정책 (Error UX Policy)

킷 전체 7개 스크립트의 출력 메시지는 일관된 포맷·이모지·색상 규칙을 따른다. 본 섹션은 현재 구현 상태를 명문화하고, 표준화 원칙을 정의한다.

### 15.1 이모지 표준 (현재 사용)

| 이모지 | 용도 | 사용 스크립트 수 | 예시 |
|--------|------|-----------------|------|
| ❌ | 에러/거부 | 7 / 7 | `❌ main 브랜치에 직접 push 금지.` |
| ✅ | 성공/완료 | 7 / 7 | `✅ 브랜치명 OK` |
| ⚠️ | 경고/주의 | 6 / 7 | `⚠️ 커밋되지 않은 변경 사항이 있습니다:` |
| 🔍 | 검사/진행 | 5 / 7 | `🔍 환경 감지 중...` |
| 📝 | 작업 진행 | 1 / 7 | `📝 PR 본문 채우는 중` |
| ℹ️ | 정보/안내 | 1 / 7 | `ℹ️ 이미 현재 브랜치입니다` |

### 15.2 메시지 포맷 규칙

1. **첫 줄**: `<이모지> <한국어 메시지>` (한 문장, 마침표로 종결)
2. **둘째 줄부터**: 4칸 들여쓰기 + 해결 가이드 또는 권장 명령어
3. **여러 항목 나열**: 들여쓰기 후 `- ` prefix
4. **비-TTY 환경(CI/Docker) ASCII fallback**: `[ERROR]`, `[OK]`, `[WARN]` 등으로 대체 `[계획]`

### 15.3 색상 정책

현재 ANSI 색상 코드는 `branch-move.sh`(녹색)와 `new-branch.sh`(밝은 시안) 2곳에서만 선택적으로 사용된다. 원칙은 다음과 같다.

- **TTY 감지 후 적용**: `[[ -t 1 ]]` 검사 후 색상 변수 정의, 비-TTY에서는 빈 문자열
- **`NO_COLOR` 환경변수 존중**: <https://no-color.org> 표준에 따라 `NO_COLOR=1` 시 색상 비활성화 `[계획]`
- **이모지 우선**: 색상은 보조 단서이며, 이모지가 1차 시각 단서

### 15.4 언어 규칙

- 본문 메시지: 한국어
- 코드/정규식/타입명/명령어: 영어 (`feat`, `git nb`, `^(feat|fix|...)/...`)
- 한국어 검색 시에도 영어 키워드 노출(`Conventional Commits`, `lefthook`)로 검색성 확보

### 15.5 문서 링크 원칙

에러 메시지는 가능한 한 TROUBLESHOOTING.md의 해당 앵커를 포함하여 사용자가 즉시 해결책으로 이동할 수 있어야 한다 `[계획]`. 현재는 일부 메시지에 문서 경로만 텍스트로 표시.

---

## 16. 관찰성 / 디버깅 / 로깅 (Observability)

### 16.1 현재 상태 (As-Is)

| 항목 | 현재 상태 |
|------|----------|
| `DEBUG`/`VERBOSE` 환경변수 | 없음 |
| `set -x` 디버그 모드 | 없음 (모든 스크립트는 `set -euo pipefail`만 사용) |
| 상태 추적 변수 | `bootstrap.sh`만 6개 `STATUS_*` 변수 보유 |
| 로그 파일 | 없음 (stdout/stderr 직접 출력) |
| 진행 표시 | `🔍 ... 중` 메시지로 단계 알림 |

### 16.2 목표 모델 (To-Be) `[계획]`

1. `DEBUG=1` 환경변수 설정 시 모든 스크립트가 `set -x` 활성화
2. `bootstrap.sh`의 `print_summary()` 패턴을 모든 스크립트의 표준으로 승격
3. 각 스크립트 종료 시 단계별 성공/실패 요약 출력
4. `NO_COLOR=1`, `CI=true` 환경변수 표준 지원

### 16.3 환경변수 규약 `[계획]`

| 변수 | 의미 | 적용 범위 |
|------|------|-----------|
| `DEBUG` | `1` 시 `set -x` 활성화 | 모든 스크립트 |
| `VERBOSE` | `1` 시 추가 진행 메시지 | 모든 스크립트 |
| `NO_COLOR` | 설정 시 ANSI 색상 비활성 | UI 출력 스크립트 |
| `CI` | 비-TTY 자동 감지 보조 | 모든 스크립트 |

### 16.4 상태 추적 표준

`bootstrap.sh`는 6개 `STATUS_*` 변수(GH/GH_AUTH/LEFTHOOK/HOOKS/ALIASES/GITATTRIBUTES)로 단계별 결과를 추적하고 `print_summary()`로 최종 표를 출력한다. 이 패턴을 7개 스크립트 전체로 일반화하여, 각 스크립트가 종료 시 "어느 단계에서 성공·실패·생략했는지"를 일관된 형식으로 출력한다 `[계획]`.

### 16.5 로그 정책

현재 모든 출력은 stdout/stderr로 직접 노출된다. 향후 `.git/branch-strategy-kit.log`로 선택적 로그 적재 검토 `[계획]`. 외부 텔레메트리는 §24와 보안 책임상 도입하지 않는다.

---

## 17. 알려진 이슈 및 제한사항 (Known Issues & Limitations)

> §11이 *의도된* 제약을 다룬다면, §17은 *발견된* 한계와 미처리 엣지 케이스를 다룬다. 상세 해결 절차는 `TROUBLESHOOTING.md` 참조.

### 17.1 문서화된 이슈 요약 (심각도 상·중)

| # | 카테고리 | 요지 | 심각도 |
|---|---------|------|--------|
| 1 | branch protection | "Required status check"가 워크플로우 1회 실행 전에는 검색 안 됨 | 중 |
| 2 | bootstrap | `lefthook install` 미실행 시 훅이 작동 안 함 | 중 |
| 3 | bootstrap | `gh` 설치 후 새 터미널 필요 (PATH 미갱신) | 중 |
| 4 | gh 인증 | `gh auth status` 실패 시 `git fb`가 PR 생성 불가 | 중 |
| 5 | Windows | `core.autocrlf=true` + `.gitattributes` 부재 시 유령 modified | 상 |
| 6 | Windows | Git Bash에서 `permission denied` (`chmod +x` + `git update-index --chmod=+x` 필요) | 상 |
| 7 | finish-branch | 다중 커밋 PR에서 `--fill-first`만 사용해 본문 불완전 | 중 |
| 8 | cleanup-merged | `gh` 미인증 시 PR 머지 신호 검출 생략 (silent skip) | 중 |

> **그 외 8건**: PR `synchronize` 트리거 누락, `.gitignore` 의도치 않은 ignore, winget 설치 후 PATH 갱신, lefthook 인라인 스크립트 mangle, 비-TTY 환경 인터랙티브 실패, branch protection rule 불일치, CI 워크플로우 권한, `git pull --ff-only` 충돌. 상세는 `TROUBLESHOOTING.md` 참조.

### 17.2 미처리 엣지 케이스

- **네트워크 오류 시 재시도 없음** `[관찰]`: `new-branch.sh`의 `git pull` 실패 시 1줄 거부만, 재시도 로직 없음
- **`gh` API rate limit 미처리** `[추론]`: `cleanup-merged.sh`가 PR 조회 시 rate limit에 걸리면 silent fail
- **대용량 브랜치(>1000개)에서 fzf 성능** `[추론]`: `branch-move.sh`의 fzf 모드는 정렬 작업이 O(n), 1000+ 브랜치에서 응답 지연 가능
- **비-TTY 환경 fallback 미구현** `[관찰]`: `new-branch.sh` 인터랙티브 모드는 비-TTY에서 즉시 거부, fallback 자동 전환 없음

### 17.3 플랫폼 제한

- **rpm-based OS 미지원** `[관찰]`: `bootstrap.sh`가 brew/apt/dnf/pacman/winget/scoop을 지원하지만 RHEL/CentOS의 `yum` 및 일부 dnf 변종에서 동작 보장 없음
- **dash/zsh/POSIX sh 미동작** `[관찰]`: bash 4+ 전용 (`set -euo pipefail`, 배열, `[[ ]]` 등)
- **GitHub 외 호스팅 미지원**: GitLab, Bitbucket, Gitea 등에서 `gh` CLI와 GitHub Actions를 사용할 수 없으므로 적용 불가

### 17.4 대응 원칙

모든 이슈는 우선 `TROUBLESHOOTING.md`로 사용자 자가 해결을 유도한다. 본질적 해결이 필요한 항목은 §12 Roadmap으로 승격하여 후속 릴리스에서 해소한다. 신규 이슈 발견 시 `TROUBLESHOOTING.md` 추가가 1차 대응이며, §17 표 갱신은 분기별 일괄.

---

## 18. 테스트 및 품질 보장 전략 (Testing & QA Strategy)

### 18.1 현재 품질 상태 (As-Is)

- **TODO/FIXME/HACK 주석**: 0건 (`grep` 검사 결과)
- **자동화 테스트 코드**: 0개 (bats, shunit2 등 미사용)
- **shellcheck baseline**: `[미확인]` — 도입 시 baseline 수립 필요
- **Self-dogfooding**: 이 레포 자체가 자신의 킷을 적용 중 (메인 보호, lefthook, CI 모두 활성)

### 18.2 품질 보장 3축 모델

1. **정적 검사** — shellcheck, `bash -n`, yamllint, markdown lint
2. **Self-Dogfooding** — 이 레포의 PR이 킷의 모든 규칙을 통과해야 머지됨
3. **수동 체크리스트** — 릴리스 전 FR-001~007 정상/에러 경로 14항목 점검

### 18.3 정적 검사 도구 `[계획]`

| 도구 | 검사 대상 | 실행 시점 | 비고 |
|------|----------|----------|------|
| `shellcheck` | `scripts/*.sh` 7개 | 매 PR (CI) + 로컬 | severity ≥ warning baseline 적용 |
| `bash -n` | `scripts/*.sh` 7개 | 매 PR (CI) | 문법만 검사 |
| `yamllint` | `*.yml`, `lefthook.yml` | 매 PR (CI) | 들여쓰기/key 중복 |
| markdown lint | `*.md` 8개 | 매 PR (CI) | link/heading 검증 |

### 18.4 Self-Dogfooding 정의

이 레포의 모든 변경은 킷이 강제하는 규칙을 통과해야 한다. 즉:
- main 직접 push 차단(Tier 1) → admin도 적용
- 브랜치명 정규식 준수(Tier 2 + Tier 3)
- PR 제목 Conventional Commits(Tier 2)
- commit-msg lefthook 통과(Tier 3)

이는 "킷 저자가 자기 킷의 첫 번째 사용자"라는 1인 프로젝트 검증 전략이다. 외부 리뷰어가 없으므로 자동 검증이 유일한 게이트.

**실측 사례: 이 레포 자체** `[관찰]`

PRD 작성 시점 기준, branch-strategy-kit 레포 자체에 킷이 적용된 결과:

| 항목 | 값 |
|------|------|
| 총 PR 수 | 29건 (#1~#29, #7은 close 후 #6으로 재제출, 실제 머지 28건) |
| 적용 기간 | 2026-04-07 ~ 2026-04-08 (약 2일, 초기 구축 burst) |
| 머지 전략 | 100% squash merge |
| 브랜치명 규칙 위반 | 0건 (모든 브랜치가 `type/name` 정규식 통과) |
| Type 분포 | feat 9 · docs 7 · fix 6 · chore 5 · remove 1 |
| main 직접 push 차단 | lefthook + branch protection 작동 (위반 시도 0건 도달) |

PR #7 → #6 재제출은 워크플로우의 정상 동작 사례다. 잘못된 커밋이 포함된 PR을 close 후 재작성한 것으로, "PR close 책임은 리뷰어"라는 `3-DAILY_WORKFLOW.md` 절차가 1인 검증 환경에서도 그대로 작동함을 보였다.

### 18.5 수동 체크리스트 (릴리스 전)

각 FR마다 **정상 경로 1개 + 에러 경로 1개** = 14항목.

- [ ] FR-001 bootstrap: 신규 환경 / 이미 설치된 환경
- [ ] FR-002 new-branch: `git nb feat name` / 잘못된 type 거부
- [ ] FR-003 finish-branch: 정상 PR 생성 / 미커밋 변경 차단
- [ ] FR-004 cleanup: 머지 브랜치 일괄 삭제 / 보호 브랜치 제외 확인
- [ ] FR-005 check-branch: 정상 브랜치명 통과 / 위반 거부
- [ ] FR-006 check-commit-msg: 정상 통과 / 형식 위반 거부
- [ ] FR-007 branch-move: fzf 사용 가능 / fallback 번호 입력

### 18.6 9곳 동기화 불변식 검증 `[계획]`

§9의 불변식 위반 방지를 위해 `scripts/verify-invariant.sh` 신설 계획.

```
# 의사코드
1. 9개 파일에서 type 목록 추출 (정규식/배열/표 형식별 파서)
2. 모든 추출 결과를 set으로 정규화
3. set이 단일하지 않으면 어느 파일이 어긋났는지 출력 후 exit 1
```

이 스크립트는 §19 `kit-ci-invariant.yml`에서 자동 호출되어 매 PR에서 검증.

---

## 19. CI/CD 품질 관리 (Kit-self CI)

### 19.1 역할 분리

| 분류 | 정의 | 현황 |
|------|------|------|
| **User-facing CI** | 킷을 도입한 *사용자 프로젝트*의 워크플로우/PR을 검증 | 3개 워크플로우 (현행) |
| **Kit-self CI** | *이 킷 레포 자체*의 코드 품질·문서·동기화를 검증 | 0개 (계획) |

§6은 User-facing CI만 다뤘다. §19는 Kit-self CI를 신설하는 계획이다.

### 19.2 User-facing CI (현행 3개)

| Workflow | 대상 | 역할 |
|----------|------|------|
| `branch-name-check.yml` | PR의 source branch | 사용자가 만든 브랜치명 정규식 준수 |
| `pr-title-check.yml` | PR 제목 | Conventional Commits 형식 |
| `stale-branches.yml` | 사용자 레포 전체 | 30일+ 비활성 브랜치 알림 |

> 위 3개는 모두 *사용자 프로젝트* 자산이며, 이 레포에 동작하는 것은 self-dogfooding의 부산물이다.

### 19.3 Kit-self CI (신설 계획) `[계획]`

| 신규 Workflow 후보 | 검사 목적 | 트리거 |
|-------------------|----------|--------|
| `kit-ci-shellcheck.yml` | `scripts/*.sh` shellcheck 정적 분석 | PR + push |
| `kit-ci-bash-syntax.yml` | `bash -n` 문법 검사 | PR + push |
| `kit-ci-yaml-lint.yml` | `lefthook.yml`, `.github/workflows/*.yml` lint | PR + push |
| `kit-ci-markdown-lint.yml` | `*.md` 8개 문서 lint | PR + push |
| `kit-ci-link-check.yml` | README·가이드 내 상호 참조 링크 | weekly cron |
| `kit-ci-invariant.yml` | §9 9곳 동기화 검증 (`verify-invariant.sh`) | PR + push |

### 19.4 검사 항목 상세

- **shellcheck**: severity ≥ warning을 baseline으로, 신규 위반만 차단 (legacy 호환)
- **markdown lint**: heading 깊이, 링크 상태, 표 정합성 — 도구 선택 자유 (markdownlint-cli2 / mdl)
- **invariant**: §9 표의 9개 파일에서 type 목록 추출 후 set 비교

### 19.5 실행 환경

- 기본: `ubuntu-latest`
- Windows 매트릭스 추가 여부 `[결정 필요]` — Git Bash 환경 호환성 회귀 방지를 위해 `windows-latest` 매트릭스 검토
- 1인 프로젝트이므로 외부 리뷰어 게이트가 없어 CI가 유일한 자동 게이트. 따라서 Kit-self CI가 §18의 핵심 실행 메커니즘.

---

## 20. 릴리스 및 버전 관리 정책 (Release & Versioning)

### 20.1 SemVer 적용

본 킷은 [Semantic Versioning 2.0.0](https://semver.org)을 따른다. `MAJOR.MINOR.PATCH`를 다음과 같이 해석:

- **MAJOR**: 기존 사용자 프로젝트에 호환되지 않는 변경 (type 제거, 정규식 엄격화 등)
- **MINOR**: 후방 호환되는 기능 추가 (새 type 추가, 새 스크립트 추가 등)
- **PATCH**: 버그 수정, 메시지 문구·이모지 변경, 문서 보완

### 20.2 현재 버전 현황

- `VERSION` 파일: `1.0.0`
- Git tag: `v1.0.0` (1개)
- 라이선스: MIT
- 도입 사례: SACHO 프로젝트 1건 (본격 작업 2026-05 시작 예정) `[관찰]`

### 20.3 Breaking Change 판정 기준

본 표가 §20의 핵심이다. 모호한 판단을 줄이기 위해 사전 분류한다.

| 변경 항목 | SemVer | 이유 |
|----------|--------|------|
| 새 type 추가 (예: `perf`) | MINOR | 기존 사용자 브랜치/PR에 영향 없음 |
| type 제거 (예: `research` 삭제) | MAJOR | 기존 브랜치명·PR이 즉시 무효 |
| 브랜치명 정규식 엄격화 | MAJOR | 기존 브랜치명이 거부될 수 있음 |
| 새 스크립트 추가 (`git xx`) | MINOR | 기존 alias·동작 영향 없음 |
| 기존 스크립트 인자 추가 (선택) | MINOR | 기본값으로 후방 호환 |
| 기존 스크립트 인자 제거 | MAJOR | 사용자 스크립트가 깨짐 |
| 에러 메시지 문구 변경 | PATCH | 기능 동일, 문구만 |
| 이모지 변경 | PATCH | 의미 동일 |
| 환경변수 이름 변경 | MAJOR | 외부 인터페이스 |
| 9곳 동기화 위치 변경(파일 추가) | MINOR | 내부 구조 |
| Git/gh/lefthook 최소 버전 상향 | MAJOR | 환경 요구 강화 |
| TROUBLESHOOTING 항목 추가 | PATCH | 문서 보완 |

### 20.4 Tag 및 릴리스 프로세스

1. `VERSION` 파일과 `CHANGELOG.md`를 동시 갱신
2. `chore: release v1.x.y` 커밋 (lefthook 통과)
3. `git tag v1.x.y` + `git push --tags`
4. GitHub Release 생성, CHANGELOG 해당 섹션 본문으로 사용

### 20.5 CHANGELOG 정책 `[계획]`

현재 `CHANGELOG.md` 부재. v1.1.0 준비 시 [Keep a Changelog](https://keepachangelog.com) 형식으로 신설 예정. v1.0.0 이후 첫 릴리스 시 소급 작성.

### 20.6 Deprecation 정책

기능 제거(MAJOR)는 최소 1개 MINOR 버전에서 사전 deprecation 경고를 출력한 후 다음 MAJOR에서 제거한다. 경고는 ⚠️ 이모지 + 영문 키워드 `DEPRECATED`로 검색성 확보.

---

## 21. 보안 고려사항 (Security Considerations)

### 21.1 위협 모델 범위

> **선언**: 본 킷은 *보안 도구*가 아니라 *워크플로우 규율 도구*다. 본 섹션은 킷이 도입된 환경에서 발생 가능한 위협을 식별하고, 킷이 책임지는 범위와 사용자(repo admin)·GitHub가 책임지는 범위를 분리한다.

### 21.2 위협 식별

| ID | 위협 | 잠재 공격자 | 영향 | 대응 |
|----|------|------------|------|------|
| T1 | 악의적 PR이 user-facing CI를 우회 | 외부 contributor | main 오염 | Tier 1(branch protection) + Tier 2(required check) |
| T2 | 내부 사용자의 `--no-verify` 남용 | 팀원 | 로컬 검증 우회 | Tier 1+2가 서버에서 차단, 로컬 우회는 허용되지만 push 단계에서 거부 |
| T3 | `bootstrap.sh` 변조 후 배포 | 킷 저장소 변조 | 팀원 환경 오염 | LICENSE/태그 검증, 사용자가 신뢰한 소스에서만 clone |
| T4 | 브랜치명에 셸 메타문자 injection | 외부 contributor | 스크립트 명령 주입 | 정규식 `^[a-z0-9][a-z0-9-]*$`가 셸 위험문자(`;`, `` ` ``, `$`, `..`) 차단 |
| T5 | `gh` 토큰 유출 | 환경 침해 | 사용자 GitHub 권한 도용 | 킷은 토큰을 직접 읽거나 저장하지 않음. `gh` CLI에 위임 |
| T6 | 핀 고정 안 된 GitHub Action 변조 | 액션 공급자 | CI 임의 코드 실행 | `@v5` 등 major tag 사용 중. SHA 핀 고정 검토 `[미확인 — 실태 확인 필요]` |

### 21.3 입력 sanitization

브랜치명·커밋 메시지·PR 제목 정규식이 1차 방어선이다. 정규식은 **셸 메타문자를 자동 거부**하므로 별도 escape 없이 사용 가능. 다만 `cleanup-merged.sh`의 `--exclude` 패턴은 사용자 직접 입력이며 bash glob으로 해석되므로, 신뢰 없는 입력에는 사용하지 말 것 (현재는 사용자 본인 입력 전제).

### 21.4 GitHub 토큰 / gh CLI 인증

- 킷은 `gh` CLI에 인증을 **위임**한다. 토큰을 직접 읽거나 저장·전송하지 않는다
- `gh auth login`은 사용자가 직접 실행하며, 킷의 `bootstrap.sh`는 인증 상태만 확인(advisory)
- CI에서는 `secrets.GITHUB_TOKEN`을 사용. 워크플로우 권한은 최소 권한 원칙(`permissions:` 명시)

### 21.5 `--no-verify` 우회와 3계층 방어

`git commit --no-verify` 또는 `git push --no-verify`로 Tier 3(클라이언트 lefthook)는 우회 가능하다. 그러나:

- **Tier 1 (branch protection)**: 서버 측, 우회 불가 (admin도 적용)
- **Tier 2 (required CI check)**: PR 머지 차단, 우회 불가 (status check 등록 시)
- **Tier 3 (lefthook)**: 빠른 피드백용. 우회는 가능하지만 서버에서 결국 차단됨

따라서 Tier 3는 *편의*이고 보안 강제력은 Tier 1+2에 있다는 점을 사용자가 이해해야 한다.

### 21.6 Supply-chain 위협

GitHub Actions 외부 액션 사용 현황 (`amannn/action-semantic-pull-request@v5`, `cbrgm/cleanup-stale-branches-action@v1`)은 major tag 핀 고정이다. SHA 핀 고정으로 강화 검토 `[계획]`. 액션 업그레이드는 §20 PATCH/MINOR 변경으로 분류.

### 21.7 책임 공유 모델

| 주체 | 책임 범위 |
|------|----------|
| **킷 저자 (Seongyul-Lee)** | 정의된 규칙이 정의대로 동작함, 정규식이 셸 injection 차단, 토큰 직접 처리 안 함 |
| **사용자 (repo admin)** | branch protection 활성화, required check 등록, gh 토큰 관리, 팀원 교육 |
| **GitHub** | branch protection enforcement, Actions 실행 격리, 토큰 저장소 보안 |

---

## 22. 의존성 리스크 / 벤더 락인 (Dependency Risk)

### 22.1 의존성 인벤토리

| 도구 | 역할 | 버전 요구 | 라이선스 | 대체 가능성 |
|------|------|----------|---------|------------|
| `git` | 버전 관리 | 2.30+ | GPL-2.0 | 없음 (불가결) |
| `bash` | 스크립트 런타임 | 4+ | GPL-3.0 | dash/zsh 미지원 |
| `gh` CLI | PR/조회/인증 | 2.x | MIT | curl + REST API |
| `lefthook` | Git 훅 매니저 | 1.x | MIT | Husky, core.hooksPath 직접 |
| GitHub Actions | CI 실행 환경 | — | (서비스) | GitLab CI, Drone 등 (마이그레이션 비용 큼) |
| GitHub branch protection | Tier 1 방어 | — | (서비스) | GitLab 보호 브랜치 (의미 동일) |

### 22.2 리스크 매트릭스

| 의존성 | 단종 확률 `[추론]` | 영향도 | 전환 비용 | 종합 |
|--------|------------------|--------|----------|------|
| `git` | 매우 낮음 | 치명 | 매우 높음 | 수용 |
| `bash` 4+ | 매우 낮음 | 치명 | 높음 | 수용 |
| `gh` CLI | 낮음 (GitHub 공식) | 중 | 낮음 (Plan B 있음) | 수용 |
| `lefthook` | 중 (작은 OSS 프로젝트) | 중 | 낮음 (Plan B 있음) | 모니터링 |
| GitHub Actions | 매우 낮음 | 치명 | 매우 높음 (전체 재작성) | 수용 |
| GitHub branch protection | 매우 낮음 | 치명 | 매우 높음 | 수용 |

### 22.3 Plan B (단종/Breaking 시나리오 대응)

| 의존성 | 시나리오 | 대응 |
|--------|---------|------|
| `gh` CLI | 단종 또는 호환성 깨짐 | `curl` + REST API로 `finish-branch.sh` 재구현. 인증은 `GITHUB_TOKEN` 환경변수 직접 |
| `lefthook` | 유지보수 중단 | `husky` 또는 `git config core.hooksPath`로 직접 관리. 검증 스크립트는 그대로 재사용 가능 |
| GitHub Actions breaking | 액션 API 변경 | 해당 워크플로우 파일만 재작성. 검증 로직은 `scripts/check-*.sh`에 있어 영향 없음 |
| branch protection API 변경 | UI/API 스펙 변경 | `1-ADMIN_SETUP.md` 갱신으로 대응. 코드 변경 불필요 |

### 22.4 벤더 락인 수용 근거

§4 설계 철학 원칙 6("복사 기반 이식")과 §11.1 기술적 제약("GitHub 전용")이 명시하듯, GitHub 생태계 락인은 **의도된 트레이드오프**다. 다중 호스팅 지원은 추상화 계층 도입 비용이 1인 프로젝트 유지 가능 범위를 초과하며, SACHO 및 잠재 사용자가 모두 GitHub 사용자라는 전제에서 정당화된다.

---

## 23. 아키텍처 의사결정 기록 (ADR)

> **본 ADR은 모두 `[사후 기록]`** — 결정 시점이 아닌 PRD 작성 시점에 정리. **결정자**: Seongyul-Lee.

### 23.0 ADR 형식

각 ADR은 5필드로 구성: **상태 / 배경 / 검토된 대안 / 결정 / 근거**.

### 23.1 ADR-001: lefthook 채택

| 필드 | 내용 |
|------|------|
| 상태 | Accepted (v1.0.0 이전) |
| 배경 | Git 훅 관리 도구가 필요. 사용자는 한 번의 명령으로 훅 설치를 완료해야 함 |
| 검토된 대안 | (a) Husky — Node.js 의존 (b) pre-commit — Python 의존 (c) git core.hooksPath 직접 관리 |
| 결정 | lefthook 채택 |
| 근거 | Go 단일 바이너리, 런타임 무의존, parallel hook 지원, YAML 설정. Husky/pre-commit는 추가 런타임 설치를 강제해 진입장벽 상승 |

### 23.2 ADR-002: bash 채택

| 필드 | 내용 |
|------|------|
| 상태 | Accepted (v1.0.0 이전) |
| 배경 | 7개 스크립트의 구현 언어 선택 |
| 검토된 대안 | (a) Node.js (b) Python (c) Go (d) bash |
| 결정 | bash 4+ 채택 |
| 근거 | 모든 OS의 git 환경에 기본 포함(Windows는 Git Bash). 추가 런타임 설치 불필요. 7개 스크립트가 전부 git/gh wrapper 수준이라 복잡한 언어 기능 불필요. dash/zsh 미지원은 §11.1 제약으로 수용 |

### 23.3 ADR-003: Squash Merge 전일화

| 필드 | 내용 |
|------|------|
| 상태 | Accepted (v1.0.0 이전) |
| 배경 | 머지 전략 통일 필요. SACHO 팀이 Squash Merge 미숙으로 운영 혼란 발생 |
| 검토된 대안 | (a) merge commit 허용 (b) rebase merge 허용 (c) squash merge만 허용 |
| 결정 | squash merge만 허용 |
| 근거 | "PR 1개 = 커밋 1개"가 가장 단순한 멘탈 모델. linear history 자동 보장. merge commit은 히스토리 오염, rebase merge는 중급 Git 지식 필요. branch protection의 `Require linear history` 옵션과 결합해 강제 |

### 23.4 ADR-004: 8개 type 확정

| 필드 | 내용 |
|------|------|
| 상태 | Accepted (v1.0.0 이전) |
| 배경 | 브랜치 type과 commit type을 동일 집합으로 통일 필요. Conventional Commits 표준은 핵심 7개를 명시하나 프로젝트 맞춤화 가능 |
| 검토된 대안 | (a) Conventional Commits 기본 7개 (b) Angular convention 11개 (c) 자체 8개 |
| 결정 | feat/fix/refactor/docs/research/data/chore/remove 8개 |
| 근거 | `research`(탐색)와 `data`(스키마/마이그레이션)는 게임/데이터 프로젝트에서 빈번. `remove`는 삭제를 명시적으로 표현해 PR 의도가 분명. test/style/build/perf는 chore로 흡수 |

### 23.5 ADR-005: gh CLI 의존

| 필드 | 내용 |
|------|------|
| 상태 | Accepted (v1.0.0 이전) |
| 배경 | PR 생성·조회 자동화 필요 |
| 검토된 대안 | (a) `gh` CLI (b) `curl` + REST API + 직접 인증 처리 (c) GitHub API 라이브러리 |
| 결정 | `gh` CLI 채택 |
| 근거 | 인증을 `gh`에 위임해 토큰 직접 처리 회피(보안). PR 생성·조회 명령이 한 줄로 가능. GitHub 공식 도구라 단종 리스크 낮음. Plan B(curl + REST)는 §22.3에 정의 |

### 23.6 ADR-006: lefthook 인라인 스크립트 회피

| 필드 | 내용 |
|------|------|
| 상태 | Accepted (Git Bash on Windows mangle 버그 발견 후) |
| 배경 | lefthook.yml에 bash 검증 로직을 인라인으로 작성하면 Git Bash on Windows에서 큰따옴표/백슬래시가 mangle되어 정규식 검증 실패 |
| 검토된 대안 | (a) lefthook.yml 인라인 스크립트 (b) `scripts/check-*.sh` 별도 파일 호출 (c) lefthook을 포기하고 git core.hooksPath 직접 |
| 결정 | `bash scripts/check-*.sh <args>` 호출 패턴 강제 |
| 근거 | 인라인은 Windows 사용자 환경에서 일관된 실패 발생. 별도 파일은 mangle 영향을 받지 않으며, 검증 로직 재사용성 향상. 1차 증거: `lefthook.yml:14` 및 `check-commit-msg.sh:8` NOTE 주석 |

---

## 24. 국제화 / 다국어 지원 계획 (Internationalization)

### 24.1 현재 언어 정책 현황

| 파일/요소 | 현재 언어 | 비고 |
|----------|----------|------|
| 사용자 문서(README, 가이드 5종) | 한국어 | SACHO 팀 한국어 화자 전제 |
| 코드/정규식/타입명 | 영어 | `feat`, `fix` 등 표준 |
| 에러 메시지 | 한국어 + 이모지 | 검색성 위해 영문 키워드 일부 병기 |
| `CLAUDE.md` | 한국어 | AI 가이드 |
| LICENSE | 영어 | MIT 표준 |

### 24.2 영어 문서 작성 계획 `[계획]`

오픈소스 배포 시 영어가 진입장벽이 되므로 단계적 영어화. 우선순위:

1. `README_en.md` (가장 먼저, OSS 발견성)
2. `1-ADMIN_SETUP_en.md`
3. `2-MEMBER_SETUP_en.md`
4. `3-DAILY_WORKFLOW_en.md`
5. `TROUBLESHOOTING_en.md`

기존 한국어 문서는 그대로 유지(주 사용자 한국어). 영어 문서는 한국어 문서의 직역이 아닌 동등 내용 재작성.

### 24.3 에러 메시지 i18n 전략 `[계획]`

| 전략 | 장점 | 단점 | 채택 여부 |
|------|------|------|----------|
| 하드코딩 영어 전환 | 단순 | 한국어 사용자 손실 | ✗ |
| `LANG` 환경변수 분기 | 표준 호환 | 코드 복잡도 상승 | 검토 |
| 메시지 카탈로그 파일 | 완전 분리 | bash 구현 부담 | ✗ |
| 한국어/영어 이중 병기 | 즉시 적용 가능 | 메시지 길어짐 | 검토 |

이모지(❌✅⚠️🔍)는 언어 독립적 1차 단서이므로, i18n 도입 후에도 그대로 유지해 시각 단서를 일관되게 제공.

### 24.4 Roadmap 편입

§12 Roadmap에 우선순위 **낮음**으로 편입한다. SACHO 팀이 본격 작업을 시작하는 2026-05까지는 한국어 사용자만 존재하므로 영어 문서 작성은 v1.x 후반 또는 v2.0 시점에 검토한다.

---

## 부록

### A. 네이밍 규칙

| 대상 | 패턴 | 예시 |
|------|------|------|
| 브랜치명 | `^(feat\|fix\|refactor\|docs\|research\|data\|chore\|remove)/[a-z0-9][a-z0-9-]*$` | `feat/login-form`, `fix/null-pointer` |
| 커밋 메시지 | `^(type)(\(scope\))?!?: subject` | `feat: 로그인 폼 추가`, `fix(auth): 토큰 만료 처리` |
| PR 제목 | 커밋 메시지와 동일 (첫 글자 대문자 금지) | `feat: basic enemy AI movement 구현` |

**허용 타입 (8종)**:

| 타입 | 용도 |
|------|------|
| `feat` | 신규 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변경 없는 코드 개선 |
| `docs` | 문서만 변경 |
| `research` | 탐색·실험·리서치 |
| `data` | DB 스키마, 마이그레이션, fixture |
| `chore` | 빌드/CI/설정 변경 |
| `remove` | 파일·기능 제거 |

### B. 참조 문서 목록

| 문서 | 대상 | 역할 |
|------|------|------|
| `README.md` | 의사결정자/리더 | 전체 개요 + 가치 제안 |
| `1-ADMIN_SETUP.md` | repo admin | 킷 1회 도입 가이드 (~15분) |
| `2-MEMBER_SETUP.md` | 신규 팀원 | 로컬 환경 셋업 가이드 (~5분) |
| `3-DAILY_WORKFLOW.md` | 모든 개발자 | 일상 워크플로우 레퍼런스 |
| `TROUBLESHOOTING.md` | 문제 해결 | 에러 원인 + 해결책 |

### C. 분석 범위

**분석 대상**: 프로젝트 루트의 전체 파일 (21개)
- 셸 스크립트 7개 (`scripts/*.sh`)
- GitHub Actions 워크플로우 3개 (`.github/workflows/*.yml`)
- 설정 파일 4개 (`lefthook.yml`, `.gitattributes`, `.gitignore`, `.github/pull_request_template.md`)
- 마크다운 문서 5개 (`README.md`, `1-ADMIN_SETUP.md`, `2-MEMBER_SETUP.md`, `3-DAILY_WORKFLOW.md`, `TROUBLESHOOTING.md`)
- 기타 2개 (`LICENSE`, `CLAUDE.md`)

**제외 대상**: `.git/` 디렉토리, `CLAUDE.md` (로컬 전용, gitignore 대상)

### D. 용어집 (Glossary)

본 PRD에서 반복 등장하는 핵심 용어 정의. "이 킷에서의 의미" 컬럼은 일반 정의와 본 킷의 적용 맥락을 구분한다.

#### D.1 Git / GitHub 용어

| 용어 | 정의 | 이 킷에서의 의미 | 관련 § |
|------|------|----------------|--------|
| Squash Merge | PR의 모든 커밋을 1개로 압축해 main에 합치는 머지 전략 | 유일하게 허용되는 머지 전략 (§4 원칙 3) | §4, §20.3, ADR-003 |
| Trunk | 단일 영구 브랜치 (보통 main) | 본 킷은 main 단일 trunk만 인정 | §4 |
| Linear History | merge commit 없이 일직선으로 이어지는 git history | branch protection의 `Require linear history`로 강제 | §4, §6.1 |
| GitHub Flow | main + 단명 작업 브랜치 + PR 기반의 워크플로우 모델 | 본 킷이 채택한 전략 | §4 |
| Branch Protection | GitHub의 브랜치 단위 정책 (push/머지 제약) | Tier 1 방어선 | §6.1, §21.5 |
| Conventional Commits | type(scope): subject 형식의 커밋 메시지 표준 | 본 킷의 commit-msg/PR 제목 검증 기반 | §6, AR-002, ADR-004 |
| Stale Branch | 일정 기간 활동이 없는 브랜치 | 30일 기준, `stale-branches.yml`이 알림 | AR-003, §17 |
| CRLF | Windows 줄바꿈(`\r\n`) | `.gitattributes`의 `eol=lf`로 강제 차단 | §8.1, §17 |

#### D.2 도구 용어

| 용어 | 정의 | 이 킷에서의 의미 | 관련 § |
|------|------|----------------|--------|
| lefthook | Go 기반 Git 훅 매니저 | Tier 3 클라이언트 훅 실행기 | §6.3, ADR-001 |
| `gh` CLI | GitHub 공식 명령행 도구 | PR 생성/조회 자동화의 기반 | FR-003, ADR-005 |
| fzf | 터미널 fuzzy finder | `branch-move.sh`의 선택 UI (선택적) | FR-007 |
| shellcheck | 셸 스크립트 정적 분석기 | Kit-self CI의 핵심 검사 | §18.3, §19.3 |
| `bash -n` | bash 문법 체크 모드 | 스크립트 변경 후 필수 검사 | §18.3 |

#### D.3 이 킷 고유 용어

| 용어 | 정의 | 이 킷에서의 의미 | 관련 § |
|------|------|----------------|--------|
| 3계층 방어선 | 서버(branch protection) → CI(Actions) → 클라이언트(lefthook)의 3단 검증 구조 | 본 킷의 핵심 아키텍처 | §4, §6.1, §21.5 |
| 9곳 동기화 불변식 | type 목록·정규식이 9개 파일에 중복 정의되어 동기화가 강제됨 | 가장 중요한 일관성 규칙 | §9, §18.6, §19.3 |
| Self-Dogfooding | 킷 저장소 자체가 자기 킷의 규칙을 따름 | 1인 프로젝트의 검증 전략 | §18.4 |
| Idempotent Bootstrap | `bootstrap.sh`를 여러 번 실행해도 동일 결과 | 사용자 안전성 보장 | FR-001 |
| User-facing CI | 킷이 도입된 사용자 프로젝트를 검증하는 워크플로우 | 현재 3개 (branch-name/pr-title/stale) | §19.1, §19.2 |
| Kit-self CI | 이 킷 레포 자체의 품질을 검증하는 워크플로우 | 0개 (계획) | §19.1, §19.3 |
| type 8종 | feat/fix/refactor/docs/research/data/chore/remove | 브랜치·커밋·PR 모두 동일 8종 사용 | §9, ADR-004 |
