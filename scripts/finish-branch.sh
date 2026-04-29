#!/usr/bin/env bash
# finish-branch.sh — 현재 브랜치를 push하고 GitHub PR을 자동 생성
#
# Usage: ./scripts/finish-branch.sh [--no-pr]
#   --no-pr   push만 수행하고 PR 생성은 건너뜀

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

NO_PR=0
for arg in "$@"; do
  case "$arg" in
    --no-pr) NO_PR=1 ;;
    *)
      echo "❌ 알 수 없는 인자: $arg"
      echo "   Usage: $0 [--no-pr]"
      exit 1
      ;;
  esac
done

# gh CLI 설치 확인 (--no-pr 시 생략)
if [[ $NO_PR -eq 0 ]] && ! command -v gh >/dev/null 2>&1; then
  echo "❌ GitHub CLI(gh)가 설치되어 있지 않습니다."
  echo "   설치: https://cli.github.com/"
  echo ""
  echo "또는 수동 PR 생성:"
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "  git push -u origin $CURRENT_BRANCH"
  echo "  # 그 후 GitHub 웹 UI에서 PR 생성"
  exit 1
fi

# 현재 브랜치
BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "$BRANCH" == "main" || "$BRANCH" == "$DEFAULT_BRANCH" ]]; then
  echo "❌ $BRANCH 브랜치에서는 실행할 수 없습니다."
  echo "   먼저 작업 브랜치로 전환하세요: git nb <type> <name>"
  exit 1
fi

# 브랜치명 규칙 검증 (한 번 더 안전망)
PATTERN="^(feat|fix|refactor|docs|research|data|chore|remove)/[a-z0-9][a-z0-9-]*$"
if [[ ! "$BRANCH" =~ $PATTERN ]]; then
  echo "❌ 브랜치명 '$BRANCH'이 규칙을 위반합니다."
  echo "   올바른 형식: feat/my-feature, fix/bug-name, data/schema-v3, remove/unused-asset 등"
  echo "   브랜치 이름 변경: git branch -m <type>/<올바른-이름>"
  exit 1
fi

# 커밋 1개 이상 있는지 확인
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "❌ 아직 커밋이 없습니다. 먼저 커밋을 만드세요."
  exit 1
fi

# DEFAULT_BRANCH 대비 커밋 차이 확인
COMMITS_AHEAD=$(git rev-list --count "$DEFAULT_BRANCH"..HEAD 2>/dev/null || echo "0")
if [[ "$COMMITS_AHEAD" == "0" ]]; then
  echo "❌ $DEFAULT_BRANCH 대비 커밋이 없습니다. 먼저 작업을 커밋하세요."
  exit 1
fi

# 커밋되지 않은 변경 사항이 있을 때만 사용자 확인 (push는 커밋만 전송하므로 안전).
# 미커밋 변경이 없으면 그대로 push 진행.
DIRTY=$(git status --porcelain)
if [[ -n "$DIRTY" ]]; then
  echo "[커밋된 변경사항]"
  git log --oneline "$DEFAULT_BRANCH"..HEAD | sed 's/^/  /'
  echo ""
  echo "[커밋되지 않은 변경사항]"
  echo "$DIRTY" | sed 's/^/  /'
  echo ""
  # TTY 가드: 비대화형(CI, redirect, GUI hook) 환경에서는 안전하게 거부.
  # set -e 환경에서 read </dev/tty 실패 시 즉시 종료를 회피하기 위해 사전 검사.
  if [[ ! -t 0 || ! -r /dev/tty ]]; then
    echo "❌ 인터랙티브 확인이 필요한데 TTY를 찾을 수 없습니다 (non-interactive shell)." >&2
    echo "   미커밋 변경이 있어 확인 프롬프트를 띄워야 합니다." >&2
    echo "   먼저 변경 사항을 커밋하거나 인터랙티브 셸에서 다시 실행하세요." >&2
    exit 1
  fi
  read -r -p "원격에 push 및 PR 생성하시겠습니까? [y/N]: " CONFIRM </dev/tty
  if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
    echo "취소되었습니다."
    exit 0
  fi
fi

# push
echo "📤 원격에 push 중: $BRANCH"
git push -u origin "$BRANCH"

if [[ $NO_PR -eq 1 ]]; then
  echo ""
  echo "push 완료✅  (--no-pr: PR 생성을 건너뛰었습니다)."
  echo "   나중에 PR을 만들려면: git fb"
  exit 0
fi

# 이미 열린 PR(state=open)이 있는지 확인
# gh pr view 는 closed/merged PR도 반환하므로 gh pr list --state open 으로 한정
EXISTING_PR_URL=$(gh pr list --head "$BRANCH" --state open --limit 1 \
  --json url --jq '.[0].url // empty' 2>/dev/null || true)

if [[ -n "$EXISTING_PR_URL" ]]; then
  EXISTING_PR_NUM=$(gh pr list --head "$BRANCH" --state open --limit 1 \
    --json number --jq '.[0].number // empty' 2>/dev/null || true)
  echo ""
  echo "기존 #${EXISTING_PR_NUM} PR에 push 완료✅  (이미 열린 PR이 있어 새로 생성하지 않았습니다.)"
  echo "   PR: $EXISTING_PR_URL"
  echo "   머지 후 로컬 정리: git cleanup"
  exit 0
fi

# PR 생성
# --fill-first: 커밋이 여러 개일 때 첫 커밋 메시지를 PR 제목/본문으로 사용.
# (--fill은 multi-commit PR에서 브랜치명을 Conventional Commits가 아닌 형식으로
#  변환해 PR 제목 검증이 실패하는 버그가 있어 --fill-first로 통일한다.)
echo "📝 PR 생성 중..."
gh pr create --base "$DEFAULT_BRANCH" --fill-first

echo ""
echo "PR 생성 완료✅  리뷰 후 GitHub에서 'Squash and merge' 버튼을 클릭하세요."
echo "   머지 후 로컬 정리: git cleanup"
