# Git 브랜치 전략 (팀 협업 버전)

> **한 줄 요약**: `main` 단일 trunk + 작업마다 단명 브랜치 생성 → squash merge → 즉시 삭제.
> GitHub Flow 기반, 소·중규모 팀에 최적화.

---

## 1. 기본 원칙

1. **`main`이 유일한 영구 브랜치**다. `develop`, `preview`, `staging` 같은 long-lived 브랜치는 만들지 않는다.
2. **모든 작업은 단명(短命) 브랜치에서 시작**한다. 브랜치 수명은 **최대 1~2일**.
3. **머지가 끝나면 브랜치는 즉시 삭제**한다 (로컬 + 원격 모두). 자동화로 강제한다.
4. **`main`은 항상 배포 가능한 상태**를 유지한다. 깨진 코드 머지 금지.
5. **모든 변경은 PR을 거친다**. 셀프 리뷰라도 PR 단계가 1회 필요하다.
6. **브랜치 네이밍(7개 중 택1)과 커밋 메시지**는 본인이 직접 결정

---

## 2. 브랜치 네이밍

| 접두어 | 용도 | 예시 |
|---|---|---|
| `feat/` | 신규 기능 | `feat/order-router` |
| `fix/` | 버그 수정 / hotfix | `fix/websocket-reconnect` |
| `refactor/` | 동작 변경 없는 리팩터 | `refactor/risk-manager-cc` |
| `docs/` | 문서만 변경 | `docs/branch-strategy` |
| `research/` | 탐색·실험·리서치 작업 | `research/ofi-decay` |
| `data/` | 데이터 관련 작업 (DB 스키마, 마이그레이션, 데이터 파이프라인, fixture, 데이터셋 추가/수정) | `data/orderbook-schema-v3` |
| `chore/` | 빌드/CI/설정 변경 | `chore/update-deps` |

규칙:
- **소문자 + 하이픈** (`feat/my-feature`, NOT `feat/MyFeature`)
- **한국어 금지** (URL/CLI 호환성)
- **짧고 구체적으로** (3~5단어 이내 권장)

→ 위 규칙은 `branch-name-check.yml` workflow와 `lefthook.yml`이 자동으로 강제한다. 위반 시 push/PR 단계에서 차단된다.

---

## 3. 표준 워크플로우

### 헬퍼 스크립트 사용 시 (권장)

```bash
# 1. 새 작업 시작
./scripts/new-branch.sh feat order-router

# 2. 코드 작성 + 커밋
git add .
git commit -m "feat: add order router"

# 3. PR 생성
./scripts/finish-branch.sh

# 4. GitHub UI에서 리뷰 받고 Squash & Merge 클릭
#    → 원격 브랜치 자동 삭제

# 5. 로컬 정리
./scripts/cleanup-merged.sh
```

### 일반 git 명령 사용 시

```bash
git checkout main && git pull
git checkout -b feat/order-router

# ... 작업 ...
git add .
git commit -m "feat: add order router"
git push -u origin feat/order-router

gh pr create --fill
# 또는 GitHub 웹 UI에서 PR 생성

# 리뷰 후 Squash & Merge

git checkout main && git pull
git branch -d feat/order-router
```

---

## 4. 머지 정책

- **squash merge만 허용**한다. GitHub Settings에서 다른 머지 방식을 비활성화한다.
  - 작업 브랜치의 중간 커밋 이력을 main에 남기지 않는다 → main 이력이 "기능 단위 1커밋"으로 깔끔.
- **PR 제목이 squash 후 main 커밋 메시지가 된다**. Conventional Commits 형식 강제 (`pr-title-check.yml`).
- **`--no-ff` merge commit 금지**. branch protection의 "Require linear history"로 강제.
- **rebase는 자기 브랜치 한정**. main에 push된 커밋은 rebase 금지.

---

## 5. 예외 — main 직접 커밋

팀 협업 환경에서는 **원칙적으로 모든 변경이 PR을 거친다**. branch protection이 main 직접 push를 차단한다.

다만 1인 개인 프로젝트에서는 다음 사소한 변경에 한해 예외를 둘 수 있다:
- 오타 수정
- 단일 docs 줄 변경
- lint/format 자동 수정

**팀 환경에서는 예외 없음**. 의심스러우면 PR로.

---

## 6. 브랜치 삭제 (자동화)

머지 직후 **로컬 + 원격 둘 다** 삭제한다.

- **원격 삭제**: GitHub Settings → "Automatically delete head branches" 활성화로 자동 처리. 또는 `gh pr merge --squash --delete-branch`.
- **로컬 삭제**: 머지 후 `./scripts/cleanup-merged.sh` 또는 `git branch -d <name>`.
- **stale 브랜치 자동 정리**: `stale-branches.yml` workflow가 30일 이상 비활성 브랜치를 주 1회 검사하여 정리.

stale 브랜치는 안티패턴 — 작업 종료 시점에 반드시 정리.

---

## 7. 브랜치 수명이 길어질 것 같으면

브랜치 수명은 **최대 1~2일**이 원칙이다. 더 길어질 것 같으면:

1. **더 작은 단위로 쪼갠다** — 큰 기능을 여러 PR로 분할
2. **feature flag로 main에 미리 머지** — 미완성 기능을 환경 변수/설정으로 비활성화
3. **별도 모듈로 격리** — 기존 코드와 독립적으로 개발 후 한 번에 통합

long-lived feature branch는 main과 충돌 위험이 기하급수적으로 증가하는 안티패턴. PR Size 라벨이 XL이 되면 분할을 검토한다.

---

## 8. 릴리스 = 태그 (브랜치 아님)

- 릴리스 브랜치는 만들지 않는다. **Git tag**로 표시한다.
- 태그 형식 예시 (프로젝트별 자유):
  - `v1.2.3` — SemVer
  - `staging-v20260407` — 스테이징 배포 시점
  - `prod-v20260407-001` — 프로덕션 배포 시점
- 태그 부여 시점에 GitHub Release 작성 권장 (변경 요약 + 롤백 포인트).

---

## 9. 언제 이 전략을 업그레이드하나

다음 조건이 되면 더 복잡한 전략(GitLab Flow / Release Flow) 검토:

- **다중 환경 동시 운영** (staging + production 분리 필수) → 환경 브랜치 도입
- **다중 버전 병행 지원** (구버전 hotfix 필요) → release 브랜치 도입
- **규제/감사 요구사항** (SOX, MiFID 등) → 릴리스 브랜치 + 변경 이력 보존

위 조건이 없는 한, **이 전략으로 충분**하다. 소·중규모 팀에 Git Flow 같은 5종 브랜치는 순수 오버헤드.

---

## 10. 체크리스트 (작업 시작 전)

- [ ] `main`에서 최신 상태로 분기했는가?
- [ ] 브랜치 이름이 네이밍 규칙(`feat/`, `fix/`, ...)을 따르는가?
- [ ] 1~2일 안에 끝낼 수 있는 작은 단위인가?
- [ ] 머지 후 로컬 + 원격 브랜치를 삭제했는가?
- [ ] PR 제목이 Conventional Commits 형식인가?
