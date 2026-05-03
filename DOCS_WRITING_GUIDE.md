# 문서 작성 규칙 및 컨벤션

이 프로젝트에서 문서를 쓸 때 따르는 규칙입니다.

---

## 문서 지도

| 파일 | 대상 독자 | 역할 |
|---|---|---|
| `README.md` | 처음 온 사람 | 킷 소개, 시작하기, 전체 구조 |
| `1-ADMIN_SETUP.md` | 관리자 | 팀 repo에 킷 도입하는 절차 |
| `2a-MEMBER_SETUP_SINGLE.md` | Single-trunk 팀원 | 1회 셋업 |
| `2b-MEMBER_SETUP_TWO.md` | Two-branch 팀원 | 1회 셋업 |
| `3a-DAILY_WORKFLOW_SINGLE.md` | Single-trunk 팀원 | 매일 쓰는 명령 레퍼런스 |
| `3b-DAILY_WORKFLOW_TWO.md` | Two-branch 팀원 | 매일 쓰는 명령 레퍼런스 |
| `TROUBLESHOOTING.md` | 에러를 만난 사람 | 증상 → 원인 → 해결 |
| `CHANGELOG.md` | 기여자·유지보수자 | PR·커밋 단위 기술 변경 이력 |
| `RELEASE_NOTES.md` | 사용자 | 버전별 사용자용 요약 |
| `PRD-v*.md` | 설계자 | 기능 설계 의사결정 기록 |

---

## 어디에 무엇을 써야 하나

**새 기능을 추가했다면:**
1. `CHANGELOG.md` — 어떤 파일이 왜 바뀌었는지 (기술 상세)
2. `docs/release-notes/RELEASE_NOTES.md` — 사용자에게 어떤 영향이 있는지 (요약)
3. 관련 가이드 문서 (`1-ADMIN_SETUP.md` / `2-...` / `3-...`) — 사용법이 바뀌었다면 반드시 반영

**버그를 고쳤다면:**
- `CHANGELOG.md`의 `[Unreleased]` 섹션에 Fixed 항목 추가
- 사용자에게 보이는 동작이 바뀌었다면 `RELEASE_NOTES.md`에도 추가

**버전 업데이트 이후:**
- `TROUBLESHOOTING.md`를 검토해 현재 버전에서 더 이상 발생하지 않는 이슈 항목을 제거합니다.

**CHANGELOG vs RELEASE_NOTES:**
- `CHANGELOG.md` — PR 번호, 파일명, 함수명, 기술적 세부 사항 포함
- `RELEASE_NOTES.md` — "어떻게 쓰면 되는지"만 담은 사용자 언어로 작성

**PR 번호·커밋 기록의 기준 레포:**
- 문서에 표기하는 PR 번호와 커밋 SHA는 모두 [`Seongyul-Lee/branch-strategy-kit`](https://github.com/Seongyul-Lee/branch-strategy-kit)를 기준으로 합니다.
- 다운스트림 레포에 킷을 이식한 경우, 해당 레포의 PR 번호와 혼용하지 않습니다.

**PRD(`PRD-v*.md`) 작성 시점:**
- **minor 이상 릴리스**(v1.1.0, v1.2.0 …)에서 신기능이 포함되거나 ADR(설계 의사결정)이 발생한 경우에만 작성합니다.
- patch 릴리스(v1.1.1, v1.1.2 …)는 버그 수정·안정화만 담으므로 PRD를 작성하지 않습니다.
- 파일명은 `PRD-v{major}.{minor}.{patch}.md` 형식입니다 (`PRD-v1.1.0.md`).

---

## 작성 규칙

### 언어
- **한국어**로 작성합니다.
- 명령어·파일명·코드는 인라인 코드(`` ` `` )로 표기합니다.

### 제목 계층
- `#` 은 파일당 하나 (문서 제목)
- `##` 부터 본문 섹션
- `####` 이하는 쓰지 않습니다 — 그 정도로 깊다면 문서를 나누는 것을 먼저 고려합니다

### 문장
- 짧게 씁니다. 한 문장에 하나의 사실만 담습니다.
- "~합니다" 체를 기본으로 합니다.
- 설명보다 예시를 먼저 씁니다.

### 표
- 3개 이상 항목을 나열할 때 표를 사용합니다.
- 표 안에 긴 설명을 넣지 않습니다. 한 줄로 요약이 안 되면 본문에서 따로 설명합니다.

### 코드 블록
- 실행 가능한 명령은 반드시 코드 블록으로 표기합니다.
- 언어 힌트를 붙입니다 (` ```bash `, ` ```yaml ` 등).

---

## 파일 이름 규칙

- **루트 레벨 문서**: 대문자 + 언더스코어 없이 (`README.md`, `CHANGELOG.md`, `DOCS_WRITING_GUIDE.md`)
- **가이드 문서**: 숫자 접두사 + 역할 (`1-ADMIN_SETUP.md`, `2a-MEMBER_SETUP_SINGLE.md`)
- **설계 문서**: 버전 포함 (`PRD-v1.0.0.md`, `PRD-v1.1.0.md`)

---

## 새 문서를 만들기 전에

이미 있는 문서에 섹션을 추가하는 것이 새 파일을 만드는 것보다 낫습니다.
새 파일을 만든다면 이 문서의 **문서 지도** 표에 함께 추가합니다.
