# 일상 워크플로우

세팅이 완료된 후, 매일 사용하는 명령어와 규칙을 정리한 레퍼런스입니다.

---

## 한눈에 보는 흐름

```
git nb  →  코딩  →  commit  →  git fb  →  GitHub에서 Squash Merge 혹은 reject/close  →  git cleanup
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
  ▶ feat       신규 기능
    fix        버그 수정 / hotfix
    refactor   동작 변경 없는 리팩터
    docs       문서만 변경
    research   탐색·실험·리서치
    data       DB 스키마 / 마이그레이션
    chore      빌드/CI/설정 변경
    remove     파일·기능 제거
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
| `remove/` | 파일·기능 제거 | `remove/unused-assets` |

**규칙:**
- **브랜치명**: 소문자 + 하이픈만 사용 (`feat/my-feature` ✅ / `feat/MyFeature` ❌). URL/CLI 호환성을 위해 한국어는 브랜치명에는 사용하지 않습니다.
- 3~5단어 이내 권장
- 커밋 메시지와 PR 제목의 **subject** 부분은 한국어 사용 가능 (§3 참조)

> 이 규칙은 CI workflow(`branch-name-check.yml`)와 lefthook이 자동 강제합니다. 위반 시 push/PR 단계에서 차단됩니다.

---

## 3. 커밋 메시지 규칙

**Conventional Commits** 형식을 따릅니다. subject 부분은 **한국어 사용 가능**합니다 (영어만 되는 기존 conventional-commits 관행과 다른, 이 키트의 결정).

```
<type>: <설명>
```

**예시 (한글/영문/혼용 모두 허용):**

```bash
# 영문 기술 용어 + 한국어 동사 (권장 스타일)
git commit -m "feat: basic enemy AI movement 구현"
git commit -m "fix: door trigger 오류 수정"
git commit -m "refactor: stat component 구조 개선"
git commit -m "data: enemy balance 테이블 추가"
git commit -m "remove: unused asset 및 테스트 코드 삭제"

# 순수 한국어도 가능
git commit -m "docs: 브랜치 전략 가이드 업데이트"

# 순수 영문도 가능 (다국적 팀 대응)
git commit -m "fix: handle null response from orderbook API"
```

**유일한 제약**: subject의 **첫 글자는 대문자(A-Z)가 아니어야** 합니다 (`pr-title-check.yml`의 `subjectPattern: ^[^A-Z].+$`). 한글·숫자·소문자·기호는 모두 OK.

> lefthook의 `commit-msg` 훅이 형식을 자동 검증합니다. 위반 시 커밋이 차단됩니다.

---

## 4. PR 만들기 — `git fb`

커밋이 완료되면 원격에 push하고 PR을 생성합니다.

```bash
git add .
git commit -m "feat: order router 구현"
git fb
# → push + PR 생성 + PR URL 출력
```

**PR 제목 규칙:**
- Conventional Commits 형식 필수 (예: `feat: order router 구현`)
- PR 제목이 squash merge 후 main의 커밋 메시지가 됩니다
- `pr-title-check.yml`이 자동 검증합니다
- 한국어/혼용 subject 허용 — 첫 글자만 대문자(A-Z)가 아니면 됨

> PR 본문이 잘못 채워졌다면: `gh pr edit <번호>`로 수정하거나 GitHub UI에서 직접 수정하세요.

**push만 하고 PR은 나중에 만들고 싶을 때:**

```bash
git fb --no-pr   # push만 수행
```

---

## 5. 코드 리뷰 & 머지

1. GitHub PR 페이지에서 팀원에게 리뷰를 요청합니다.
2. 리뷰어가 Approve 판단 시, **Squash and merge** 버튼을 클릭합니다.
3. 원격 브랜치는 `Automatically delete head branches` 설정에 의해 자동 삭제됩니다.

**머지 규칙:**
- **squash merge만 허용** (merge commit, rebase merge 금지)
- **linear history 강제** (Branch Protection 설정)
- rebase는 자기 브랜치 한정. main에 push된 커밋은 rebase 금지

**PR Close 규칙 (중요):**

- **PR을 close하는 책임은 리뷰어에게 있습니다.** PR 작성자는 자기 PR을 직접 close하지 않습니다.
- **리뷰어가 PR을 reject한다면 원격 브랜치 삭제도 함께 진행해야 합니다.** 이는 필수 절차입니다.
  - GitHub UI: PR 페이지 하단의 **Close pull request** 버튼 클릭 -> **Delete branch** 버튼도 반드시 클릭
  - CLI: `gh pr close <번호> --delete-branch` (한 번에 처리)
- 작성자는 **리뷰어가 close + 원격 삭제까지 마친 뒤** `git cleanup` 한 줄로 로컬 브랜치 정리.

> 💡 **왜 작성자가 PR을 직접 close하지 않나**: PR의 결정(머지/거절)을 한 명(리뷰어)에게 일관되게 위임하면 작성자가 "이미 close된 PR을 다시 open하는" 혼란이 사라지고, 검토 이력이 깨끗해집니다. 또한 리뷰어의 원격 삭제를 규칙으로 고정하면 작성자는 **머지/거절 어느 쪽이든 `git cleanup` 하나면 충분**합니다.

---

## 6. 정리하기 — `git cleanup`

머지 후 로컬에 남아 있는 브랜치를 정리합니다.

```bash
git cleanup                              # 모든 머지된 브랜치 정리(중요)

git cleanup --exclude feat/keep-this     # 특정 브랜치 제외
git cleanup --exclude 'feat/wip-*'       # glob 패턴 제외 (반복 사용 가능)
```

> ⚠️ `git cleanup`은 **머지 완료된 작업 브랜치만** 삭제합니다. PR이 없거나 OPEN 상태인 브랜치는 절대 건드리지 않습니다. main/master/develop도 보호됨.

**PR이 거절(reject)된 경우도 동일:**

§5의 "PR Close 규칙"에 따라 리뷰어가 PR을 reject할 때 **원격 브랜치까지 함께 삭제**합니다. 따라서 작성자는 머지/거절 어느 쪽이든 평소와 동일하게:

```bash
git cleanup
```

한 줄이면 끝납니다. `git fetch -p`가 사라진 원격 브랜치를 감지하고 `(gone from remote)` 사유로 자동 정리됩니다.

**예시 출력 (검출 사유가 inline으로 표시됨):**

```
🔍 main 브랜치 최신화 중...
🔍 원격 추적 정보 정리 중 (git fetch -p)...
🔍 GitHub PR 상태 확인 중 (gh)...

다음 브랜치들이 삭제됩니다:
  feat/order-router          (merged)
  fix/websocket-reconnect    (PR merged on GitHub)
  refactor/api-cleanup       (gone from remote)

진행하시겠습니까? [y/N]: y
✅ feat/order-router 삭제 완료 (merged)
✅ fix/websocket-reconnect 삭제 완료 (PR merged on GitHub)
✅ refactor/api-cleanup 삭제 완료 (gone from remote)
```

`--exclude`로 일부를 제외한 경우 별도 섹션으로 안내됩니다:

```
다음 브랜치들이 삭제됩니다:
  feat/order-router    (merged)

⏭  --exclude로 제외됨:
     feat/keep-this

진행하시겠습니까? [y/N]:
```

**삭제 사유 태그:**

| 태그 | 의미 |
|---|---|
| `(merged)` | 일반 merge commit으로 main에 흡수됨 (`git branch --merged main` 으로 감지) |
| `(gone from remote)` | 원격 브랜치가 사라진 신호. 일반적으로 PR squash merge + GitHub auto-delete head branches 설정이 동작한 결과 |
| `(PR merged on GitHub)` | `gh pr list --state merged`로 감지. `gh` CLI 필수. auto-delete가 동작하지 않은 케이스 보정 |

> `gh` CLI가 미설치/미인증이면 `(merged)` + `(gone from remote)` 두 종류만 정리됩니다.

---

## 7. 브랜치 전환 — `git branch-move`

여러 작업 브랜치를 운영 중일 때, 인터랙티브 메뉴로 로컬 브랜치를 선택해 checkout합니다.

```bash
git branch-move
```

- 최근 커밋 시각 내림차순으로 정렬됩니다.
- 현재 브랜치는 `*` 마커와 색상으로 강조됩니다.
- **`fzf`가 설치되어 있으면** 화살표 + Enter로 선택 (권장).
- **없으면** 번호 입력 fallback으로 동작 (의존성 0).
- 커밋되지 않은 변경이 있으면 거부됩니다 — 먼저 커밋/스태시 후 사용하세요.

```
$ git branch-move
로컬 브랜치 (최근 커밋 순):
   1) * feat/order-router         2 hours ago    feat: 라우터 초기 구현
   2)   fix/websocket-reconnect   1 day ago      fix: 재연결 백오프 추가
   3)   chore/fb-no-pr-message    3 days ago     chore: fb 메시지 개선

이동할 브랜치 번호 [1-3, q=취소]: 2
✅ 'fix/websocket-reconnect' 브랜치로 이동했습니다.
```

> 💡 fzf 설치: macOS `brew install fzf`, Windows `winget install fzf`. 키트 필수 의존성은 아닙니다.

---

## 8. 릴리스 태깅

릴리스 브랜치를 만들지 않습니다. **Git tag**로 표시합니다.

```bash
git tag v1.2.3                 # SemVer
git tag staging-v20260407      # 스테이징 배포 시점
git tag prod-v20260407-001     # 프로덕션 배포 시점
git push origin <tag>
```

태그 부여 시 GitHub Release 작성을 권장합니다 (변경 요약 + 롤백 포인트).

---

## 9. 브랜치 수명이 길어질 것 같으면

**더 작은 단위로 쪼갭니다:**

1. 큰 기능을 여러 PR로 분할
2. feature flag로 미완성 기능을 main에 미리 머지
3. 별도 모듈로 격리 후 한 번에 통합

---

## Quick Reference

| 하고 싶은 것 | 명령어 |
|---|---|
| 새 기능 시작 | `git nb feat my-feature` |
| 파일·기능 제거 | `git nb remove unused-assets` |
| 새 브랜치 (인터랙티브) | `git nb` |
| PR 생성 | `git fb` |
| 머지 후 정리 | `git cleanup` |
| 브랜치 전환 | `git branch-move` |
| 릴리스 태깅 | `git tag v1.2.3 && git push origin v1.2.3` |

**alias ↔ 스크립트 대응표:**

| alias | 스크립트 |
|---|---|
| `git nb <type> <n>` | `./scripts/new-branch.sh <type> <n>` |
| `git fb` | `./scripts/finish-branch.sh` |
| `git cleanup` | `./scripts/cleanup-merged.sh` |
| `git branch-move` | `./scripts/branch-move.sh` |
| `git bootstrap` | `./scripts/bootstrap.sh` |

> alias가 등록되지 않은 환경에서는 스크립트를 직접 호출하세요.

---

## 작업 시작 전 체크리스트

- [ ] `main`에서 최신 상태로 분기했는가?
- [ ] 브랜치 이름이 네이밍 규칙(`feat/`, `fix/`, ...)을 따르는가?
- [ ] 1~2일 안에 끝낼 수 있는 작은 단위인가?
- [ ] PR 제목을 Conventional Commits 형식으로 작성할 것인가?
- [ ] 머지 후 `git cleanup`을 실행할 것인가?
