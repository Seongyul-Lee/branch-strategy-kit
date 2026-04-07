#!/usr/bin/env bash
# cleanup-merged.sh — 머지된 로컬 브랜치 + 원격에서 사라진 브랜치를 일괄 삭제
#
# Usage: ./scripts/cleanup-merged.sh

set -euo pipefail

PROTECTED_BRANCHES="main master develop"

# main 최신화
echo "🔍 main 브랜치 최신화 중..."
git checkout main
git pull --ff-only

echo "🔍 원격 추적 정보 정리 중 (git fetch -p)..."
git fetch -p

# 1) 머지된 로컬 브랜치
MERGED=$(git branch --merged main \
  | sed 's/^[ *]*//' \
  | grep -v -x -F "$(echo "$PROTECTED_BRANCHES" | tr ' ' '\n')" \
  || true)

# 2) 원격에서 삭제된 브랜치를 추적하던 로컬 브랜치 (squash merge 대응)
GONE=$(git branch -vv \
  | awk '/: gone\]/{print $1}' \
  | grep -v -x -F "$(echo "$PROTECTED_BRANCHES" | tr ' ' '\n')" \
  || true)

# 합치고 중복 제거
ALL_TO_DELETE=$(printf "%s\n%s\n" "$MERGED" "$GONE" | sort -u | sed '/^$/d')

if [[ -z "$ALL_TO_DELETE" ]]; then
  echo "✅ 정리할 머지된 브랜치가 없습니다."
  exit 0
fi

echo ""
echo "다음 브랜치들이 삭제됩니다:"
echo "$ALL_TO_DELETE" | sed 's/^/  /'
echo ""
read -r -p "진행하시겠습니까? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
  echo "취소되었습니다."
  exit 0
fi

echo ""
# 머지된 브랜치는 -d (안전), 원격 gone 브랜치는 -D (강제, squash merge라 -d 거부됨)
while IFS= read -r BRANCH; do
  [[ -z "$BRANCH" ]] && continue

  if echo "$MERGED" | grep -qx "$BRANCH"; then
    if git branch -d "$BRANCH" 2>/dev/null; then
      echo "✅ $BRANCH 삭제 완료 (merged)"
    else
      git branch -D "$BRANCH"
      echo "✅ $BRANCH 삭제 완료 (forced)"
    fi
  else
    git branch -D "$BRANCH"
    echo "✅ $BRANCH 삭제 완료 (gone from remote)"
  fi
done <<< "$ALL_TO_DELETE"

echo ""
echo "🎉 정리 완료."
