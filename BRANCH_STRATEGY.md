# Git 브랜치 전략 (팀 협업 버전)

> **한 줄 요약**: `main` 단일 trunk + 작업마다 단명 브랜치 생성 → squash merge → 즉시 삭제.

---

## 1. 기본 규칙

- **`main`이 유일한 영구 브랜치**. `develop`, `staging` 같은 long-lived 브랜치를 만들지 않습니다.
- **모든 작업은 단명 브랜치에서 시작**. 브랜치 수명 **최대 1~2일**.
- **머지 직후 브랜치 즉시 삭제** (로컬 + 원격).
- **`main`은 항상 배포 가능 상태**.
- **모든 변경은 PR을 거칩니다**. 셀프 리뷰라도 PR 1회 필수.

---

## 2. 브랜치 네이밍

| 접두어 | 용도 | 예시 |
|---|---|---|
| `feat/` | 신규 기능 | `feat/order-router` |
| `fix/` | 버그 수정 / hotfix | `fix/websocket-reconnect` |
| `refactor/` | 동작 변경 없는 리팩터 | `refactor/risk-manager-cc` |
| `docs/` | 문서만 변경 | `docs/branch-strategy` |
| `research/` | 탐색·실험·리서치 | `research/ofi-decay` |
| `data/` | DB 스키마, 마이그레이션, fixture, 데이터셋 | `data/orderbook-schema-v3` |
| `chore/` | 빌드/CI/설정 변경 | `chore/update-deps` |

규칙:
- **소문자 + 하이픈** (`feat/my-feature`, ❌ `feat/MyFeature`)
- **한국어 금지** (URL/CLI 호환성)
- **3~5단어 이내 권장**

위 규칙은 `branch-name-check.yml` workflow와 `lefthook.yml`이 자동 강제합니다. 위반 시 push/PR 단계에서 차단됩니다.

---

## 3. 표준 워크플로우

### 헬퍼 스크립트 사용 (권장)

`bootstrap.sh` 실행 후에는 짧은 **Git alias** (`git nb` / `git fb` / `git cleanup`)로 호출할 수 있습니다.

```bash
# 1. 새 작업 시작
git nb feat order-router
# 또는 `git nb` 만 실행 → 메뉴에서 type 선택 + 이름 입력

# 2. 코드 작성 + 커밋
git add .
git commit -m "feat: add order router"

# 3. PR 생성
git fb

# 4. GitHub UI에서 Squash & Merge 클릭 → 원격 브랜치 자동 삭제

# 5. 로컬 정리
git cleanup
```

alias가 등록되지 않은 환경에서는 동일한 순서로 `./scripts/new-branch.sh`, `./scripts/finish-branch.sh`, `./scripts/cleanup-merged.sh`를 호출하면 됩니다. 자세한 대응: [SCRIPTS_USAGE.md § 짧은 명령어 (Git aliases)](./SCRIPTS_USAGE.md#짧은-명령어-git-aliases)

### 헬퍼 스크립트 없이

```bash
git checkout main && git pull
git checkout -b feat/order-router

# ... 작업 ...
git add .
git commit -m "feat: add order router"
git push -u origin feat/order-router

gh pr create --fill
# 리뷰 후 Squash & Merge

git checkout main && git pull
git branch -d feat/order-router
```

---

## 4. 머지 규칙

- **squash merge만 허용**. merge commit, rebase merge 금지.
- **PR 제목이 squash 후 main 커밋 메시지**가 됩니다. Conventional Commits 형식 강제 (`pr-title-check.yml`).
- **linear history 강제**. branch protection에서 `Require linear history` ON.
- **rebase는 자기 브랜치 한정**. main에 push된 커밋은 rebase 금지.

---

## 5. main 직접 커밋 (예외)

팀 환경에서는 **예외 없음**. branch protection이 직접 push를 차단합니다.

1인 개인 프로젝트에서는 다음에 한해 허용:
- 오타 수정
- 단일 docs 줄 변경
- lint/format 자동 수정

---

## 6. 브랜치 삭제

머지 직후 **로컬 + 원격 모두** 삭제합니다.

- **원격**: GitHub Settings → "Automatically delete head branches" ON → 자동 처리
- **로컬**: `./scripts/cleanup-merged.sh` (3가지 신호로 감지 — SCRIPTS_USAGE.md §3)
- **stale 브랜치 자동 정리**: `stale-branches.yml` workflow가 30일 이상 비활성 브랜치를 주 1회 정리

---

## 7. 브랜치 수명이 길어질 것 같으면

**더 작은 단위로 쪼갭니다**:
1. 큰 기능을 여러 PR로 분할
2. feature flag로 미완성 기능을 main에 미리 머지
3. 별도 모듈로 격리 후 한 번에 통합

PR Size 라벨이 `XL`이 되면 분할 검토.

---

## 8. 릴리스 = Git tag

릴리스 브랜치를 만들지 않습니다. **Git tag**로 표시합니다.

```bash
git tag v1.2.3                 # SemVer
git tag staging-v20260407      # 스테이징 배포 시점
git tag prod-v20260407-001     # 프로덕션 배포 시점
git push origin <tag>
```

태그 부여 시 GitHub Release 작성 권장 (변경 요약 + 롤백 포인트).

---

## 9. 작업 시작 전 체크리스트

- [ ] `main`에서 최신 상태로 분기했는가?
- [ ] 브랜치 이름이 네이밍 규칙(`feat/`, `fix/`, ...)을 따르는가?
- [ ] 1~2일 안에 끝낼 수 있는 작은 단위인가?
- [ ] PR 제목을 Conventional Commits 형식으로 작성할 것인가?
- [ ] 머지 후 `cleanup-merged.sh`를 실행할 것인가?
