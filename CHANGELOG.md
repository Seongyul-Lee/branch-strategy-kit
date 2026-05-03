# Changelog

> **기술적 변경 로그입니다.** PR·커밋 단위의 세부 변경을 추적합니다. 버전별 사용자용 요약은 [`RELEASE_NOTES.md`](RELEASE_NOTES.md)를 보세요.

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

### Fixed
- `install.sh` — 클린 체크아웃 직후 실행 시 `Permission denied` 발생. 파일에 실행 권한(+x) 부여 (#49)
- `verify-invariant.sh` — README 일관성 검사를 Tier A(필수)에서 Tier B(권장)로 이동.
  `install.sh`가 README를 복사하지 않아 다운스트림에서 항상 실패하던 모순 해결 (#48)

## [1.1.1] - 2026-04-29

### Changed
- `finish-branch.sh` (`git fb`) — 미커밋 변경 처리를 hard block에서 `[커밋된 변경사항]` /
  `[커밋되지 않은 변경사항]` 표시 + `[y/N]` 프롬프트로 변경. 워킹트리가 깨끗하면 프롬프트
  없이 그대로 push. `/dev/tty` 접근 가능 여부와 stdout/stderr TTY 출력 가드, `--no-pr`
  모드별 프롬프트 문구 분기 포함 (#46)

### Fixed
- `install.sh` — `find` 출력이 stdin을 가로채 인터랙티브 프롬프트가 동작하지 않던 버그.
  read 입력을 `/dev/tty` 에서 직접 받도록 변경 (#45)
- `sync-main.sh` — `DEFAULT_BRANCH` 검증을 `develop` 화이트리스트로 강화. checkout 전
  로컬·origin 가드와 `git pull --ff-only` 실패 처리, `MAIN_REF` 동적 결정(origin/main
  freshness 추적), `git fetch` 실패 시 묵살 대신 명시적 에러 + exit 1 (#46)
- `cleanup-merged.sh` — `set -euo pipefail` 직후 Bash 4+ 가드 명시화, `DEFAULT_BRANCH`
  checkout 가드 추가, `grep -qx` 비교 5곳을 `grep -Fxq --` 로 안전화하여 메타문자/하이픈
  시작 브랜치명 오동작 차단, fetch 실패 명시 처리 (#46)
- `verify-invariant.sh` — `extract_readme_types()` 파이프라인을 브레이스 그룹 + `|| true`
  로 감싸 README grep 실패 시 `set -e`/pipefail 즉사로 검증이 중단되던 문제 해결 (#46)

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
- `PRD-v1.1.0.md` — v1.1.0 Product Requirements Document, ADR-010 포함 (#41, #43)

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
- `PRD.md` → `PRD-v1.0.0.md` rename (#41)
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
- 초기 구성: 브랜치 전략 킷 스캐폴딩 — 스크립트·lefthook·GitHub Actions·문서·PR 템플릿 (#0)
- `bootstrap.sh` — 의존성·lefthook·git alias 일괄 등록 원스텝 설치 스크립트 (#1)
- `new-branch.sh` 인터랙티브 모드 — 화살표 키로 브랜치 type 선택 (#6)
- `cleanup-merged.sh` — GitHub PR 상태 확인으로 머지 감지 정확도 향상 (#8)
- `bootstrap.sh` — git alias 4종(`nb`, `fb`, `cleanup`, `bm`) 자동 등록 (#10)
- `bootstrap.sh` — GitHub auth 상태 advisory 체크 추가 (#17)
- `remove` 브랜치 type 추가 및 한글 커밋 메시지 공식 지원 (#18)
- `cleanup-merged.sh` — 감지 이유 인라인 표시 + `--exclude` 옵션 추가 (#19)
- PR 거절 워크플로우 및 reviewer-closes-PR 규칙 문서화 (#20)
- `LICENSE` (MIT) 추가 (#21)
- `finish-branch.sh` — `--no-pr` 플래그 추가 (push만 하고 PR 생성 건너뜀) (#22)

### Changed
- 가이드 문서 구조 재편 — 설치·설계 중심에서 사용자 워크플로우 중심으로 재구성 (#9, #13, #14)
- 독립형 레포 관리자용 Require approvals 0 설정 경고 문서 추가 (#4)

### Fixed
- `finish-branch.sh` — 멀티 커밋 PR 제목 생성에 `--fill-first` 적용 (#3)
- `pr-title-check.yml` — `synchronize` 이벤트 트리거 누락 추가 (#5)
- `scripts/*.sh` — git index에 실행 권한(+x) 설정 (#11)
- `.gitattributes` — CRLF/LF 정규화 갭 수정 및 `bootstrap.sh` 동기화 (#12)
- 어드민 셋업 가이드 — §2-3, §3-2에 로컬 브랜치 정리 단계 추가 (#15)
- 멤버 셋업 가이드 Step 1 — clone + update 양쪽 경로 모두 커버 (#16)

### Removed
- `test.txt` — 워크플로우 스모크 테스트용 임시 파일 삭제 (#23)

[Unreleased]: https://github.com/Seongyul-Lee/branch-strategy-kit/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/Seongyul-Lee/branch-strategy-kit/releases/tag/v1.1.1
[1.1.0]: https://github.com/Seongyul-Lee/branch-strategy-kit/releases/tag/v1.1.0
[1.0.0]: https://github.com/Seongyul-Lee/branch-strategy-kit/releases/tag/v1.0.0
