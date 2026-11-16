#!/usr/bin/env bash
# Probes Qualcomm's QAIRT 2.50 download (flutter_edge_ai_litertlm's qualcomm_npu hook
# fetches it on Linux arm64) from this runner: 3 ranged GETs (bytes 0-1023) a few seconds
# apart, one HEAD and one plain GET cut after 1 KB, each with its HTTP status, Content-Range and, on failure, the
# <Code> of the error body; then the runner's egress country and org. Never fails.
#   qairt-probe.sh <label>
set +e +o pipefail
label=${1:-probe}
url=https://softwarecenter.qualcomm.com/api/download/software/sdks/Qualcomm_AI_Runtime_Community/All/2.50.0.260828/v2.50.0.260828.zip
t=$(mktemp -d)
for i in 1 2 3; do
  code=$(curl -sS -L --max-time 60 -r 0-1023 -D "$t/h$i" -o "$t/b$i" -w '%{http_code}' "$url")
  cr=$(grep -i '^content-range:' "$t/h$i" | tail -1 | tr -d '\r' | cut -d' ' -f2-)
  err=""
  case "$code" in 2*) ;; *) err=$(grep -o '<Code>[^<]*</Code>' "$t/b$i" | head -1); [ -n "$err" ] || err="body: $(head -c 200 "$t/b$i" | tr -d '\r\n')";; esac
  echo "QAIRT_PROBE $label ranged_get attempt=$i at=$(date -u +%H:%M:%SZ) status=$code content_range=${cr:-none} bytes=$(wc -c <"$t/b$i" | tr -d ' ') $err"
  [ $i -lt 3 ] && sleep 5
done
code=$(curl -sS -L -I --max-time 60 -D "$t/hh" -o /dev/null -w '%{http_code}' "$url")
echo "QAIRT_PROBE $label head at=$(date -u +%H:%M:%SZ) status=$code"
# A plain GET, as a downloader without Range sends it; cut after 1 KB (the status is in the headers).
curl -sS -L --max-time 60 -D "$t/hg" -o - "$url" 2>/dev/null | head -c 1024 > "$t/bg"
code=$(grep -E '^HTTP/' "$t/hg" | tail -1 | awk '{print $2}')
err=""; case "$code" in 2*) ;; *) err=$(grep -o '<Code>[^<]*</Code>' "$t/bg" | head -1);; esac
echo "QAIRT_PROBE $label plain_get at=$(date -u +%H:%M:%SZ) status=${code:-none} content_length=$(grep -i '^content-length:' "$t/hg" | tail -1 | tr -d '\r' | cut -d' ' -f2) $err"
grep -hiE '^(HTTP/|server:|x-amz-cf-pop:|x-cache:)' "$t/h1" "$t/hh" "$t/hg" | tr -d '\r' | sed "s/^/QAIRT_HDR $label /"
info=$(curl -sS --max-time 20 https://ipinfo.io/json)
echo "EGRESS $label country=$(printf '%s' "$info" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("country"))' 2>/dev/null) org=\"$(printf '%s' "$info" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("org"))' 2>/dev/null)\" region=$(printf '%s' "$info" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("region"))' 2>/dev/null)"
rm -rf "$t"
exit 0
