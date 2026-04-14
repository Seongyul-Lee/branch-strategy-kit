# Changelog

본 킷의 모든 주요 변경사항은 이 파일에 기록된다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)을 따르며,
버전 규칙은 [Semantic Versioning 2.0.0](https://semver.org/lang/ko/)을 준수한다.

변경 분류 범례:
- **Added** — 신규 기능/스크립트/문서 추가
- **Changed** — 기존 기능의 동작 변경 (후방 호환)
- **Deprecated** — 곧 제거될 기능
- **Removed** — 제거된 기능
- **Fixed** — 버그 수정
- **Security** — 보안 관련 수정

## [Unreleased]

## [1.1.0] - 2026-04-14

### Added
- `PRD.md` — 킷 Product Requirements Document 추가 (#30)
- `VERSION` 파일 및 `CHANGELOG.md` 신설 (#32)
- Two-branch(develop/main) 운영 모드 지원 — `.kit-config`에서 `DEFAULT_BRANCH` 전환 (#35)
- `scripts/sync-main.sh` — develop→main PR 생성 (`git sync-main`) (#35)
- `scripts/_config.sh` — 킷 설정 로더 헬퍼 (#35)
- `2b-MEMBER_SETUP_TWO.md`, `3b-DAILY_WORKFLOW_TWO.md` — Two-branch 팀원/데일리 가이드 (#35)
- `branch-name-check.yml` develop→main PR 예외 처리 (#35)
- `install.sh` — 킷 파일 일괄 복사 스크립트 (`--dry-run` 지원) (#36)
- Kit-self CI: ShellCheck + bash syntax check (#38)
- Kit-self CI: YAML lint, markdown lint, link check (#39)
- `scripts/verify-invariant.sh` + `kit-ci-invariant.yml` — 12곳 type 목록 일관성 자동 검증 (#40)
- `PRD-v1.1.md` — v1.1.0 Product Requirements Document, ADR-010 포함 (#41, #43)

### Changed
- `README.md` 개선 (#24)
- `finish-branch.sh` 출력 메시지 문구 수정 (#25, #26)
- `branch-move.sh` 리팩터링 (20+ / 43- 라인, 동작 동일) (#27)
- OS별 `gh` 설치 가이드 및 실행 환경 명시 등 문서 개선 (#28)
- 전 스크립트 출력 메시지를 `git nb` / `git fb` alias 스타일로 통일
  (`bootstrap.sh`, `check-branch.sh`, `finish-branch.sh`, `new-branch.sh`) (#29)
- `1-ADMIN_SETUP.md` §3 관리자 커맨드 안내 개선 (#33)
- `PRD.md`의 `chmod` 명령어를 §3 개선 내용과 동기화 (#34)
- 기존 스크립트(new-branch, finish-branch, cleanup-merged, check-branch)가
  `$DEFAULT_BRANCH` 변수 사용 (#35)
- `bootstrap.sh`에 `sync-main` alias 추가 (#35)
- `1-ADMIN_SETUP.md` Step 2-1에 파일 복사 통합, Step 3 재구성 (#36)
- 문서 분리: `2-MEMBER_SETUP` → `2a`(Single) + `2b`(Two),
  `3-DAILY_WORKFLOW` → `3a`(Single) + `3b`(Two) (#35)
- `PRD.md` → `PRD-v1.0.md` rename (#41)
- `cleanup-merged.sh` signal 3 재설계 — 기존 `gh pr list --state merged` 벌크 조회를
  `--head <branch>` per-branch 역방향 조회 + `headRefOid` SHA 정확 일치 검증으로 전환.
  브랜치명 재사용(1차 머지 후 같은 이름 재생성) 오탐 차단, `PR_MERGED_CACHE` associative
  array로 API 호출 캐싱. 14개 시나리오 트레이싱 검증 완료 (#42, ADR-010)

### Fixed
- `git nb` 인터랙티브 type 선택 메뉴가 특정 방향키 입력 시 silent exit되던 버그.
  `new-branch.sh`의 `((selected=...))` 산술 명령이 결과 0일 때 exit 1을 반환,
  `set -euo pipefail` 하에서 스크립트가 조용히 종료되던 문제.
  `selected=$(( ... ))` 산술 확장으로 변경하여 해결 (#31)

## [1.0.0] - 2026-04-08

### Added
- 초기 릴리스: 브랜치 전략 킷 (스크립트 + lefthook + GitHub Actions + 문서 + PR 템플릿)
- 브랜치 네이밍 규칙: `^(feat|fix|refactor|docs|research|data|chore|remove)/[a-z0-9][a-z0-9-]*$`
- 스크립트: `bootstrap.sh`, `new-branch.sh`, `finish-branch.sh`, `cleanup-merged.sh`,
  `branch-move.sh`, `check-branch.sh`, `check-commit-msg.sh`
- GitHub Actions: `branch-name-check.yml`, `pr-title-check.yml`, `stale-branches.yml`
- lefthook 훅(pre-push, commit-msg) 구성
- Git alias 4종(`nb`, `fb`, `cleanup`, `bm`) 자동 등록
- 가이드 문서: `README.md`, `1-ADMIN_SETUP.md`, `2-MEMBER_SETUP.md`,
  `3-DAILY_WORKFLOW.md`, `TROUBLESHOOTING.md`

[Unreleased]: https://github.com/Seongyul-Lee/branch-strategy-kit/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Seongyul-Lee/branch-strategy-kit/releases/tag/v1.1.0
[1.0.0]: https://github.com/Seongyul-Lee/branch-strategy-kit/releases/tag/v1.0.0
