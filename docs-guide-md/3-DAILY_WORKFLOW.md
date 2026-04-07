# 일상 워크플로우

세팅이 완료된 후, 매일 사용하는 명령어와 규칙을 정리한 레퍼런스입니다.

---

## 한눈에 보는 흐름

```
git nb  →  코딩  →  commit  →  git fb  →  GitHub에서 Squash Merge  →  git cleanup
```

---

## 1. 새 브랜치 만들기 — `git nb`

main을 최신화한 뒤 규칙에 맞는 새 브랜치를 만들고 체크아웃합니다.

```bash
# 인터랙티브 — type 메뉴 선택 + 이름 입력
git nb

# type만 지정 — 이름은 프롬프트로 입력
git nb feat

# 인자 모드 — 한 줄로 완성
git nb feat order-router
```

**인터랙티브 모드 예시:**

```
$ git nb
브랜치 type을 선택하세요 (↑↓ 이동, Enter 확정):
  ▶ feat
    fix
    refactor
    docs
    research
    data
    chore
브랜치 이름을 입력하세요: order router
✅ 새 브랜치 생성: feat/order-router
```

이름 자동 변환: 대문자 → 소문자, 공백/언더스코어 → 하이픈.

```bash
git nb fix "WebSocket Reconnect"    # → fix/websocket-reconnect
```

---

## 2. 브랜치 네이밍 규칙

| 접두어 | 용도 | 예시 |
|---|---|---|
| `feat/` | 신규 기능 | `feat/order-router` |
| `fix/` | 버그 수정 / hotfix | `fix/websocket-reconnect` |
| `refactor/` | 동작 변경 없는 리팩터 | `refactor/risk-manager-cc` |
| `docs/` | 문서만 변경 | `docs/branch-strategy` |
| `research/` | 탐색·실험·리서치 | `research/ofi-decay` |
| `data/` | DB 스키마, 마이그레이션, fixture | `data/orderbook-schema-v3` |
| `chore/` | 빌드/CI/설정 변경 | `chore/update-deps` |

**규칙:**
- 소문자 + 하이픈만 사용 (`feat/my-feature` ✅ / `feat/MyFeature` ❌)
- 한국어 금지 (URL/CLI 호환성)
- 3~5단어 이내 권장

> 이 규칙은 CI workflow(`branch-name-check.yml`)와 lefthook이 자동 강제합니다. 위반 시 push/PR 단계에서 차단됩니다.

---

## 3. 커밋 메시지 규칙

**Conventional Commits** 형식을 따릅니다:

```
<type>: <설명>
```

**예시:**

```bash
git commit -m "feat: add order router"
git commit -m "fix: resolve websocket reconnect issue"
git commit -m "docs: update branch strategy guide"
git commit -m "refactor: extract risk calculation module"
```

> lefthook의 `commit-msg` 훅이 형식을 자동 검증합니다. 위반 시 커밋이 차단됩니다.

---

## 4. PR 만들기 — `git fb`

커밋이 완료되면 원격에 push하고 PR을 생성합니다.

```bash
git add .
git commit -m "feat: add order router"
git fb
# → push + PR 생성 + PR URL 출력
```

**PR 제목 규칙:**
- Conventional Commits 형식 필수 (예: `feat: add order router`)
- PR 제목이 squash merge 후 main의 커밋 메시지가 됩니다
- `pr-title-check.yml`이 자동 검증합니다

> PR 본문이 잘못 채워졌다면: `gh pr edit <번호>`로 수정하거나 GitHub UI에서 직접 수정하세요.

---

## 5. 코드 리뷰 & 머지

1. GitHub PR 페이지에서 팀원에게 리뷰를 요청합니다.
2. 리뷰어가 Approve하면 **Squash and merge** 버튼을 클릭합니다.
3. 원격 브랜치는 `Automatically delete head branches` 설정에 의해 자동 삭제됩니다.

**머지 규칙:**
- **squash merge만 허용** (merge commit, rebase merge 금지)
- **linear history 강제** (Branch Protection 설정)
- rebase는 자기 브랜치 한정. main에 push된 커밋은 rebase 금지

---

## 6. 정리하기 — `git cleanup`

머지 후 로컬에 남아 있는 브랜치를 정리합니다.

```bash
git cleanup
```

**예시 출력:**

```
🔍 main 브랜치 최신화 중...
🔍 원격 추적 정보 정리 중 (git fetch -p)...
🔍 GitHub PR 상태 확인 중 (gh)...

다음 브랜치들이 삭제됩니다:
  feat/order-router
  fix/websocket-reconnect

진행하시겠습니까? [y/N]: y
✅ feat/order-router 삭제 완료 (merged)
✅ fix/websocket-reconnect 삭제 완료 (PR merged on GitHub)
```

**삭제 사유 태그:**

| 태그 | 의미 |
|---|---|
| `(merged)` | 일반 merge commit으로 main에 흡수됨 |
| `(gone from remote)` | 원격 브랜치가 사라진 신호. 일반적으로 PR squash merge + GitHub auto-delete head branches 설정이 동작한 결과 |
| `(PR merged on GitHub)` | `gh pr list --state merged`로 감지. `gh` CLI 필수 |

> `gh` CLI가 미설치/미인증이면 `(merged)` + `(gone from remote)` 두 종류만 정리됩니다.

---

## 7. 릴리스 태깅

릴리스 브랜치를 만들지 않습니다. **Git tag**로 표시합니다.

```bash
git tag v1.2.3                 # SemVer
git tag staging-v20260407      # 스테이징 배포 시점
git tag prod-v20260407-001     # 프로덕션 배포 시점
git push origin <tag>
```

태그 부여 시 GitHub Release 작성을 권장합니다 (변경 요약 + 롤백 포인트).

---

## 8. 브랜치 수명이 길어질 것 같으면

**더 작은 단위로 쪼갭니다:**

1. 큰 기능을 여러 PR로 분할
2. feature flag로 미완성 기능을 main에 미리 머지
3. 별도 모듈로 격리 후 한 번에 통합

---

## Quick Reference

| 하고 싶은 것 | 명령어 |
|---|---|
| 새 기능 시작 | `git nb feat my-feature` |
| 새 브랜치 (인터랙티브) | `git nb` |
| PR 생성 | `git fb` |
| 머지 후 정리 | `git cleanup` |
| 릴리스 태깅 | `git tag v1.2.3 && git push origin v1.2.3` |

**alias ↔ 스크립트 대응표:**

| alias | 스크립트 |
|---|---|
| `git nb <type> <n>` | `./scripts/new-branch.sh <type> <n>` |
| `git fb` | `./scripts/finish-branch.sh` |
| `git cleanup` | `./scripts/cleanup-merged.sh` |
| `git bootstrap` | `./scripts/bootstrap.sh` |

> alias가 등록되지 않은 환경에서는 스크립트를 직접 호출하세요.

---

## 작업 시작 전 체크리스트

- [ ] `main`에서 최신 상태로 분기했는가?
- [ ] 브랜치 이름이 네이밍 규칙(`feat/`, `fix/`, ...)을 따르는가?
- [ ] 1~2일 안에 끝낼 수 있는 작은 단위인가?
- [ ] PR 제목을 Conventional Commits 형식으로 작성할 것인가?
- [ ] 머지 후 `git cleanup`을 실행할 것인가?
