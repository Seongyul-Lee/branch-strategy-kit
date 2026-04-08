#!/usr/bin/env bash
# branch-move.sh — 로컬 브랜치를 인터랙티브로 선택해 checkout
#
# Usage: ./scripts/branch-move.sh
#
# 동작:
#   1. uncommitted 변경이 있으면 거부 (stash 자동화 안 함)
#   2. 로컬 브랜치를 최근 커밋 시각 내림차순으로 나열
#   3. fzf가 설치되어 있으면 fzf UI, 없으면 번호 입력 fallback
#   4. 선택한 브랜치로 checkout
#
# 표시: 브랜치명만 한 줄씩.
# 현재 브랜치는 '*' 마커 + 녹색으로 강조 (TTY일 때만 색상)

set -euo pipefail

CURRENT=$(git rev-parse --abbrev-ref HEAD)

# uncommitted 변경 차단
if [[ -n "$(git status --porcelain)" ]]; then
  echo "❌ ${CURRENT} 브랜치에 커밋되지 않은 변경 사항이 있습니다. ❌"
  git status --short
  echo ""
  echo "   먼저 커밋하거나 stash 후 다시 시도하세요:"
  echo "   git add . && git commit -m \"<type>: ...\""
  echo "   또는: git stash"
  exit 1
fi

# 색상 (TTY일 때만)
if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'
  C_RESET=$'\033[0m'
else
  C_GREEN=""
  C_RESET=""
fi

# 브랜치 목록: 최근 커밋 시각 내림차순, 이름만
RAW=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)')

if [[ -z "$RAW" ]]; then
  echo "❌ 로컬 브랜치가 없습니다."
  exit 1
fi

BRANCH_COUNT=$(printf '%s\n' "$RAW" | grep -c .)
if [[ "$BRANCH_COUNT" -le 1 ]]; then
  echo "ℹ️  로컬 브랜치가 '${CURRENT}' 하나뿐이라 이동할 브랜치가 없습니다."
  echo "   새 작업 브랜치 만들기: git nb <type> <name>"
  exit 0
fi

# 현재 브랜치를 맨 위로
CURRENT_LINE=$(printf '%s\n' "$RAW" | grep -Fx "$CURRENT" || true)
OTHERS=$(printf '%s\n' "$RAW" | grep -Fxv "$CURRENT" || true)

ORDERED=""
[[ -n "$CURRENT_LINE" ]] && ORDERED+="$CURRENT_LINE"$'\n'
[[ -n "$OTHERS" ]] && ORDERED+="$OTHERS"
ORDERED=${ORDERED%$'\n'}

# fzf 모드
if command -v fzf >/dev/null 2>&1; then
  FORMATTED=""
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    if [[ "$name" == "$CURRENT" ]]; then
      FORMATTED+="${C_GREEN}* ${name}${C_RESET}"$'\n'
    else
      FORMATTED+="  ${name}"$'\n'
    fi
  done <<< "$ORDERED"

  SELECTED=$(printf '%s' "$FORMATTED" \
    | fzf --ansi \
          --prompt='브랜치 선택> ' \
          --header='Enter: checkout, ESC: 취소' \
          --no-sort \
          --height=40% \
          --reverse || true)

  if [[ -z "$SELECTED" ]]; then
    echo "취소되었습니다."
    exit 0
  fi

  TARGET=$(printf '%s' "$SELECTED" | sed 's/^..//' | awk '{print $1}')
else
  # 번호 입력 fallback
  echo "ℹ️  fzf가 설치되어 있지 않아 번호 입력 모드로 동작합니다."
  echo "   더 나은 경험: brew install fzf  /  winget install fzf"
  echo ""
  echo "로컬 브랜치 (최근 커밋 순):"

  IDX=0
  declare -a NAMES=()
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    IDX=$((IDX + 1))
    NAMES+=("$name")
    if [[ "$name" == "$CURRENT" ]]; then
      printf "  ${C_GREEN}%2d) * %s${C_RESET}\n" "$IDX" "$name"
    else
      printf "  %2d)   %s\n" "$IDX" "$name"
    fi
  done <<< "$ORDERED"

  echo ""
  read -r -p "이동할 브랜치 번호 [1-${IDX}, q=취소]: " INPUT

  if [[ "$INPUT" =~ ^[qQ]$ || -z "$INPUT" ]]; then
    echo "취소되었습니다."
    exit 0
  fi

  if [[ ! "$INPUT" =~ ^[0-9]+$ ]]; then
    echo "❌ 숫자를 입력하세요."
    exit 1
  fi

  if (( INPUT < 1 || INPUT > IDX )); then
    echo "❌ 1~${IDX} 범위의 번호를 입력하세요."
    exit 1
  fi

  TARGET="${NAMES[$((INPUT - 1))]}"
fi

if [[ -z "$TARGET" ]]; then
  echo "❌ 브랜치를 선택하지 못했습니다."
  exit 1
fi

if [[ "$TARGET" == "$CURRENT" ]]; then
  echo "ℹ️  이미 '$CURRENT' 브랜치에 있습니다."
  exit 0
fi

git checkout "$TARGET"
echo "✅ '$TARGET' 브랜치로 이동했습니다."
