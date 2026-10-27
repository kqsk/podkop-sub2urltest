"use strict";
"require view";
"require form";
"require fs";
"require ui";

return view.extend({
  render: function () {
    const m = new form.Map(
      "podkop-sub2urltest",
      _("Подписки Podkop"),
      _("Импорт VPN-подписок в секции Podkop URLTest или Selector. Скрипт скачивает подписку, извлекает узлы и записывает их в конфиг Podkop.")
    );

    const s = m.section(form.TypedSection, "subscription", _("Подписки"));
    s.anonymous = false;
    s.addremove = true;
    // Вертикальная раскладка: полей много и часть из них — выпадающие списки,
    // в таблице (tblsection) они не помещаются.

    let o = s.option(form.Flag, "enabled", _("Включено"));
    o.default = "0";
    o.rmempty = false;

    o = s.option(form.DynamicList, "url", _("Ссылки на подписки"));
    o.description = _("Можно добавить несколько: серверы из всех подписок складываются в один список");
    o.placeholder = "https://provider.example/api/sub/TOKEN";
    o.rmempty = false;
    o.validate = function (_section_id, value) {
      // DynamicList also validates its empty "add" field: empty is not an error
      if (!value) return true;
      if (value.indexOf("https://") !== 0 && value.indexOf("http://") !== 0)
        return _("Ссылка должна начинаться с http:// или https://");
      return true;
    };

    o = s.option(form.Value, "podkop_section", _("Секция Podkop"));
    o.placeholder = "main";
    o.default = "main";
    o.rmempty = false;
    o.description = _("Имя секции в конфиге Podkop, куда записывать узлы.");

    o = s.option(form.ListValue, "podkop_mode", _("Режим"));
    o.value("urltest", _("URLTest (автовыбор быстрейшего)"));
    o.value("selector", _("Selector (ручной выбор)"));
    o.default = "urltest";
    o.rmempty = false;

    // (todo 1) Интервал обновления — выпадающий список. Бэкенд понимает
    // суффиксы s/m/h/d (interval_seconds), поэтому храним человекочитаемо.
    o = s.option(form.Value, "update_interval", _("Интервал обновления"));
    o.value("30m", _("Каждые 30 минут"));
    o.value("1h", _("Каждый час"));
    o.value("3h", _("Каждые 3 часа"));
    o.value("6h", _("Каждые 6 часов"));
    o.value("12h", _("Каждые 12 часов"));
    o.value("24h", _("Каждые 24 часа"));
    o.value("daily", _("Раз в сутки ночью (04:00)"));
    o.default = "6h";
    o.rmempty = false;
    o.description = _("Можно выбрать из списка или ввести своё (например 90m, 8h).");

    o = s.option(form.Value, "max_nodes", _("Максимум узлов"));
    o.value("0", _("0 — без ограничения"));
    o.value("10", "10");
    o.value("20", "20");
    o.value("50", "50");
    o.default = "0";
    o.rmempty = false;

    // (todo 2) User-Agent — выпадающий список актуальных клиентов.
    // Панели Remnawave/Marzban отдают разный формат в зависимости от UA;
    // Sing-box отдаёт построчный base64-список ссылок (его и парсим лучше всего).
    o = s.option(form.Value, "user_agent", _("User-Agent"));
    o.value("Sing-box/1.8.29", _("Sing-box/1.8.29 (рекомендуется)"));
    o.value("Happ/3.13.0", "Happ/3.13.0");
    o.value("v2rayNG/1.8.5", "v2rayNG/1.8.5");
    o.value("v2rayN/6.42", "v2rayN/6.42");
    o.value("Hiddify/2.0.5", "Hiddify/2.0.5");
    o.value("Streisand/1.6.0", "Streisand/1.6.0");
    o.value("Shadowrocket/2.2.0", "Shadowrocket/2.2.0");
    o.value("Stash/2.5.0", "Stash/2.5.0");
    o.value("NekoBox/1.3.5", "NekoBox/1.3.5");
    o.value("clash-verge/1.7.0", "clash-verge/1.7.0");
    o.value("ClashMetaForAndroid/2.11.10", _("ClashMetaForAndroid (может отдать YAML)"));
    o.default = "Sing-box/1.8.29";
    o.rmempty = false;
    o.description = _("Если узлы не подгружаются — смените User-Agent. Многие панели гейтят реальный конфиг по нему.");

    o = s.option(form.Value, "hwid", _("HWID (ID устройства)"));
    o.rmempty = true;
    o.password = true;
    o.description = _("Оставьте пустым — сгенерируется стабильный HWID и роутер будет считаться одним устройством. Задайте вручную, если у подписки лимит по устройствам.");

    // (todo, из фикса xhttp) Какие транспорты Podkop умеет конвертировать.
    o = s.option(form.Value, "supported_transports", _("Поддерживаемые транспорты"));
    o.value("tcp,raw,ws,grpc", _("tcp, ws, grpc (умеет Podkop)"));
    o.value("", _("Без фильтра (оставить все)"));
    o.default = "tcp,raw,ws,grpc";
    o.description = _("Узлы с транспортом не из списка (xhttp, httpupgrade, quic…) отбрасываются — Podkop их не конвертирует и ругается «Unknown transport».");

    o = s.option(form.Value, "exclude_keywords", _("Игнорировать серверы со словами"));
    o.default = "🇷🇺,Россия,Москва,Питер,Обход,обход,Авто,авто,Осталось,осталось,дней,Истекает,Трафик,Проверяйте,🇦🇶,Антарктика";
    o.description = _("Через запятую. Сервер пропускается, если его название содержит любое из слов (служебные строки, российские и «обходные» серверы). Регистр важен.");

    o = s.option(form.Flag, "restart_podkop", _("Перезапускать Podkop после обновления"));
    o.default = "1";
    o.rmempty = false;

    // (todo 3) URLTest test URL — выпадающий список.
    o = s.option(form.Value, "test_url", _("URL проверки (URLTest)"));
    o.value("https://cp.cloudflare.com/generate_204", _("Cloudflare (рекомендуется)"));
    o.value("https://www.gstatic.com/generate_204", "Google gstatic");
    o.value("https://www.google.com/generate_204", "Google");
    o.value("https://connectivitycheck.gstatic.com/generate_204", "Google connectivitycheck");
    o.value("http://www.apple.com/library/test/success.html", "Apple");
    o.value("https://1.1.1.1/cdn-cgi/trace", "Cloudflare 1.1.1.1");
    o.default = "https://cp.cloudflare.com/generate_204";
    o.depends("podkop_mode", "urltest");

    o = s.option(form.ListValue, "test_interval", _("Интервал проверки URLTest"));
    o.value("30s", "30 " + _("сек"));
    o.value("1m", "1 " + _("мин"));
    o.value("3m", "3 " + _("мин"));
    o.value("5m", "5 " + _("мин"));
    o.value("10m", "10 " + _("мин"));
    o.default = "1m";
    o.depends("podkop_mode", "urltest");

    o = s.option(form.Value, "test_tolerance", _("Допуск URLTest, мс"));
    o.default = "50";
    o.datatype = "range(50,1000)";
    o.depends("podkop_mode", "urltest");

    // ---- Проверка скорости (speedtest) -------------------------------
    o = s.option(form.Flag, "speedtest_enabled", _("Проверять скорость узлов"));
    o.default = "0";
    o.description = _("Реально качает тестовый файл через каждый узел и выкидывает медленные/мёртвые из Podkop. URLTest меряет только пинг — это меряет именно мегабиты.");

    o = s.option(form.ListValue, "speedtest_interval", _("Как часто мерить скорость"));
    o.value("off", _("Никогда (только вручную кнопкой)"));
    o.value("after_update", _("После каждого обновления подписки"));
    o.value("6h", _("Каждые 6 часов"));
    o.value("12h", _("Каждые 12 часов"));
    o.value("24h", _("Раз в сутки (04:30)"));
    o.value("weekly", _("Раз в неделю (вс, 04:30)"));
    o.default = "off";
    o.depends("speedtest_enabled", "1");
    o.description = _("Замер 28 узлов занимает ~4 минуты. Для регулярного — раз в сутки/неделю достаточно.");

    o = s.option(form.Value, "speedtest_min_mbps", _("Минимальная скорость, Мбит/с"));
    o.value("10", "10");
    o.value("20", "20");
    o.value("30", "30");
    o.value("50", "50");
    o.value("100", "100");
    o.default = "20";
    o.depends("speedtest_enabled", "1");
    o.description = _("Узлы медленнее этого порога выкидываются.");

    o = s.option(form.Value, "speedtest_url", _("URL тестового файла"));
    o.value("https://speed.cloudflare.com/__down?bytes=20000000", _("Cloudflare 20 МБ (рекомендуется)"));
    o.value("https://speed.cloudflare.com/__down?bytes=50000000", _("Cloudflare 50 МБ"));
    o.value("https://speed.hetzner.de/100MB.bin", _("Hetzner 100 МБ"));
    o.default = "https://speed.cloudflare.com/__down?bytes=20000000";
    o.depends("speedtest_enabled", "1");

    o = s.option(form.Button, "_speedtest", _("Проверить скорость сейчас"));
    o.inputstyle = "reload";
    o.depends("speedtest_enabled", "1");
    o.onclick = function (_ev, section_id) {
      ui.addNotification(null, E("p", {}, _("Проверка скорости запущена в фоне (~4 мин на 28 узлов). Результат — в системном логе, список обновится автоматически.")));
      return fs.exec("/usr/bin/podkop-sub2urltest", ["speedtest", section_id])
        .then(function (res) {
          if (res.code === 0) {
            ui.addNotification(null, E("p", {}, _("Проверка скорости завершена, медленные узлы убраны.")));
          } else {
            ui.addNotification(null, E("p", {}, _("Проверка скорости не удалась. Смотрите системный лог.")), "danger");
          }
        })
        .catch(function () {
          ui.addNotification(null, E("p", {}, _("Проверка скорости не удалась. Смотрите системный лог.")), "danger");
        });
    };

    o = s.option(form.Button, "_update", _("Обновить сейчас"));
    o.inputstyle = "apply";
    o.onclick = function (_ev, section_id) {
      return fs.exec("/usr/bin/podkop-sub2urltest", ["update", section_id])
        .then(function (res) {
          if (res.code === 0) {
            ui.addNotification(null, E("p", {}, _("Подписка обновлена.")));
          } else {
            ui.addNotification(null, E("p", {}, _("Ошибка обновления. Смотрите системный лог.")), "danger");
          }
        })
        .catch(function () {
          ui.addNotification(null, E("p", {}, _("Ошибка обновления. Смотрите системный лог.")), "danger");
        });
    };

    return m.render();
  },
});
