#!/usr/bin/env bash

set -euo pipefail

MODE="soft"

if [[ "${1:-}" == "--full" ]]; then
  MODE="full"
elif [[ -n "${1:-}" ]]; then
  echo "Usage: ./reset-local.sh [--full]"
  exit 1
fi

remove_path() {
  local path="$1"

  if [[ -e "$path" ]]; then
    rm -rf "$path"
    echo "removed $path"
  else
    echo "skip $path (not found)"
  fi
}

echo "Reset mode: $MODE"

# These files contain local addresses that become stale after restarting anvil.
remove_path "deployments"

if [[ "$MODE" == "full" ]]; then
  # Full reset also removes previous script artifacts and compiled outputs.
  remove_path "broadcast"
  remove_path "cache"
  remove_path "out"
fi

echo "Local reset complete."
