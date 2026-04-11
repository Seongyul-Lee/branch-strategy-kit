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

### Added
- `PRD.md` — 킷 Product Requirements Document 추가 (#30)
- `VERSION` 파일 및 `CHANGELOG.md` 신설 (본 커밋)

### Changed
- `README.md` 개선 (#24)
- `finish-branch.sh` 출력 메시지 문구 수정 (#25, #26)
- `branch-move.sh` 리팩터링 (20+ / 43- 라인, 동작 동일) (#27)
- OS별 `gh` 설치 가이드 및 실행 환경 명시 등 문서 개선 (#28)
- 전 스크립트 출력 메시지를 `git nb` / `git fb` alias 스타일로 통일
  (`bootstrap.sh`, `check-branch.sh`, `finish-branch.sh`, `new-branch.sh`) (#29)

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

[Unreleased]: https://github.com/Seongyul-Lee/branch-strategy-kit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Seongyul-Lee/branch-strategy-kit/releases/tag/v1.0.0
