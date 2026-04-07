#!/usr/bin/env bash
# new-branch.sh — main을 최신화하고 <type>/<name> 형식의 새 작업 브랜치 생성
#
# Usage: ./scripts/new-branch.sh <type> <name>
#   type: feat | fix | refactor | docs | research | data | chore
#   name: kebab-case (대소문자/공백/언더스코어는 자동 변환)

set -euo pipefail

ALLOWED_TYPES="feat fix refactor docs research data chore"

print_usage() {
  echo "Usage: $0 <type> <name>"
  echo "  type: feat | fix | refactor | docs | research | data | chore"
  echo "  name: kebab-case (자동 변환)"
}

TYPE="${1:-}"
NAME="${2:-}"

if [[ -z "$TYPE" || -z "$NAME" ]]; then
  echo "❌ 인자가 부족합니다."
  print_usage
  exit 1
fi

# type 검증
TYPE_VALID=0
for t in $ALLOWED_TYPES; do
  if [[ "$TYPE" == "$t" ]]; then
    TYPE_VALID=1
    break
  fi
done

if [[ $TYPE_VALID -eq 0 ]]; then
  echo "❌ type '$TYPE'은 허용되지 않습니다."
  echo "   허용: feat | fix | refactor | docs | research | data | chore"
  exit 1
fi

# name을 kebab-case로 정규화: 소문자화 + 공백/언더스코어를 하이픈으로
NAME_NORMALIZED=$(echo "$NAME" \
  | tr '[:upper:]' '[:lower:]' \
  | tr ' _' '--' \
  | sed 's/--*/-/g' \
  | sed 's/^-//' \
  | sed 's/-$//')

if [[ -z "$NAME_NORMALIZED" ]]; then
  echo "❌ name을 빈 문자열로 지정할 수 없습니다."
  exit 1
fi

# 정규식 검증 (workflow 정규식과 동일)
if [[ ! "$NAME_NORMALIZED" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "❌ name '$NAME_NORMALIZED'이 규칙(소문자+숫자+하이픈)을 위반합니다."
  exit 1
fi

BRANCH="${TYPE}/${NAME_NORMALIZED}"

# main 최신화
echo "🔍 main 브랜치 최신화 중..."
git checkout main
git pull --ff-only

# 브랜치 존재 여부 확인
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "❌ 브랜치 '$BRANCH'이 이미 존재합니다."
  echo "   이미 있는 브랜치로 전환: git checkout $BRANCH"
  exit 1
fi

# 새 브랜치 생성
git checkout -b "$BRANCH"

echo ""
echo "✅ 새 브랜치 생성: $BRANCH"
echo "   작업 후: ./scripts/finish-branch.sh"
