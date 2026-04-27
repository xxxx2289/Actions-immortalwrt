#!/bin/bash
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# Modify default theme
sed -i 's/luci-theme-material/luci-theme-argon/g' feeds/luci/collections/luci/Makefile


# temp
git clone https://github.com/lkiuyu/luci-app-cpu-perf package/luci-app-cpu-perf
git clone https://github.com/lkiuyu/luci-app-cpu-status package/luci-app-cpu-status
git clone https://github.com/gSpotx2f/luci-app-cpu-status-mini package/luci-app-cpu-status-mini
git clone https://github.com/lkiuyu/luci-app-temp-status package/luci-app-temp-status

# DbusSmsForwardCPlus
git clone https://github.com/lkiuyu/DbusSmsForwardCPlus package/DbusSmsForwardCPlus


# Fix libmbim dependency
if [ -f feeds/packages/libs/libmbim/Makefile ]; then
  sed -i '/define Package\/libmbim/,/endef/s/DEPENDS:=.*/DEPENDS:=+glib2/' feeds/packages/libs/libmbim/Makefile
fi

# Make sure glib2 is selected
sed -i '/^CONFIG_PACKAGE_glib2=/d' .config
sed -i '/^# CONFIG_PACKAGE_glib2 is not set/d' .config
echo 'CONFIG_PACKAGE_glib2=y' >> .config