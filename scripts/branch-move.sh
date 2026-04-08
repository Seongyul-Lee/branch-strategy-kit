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
# 표시 정보: 브랜치명 / 상대 시각 / 마지막 커밋 subject
# 현재 브랜치는 첫 줄에 '*' 마커 + 녹색으로 강조 (TTY일 때만 색상)

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
  C_DIM=$'\033[2m'
  C_RESET=$'\033[0m'
else
  C_GREEN=""
  C_DIM=""
  C_RESET=""
fi

# 브랜치 목록 수집: 최근 커밋 시각 내림차순
# 형식: <name>|<relative-date>|<subject>
RAW=$(git for-each-ref --sort=-committerdate refs/heads/ \
  --format='%(refname:short)|%(committerdate:relative)|%(subject)')

if [[ -z "$RAW" ]]; then
  echo "❌ 로컬 브랜치가 없습니다."
  exit 1
fi

# 현재 브랜치를 맨 위로 끌어올리기
CURRENT_LINE=$(printf '%s\n' "$RAW" | grep -E "^${CURRENT}\|" || true)
OTHERS=$(printf '%s\n' "$RAW" | grep -vE "^${CURRENT}\|" || true)

ORDERED=""
[[ -n "$CURRENT_LINE" ]] && ORDERED+="$CURRENT_LINE"$'\n'
[[ -n "$OTHERS" ]] && ORDERED+="$OTHERS"
ORDERED=${ORDERED%$'\n'}

# 컬럼 폭 계산 (브랜치명 / 상대 시각)
MAX_NAME=0
MAX_DATE=0
while IFS='|' read -r name date subject; do
  [[ -z "$name" ]] && continue
  (( ${#name} > MAX_NAME )) && MAX_NAME=${#name}
  (( ${#date} > MAX_DATE )) && MAX_DATE=${#date}
done <<< "$ORDERED"
NAME_W=$((MAX_NAME + 2))
DATE_W=$((MAX_DATE + 2))

# 한 줄 포맷팅 (마커 + 색상 적용)
format_line() {
  local marker="$1" name="$2" date="$3" subject="$4"
  if [[ "$name" == "$CURRENT" ]]; then
    printf "${C_GREEN}%s %-${NAME_W}s %-${DATE_W}s %s${C_RESET}\n" \
      "$marker" "$name" "$date" "$subject"
  else
    printf "%s %-${NAME_W}s ${C_DIM}%-${DATE_W}s${C_RESET} %s\n" \
      "$marker" "$name" "$date" "$subject"
  fi
}

# fzf 모드
if command -v fzf >/dev/null 2>&1; then
  FORMATTED=""
  while IFS='|' read -r name date subject; do
    [[ -z "$name" ]] && continue
    if [[ "$name" == "$CURRENT" ]]; then
      FORMATTED+=$(format_line "*" "$name" "$date" "$subject")$'\n'
    else
      FORMATTED+=$(format_line " " "$name" "$date" "$subject")$'\n'
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

  # 첫 두 글자(* 또는 공백 + 공백)를 떼고 첫 토큰이 브랜치명
  TARGET=$(printf '%s' "$SELECTED" | sed 's/^..//' | awk '{print $1}')
else
  # 번호 입력 fallback
  echo "ℹ️  fzf가 설치되어 있지 않아 번호 입력 모드로 동작합니다."
  echo "   더 나은 경험: brew install fzf  /  winget install fzf"
  echo ""
  echo "로컬 브랜치 (최근 커밋 순):"

  IDX=0
  declare -a NAMES=()
  while IFS='|' read -r name date subject; do
    [[ -z "$name" ]] && continue
    IDX=$((IDX + 1))
    NAMES+=("$name")
    if [[ "$name" == "$CURRENT" ]]; then
      printf "  ${C_GREEN}%2d) * %-${NAME_W}s %-${DATE_W}s %s${C_RESET}\n" \
        "$IDX" "$name" "$date" "$subject"
    else
      printf "  %2d)   %-${NAME_W}s ${C_DIM}%-${DATE_W}s${C_RESET} %s\n" \
        "$IDX" "$name" "$date" "$subject"
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
