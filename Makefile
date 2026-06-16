include $(TOPDIR)/rules.mk

PKG_NAME:=podkop-sub2urltest
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/podkop-sub2urltest
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Subscription importer for Podkop
  DEPENDS:=+podkop +jq +coreutils-base64 +ca-bundle
  PKGARCH:=all
endef

define Package/podkop-sub2urltest/description
  Fetches raw, base64, or common Mihomo/Clash subscriptions and writes
  supported nodes into Podkop selector/urltest UCI sections.
endef

define Build/Compile
endef

define Package/podkop-sub2urltest/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/podkop-sub2urltest $(1)/usr/bin/podkop-sub2urltest
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/podkop-sub2urltest $(1)/etc/config/podkop-sub2urltest
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/podkop-sub2urltest $(1)/etc/init.d/podkop-sub2urltest
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/podkop-sub2urltest.js $(1)/www/luci-static/resources/view/podkop-sub2urltest.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json $(1)/usr/share/luci/menu.d/luci-app-podkop-sub2urltest.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json $(1)/usr/share/rpcd/acl.d/luci-app-podkop-sub2urltest.json
endef

$(eval $(call BuildPackage,podkop-sub2urltest))
