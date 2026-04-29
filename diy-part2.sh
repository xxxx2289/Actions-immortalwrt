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

# 改 libmbim
# sed -i 's/DEPENDS:=+glib2/DEPENDS:=+glib2 +glib2-gio +glib2-gobject +glib2-core/' package/feeds/packages/libmbim/Makefile

# 改 libqrtr-glib
# sed -i 's/DEPENDS:=+glib2/DEPENDS:=+glib2 +glib2-gio +glib2-gobject +glib2-core/' package/feeds/packages/libqrtr-glib/Makefile

# 验证
# echo "=== libmbim ==="
# grep "DEPENDS" package/feeds/packages/libmbim/Makefile
# echo "=== libqrtr-glib ==="
# grep "DEPENDS" package/feeds/packages/libqrtr-glib/Makefile






