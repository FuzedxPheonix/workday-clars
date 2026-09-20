#!/usr/bin/env bash
# Usage: ./unpack_clar.sh starter-kits/<kit-name>
# Unzips the kit's .clar export into <kit>/src so Git can diff readable files.
set -euo pipefail

kit="${1:?Usage: $0 <kit-folder>}"

shopt -s nullglob
clars=("$kit"/*.clar)
if [ "${#clars[@]}" -ne 1 ]; then
  echo "Expected exactly one .clar in $kit, found ${#clars[@]}" >&2
  exit 1
fi
clar="${clars[0]}"

unzip -tq "$clar" >/dev/null   # fail early if the archive is corrupt

rm -rf "$kit/src"
mkdir -p "$kit/src"
unzip -q "$clar" -d "$kit/src"

echo "Unpacked $clar -> $kit/src"
echo "Review src/ for tenant URLs, IDs, or credentials before committing."
