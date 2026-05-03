# Branch Strategy Kit — 릴리스 노트

---

## v1.0.0 — 첫 번째 릴리스 (2026-04-08)

> 한 줄 요약: **브랜치 전략 킷의 초기 릴리스입니다.** 스크립트·훅·CI·문서를 한 번에 팀 레포에 이식할 수 있는 기반이 갖춰졌습니다.

### 새로 생긴 것

- **브랜치 네이밍 규칙** — `feat|fix|refactor|docs|research|data|chore|remove` 타입을 강제하는 정규식으로 네이밍 일관성을 확보합니다.
- **스크립트 7종** — `bootstrap.sh`(초기 설치), `new-branch.sh`(`git nb`), `finish-branch.sh`(`git fb`), `cleanup-merged.sh`(`git cleanup`), `branch-move.sh`(`git bm`), `check-branch.sh`, `check-commit-msg.sh`.
- **Git alias 4종 자동 등록** — `bootstrap.sh` 한 번으로 `nb` / `fb` / `cleanup` / `bm`이 로컬에 등록됩니다.
- **GitHub Actions 3종** — `branch-name-check.yml`(PR 브랜치명 검사), `pr-title-check.yml`(PR 제목 검사), `stale-branches.yml`(장기 방치 브랜치 알림).
- **lefthook 훅** — pre-push(브랜치명), commit-msg(커밋 메시지) 검사를 로컬에서 실행합니다.
- **가이드 문서 5종** — `README.md`, `1-ADMIN_SETUP.md`, `2-MEMBER_SETUP.md`, `3-DAILY_WORKFLOW.md`, `TROUBLESHOOTING.md`.

---

## v1.1.0 — Two-branch 전략 정식 지원 (2026-04-14)

> 한 줄 요약: **`feature → develop → main` 두 단계 머지 워크플로우를 정식으로 지원합니다.** 기존 single-branch 사용자는 그대로, 더 엄격한 운영이 필요한 팀은 설정 한 줄로 전환할 수 있습니다.

### 새로 생긴 것

- **Two-branch 모드** — `.kit-config`의 `DEFAULT_BRANCH=develop`만 바꾸면 모든 스크립트가 자동으로 따라갑니다.
- **`git sync-main`** — develop에 쌓인 변경을 묶어 main으로 올리는 PR을 한 번에 생성합니다.
- **`install.sh`** — 킷 파일을 프로젝트에 일괄 복사. `--dry-run`으로 미리 볼 수 있습니다.
- **별도 가이드 문서** — Single 팀은 `2a` / `3a`, Two-branch 팀은 `2b` / `3b`만 보면 됩니다.

### 더 똑똑해진 것

- **`git cleanup` 정확도 개선** — 같은 이름의 브랜치를 지우고 다시 만들었을 때 머지 이력을 오탐하던 문제를 SHA 기반 검증으로 차단했습니다. (이제 안심하고 브랜치명을 재사용해도 됩니다.)
- **메시지 톤 통일** — 모든 스크립트 출력이 `git nb`, `git fb` 스타일로 일관되게 정리됐습니다.

### 버그 수정

- **`git nb` 메뉴가 갑자기 사라지던 문제** — 화살표로 type을 고를 때 가끔 스크립트가 조용히 종료되던 버그를 잡았습니다.

### 내부 정비 *(사용자에게는 보이지 않음)*

- ShellCheck / YAML / Markdown / 링크 검사 CI 추가, type 목록 자동 검증, PRD-v1.1.0 / VERSION / CHANGELOG 신설.

---

## v1.1.1 — 막혀 있던 흐름들 수습 (2026-04-29)

> 한 줄 요약: **"왜 안 되지?" 싶었던 자잘한 막힘을 한 번에 정리한 패치입니다.** 신규 기능 없음, 동작 신뢰도만 끌어올렸습니다.

### 사용 흐름이 바뀐 것

- **`git fb` — 커밋 안 한 파일이 있어도 더 이상 막히지 않습니다.**
  이전에는 워킹트리에 변경이 남아 있으면 무조건 차단됐습니다. 이제는 무엇이 커밋됐고 무엇이 안 됐는지 보여준 뒤 `[y/N]`로 묻고, 깨끗하면 프롬프트 없이 그대로 push합니다.

### 버그 수정

- **`install.sh` 인터랙티브 프롬프트가 먹통이던 문제** — 내부에서 쓰는 `find` 출력이 사용자 입력 자리를 가로채던 버그를 잡았습니다.
- **`git sync-main` 안정화** — 잘못된 `DEFAULT_BRANCH` 값 차단, origin 신선도 추적, fetch 실패 시 침묵 대신 명시적 에러.
- **`git cleanup` 안전성** — 하이픈으로 시작하거나 특수문자가 든 브랜치명에서 오동작하던 비교 로직을 안전하게 교체했습니다.
- **`verify-invariant.sh`** — README 검사가 한 번 실패하면 검증 전체가 즉사하던 문제 수정.

---

## v1.1.1 이후 — Unreleased

> 한 줄 요약: **다운스트림 프로젝트에 `install.sh`가 깔리면서 드러난 두 가지를 정리합니다.** 정식 릴리스 전 상태입니다.

### 변경

- **`install.sh` 실행 권한 부여** — 클린 체크아웃 직후 가이드대로 `~/branch-strategy-kit/install.sh`를 실행하면 `Permission denied`가 나던 문제 해결. (#49)
- **README 일관성 검증을 필수 → 권장으로 완화** — `install.sh`가 README를 복사하지 않는데도 Tier A 필수 검증에 들어 있어, 다운스트림에서는 항상 실패하던 모순을 바로잡았습니다. Tier B(권장)로 옮겨 본 레포는 그대로 통과, 다운스트림은 SKIP/WARN으로 흡수됩니다. (#48)

---

### 업그레이드 안내

- **v1.1.0 → v1.1.1**: 별도 마이그레이션 없음. 기존 동작 그대로 + `git fb`가 덜 막히게 동작합니다.
- **v1.0.x → v1.1.0**: Single-branch 팀은 변경 없이 동작합니다. Two-branch로 전환하려면 `.kit-config`의 `DEFAULT_BRANCH`만 바꾸세요.
