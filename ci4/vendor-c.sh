#!/usr/bin/env bash
# Variant C: flutter_litert 4.0.0 from pub.dev with only the CMake half of the
# sample's 3.9.3 patch re-applied (flutter_litert bundles and downloads no LiteRT
# runtime, WebGPU accelerator or DXC on Linux and Windows). The Dart code is
# 4.0.0 as published. Run from the sample folder after variant-b.patch.
set -eu
VERSION=4.0.0
here=$(cd "$(dirname "$0")" && pwd)
dart pub cache add flutter_litert --version "$VERSION"
if [ -n "${PUB_CACHE:-}" ]; then
  pc=$PUB_CACHE
elif [ ! -d "$HOME/.pub-cache" ] && [ -n "${LOCALAPPDATA:-}" ]; then
  pc=$(cygpath -u "$LOCALAPPDATA" 2>/dev/null || printf '%s' "$LOCALAPPDATA")/Pub/Cache
else
  pc=$HOME/.pub-cache
fi
src=$pc/hosted/pub.dev/flutter_litert-$VERSION
[ -d "$src" ] || { echo "error: $src not found" >&2; exit 1; }
rm -rf third_party/flutter_litert
mkdir -p third_party/flutter_litert
(cd "$src" && tar cf - --exclude ./example --exclude ./windows/libLiteRt.dll .) |
  (cd third_party/flutter_litert && tar xf -)
python "$here/c_cmake.py" third_party/flutter_litert
python - <<'EOF'
p = 'pubspec.yaml'
s = open(p).read()
anchor = 'flutter:\n  uses-material-design'
block = ('dependency_overrides:\n'
         '  # ci4 variant C: flutter_litert 4.0.0 with no own LiteRT runtime on\n'
         '  # Linux and Windows (ci4/vendor-c.sh in hugocornellier/flutter_litert ci/sasha-sample-litert4).\n'
         '  flutter_litert:\n'
         '    path: third_party/flutter_litert\n\n')
assert anchor in s and 'dependency_overrides' not in s
s = s.replace(anchor, block + anchor, 1)
open(p, 'w').write(s)
EOF
echo "third_party/flutter_litert: flutter_litert $VERSION, CMake without the LiteRT runtime"
git diff --no-index "$src/linux/CMakeLists.txt" third_party/flutter_litert/linux/CMakeLists.txt || true
git diff --no-index "$src/windows/CMakeLists.txt" third_party/flutter_litert/windows/CMakeLists.txt || true
