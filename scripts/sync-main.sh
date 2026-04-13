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

# Single-trunk 모드 체크
if [[ "$DEFAULT_BRANCH" == "main" ]]; then
  echo "❌ Single-trunk 모드에서는 sync-main을 사용할 수 없습니다."
  echo "   Two-branch 모드를 사용하려면 .kit-config에서 DEFAULT_BRANCH=develop으로 변경하세요."
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

# develop으로 전환 + 최신화
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]]; then
  echo "🔍 $DEFAULT_BRANCH 브랜치로 전환 중..."
  git checkout "$DEFAULT_BRANCH"
fi
echo "🔍 $DEFAULT_BRANCH 브랜치 최신화 중..."
git pull --ff-only

# main과의 차이 확인
COMMITS_AHEAD=$(git rev-list --count main.."$DEFAULT_BRANCH" 2>/dev/null || echo "0")
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
  COMMIT_LOG=$(git log --oneline main.."$DEFAULT_BRANCH" | head -20)
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
