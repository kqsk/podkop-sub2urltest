# podkop-sub2urltest

🇷🇺 **Русский** · 🇬🇧 [English](README.en.md)

Companion-пакет для OpenWrt + [Podkop](https://podkop.net). Берёт ссылку-подписку
вашего VPN (subscription URL) и импортирует из неё ноды в Podkop-секцию
`urltest` или `selector` через UCI.

Добавляет отдельную страницу в LuCI:

```text
Службы → Podkop Subscriptions
```

## Зачем это нужно

Podkop в режиме Proxy ждёт **готовые** proxy-ссылки (`vless://`, `ss://`,
`trojan://`, …) или их список для URLTest/Selector. Обычную HTTPS-подписку вида
`https://provider.example/api/sub/TOKEN` он напрямую не принимает.

Этот пакет закрывает разрыв: скачивает подписку, разбирает её на отдельные ноды
и записывает их в Podkop. Вы один раз вставляете ссылку-подписку — дальше Podkop
сам получает актуальный список нод, автоматически по расписанию.

## Что понимает на входе

- сырые списки proxy-URI: `vless://`, `ss://`, `trojan://`, `socks4://`,
  `socks4a://`, `socks5://`, `hy2://`
- base64-кодированные списки proxy-URI
- типичные Mihomo/Clash YAML `proxies:` для `vless`, `trojan`,
  `ss`/`shadowsocks`, `hysteria2`/`hy2`

Subscription URL и сами ноды в лог **не пишутся**.

## Установка (без сборки ipk)

### Проще всего — с GitHub

Подходит любой OpenWrt (старые на `opkg` и 25+ на `apk`), нужен уже
установленный [Podkop](https://github.com/itdoginfo/podkop). Зайти на роутер по
SSH (`ssh root@192.168.1.1`) и вставить одну строку:

```sh
wget -qO- https://raw.githubusercontent.com/kqsk/podkop-sub2urltest/main/remote-install.sh | ash
```

Установщик спросит ссылку-подписку (можно пропустить Enter и вписать потом в
LuCI). Если Podkop не стоит — скрипт остановится и покажет команду его установки.

Установщик ставит зависимости, пишет ссылку-подписку в
`/etc/config/podkop-sub2urltest`, делает первый импорт и включает периодические
обновления. Потом всё настраивается в LuCI: **Службы → Podkop Subscriptions**.

Без интерактива (ссылка через переменную окружения):

```sh
wget -O /tmp/podkop-sub2urltest-install.sh https://raw.githubusercontent.com/kqsk/podkop-sub2urltest/main/remote-install.sh
SUB_URL='https://provider.example/api/sub/TOKEN' ash /tmp/podkop-sub2urltest-install.sh
```

Повторный запуск установщика обновляет скрипт и **сохраняет** существующий
конфиг (ссылку и ноды не трогает).

### Установка вручную

Скопировать папку на роутер и запустить:

```sh
cd /path/to/podkop-sub2urltest
ash install.sh
```

Либо скопировать файлы по отдельности:

```sh
scp files/usr/bin/podkop-sub2urltest root@192.168.1.1:/usr/bin/
scp files/etc/config/podkop-sub2urltest root@192.168.1.1:/etc/config/
scp files/etc/init.d/podkop-sub2urltest root@192.168.1.1:/etc/init.d/
ssh root@192.168.1.1 'chmod +x /usr/bin/podkop-sub2urltest /etc/init.d/podkop-sub2urltest'
```

Зависимости:

```sh
# OpenWrt 25 и новее
apk update && apk add jq coreutils-base64 ca-bundle
# OpenWrt 24 и старше
opkg update && opkg install jq coreutils-base64 ca-bundle
```

## Настройка

Файл `/etc/config/podkop-sub2urltest`:

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

Затем:

```sh
podkop-sub2urltest update
```

Включить периодическое обновление:

```sh
/etc/init.d/podkop-sub2urltest enable
/etc/init.d/podkop-sub2urltest start
```

## Команды

```sh
podkop-sub2urltest update [секция]     # скачать + импортировать ноды в Podkop
podkop-sub2urltest speedtest [секция]  # замерить реальные Mbit/s, выкинуть медленные
podkop-sub2urltest parse-file ФАЙЛ     # отладка: показать распарсенные ссылки
```

## Параметры

| Параметр | Значение |
|----------|----------|
| `url` | Ссылка-подписка. Поле называется именно `url`. |
| `user_agent` | Панели отдают разный конфиг по UA. `Sing-box/1.8.29` возвращает base64-список URI (лучше всего парсится). `ClashMetaForAndroid` может вернуть Clash YAML или заглушку «app not supported». |
| `hwid` | Уходит как `X-Hwid`. Пусто = один раз генерируется стабильный HWID (`/etc/podkop-sub2urltest.hwid.<секция>`), роутер считается ОДНИМ устройством. Задать вручную для подписок с лимитом по HWID. |
| `supported_transports` | Оставлять только эти vless/trojan-транспорты. Podkop умеет лишь `tcp/raw,ws,grpc`; ноды `xhttp`/`httpupgrade`/`quic` отбрасываются, чтобы не ловить «Unknown transport». Пусто = без фильтра. |
| `speedtest_enabled` | Включить замер реальной полосы импортированных нод. |
| `speedtest_interval` | `off` (только вручную) / `after_update` / `6h` / `12h` / `24h` / `weekly`. Временные варианты ставят строку в cron. |
| `speedtest_min_mbps` | Ноды медленнее этого порога удаляются из Podkop. |
| `speedtest_url` / `speedtest_timeout` | URL тестового файла и таймаут на ноду (секунды). |

## Скорость против задержки

Podkop URLTest выбирает ноду с наименьшей **задержкой** (ping), а не наибольшей
**полосой**. Нода с быстрым пингом может качать медленно. `speedtest` закрывает
это: поднимает временный sing-box на каждую ноду (переиспользуя уже
сконвертированный Podkop-outbound), качает `speedtest_url` через неё и выкидывает
ноды ниже `speedtest_min_mbps`. ~4 мин на ~28 нод; скорость нод плавает во
времени — поэтому есть расписание (`speedtest_interval`).

## Заметки

- `podkop_mode 'urltest'` пишет в `urltest_proxy_links`.
- `podkop_mode 'selector'` пишет в `selector_proxy_links`.
- `speedtest` требует `sing-box` (ставится вместе с Podkop) и `curl`.
- Предпочтительнее сырые/base64 списки URI, а не Mihomo YAML — они точно
  сохраняют специфичные для провайдера параметры URI. YAML-парсер намеренно
  небольшой (типовые Remnawave-style VLESS Reality/TLS, Trojan, Shadowsocks,
  Hysteria2).
- Subscription URL и proxy-ссылки в лог не пишутся.
