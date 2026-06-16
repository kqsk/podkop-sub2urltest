#!/bin/sh
# Throwaway router diagnostics. Prints node/outbound counts and sing-box health.
# No secrets printed.
CFG="$(uci -q get podkop.settings.config_path)"
[ -n "$CFG" ] || CFG=/etc/sing-box/config.json

echo "NODES_IN_UCI=$(uci -q get podkop.main.urltest_proxy_links | wc -w)"
echo "CFG_PATH=$CFG"
if [ -s "$CFG" ]; then
	echo "CFG_OUTBOUNDS=$(jq '.outbounds | length' "$CFG" 2>/dev/null)"
	echo "MAIN_OUT_TAGS=$(jq -r '[.outbounds[].tag // empty | select(startswith("main-") and endswith("-out"))] | length' "$CFG" 2>/dev/null)"
	echo "CFG_CHECK:"
	sing-box check -c "$CFG" 2>&1 | head -5
else
	echo "CFG_MISSING"
fi

echo "SINGBOX_PROC:"
pgrep -a sing-box 2>/dev/null | sed 's#-c .*#-c <cfg>#' | head -5

echo "PODKOP_STATUS:"
/etc/init.d/podkop status 2>&1 | head -2

echo "SPEEDTEST_CFG:"
uci show podkop-sub2urltest 2>/dev/null | grep -i speed

echo "MAIN_TAGS_LIST:"
jq -r '.outbounds[].tag // empty | select(startswith("main-"))' "$CFG" 2>/dev/null | tr '\n' ' '
echo
echo "STRAY_SINGBOX:"
for p in $(pgrep sing-box); do
	echo "pid=$p ppid=$(cut -d' ' -f4 /proc/$p/stat 2>/dev/null) args=[$(tr '\0' ' ' </proc/$p/cmdline 2>/dev/null | sed 's#-c .*#-c <cfg>#')]"
done
