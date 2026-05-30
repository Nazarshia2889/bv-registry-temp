#!/usr/bin/env bash
# build_all.sh - Walk every spec and build/push it via build_and_push.sh.
#
# Usage:
#   scripts/build_all.sh [filter_glob]
#   scripts/build_all.sh             # all specs
#   scripts/build_all.sh "samtools*" # only specs matching the glob
#
# Set FORCE=1 to rebuild already-locked images. Set CONCURRENCY=N to
# parallelize (default: 4); each builder downloads its own conda packages so
# the bottleneck is bandwidth.

set -euo pipefail

FILTER="${1:-*}"
CONCURRENCY="${CONCURRENCY:-4}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="${ROOT}/build_logs"
mkdir -p "${LOG_DIR}"

SPECS=()
while IFS= read -r -d '' f; do SPECS+=("${f}"); done < <(
    find "${ROOT}/specs" -type f -name '*.toml' -path "*${FILTER}*" -print0
)

echo "  ${#SPECS[@]} specs match filter '${FILTER}'"

build_one() {
    local spec="$1"
    local rel="${spec#${ROOT}/}"
    local log="${LOG_DIR}/$(echo "${rel}" | tr '/' '_').log"
    if "${ROOT}/scripts/build_and_push.sh" "${spec}" \
           > "${log}" 2>&1; then
        echo "  OK  ${rel}"
    else
        echo "  ERR ${rel}  (see ${log})"
    fi
}
export -f build_one
export ROOT LOG_DIR

printf '%s\n' "${SPECS[@]}" \
  | xargs -n 1 -P "${CONCURRENCY}" -I {} bash -c 'build_one "$@"' _ {}

echo "  done. logs in ${LOG_DIR}/"
