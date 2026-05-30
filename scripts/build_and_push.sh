#!/usr/bin/env bash
# build_and_push.sh - Build a factored OCI image with bv-builder, push to
# GHCR, and update the matching manifest's [tool.factored] block with the
# resulting digest.
#
# Usage:
#   scripts/build_and_push.sh <spec_path>
#   scripts/build_and_push.sh specs/cutadapt/4.9.toml
#
# Env vars:
#   BV_BUILDER       path to bv-builder binary (default: looks in PATH and
#                    in the sibling bv/ checkout's target/release/)
#   GHCR_OWNER       GHCR namespace (default: tejasprabhune)
#   GHCR_REPO_PREFIX repo prefix (default: bv-pkg)
#   MAX_LAYERS       passed to `bv-builder build --max-layers`. 0 disables
#                    popularity-based packing (default: 0)
#   POPULARITY_FILE  optional popularity.json from `bv-builder pack`
#
# Notes:
# - The script overwrites [tool.factored] in the matching manifest. If the
#   block is absent, it is appended.
# - Skips the build if the image already exists on GHCR with a recorded
#   digest in the manifest. Use FORCE=1 to rebuild.

set -euo pipefail

SPEC="${1:?spec_path required}"
[ -f "${SPEC}" ] || { echo "spec not found: ${SPEC}" >&2; exit 1; }

GHCR_OWNER="${GHCR_OWNER:-tejasprabhune}"
GHCR_REPO_PREFIX="${GHCR_REPO_PREFIX:-bv-pkg}"
MAX_LAYERS="${MAX_LAYERS:-0}"

BV_BUILDER="${BV_BUILDER:-}"
if [ -z "${BV_BUILDER}" ]; then
    if command -v bv-builder >/dev/null 2>&1; then
        BV_BUILDER="$(command -v bv-builder)"
    else
        # Look for sibling checkout
        for cand in "$(dirname "$0")/../../bv/target/release/bv-builder" \
                    "$(dirname "$0")/../../bv-builder/target/release/bv-builder"; do
            if [ -x "${cand}" ]; then BV_BUILDER="${cand}"; break; fi
        done
    fi
fi
[ -x "${BV_BUILDER}" ] || { echo "bv-builder not found; set BV_BUILDER=" >&2; exit 1; }

# Pull name + version from the spec
NAME=$(awk -F'"' '/^name *= /{print $2; exit}' "${SPEC}")
VERSION=$(awk -F'"' '/^version *= /{print $2; exit}' "${SPEC}")
[ -n "${NAME}" ] && [ -n "${VERSION}" ] || {
    echo "could not parse name/version from ${SPEC}" >&2; exit 1
}

REGISTRY_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${REGISTRY_ROOT}/tools/${NAME}/${VERSION}.toml"
[ -f "${MANIFEST}" ] || { echo "manifest not found: ${MANIFEST}" >&2; exit 1; }

REF="ghcr.io/${GHCR_OWNER}/${GHCR_REPO_PREFIX}/${NAME}:${VERSION}"
TARBALL="$(mktemp -d)/${NAME}-${VERSION}.tar"

# Skip if already built and recorded
if [ -z "${FORCE:-}" ] && grep -q "image_digest = \"sha256:" "${MANIFEST}" \
       && grep -q "image_reference = \"${REF}\"" "${MANIFEST}"; then
    echo "  skip ${NAME} ${VERSION}: already built (FORCE=1 to rebuild)"
    exit 0
fi

retry() {
    local attempts="${1}"; shift
    local delay=10
    local i=1
    while true; do
        if "$@"; then return 0; fi
        if [ "${i}" -ge "${attempts}" ]; then
            echo "    failed after ${attempts} attempts" >&2
            return 1
        fi
        echo "    attempt ${i}/${attempts} failed, retrying in ${delay}s..." >&2
        sleep "${delay}"
        i=$((i + 1))
        delay=$((delay * 2))
    done
}

echo "==> ${NAME} ${VERSION}: building"
if [ -n "${POPULARITY_FILE:-}" ]; then
    retry 3 "${BV_BUILDER}" build "${SPEC}" \
        --output "${TARBALL}" \
        --max-layers "${MAX_LAYERS}" \
        --popularity "${POPULARITY_FILE}"
else
    retry 3 "${BV_BUILDER}" build "${SPEC}" \
        --output "${TARBALL}" \
        --max-layers "${MAX_LAYERS}"
fi

echo "==> ${NAME} ${VERSION}: pushing to ${REF}"
retry 3 "${BV_BUILDER}" push "${TARBALL}" "${REF}"
DIGEST=$(cat /tmp/push-digest.txt)
echo "==> ${NAME} ${VERSION}: digest ${DIGEST}"

# Splice [tool.factored] into the manifest
python3 - <<PY
import re
from pathlib import Path

p = Path("${MANIFEST}")
s = p.read_text()
spec_rel = "specs/${NAME}/${VERSION}.toml"

block = f"""
[tool.factored]
spec_path = "{spec_rel}"
image_reference = "${REF}"
image_digest = "${DIGEST}"
"""

if re.search(r'^\[tool\.factored\]', s, re.MULTILINE):
    s = re.sub(
        r'\[tool\.factored\][\s\S]*?(?=\n\[|\Z)',
        block.lstrip() + '\n',
        s, count=1, flags=re.MULTILINE,
    )
else:
    s = s.rstrip() + "\n" + block

p.write_text(s)
print(f"  updated {p}")
PY

rm -rf "$(dirname "${TARBALL}")"
