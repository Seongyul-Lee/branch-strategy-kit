#!/usr/bin/env bash
# sync-main.sh — develop→main PR 생성 (Two-branch 모드 전용)
#
# Usage:
#   ./scripts/sync-main.sh              # develop→main PR 생성
#   ./scripts/sync-main.sh --tag v1.2.0 # 릴리스 태그 포함 PR 생성
#
# DEFAULT_BRANCH=develop 일 때만 동작. main 모드에서는 에러.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

TAG=""

# 인자 파싱
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      if [[ -z "${2:-}" ]]; then
        echo "❌ --tag는 버전 인자가 필요합니다. 예: --tag v1.2.0"
        exit 1
      fi
      TAG="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--tag <version>]"
      echo "  --tag <version>  릴리스 태그 포함 PR 생성 (예: v1.2.0)"
      exit 0
      ;;
    *)
      echo "❌ 알 수 없는 인자: $1"
      echo "   Usage: $0 [--tag <version>]"
      exit 1
      ;;
  esac
done

# DEFAULT_BRANCH 검증: develop 일 때만 실행 (master, 오타 등 차단)
if [[ "$DEFAULT_BRANCH" != "develop" ]]; then
  echo "❌ sync-main은 DEFAULT_BRANCH=develop 일 때만 사용할 수 있습니다."
  echo "   현재 설정값: ${DEFAULT_BRANCH}"
  echo "   .kit-config에서 DEFAULT_BRANCH=develop으로 설정하세요."
  exit 1
fi

# gh CLI 설치 확인
if ! command -v gh >/dev/null 2>&1; then
  echo "❌ GitHub CLI(gh)가 설치되어 있지 않습니다."
  echo "   설치: https://cli.github.com/"
  exit 1
fi

# 태그 형식 검증 (--tag 사용 시)
if [[ -n "$TAG" ]]; then
  if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ 태그 형식이 올바르지 않습니다: $TAG"
    echo "   올바른 형식: v1.0.0, v2.1.3 등 (semver)"
    exit 1
  fi
  if git tag -l "$TAG" | grep -q .; then
    echo "❌ 태그 '$TAG'가 이미 존재합니다."
    exit 1
  fi
fi

# develop으로 전환 + 최신화 (로컬 미존재 시 origin에서 추적 브랜치 생성)
# 가드 전 fetch: refs/remotes/origin/$DEFAULT_BRANCH가 stale/미존재 상태에서
# "origin도 없음"으로 오탐 종료하는 것을 방지. fetch 실패는 stale ref 위에서
# 잘못 판단하지 않도록 명시적으로 종료한다.
echo "🔍 원격 정보 최신화 중..."
if ! git fetch origin "$DEFAULT_BRANCH" --quiet; then
  echo "❌ origin/$DEFAULT_BRANCH fetch에 실패했습니다." >&2
  echo "   원격 접근/인증 상태 또는 네트워크 연결을 확인하세요." >&2
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]]; then
  echo "🔍 $DEFAULT_BRANCH 브랜치로 전환 중..."
  if git show-ref --verify --quiet "refs/heads/$DEFAULT_BRANCH"; then
    git checkout "$DEFAULT_BRANCH"
  elif git show-ref --verify --quiet "refs/remotes/origin/$DEFAULT_BRANCH"; then
    echo "   로컬에 $DEFAULT_BRANCH 브랜치가 없어 원격에서 추적 브랜치를 생성합니다..."
    git checkout -b "$DEFAULT_BRANCH" --track "origin/$DEFAULT_BRANCH"
  else
    echo "❌ 로컬 브랜치 '$DEFAULT_BRANCH'이 없고 origin/$DEFAULT_BRANCH도 찾을 수 없습니다." >&2
    echo "   원격 저장소 접근 가능 여부와 .kit-config의 DEFAULT_BRANCH 설정을 확인하세요." >&2
    exit 1
  fi
fi
echo "🔍 $DEFAULT_BRANCH 브랜치 최신화 중..."
if ! git pull --ff-only; then
  echo "❌ '$DEFAULT_BRANCH' 브랜치 최신화에 실패했습니다." >&2
  echo "   upstream 설정 또는 원격 상태를 확인하세요." >&2
  exit 1
fi

# main 비교 ref 결정 (fetch 성공 시 origin/main 우선, 실패 시 로컬 main 폴백)
# fetch 실패를 무시하면 stale origin/main 으로 rev-list/git log 결과가 왜곡되므로
# freshness를 추적해 안전한 기준점만 사용한다.
MAIN_FRESH=0
if git fetch origin main --quiet 2>/dev/null; then
  MAIN_FRESH=1
else
  echo "⚠️  origin/main 최신화에 실패했습니다. 로컬 main으로만 비교를 시도합니다." >&2
  echo "   네트워크/권한/원격 상태를 확인하세요." >&2
fi

if [[ "$MAIN_FRESH" -eq 1 ]] && git show-ref --verify --quiet "refs/remotes/origin/main"; then
  MAIN_REF="origin/main"
elif git show-ref --verify --quiet "refs/heads/main"; then
  MAIN_REF="main"
elif git show-ref --verify --quiet "refs/remotes/origin/main"; then
  echo "❌ origin/main은 존재하지만 최신화에 실패해 freshness를 보장할 수 없습니다." >&2
  echo "   stale ref를 기준으로 커밋 개수/요약이 왜곡될 수 있어 종료합니다." >&2
  echo "   원격 접근을 복구하거나 로컬 main 브랜치를 준비한 뒤 다시 시도하세요." >&2
  exit 1
else
  echo "❌ main 브랜치를 찾을 수 없습니다 (로컬도 origin/main도 없음)." >&2
  echo "   sync-main은 main을 릴리스 브랜치로 전제합니다." >&2
  exit 1
fi

# main과의 차이 확인
COMMITS_AHEAD=$(git rev-list --count "${MAIN_REF}..${DEFAULT_BRANCH}" 2>/dev/null || echo "0")
if [[ "$COMMITS_AHEAD" == "0" ]]; then
  echo "✅ main 대비 변경 사항이 없습니다."
  exit 0
fi

echo "📊 main 대비 $COMMITS_AHEAD개 커밋 차이"

# 이미 열린 PR 확인
EXISTING_PR_URL=$(gh pr list --head "$DEFAULT_BRANCH" --base main --state open --limit 1 \
  --json url --jq '.[0].url // empty' 2>/dev/null || true)

if [[ -n "$EXISTING_PR_URL" ]]; then
  EXISTING_PR_NUM=$(gh pr list --head "$DEFAULT_BRANCH" --base main --state open --limit 1 \
    --json number --jq '.[0].number // empty' 2>/dev/null || true)
  echo ""
  echo "기존 #${EXISTING_PR_NUM} PR이 이미 열려 있습니다."
  echo "   PR: $EXISTING_PR_URL"
  exit 0
fi

# PR 생성
echo "📝 develop→main PR 생성 중..."

if [[ -n "$TAG" ]]; then
  # 릴리스 태그 모드: 커밋 요약을 본문에 포함
  COMMIT_LOG=$(git log --oneline "${MAIN_REF}..${DEFAULT_BRANCH}" | head -20)
  PR_BODY="## Release ${TAG}

### 포함된 변경 사항
\`\`\`
${COMMIT_LOG}
\`\`\`

---
PR 머지 후 태그를 생성하세요:
\`\`\`bash
git checkout main && git pull
git tag ${TAG} && git push origin ${TAG}
\`\`\`"

  gh pr create \
    --base main \
    --head "$DEFAULT_BRANCH" \
    --title "chore: release ${TAG}" \
    --body "$PR_BODY"
else
  # 일반 동기화 모드
  gh pr create \
    --base main \
    --head "$DEFAULT_BRANCH" \
    --fill-first
fi

echo ""
echo "✅ PR 생성 완료. GitHub에서 'Squash and merge' 버튼을 클릭하세요."
if [[ -n "$TAG" ]]; then
  echo ""
  echo "📌 머지 후 태그를 생성하려면:"
  echo "   git checkout main && git pull"
  echo "   git tag ${TAG} && git push origin ${TAG}"
fi
