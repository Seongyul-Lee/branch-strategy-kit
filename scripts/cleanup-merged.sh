#!/usr/bin/env bash
# cleanup-merged.sh — 머지된 로컬 브랜치 + 원격에서 사라진 브랜치를 일괄 삭제
#
# Usage:
#   ./scripts/cleanup-merged.sh                       # 검출된 모든 머지된 브랜치 삭제
#   ./scripts/cleanup-merged.sh --exclude <pattern>   # 패턴 일치 브랜치는 제외 (반복 가능)
#   ./scripts/cleanup-merged.sh --exclude feat/keep --exclude 'wip-*'
#
# 정리 대상은 세 가지 신호 중 하나라도 만족하는 로컬 브랜치:
#   1) git branch --merged main          — 일반 머지로 main에 흡수된 브랜치
#   2) git branch -vv 의 ': gone]' 표시   — 원격에서 사라진 추적 브랜치 (squash merge 대응)
#   3) GitHub PR이 MERGED 상태             — auto-delete 미동작 케이스 대응 (gh CLI 필요)
#
# 3번 검사는 gh CLI가 설치 + 인증되어 있을 때만 동작합니다.
# gh가 없거나 인증 안 되어 있으면 경고 후 1)+2)로만 동작합니다.

set -euo pipefail

if (( ${BASH_VERSINFO[0]:-0} < 4 )); then
  echo "❌ 이 스크립트는 Bash 4 이상이 필요합니다. 현재: ${BASH_VERSION:-unknown}" >&2
  echo "   macOS 기본 /bin/bash(3.2)에서는 동작하지 않습니다. 최신 bash로 다시 실행하세요." >&2
  exit 1
fi

source "$(dirname "${BASH_SOURCE[0]}")/_config.sh"

PROTECTED_BRANCHES=$(echo "main master develop $DEFAULT_BRANCH" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//')

# --exclude 패턴 누적 (bash glob 문법: *, ?, [abc] 지원)
EXCLUDE_PATTERNS=()

print_usage() {
  cat <<'USAGE'
Usage: ./scripts/cleanup-merged.sh [--exclude <pattern>]...

Options:
  --exclude <pattern>   삭제 대상에서 제외할 브랜치명 패턴.
                        bash glob(*, ?, [...])을 지원하며 여러 번 사용 가능.
                        예:
                          --exclude feat/keep-this        (정확 일치)
                          --exclude 'feat/wip-*'          (prefix 매칭)
                          --exclude 'data/*'              (data 브랜치 전부 제외)
  -h, --help            이 메시지를 표시하고 종료
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --exclude)
      if [[ -z "${2:-}" ]]; then
        echo "❌ --exclude는 패턴 인자가 필요합니다." >&2
        print_usage >&2
        exit 1
      fi
      EXCLUDE_PATTERNS+=("$2")
      shift 2
      ;;
    --exclude=*)
      EXCLUDE_PATTERNS+=("${1#*=}")
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "❌ 알 수 없는 인자: $1" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done

# DEFAULT_BRANCH 최신화 (로컬 미존재 시 origin에서 추적 브랜치 생성)
echo "🔍 $DEFAULT_BRANCH 브랜치 최신화 중..."
if git show-ref --verify --quiet "refs/heads/$DEFAULT_BRANCH"; then
  git checkout "$DEFAULT_BRANCH"
elif git show-ref --verify --quiet "refs/remotes/origin/$DEFAULT_BRANCH"; then
  echo "   로컬에 $DEFAULT_BRANCH 브랜치가 없어 원격에서 추적 브랜치를 생성합니다..."
  git checkout -b "$DEFAULT_BRANCH" --track "origin/$DEFAULT_BRANCH"
else
  echo "❌ 로컬 브랜치 '$DEFAULT_BRANCH'이 없고 origin/$DEFAULT_BRANCH도 찾을 수 없습니다." >&2
  echo "   원격 저장소를 fetch 했는지, .kit-config의 DEFAULT_BRANCH 설정이 올바른지 확인하세요." >&2
  exit 1
fi
git pull --ff-only

echo "🔍 원격 추적 정보 정리 중 (git fetch -p)..."
git fetch -p

# 보호 브랜치 목록을 newline-separated로 (grep -F 입력용)
PROTECTED_LINES=$(echo "$PROTECTED_BRANCHES" | tr ' ' '\n')

# 1) 머지된 로컬 브랜치
MERGED=$(git branch --merged "$DEFAULT_BRANCH" \
  | sed 's/^[ *]*//' \
  | grep -v -x -F "$PROTECTED_LINES" \
  || true)

# 2) 원격에서 삭제된 브랜치를 추적하던 로컬 브랜치 (squash merge 대응)
GONE=$(git branch -vv \
  | awk '/: gone\]/{print $1}' \
  | grep -v -x -F "$PROTECTED_LINES" \
  || true)

# gh 인증 상태 + PR 캐시 (스크립트 레벨 1회 선언)
# PR_MERGED_CACHE는 is_pr_merged_for_branch()와 detect_reason() 간 공유되며,
# 재선언 시 리셋되므로 반드시 한 번만 declare 한다.
GH_AVAILABLE=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GH_AVAILABLE=1
fi

declare -A PR_MERGED_CACHE

# is_pr_merged_for_branch <branch>
#   종료 코드: 0 = 머지됨, 1 = 머지 아님 / gh 미사용 / 확인 불가
#   부수 효과: PR_MERGED_CACHE[branch] = "yes" | "no"
#
# PR의 headRefOid와 로컬 브랜치의 HEAD SHA가 정확히 일치해야 머지로 인정.
# 브랜치명 재사용(1차 merged 후 같은 이름으로 새 브랜치) 시 오탐을 차단한다.
is_pr_merged_for_branch() {
  local branch="$1"

  if [[ -n "${PR_MERGED_CACHE[$branch]+x}" ]]; then
    [[ "${PR_MERGED_CACHE[$branch]}" == "yes" ]]
    return
  fi

  if [[ "$GH_AVAILABLE" -ne 1 ]]; then
    PR_MERGED_CACHE[$branch]="no"
    return 1
  fi

  local pr_head_sha
  pr_head_sha=$(gh pr list --head "$branch" --state merged --limit 1 \
      --json headRefOid --jq '.[0].headRefOid // empty' 2>/dev/null || true)

  if [[ -z "$pr_head_sha" ]]; then
    PR_MERGED_CACHE[$branch]="no"
    return 1
  fi

  local branch_head
  branch_head=$(git rev-parse "$branch" 2>/dev/null || true)

  if [[ -n "$branch_head" && "$branch_head" == "$pr_head_sha" ]]; then
    PR_MERGED_CACHE[$branch]="yes"
    return 0
  fi

  PR_MERGED_CACHE[$branch]="no"
  return 1
}

# 3) GitHub PR이 MERGED 상태인 로컬 브랜치 (auto-delete 미동작 대응)
#    시그널 1/2에서 이미 검출된 브랜치는 제외(UNCHECKED)하고 per-branch 역방향 조회.
#    `gh pr list --state merged --limit N` 풀 스캔은 N 초과 시 누락되지만,
#    `--head <branch>`는 브랜치당 독립 조회라 누락이 없고 헤드 SHA까지 확보된다.
PR_MERGED=""

if [[ "$GH_AVAILABLE" -eq 1 ]]; then
  # comm -23은 양쪽 입력이 정렬되어 있어야 올바른 차집합을 반환한다 → sort -u 필수
  ALREADY_DETECTED=$(printf "%s\n%s" "$MERGED" "$GONE" | sort -u | sed '/^$/d')

  LOCAL_BRANCHES=$(git for-each-ref --format='%(refname:short)' refs/heads/ \
    | grep -v -x -F "$PROTECTED_LINES" \
    | sort -u || true)

  if [[ -n "$ALREADY_DETECTED" ]]; then
    UNCHECKED=$(comm -23 \
      <(printf '%s\n' "$LOCAL_BRANCHES") \
      <(printf '%s\n' "$ALREADY_DETECTED") \
      | sed '/^$/d' || true)
  else
    UNCHECKED="$LOCAL_BRANCHES"
  fi

  if [[ -n "$UNCHECKED" ]]; then
    echo "🔍 GitHub PR 상태 확인 중 (gh)..."
    while IFS= read -r branch; do
      [[ -z "$branch" ]] && continue
      if is_pr_merged_for_branch "$branch"; then
        PR_MERGED+="$branch"$'\n'
      fi
    done <<< "$UNCHECKED"
  fi
else
  echo "⚠️  gh CLI 미설치 또는 미인증 — PR 상태 검사를 건너뜁니다."
  echo "   (gh CLI를 설치하면 auto-delete가 동작하지 않은 머지된 브랜치도 정리됩니다)"
fi

# 합치고 중복 제거
ALL_TO_DELETE=$(printf "%s\n%s\n%s\n" "$MERGED" "$GONE" "$PR_MERGED" | sort -u | sed '/^$/d')

# --exclude 패턴 적용 (bash glob 매칭)
EXCLUDED_BRANCHES=""
if [[ ${#EXCLUDE_PATTERNS[@]} -gt 0 && -n "$ALL_TO_DELETE" ]]; then
  FILTERED=""
  while IFS= read -r b; do
    [[ -z "$b" ]] && continue
    matched=0
    for pat in "${EXCLUDE_PATTERNS[@]}"; do
      # bash 내장 glob 매칭 — $pat은 인용하지 않아야 패턴으로 해석됨
      # shellcheck disable=SC2053
      if [[ "$b" == $pat ]]; then
        matched=1
        break
      fi
    done
    if [[ $matched -eq 1 ]]; then
      EXCLUDED_BRANCHES+="$b"$'\n'
    else
      FILTERED+="$b"$'\n'
    fi
  done <<< "$ALL_TO_DELETE"
  ALL_TO_DELETE=$(printf '%s' "$FILTERED" | sed '/^$/d')
fi

if [[ -z "$ALL_TO_DELETE" ]]; then
  if [[ -n "$EXCLUDED_BRANCHES" ]]; then
    echo "✅ --exclude로 모든 후보가 제외되어 삭제할 브랜치가 없습니다."
    echo "   제외됨:"
    printf '%s' "$EXCLUDED_BRANCHES" | sed '/^$/d' | sed 's/^/     ⏭  /'
  else
    echo "✅ 정리할 머지된 브랜치가 없습니다."
  fi
  exit 0
fi

# 각 브랜치의 검출 사유를 inline으로 표시 — 사용자가 y/N 결정 직전에
# "왜 이 브랜치가 검출됐는지" 즉시 파악할 수 있도록.
# 한 브랜치가 여러 신호에 매칭될 수 있으므로 우선순위를 정해 한 줄에
# 가장 구체적인 사유 하나만 표기 (실제 삭제 분기 로직과 동일 우선순위).
detect_reason() {
  local branch="$1"
  if printf '%s\n' "$MERGED" | grep -Fxq -- "$branch"; then
    echo "merged"
  elif printf '%s\n' "$PR_MERGED" | grep -Fxq -- "$branch"; then
    # 삭제 단계에서 `git push origin --delete`로 원격도 정리 필요.
    echo "PR merged on GitHub — origin still alive"
  elif printf '%s\n' "$GONE" | grep -Fxq -- "$branch"; then
    # GONE 브랜치는 원격 사라짐만으론 머지 여부를 알 수 없다.
    # headRefOid 일치 확인으로 실제 머지/미머지를 구분 (오탐 차단).
    if is_pr_merged_for_branch "$branch"; then
      echo "PR merged on GitHub — origin already gone"
    else
      echo "⚠️  gone from remote (PR not merged)"
    fi
  else
    echo "gone from remote"
  fi
}

# 가장 긴 브랜치명 폭에 맞춰 컬럼 정렬
MAX_W=0
while IFS= read -r b; do
  [[ -z "$b" ]] && continue
  [[ ${#b} -gt $MAX_W ]] && MAX_W=${#b}
done <<< "$ALL_TO_DELETE"
COL_W=$((MAX_W + 4))

echo ""
echo "다음 브랜치들이 삭제됩니다:"
while IFS= read -r b; do
  [[ -z "$b" ]] && continue
  printf "  %-${COL_W}s(%s)\n" "$b" "$(detect_reason "$b")"
done <<< "$ALL_TO_DELETE"

if [[ -n "$EXCLUDED_BRANCHES" ]]; then
  echo ""
  echo "⏭  --exclude로 제외됨:"
  printf '%s' "$EXCLUDED_BRANCHES" | sed '/^$/d' | sed 's/^/     /'
fi

echo ""
read -r -p "진행하시겠습니까? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
  echo "취소되었습니다."
  exit 0
fi

echo ""
# 검사 종류별로 분기:
#   - MERGED:    -d 시도 후 실패 시 -D (안전 우선)
#   - PR_MERGED: 원격 브랜치도 함께 삭제(auto-delete 미동작 보정) + 로컬 -D
#   - GONE:      원격 추적이 이미 사라짐, -D 강제 삭제
while IFS= read -r BRANCH; do
  [[ -z "$BRANCH" ]] && continue

  if printf '%s\n' "$MERGED" | grep -Fxq -- "$BRANCH"; then
    if git branch -d "$BRANCH" 2>/dev/null; then
      echo "✅ $BRANCH 삭제 완료 (merged)"
    else
      git branch -D "$BRANCH"
      echo "✅ $BRANCH 삭제 완료 (forced)"
    fi
  elif printf '%s\n' "$PR_MERGED" | grep -Fxq -- "$BRANCH"; then
    # 원격 브랜치 정리 (실패해도 로컬 삭제는 계속 진행)
    if git push origin --delete "$BRANCH" >/dev/null 2>&1; then
      echo "   🌐 원격 브랜치도 삭제: origin/$BRANCH"
    fi
    git branch -D "$BRANCH"
    echo "✅ $BRANCH 삭제 완료 (PR merged on GitHub)"
  else
    git branch -D "$BRANCH"
    echo "✅ $BRANCH 삭제 완료 (gone from remote)"
  fi
done <<< "$ALL_TO_DELETE"

echo ""
echo "🎉 정리 완료."
