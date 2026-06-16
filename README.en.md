# podkop-sub2urltest

🇷🇺 [Русский](README.md) · 🇬🇧 **English**

OpenWrt companion package for Podkop. It imports subscription URLs into a
Podkop `urltest` or `selector` proxy section.

It also adds a separate LuCI page:

```text
Services -> Podkop Subscriptions
```

Supported subscription bodies:

- raw proxy URI lists: `vless://`, `ss://`, `trojan://`, `socks4://`,
  `socks4a://`, `socks5://`, `hy2://`
- base64 encoded proxy URI lists
- common Mihomo/Clash YAML `proxies:` entries for `vless`, `trojan`,
  `ss`/`shadowsocks`, and `hysteria2`/`hy2`

It does not log subscription URLs or proxy links.

## Install without building an ipk

### Easiest install from GitHub

Run this on the OpenWrt router (SSH as root):

```sh
wget -O /tmp/podkop-sub2urltest-install.sh https://raw.githubusercontent.com/kqsk/podkop-sub2urltest/main/remote-install.sh
ash /tmp/podkop-sub2urltest-install.sh
```

The installer asks for the subscription URL, writes it to
`/etc/config/podkop-sub2urltest`, runs the first update, and enables periodic
updates.

For non-interactive install:

```sh
wget -O /tmp/podkop-sub2urltest-install.sh https://raw.githubusercontent.com/kqsk/podkop-sub2urltest/main/remote-install.sh
SUB_URL='https://provider.example/api/sub/TOKEN' ash /tmp/podkop-sub2urltest-install.sh
```

If the installer was not edited before upload, pass the raw GitHub base URL:

```sh
wget -O /tmp/podkop-sub2urltest-install.sh https://raw.githubusercontent.com/kqsk/podkop-sub2urltest/main/remote-install.sh
PODKOP_SUB2URLTEST_BASE='https://raw.githubusercontent.com/kqsk/podkop-sub2urltest/main' \
SUB_URL='https://provider.example/api/sub/TOKEN' ash /tmp/podkop-sub2urltest-install.sh
```

Running the installer again updates the script and keeps the existing config.

### Manual install

Copy this directory to the router, then run:

```sh
cd /path/to/podkop-sub2urltest
ash install.sh
```

Or copy the files manually:

```sh
scp files/usr/bin/podkop-sub2urltest root@192.168.1.10:/usr/bin/
scp files/etc/config/podkop-sub2urltest root@192.168.1.10:/etc/config/
scp files/etc/init.d/podkop-sub2urltest root@192.168.1.10:/etc/init.d/
ssh root@192.168.1.10 'chmod +x /usr/bin/podkop-sub2urltest /etc/init.d/podkop-sub2urltest'
```

Install runtime dependencies:

```sh
opkg update
opkg install jq coreutils-base64 ca-bundle
```

## Configure

Edit `/etc/config/podkop-sub2urltest`:

```uci
config subscription 'main'
	option enabled '1'
	option url 'https://provider.example/api/sub/TOKEN'
	option podkop_section 'main'
	option podkop_mode 'urltest'
	option user_agent 'Sing-box/1.8.29'
	option hwid ''
	option supported_transports 'tcp,raw,ws,grpc'
	option restart_podkop '1'
	option update_interval '21600'
	option max_nodes '0'
	option test_url 'https://cp.cloudflare.com/generate_204'
	option test_interval '1m'
	option test_tolerance '50'
	option speedtest_enabled '0'
	option speedtest_interval 'off'
	option speedtest_min_mbps '20'
	option speedtest_url 'https://speed.cloudflare.com/__down?bytes=20000000'
	option speedtest_timeout '10'
```

Then run:

```sh
podkop-sub2urltest update
```

Enable periodic updates:

```sh
/etc/init.d/podkop-sub2urltest enable
/etc/init.d/podkop-sub2urltest start
```

## Commands

```sh
podkop-sub2urltest update [section]     # fetch + import nodes into Podkop
podkop-sub2urltest speedtest [section]  # measure real Mbit/s, drop slow nodes
podkop-sub2urltest parse-file FILE      # debug: print parsed links from a file
```

## Options

| Option | Meaning |
|--------|---------|
| `user_agent` | Panels gate the real config on UA. `Sing-box/1.8.29` returns a base64 URI list (best for parsing). `ClashMetaForAndroid` may return Clash YAML or an "app not supported" placeholder. |
| `hwid` | Sent as `X-Hwid`. Empty = a stable HWID is generated once (`/etc/podkop-sub2urltest.hwid.<section>`) so the router counts as ONE device. Set manually for HWID-limited subscriptions. |
| `supported_transports` | Only these vless/trojan transports are kept. Podkop converts `tcp/raw,ws,grpc` only; `xhttp`/`httpupgrade`/`quic` nodes are dropped to avoid Podkop's "Unknown transport" error. Empty = no filter. |
| `speedtest_enabled` | Enable real bandwidth testing of imported nodes. |
| `speedtest_interval` | `off` (manual only) / `after_update` / `6h` / `12h` / `24h` / `weekly`. Time-based cadences install a cron line. |
| `speedtest_min_mbps` | Nodes slower than this are removed from Podkop. |
| `speedtest_url` / `speedtest_timeout` | Test file URL and per-node timeout (seconds). |

## Speed vs latency

Podkop URLTest selects the node with the lowest **latency**, not the highest
**bandwidth**. A fast-ping node can still be slow. `speedtest` fills that gap: it
spins a throwaway sing-box per node (reusing Podkop's own converted outbound),
downloads `speedtest_url` through it, and prunes nodes below `speedtest_min_mbps`.
Cost is ~4 min for ~28 nodes, and node speed fluctuates over time — that is why
the schedule (`speedtest_interval`) exists.

## Notes

- `podkop_mode 'urltest'` writes `urltest_proxy_links`.
- `podkop_mode 'selector'` writes `selector_proxy_links`.
- `speedtest` requires `sing-box` (installed by Podkop) and `curl`.
- Prefer raw/base64 URI lists over Mihomo YAML — they preserve provider-specific
  URI parameters exactly. The Mihomo YAML parser is intentionally small (common
  Remnawave-style VLESS Reality/TLS, Trojan, Shadowsocks, Hysteria2).
- It does not log subscription URLs or proxy links.
