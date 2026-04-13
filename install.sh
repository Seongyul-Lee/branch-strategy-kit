#!/usr/bin/env bash
# install.sh — 킷 파일을 대상 repo(pwd)에 일괄 복사하는 스크립트
#
# Usage:
#   cd <your-team-repo>
#   ~/branch-strategy-kit/install.sh              # 일반 실행
#   ~/branch-strategy-kit/install.sh --dry-run    # 복사 없이 목록만 출력
#   ~/branch-strategy-kit/install.sh -h|--help    # 사용법 출력
#
# 킷 repo에 속하는 스크립트. 대상 repo에 복사되는 자산이 아님.
# _config.sh 등 킷 내부 헬퍼에 의존하지 않음 — 독립 실행.

set -euo pipefail

# bash 4+ 확인
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  echo "❌ bash 4 이상이 필요합니다. 현재: ${BASH_VERSION}" >&2
  exit 1
fi

# ── 킷 루트 경로 자동 탐지 ──────────────────────────────────
KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 복사 대상 파일 목록 ─────────────────────────────────────
# 파일 추가/삭제 시 이 배열만 수정.
# 디렉터리는 후행 슬래시(/)로 표시 — 재귀 복사 대상.
COPY_FILES=(
  .github/workflows/branch-name-check.yml
  .github/workflows/pr-title-check.yml
  .github/workflows/stale-branches.yml
  .github/pull_request_template.md
  .kit-config
  .gitattributes
  lefthook.yml
  scripts/
)

# ── 플래그 파싱 ──────────────────────────────────────────────
DRY_RUN=0

print_usage() {
  cat <<'USAGE'
Usage: ~/branch-strategy-kit/install.sh [--dry-run | -h | --help]

  대상 repo 디렉터리에서 실행하세요 (인자로 경로를 받지 않습니다).

  --dry-run   실제 복사 없이 복사될 파일 목록만 출력
  -h, --help  이 도움말 출력
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "❌ 알 수 없는 인자: $arg" >&2
      echo "" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done

# ── 대상 디렉터리 검증 ──────────────────────────────────────
TARGET_DIR="$(pwd)"

# git repo인지 확인
if ! git -C "$TARGET_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ 현재 디렉터리가 git 저장소가 아닙니다: $TARGET_DIR" >&2
  echo "   대상 repo로 이동한 후 재실행하세요:" >&2
  echo "   cd <your-team-repo> && ~/branch-strategy-kit/install.sh" >&2
  exit 1
fi

# 킷 자체에 설치하려는 경우 방지
KIT_REAL="$(cd "$KIT_ROOT" && pwd -P)"
TARGET_REAL="$(cd "$TARGET_DIR" && pwd -P)"
if [[ "$KIT_REAL" == "$TARGET_REAL" ]]; then
  echo "❌ 킷 디렉터리 자체에는 설치할 수 없습니다." >&2
  echo "   대상 repo로 이동한 후 재실행하세요:" >&2
  echo "   cd <your-team-repo> && ~/branch-strategy-kit/install.sh" >&2
  exit 1
fi

# ── 킷 버전 표시 ────────────────────────────────────────────
KIT_VERSION="unknown"
if [[ -f "$KIT_ROOT/VERSION" ]]; then
  KIT_VERSION="$(cat "$KIT_ROOT/VERSION" | tr -d '[:space:]')"
fi

echo ""
echo "🔧 Branch Strategy Kit v${KIT_VERSION}"
echo "   킷 경로: $KIT_ROOT"
echo "   대상 경로: $TARGET_DIR"
echo ""

# ── dry-run 모드 ─────────────────────────────────────────────
if [[ $DRY_RUN -eq 1 ]]; then
  echo "📋 복사될 파일 목록 (--dry-run):"
  echo ""
  for item in "${COPY_FILES[@]}"; do
    if [[ "$item" == */ ]]; then
      # 디렉터리: 하위 파일 나열
      while IFS= read -r -d '' f; do
        rel="${f#"$KIT_ROOT/"}"
        if [[ -f "$TARGET_DIR/$rel" ]]; then
          echo "  [덮어쓰기] $rel"
        else
          echo "  [신규]     $rel"
        fi
      done < <(find "$KIT_ROOT/$item" -type f -print0 2>/dev/null)
    else
      if [[ -f "$TARGET_DIR/$item" ]]; then
        echo "  [덮어쓰기] $item"
      else
        echo "  [신규]     $item"
      fi
    fi
  done
  echo ""
  echo "실제 복사하려면 --dry-run 없이 다시 실행하세요."
  exit 0
fi

# ── 경로 확인 사용자 승인 ────────────────────────────────────
echo "복사 대상 경로: $TARGET_DIR"
printf '키트를 적용하실 경로가 맞습니까? [y/N]: '

if [[ -t 0 ]]; then
  read -r CONFIRM
else
  echo ""
  echo "❌ 인터랙티브 모드에서만 실행할 수 있습니다 (TTY 필요)." >&2
  exit 1
fi

if [[ "${CONFIRM,,}" != "y" ]]; then
  echo ""
  echo "키트를 적용하실 경로로 이동한 후 재실행:"
  echo "  cd <your-team-repo> && ~/branch-strategy-kit/install.sh"
  exit 0
fi

echo ""

# ── 복사 실행 ────────────────────────────────────────────────
COPIED=0
SKIPPED=0
OVERWRITTEN=0

copy_single_file() {
  local src="$1"
  local rel="$2"
  local dst="$TARGET_DIR/$rel"

  # 디렉터리 생성
  mkdir -p "$(dirname "$dst")"

  if [[ -f "$dst" ]]; then
    # 기존 파일 존재 — diff 확인
    if diff -q "$src" "$dst" >/dev/null 2>&1; then
      echo "  ⏭️  $rel (동일 — 건너뜀)"
      SKIPPED=$((SKIPPED + 1))
      return
    fi

    echo "  ⚠️  $rel — 기존 파일과 다릅니다:"
    diff --unified=3 "$dst" "$src" | head -20 || true
    echo ""
    printf "  v${KIT_VERSION}으로 업데이트하려면 덮어쓰기가 필요합니다. 덮어쓸까요? [y/N]: "
    local answer
    read -r answer
    if [[ "${answer,,}" != "y" ]]; then
      echo "  ⏭️  $rel (건너뜀)"
      SKIPPED=$((SKIPPED + 1))
      return
    fi
    cp "$src" "$dst"
    echo "  ✅ $rel (덮어쓰기)"
    OVERWRITTEN=$((OVERWRITTEN + 1))
  else
    cp "$src" "$dst"
    echo "  ✅ $rel (신규)"
    COPIED=$((COPIED + 1))
  fi
}

echo "📦 파일 복사 시작..."
echo ""

for item in "${COPY_FILES[@]}"; do
  if [[ "$item" == */ ]]; then
    # 디렉터리 재귀 복사
    while IFS= read -r -d '' f; do
      rel="${f#"$KIT_ROOT/"}"
      copy_single_file "$f" "$rel"
    done < <(find "$KIT_ROOT/$item" -type f -print0 2>/dev/null)
  else
    if [[ ! -f "$KIT_ROOT/$item" ]]; then
      echo "  ⚠️  $item — 킷에 파일이 없습니다 (건너뜀)"
      continue
    fi
    copy_single_file "$KIT_ROOT/$item" "$item"
  fi
done

# ── 실행 권한 설정 ───────────────────────────────────────────
if [[ -d "$TARGET_DIR/scripts" ]]; then
  chmod +x "$TARGET_DIR/scripts/"*.sh 2>/dev/null || true
  echo ""
  echo "🔑 scripts/*.sh 실행 권한 설정 완료"
fi

# ── 결과 요약 ────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 결과 요약"
echo "   신규 복사: ${COPIED}개"
echo "   덮어쓰기: ${OVERWRITTEN}개"
echo "   건너뜀:   ${SKIPPED}개"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 다음 단계 안내 ───────────────────────────────────────────
echo ""
echo "📌 다음 단계:"
echo "   1. git add → commit → push → PR"
echo "   2. ./scripts/bootstrap.sh 실행 (lefthook + alias 등록)"
echo ""
