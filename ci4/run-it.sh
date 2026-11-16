#!/usr/bin/env bash
# Runs one integration test on this desktop and keeps its log:
#   run-it.sh <name> <device> <test file> [flutter test args...]
# The DETBUNDLED / DETCOEX lines and the result go to the job summary. Linux
# runs headless under xvfb-run. Exit status: the test's.
set -u
name=$1 device=$2 file=$3
shift 3
log=${RUNNER_TEMP:-/tmp}/it-$name.log
cmd=(flutter test "$file" -d "$device" "$@")
if [ "$device" = linux ]; then
  cmd=(xvfb-run -a -s '-screen 0 1280x1024x24' "${cmd[@]}")
fi
echo "+ ${cmd[*]}"
start=$(date +%s)
"${cmd[@]}" >"$log" 2>&1
rc=$?
secs=$(( $(date +%s) - start ))
# The whole log in the job log (it is the evidence), the key lines again at the end.
cat "$log"
echo "=== $name: exit $rc after ${secs}s ==="
grep -E 'DETBUNDLED|DETCOEX|LiteRt|LiteRT|Detector\]|Exception|Error|error:|FAILED|All tests passed|Some tests failed' "$log" |
  grep -v '^\s*$' | tail -n 80 | sed "s/^/[$name] /"
{
  echo "### $name: exit $rc (${secs}s)"
  echo '```'
  grep -E 'DETBUNDLED|DETCOEX' "$log" | cut -c1-400
  [ $rc -ne 0 ] && tail -n 25 "$log" | cut -c1-300
  echo '```'
} >>"${GITHUB_STEP_SUMMARY:-/dev/null}"
exit $rc
