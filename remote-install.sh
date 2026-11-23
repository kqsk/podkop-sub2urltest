#!/bin/ash

set -e

DEFAULT_BASE="https://raw.githubusercontent.com/kqsk/podkop-sub2urltest/main"
BASE="${PODKOP_SUB2URLTEST_BASE:-$DEFAULT_BASE}"
TMP_DIR="/tmp/podkop-sub2urltest-install.$$"

log() {
	printf '%s\n' "$*"
}

die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

download() {
	local url="$1"
	local out="$2"

	if command -v uclient-fetch >/dev/null 2>&1; then
		uclient-fetch -q -O "$out" "$url"
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "$out" "$url"
	elif command -v curl >/dev/null 2>&1; then
		curl -fsSL -o "$out" "$url"
	else
		die "missing downloader: install uclient-fetch, wget, or curl"
	fi
}

ensure_deps() {
	local missing=""

	command -v jq >/dev/null 2>&1 || missing="$missing jq"
	command -v base64 >/dev/null 2>&1 || missing="$missing coreutils-base64"
	command -v uci >/dev/null 2>&1 || missing="$missing uci"
	command -v curl >/dev/null 2>&1 || missing="$missing curl"
	command -v flock >/dev/null 2>&1 || missing="$missing flock"

	if ! command -v podkop >/dev/null 2>&1; then
		log "Podkop is not installed. Install it first (official installer), then run this again:"
		log "  wget -O /tmp/podkop-install.sh https://raw.githubusercontent.com/itdoginfo/podkop/refs/heads/main/install.sh && sh /tmp/podkop-install.sh"
		exit 1
	fi

	if [ -n "$missing" ]; then
		log "Installing missing dependencies:$missing"
		if command -v apk >/dev/null 2>&1; then
			# OpenWrt 25.x and newer
			apk update
			apk add $missing ca-bundle
		elif command -v opkg >/dev/null 2>&1; then
			opkg update
			opkg install $missing ca-bundle
		fi
	fi

	command -v jq >/dev/null 2>&1 || die "jq is missing"
	command -v base64 >/dev/null 2>&1 || die "base64 is missing"
	command -v uci >/dev/null 2>&1 || die "uci is missing"
	command -v curl >/dev/null 2>&1 || die "curl is missing"
	command -v flock >/dev/null 2>&1 || die "flock is missing"
}

prompt_subscription_url() {
	if [ -n "${SUB_URL:-}" ]; then
		return 0
	fi

	# stdin is the script itself when run as "wget -qO- ... | ash": ask on the terminal
	if ( : </dev/tty ) 2>/dev/null; then
		log ""
		log "Paste subscription URL, or press Enter to configure it later."
		printf 'Subscription URL: '
		read -r SUB_URL </dev/tty || SUB_URL=""
	fi
}

install_files() {
	local ts

	mkdir -p "$TMP_DIR"
	download "$BASE/files/usr/bin/podkop-sub2urltest" "$TMP_DIR/podkop-sub2urltest"
	download "$BASE/files/etc/init.d/podkop-sub2urltest" "$TMP_DIR/podkop-sub2urltest.init"
	download "$BASE/files/etc/config/podkop-sub2urltest" "$TMP_DIR/podkop-sub2urltest.config"
	download "$BASE/files/www/luci-static/resources/view/podkop-sub2urltest.js" "$TMP_DIR/podkop-sub2urltest.js"
	download "$BASE/files/usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json" "$TMP_DIR/menu.json"
	download "$BASE/files/usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json" "$TMP_DIR/acl.json"

	chmod +x "$TMP_DIR/podkop-sub2urltest" "$TMP_DIR/podkop-sub2urltest.init"
	/bin/ash -n "$TMP_DIR/podkop-sub2urltest"
	/bin/ash -n "$TMP_DIR/podkop-sub2urltest.init"

	ts="$(date +%Y%m%d%H%M%S)"

	if [ -f /usr/bin/podkop-sub2urltest ]; then
		cp /usr/bin/podkop-sub2urltest "/usr/bin/podkop-sub2urltest.bak.$ts"
	fi

	cp "$TMP_DIR/podkop-sub2urltest" /usr/bin/podkop-sub2urltest
	chmod 0755 /usr/bin/podkop-sub2urltest

	if [ -f /etc/config/podkop-sub2urltest ]; then
		cp /etc/config/podkop-sub2urltest "/etc/config/podkop-sub2urltest.bak.$ts"
	else
		cp "$TMP_DIR/podkop-sub2urltest.config" /etc/config/podkop-sub2urltest
		chmod 0600 /etc/config/podkop-sub2urltest
	fi

	cp "$TMP_DIR/podkop-sub2urltest.init" /etc/init.d/podkop-sub2urltest
	chmod 0755 /etc/init.d/podkop-sub2urltest

	mkdir -p /www/luci-static/resources/view
	cp "$TMP_DIR/podkop-sub2urltest.js" /www/luci-static/resources/view/podkop-sub2urltest.js
	chmod 0644 /www/luci-static/resources/view/podkop-sub2urltest.js

	mkdir -p /usr/share/luci/menu.d
	cp "$TMP_DIR/menu.json" /usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json
	chmod 0644 /usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json

	mkdir -p /usr/share/rpcd/acl.d
	cp "$TMP_DIR/acl.json" /usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json
	chmod 0644 /usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json

	/etc/init.d/podkop-sub2urltest enable
	/etc/init.d/rpcd reload 2>/dev/null || /etc/init.d/rpcd restart 2>/dev/null || true
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache 2>/dev/null || true
}

configure_subscription() {
	if [ -z "${SUB_URL:-}" ]; then
		log ""
		log "Installed. Configure subscription later:"
		log "  uci set podkop-sub2urltest.main.enabled='1'"
		log "  uci set podkop-sub2urltest.main.url='https://provider.example/api/sub/TOKEN'"
		log "  uci commit podkop-sub2urltest"
		log "  podkop-sub2urltest update main"
		log "  /etc/init.d/podkop-sub2urltest restart"
		return 0
	fi

	uci set podkop-sub2urltest.main.enabled='1'
	uci set podkop-sub2urltest.main.url="$SUB_URL"
	uci set podkop-sub2urltest.main.podkop_section="${PODKOP_SECTION:-main}"
	uci set podkop-sub2urltest.main.podkop_mode="${PODKOP_MODE:-urltest}"
	uci set podkop-sub2urltest.main.restart_podkop='1'
	uci commit podkop-sub2urltest

	log "Subscription URL saved. Updating Podkop..."
	/usr/bin/podkop-sub2urltest update main
	/etc/init.d/podkop-sub2urltest restart
	log "Done. Settings: LuCI -> Services -> Podkop Subscriptions"
}

case "$BASE" in
	*"YOUR_GITHUB_USER"*)
		die "set PODKOP_SUB2URLTEST_BASE to your raw GitHub URL before publishing this installer"
		;;
esac

# One function call on the last line: when piped ("wget -qO- ... | ash") the
# shell has read the whole script before anything runs, so no command can
# swallow the rest of it from stdin.
main() {
	ensure_deps
	prompt_subscription_url
	install_files
	configure_subscription
	rm -rf "$TMP_DIR"
}

main "$@"
