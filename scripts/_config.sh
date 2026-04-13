#!/usr/bin/env bash
# _config.sh — 내부 헬퍼. 직접 실행하지 않음.
# 다른 스크립트에서 source하여 .kit-config 설정을 로드한다.

_KIT_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_KIT_CONFIG_FILE="${_KIT_CONFIG_DIR}/.kit-config"

if [[ -f "$_KIT_CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$_KIT_CONFIG_FILE"
fi

DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
