#!/bin/bash
#

# Modify default theme
sed -i 's/luci-theme-material/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Disable MBIM / QMI / ModemManager userspace packages to avoid glib2 split dependency errors
for p in \
  libmbim \
  mbim-utils \
  libqmi \
  qmi-utils \
  libqrtr-glib \
  modemmanager \
  modemmanager-rpcd \
  luci-proto-mbim \
  luci-proto-qmi \
  luci-proto-modemmanager \
  luci-app-modemmanager
do
  sed -i "/^CONFIG_PACKAGE_${p}=/d" .config
  sed -i "/^# CONFIG_PACKAGE_${p} is not set/d" .config
  echo "# CONFIG_PACKAGE_${p} is not set" >> .config
done

echo "===== Disabled modem userspace packages ====="
grep -E "CONFIG_PACKAGE_(libmbim|mbim-utils|libqmi|qmi-utils|libqrtr-glib|modemmanager|modemmanager-rpcd|luci-proto-mbim|luci-proto-qmi|luci-proto-modemmanager|luci-app-modemmanager)" .config || true