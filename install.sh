#!/bin/ash

set -e

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

need_file() {
	if [ ! -f "$1" ]; then
		echo "missing file: $1" >&2
		exit 1
	fi
}

need_file "$ROOT/files/usr/bin/podkop-sub2urltest"
need_file "$ROOT/files/etc/init.d/podkop-sub2urltest"
need_file "$ROOT/files/etc/config/podkop-sub2urltest"
need_file "$ROOT/files/www/luci-static/resources/view/podkop-sub2urltest.js"
need_file "$ROOT/files/usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json"
need_file "$ROOT/files/usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json"

if ! command -v podkop >/dev/null 2>&1; then
	echo "warning: podkop is not installed or not in PATH" >&2
fi

missing=""
for dep in jq base64 uci; do
	if ! command -v "$dep" >/dev/null 2>&1; then
		missing="$missing $dep"
	fi
done

if [ -n "$missing" ]; then
	echo "missing runtime command(s):$missing" >&2
	echo "install dependencies first, usually:" >&2
	echo "  apk update && apk add jq coreutils-base64 ca-bundle    (OpenWrt 25+)" >&2
	echo "  opkg update && opkg install jq coreutils-base64 ca-bundle    (older)" >&2
	exit 1
fi

ts="$(date +%Y%m%d%H%M%S)"

if [ -f /usr/bin/podkop-sub2urltest ]; then
	cp /usr/bin/podkop-sub2urltest "/usr/bin/podkop-sub2urltest.bak.$ts"
fi

cp "$ROOT/files/usr/bin/podkop-sub2urltest" /usr/bin/podkop-sub2urltest
chmod 0755 /usr/bin/podkop-sub2urltest

if [ -f /etc/config/podkop-sub2urltest ]; then
	cp /etc/config/podkop-sub2urltest "/etc/config/podkop-sub2urltest.bak.$ts"
else
	cp "$ROOT/files/etc/config/podkop-sub2urltest" /etc/config/podkop-sub2urltest
	chmod 0600 /etc/config/podkop-sub2urltest
fi

cp "$ROOT/files/etc/init.d/podkop-sub2urltest" /etc/init.d/podkop-sub2urltest
chmod 0755 /etc/init.d/podkop-sub2urltest

mkdir -p /www/luci-static/resources/view
cp "$ROOT/files/www/luci-static/resources/view/podkop-sub2urltest.js" /www/luci-static/resources/view/podkop-sub2urltest.js
chmod 0644 /www/luci-static/resources/view/podkop-sub2urltest.js

mkdir -p /usr/share/luci/menu.d
cp "$ROOT/files/usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json" /usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json
chmod 0644 /usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json

mkdir -p /usr/share/rpcd/acl.d
cp "$ROOT/files/usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json" /usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json
chmod 0644 /usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json

/etc/init.d/podkop-sub2urltest enable
/etc/init.d/rpcd reload 2>/dev/null || /etc/init.d/rpcd restart 2>/dev/null || true
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache 2>/dev/null || true

cat <<'EOF'
podkop-sub2urltest installed.

Configure /etc/config/podkop-sub2urltest:
  option enabled '1'
  option url 'https://provider.example/api/sub/TOKEN'

Then run:
  podkop-sub2urltest update
  /etc/init.d/podkop-sub2urltest restart
EOF
