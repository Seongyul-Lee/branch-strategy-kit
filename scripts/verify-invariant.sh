#!/usr/bin/env bash
# verify-invariant.sh — 불변식 동기화 검증
#
# 12곳에 중복 정의된 허용 type 목록이 모두 동일한지 검증한다.
# canonical source: scripts/check-branch.sh의 PATTERN
#
# Usage:
#   bash scripts/verify-invariant.sh
#
# Exit codes:
#   0 — Tier A 전체 통과 (Tier B 경고는 허용)
#   1 — Tier A 하나 이상 실패

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 카운터
TIER_A_TOTAL=0
TIER_A_PASS=0
TIER_A_FAIL=0
TIER_B_TOTAL=0
TIER_B_PASS=0
TIER_B_WARN=0

# ── 유틸리티 ──

# 파일에서 PATTERN= 줄의 alternation group 내부를 추출하여 정렬된 type 목록 반환
extract_pattern_types() {
  local file="$1"
  grep 'PATTERN=' "$file" \
    | sed 's/.*\^(\([^)]*\)).*/\1/' \
    | tr '|' '\n' \
    | tr -d '\r' \
    | sort
}

# 두 정렬된 목록을 비교하여 missing/extra 출력. 일치하면 0, 불일치면 1 반환.
compare_types() {
  local canonical_list="$1"
  local target_list="$2"
  local label="$3"

  local missing extra
  missing=$(comm -23 <(echo "$canonical_list") <(echo "$target_list"))
  extra=$(comm -13 <(echo "$canonical_list") <(echo "$target_list"))

  if [[ -z "$missing" && -z "$extra" ]]; then
    return 0
  else
    [[ -n "$missing" ]] && echo "         missing: $missing"
    [[ -n "$extra" ]]   && echo "         extra:   $extra"
    return 1
  fi
}

# ── Canonical 추출 ──

CANONICAL_FILE="$ROOT_DIR/scripts/check-branch.sh"
if [[ ! -f "$CANONICAL_FILE" ]]; then
  echo "❌ canonical source를 찾을 수 없습니다: $CANONICAL_FILE"
  exit 1
fi

CANONICAL_TYPES=$(extract_pattern_types "$CANONICAL_FILE")
CANONICAL_COUNT=$(echo "$CANONICAL_TYPES" | wc -l | tr -d ' ')

if [[ -z "$CANONICAL_TYPES" ]]; then
  echo "❌ canonical source에서 type 목록을 추출할 수 없습니다."
  exit 1
fi

echo "🔍 불변식 동기화 검증 시작 (canonical: scripts/check-branch.sh)"
echo "   canonical types: $(echo "$CANONICAL_TYPES" | tr '\n' ' ')"
echo ""

# ── Tier A: 필수 검증 ──

echo "── Tier A: 필수 검증 ──"

check_tier_a() {
  local file="$1"
  local label="$2"
  local types="$3"

  TIER_A_TOTAL=$((TIER_A_TOTAL + 1))

  if [[ ! -f "$ROOT_DIR/$file" ]]; then
    echo "⏭️  [$TIER_A_TOTAL] $file — SKIP (파일 없음)"
    return 0
  fi

  if [[ -z "$types" ]]; then
    echo "❌ [$TIER_A_TOTAL] $file — FAIL (파서가 빈 결과 반환)"
    TIER_A_FAIL=$((TIER_A_FAIL + 1))
    return 0
  fi

  if compare_types "$CANONICAL_TYPES" "$types" "$file"; then
    echo "✅ [$TIER_A_TOTAL] $file"
    TIER_A_PASS=$((TIER_A_PASS + 1))
  else
    echo "❌ [$TIER_A_TOTAL] $file"
    TIER_A_FAIL=$((TIER_A_FAIL + 1))
  fi
}

# 1. scripts/check-commit-msg.sh — regex PATTERN
extract_commit_msg_types() {
  grep 'PATTERN=' "$ROOT_DIR/scripts/check-commit-msg.sh" \
    | sed 's/.*\^(\([^)]*\)).*/\1/' \
    | tr '|' '\n' \
    | tr -d '\r' \
    | sort
}

# 2. scripts/finish-branch.sh — regex PATTERN
extract_finish_branch_types() {
  extract_pattern_types "$ROOT_DIR/scripts/finish-branch.sh"
}

# 3. scripts/new-branch.sh — ALLOWED_TYPES array
extract_new_branch_types() {
  grep 'ALLOWED_TYPES=' "$ROOT_DIR/scripts/new-branch.sh" \
    | sed 's/.*(\([^)]*\)).*/\1/' \
    | tr ' ' '\n' \
    | tr -d '\r' \
    | sort
}

# 4. .github/workflows/branch-name-check.yml — regex PATTERN
extract_branch_name_check_types() {
  extract_pattern_types "$ROOT_DIR/.github/workflows/branch-name-check.yml"
}

# 5. .github/workflows/pr-title-check.yml — types: |- block (one type per indented line)
extract_pr_title_check_types() {
  local file="$ROOT_DIR/.github/workflows/pr-title-check.yml"
  # types: |- 블록 시작부터 다음 비어있지 않은 비들여쓰기 키까지 추출
  awk '/^[[:space:]]*types:[[:space:]]*\|-/{found=1; next}
       found && /^[[:space:]]+[a-z]/{print; next}
       found && /^[[:space:]]*[a-zA-Z_#]/{found=0}' "$file" \
    | awk '{print $1}' \
    | tr -d '\r' \
    | sort
}

# 6. .github/pull_request_template.md — checkbox list (변경 유형 섹션)
extract_pr_template_types() {
  # "변경 유형" 섹션의 체크박스에서 type 명칭만 추출 (괄호 앞 단어)
  # 형식: "- [ ] feat (설명)" → $1=-, $2=[, $3=], $4=feat
  local file="$ROOT_DIR/.github/pull_request_template.md"
  awk '/^## 변경 유형/{found=1; next}
       found && /^## /{found=0}
       found && /^- \[ \]/{print $4}' "$file" \
    | tr -d '\r' \
    | sort
}

# 7. README.md — inline backtick list
extract_readme_types() {
  grep '허용되는 브랜치 type' "$ROOT_DIR/README.md" \
    | grep -oE '`[a-z]+`' \
    | tr -d '`' \
    | tr -d '\r' \
    | sort
}

# ── Tier A 실행 ──

check_tier_a "scripts/check-commit-msg.sh" "PATTERN" "$(extract_commit_msg_types)"
check_tier_a "scripts/finish-branch.sh" "PATTERN" "$(extract_finish_branch_types)"
check_tier_a "scripts/new-branch.sh" "ALLOWED_TYPES" "$(extract_new_branch_types)"
check_tier_a ".github/workflows/branch-name-check.yml" "PATTERN" "$(extract_branch_name_check_types)"
check_tier_a ".github/workflows/pr-title-check.yml" "types" "$(extract_pr_title_check_types)"
check_tier_a ".github/pull_request_template.md" "checkbox" "$(extract_pr_template_types)"
check_tier_a "README.md" "backtick list" "$(extract_readme_types)"

echo ""

# ── Tier B: 가이드 문서 검증 ──

echo "── Tier B: 가이드 문서 검증 ──"

check_tier_b() {
  local file="$1"

  TIER_B_TOTAL=$((TIER_B_TOTAL + 1))

  if [[ ! -f "$ROOT_DIR/$file" ]]; then
    echo "⏭️  [$TIER_B_TOTAL] $file — SKIP (파일 없음)"
    return 0
  fi

  local found=0
  local missing_types=""
  local type
  while IFS= read -r type; do
    if grep -q "$type" "$ROOT_DIR/$file"; then
      found=$((found + 1))
    else
      missing_types="$missing_types $type"
    fi
  done <<< "$CANONICAL_TYPES"

  if [[ $found -eq $CANONICAL_COUNT ]]; then
    echo "✅ [$TIER_B_TOTAL] $file — $found/$CANONICAL_COUNT types found"
    TIER_B_PASS=$((TIER_B_PASS + 1))
  else
    echo "⚠️  [$TIER_B_TOTAL] $file — $found/$CANONICAL_COUNT types found (missing:$missing_types)"
    TIER_B_WARN=$((TIER_B_WARN + 1))
  fi
}

check_tier_b "3a-DAILY_WORKFLOW_SINGLE.md"
check_tier_b "3b-DAILY_WORKFLOW_TWO.md"
check_tier_b "2a-MEMBER_SETUP_SINGLE.md"
check_tier_b "2b-MEMBER_SETUP_TWO.md"

echo ""

# ── 결과 요약 ──

echo "── 결과 ──"

if [[ $TIER_A_FAIL -eq 0 ]]; then
  echo "Tier A: $TIER_A_PASS/$TIER_A_TOTAL passed ✅"
else
  echo "Tier A: $TIER_A_PASS/$TIER_A_TOTAL passed ❌ FAIL"
fi

if [[ $TIER_B_WARN -eq 0 ]]; then
  echo "Tier B: $TIER_B_PASS/$TIER_B_TOTAL passed ✅"
else
  echo "Tier B: $TIER_B_PASS/$TIER_B_TOTAL passed ⚠️  WARNING"
fi

# Tier A 실패 시 exit 1
if [[ $TIER_A_FAIL -gt 0 ]]; then
  exit 1
fi
