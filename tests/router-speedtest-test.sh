#!/bin/sh
# Validate speedtest concurrency fix: start one in bg, fire a second; the second
# must skip cleanly via flock. Then let the first finish and show results.
rm -f /tmp/st1.log
podkop-sub2urltest speedtest main >/tmp/st1.log 2>&1 &
BG=$!
sleep 3
echo "=== SECOND (concurrent) — expect 'already running, skipping' ==="
podkop-sub2urltest speedtest main 2>&1 | head -3
echo "=== waiting for first to finish (pid $BG) ==="
wait "$BG"
echo "=== FIRST result tail ==="
tail -20 /tmp/st1.log
echo "=== NODES_AFTER=$(uci -q get podkop.main.urltest_proxy_links | wc -w) ==="
