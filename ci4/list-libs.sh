#!/usr/bin/env bash
# Lists every LiteRT / TFLite / accelerator / DXC / vcruntime native library under the given
# directories: size, SHA-256 and path, and on Linux the SONAME, NEEDED and
# RUNPATH entries, so each file in a bundle can be traced to the package it
# came from (same size and hash as the copy in that package's cache).
#
#   list-libs.sh <label> <dir>...
set -u
label=$1
shift
echo "=== LIBS $label ==="
for dir in "$@"; do
  [ -e "$dir" ] || { echo "--- $dir (absent)"; continue; }
  echo "--- $dir"
  find "$dir" \( -path '*/assets/models' -o -path '*/.git' \) -prune -o -type f \
    \( -iname '*litert*' -o -iname '*Accelerator*' -o -iname 'libtensorflowlite*' \
       -o -iname 'dxcompiler*' -o -iname 'dxil*' -o -iname 'vcruntime*' \) \
    \( -iname '*.so' -o -iname '*.so.*' -o -iname '*.dll' -o -iname '*.dylib' \) -print 2>/dev/null |
    sort | while IFS= read -r f; do
      size=$(wc -c <"$f" | tr -d ' ')
      sha=$(sha256sum "$f" 2>/dev/null | awk '{print $1}')
      [ -n "$sha" ] || sha=$(shasum -a 256 "$f" | awk '{print $1}')
      printf 'LIB %-10s %12s %s %s\n' "$label" "$size" "$sha" "$f"
      if command -v readelf >/dev/null 2>&1 && head -c 4 "$f" | grep -q 'ELF'; then
        arch=$(readelf -h "$f" 2>/dev/null | sed -n 's/^ *Machine: *//p')
        echo "      machine: $arch"
        readelf -d "$f" 2>/dev/null | grep -E 'SONAME|NEEDED|RUNPATH|RPATH' | sed 's/^/      /'
      fi
    done
done
