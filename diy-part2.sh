#!/bin/bash
set -e

echo "===== DIY PART2: remove MSM8916 baseband/modem packages for all 410 WiFi devices ====="

# Default IP
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate 2>/dev/null || true

# Theme
sed -i 's/luci-theme-material/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# Optional CPU/temp status packages
git clone https://github.com/lkiuyu/luci-app-cpu-perf package/luci-app-cpu-perf 2>/dev/null || true
git clone https://github.com/lkiuyu/luci-app-cpu-status package/luci-app-cpu-status 2>/dev/null || true
git clone https://github.com/gSpotx2f/luci-app-cpu-status-mini package/luci-app-cpu-status-mini 2>/dev/null || true
git clone https://github.com/lkiuyu/luci-app-temp-status package/luci-app-temp-status 2>/dev/null || true

# Remove SMS/modem-related package source
rm -rf package/DbusSmsForwardCPlus package/feeds/*/DbusSmsForwardCPlus 2>/dev/null || true

# Only remove cellular/baseband/modem packages.
# Keep Wi-Fi/WCNSS packages:
#   kmod-rproc-wcnss
#   kmod-wcn36xx
#   qcom-msm8916-*-wcnss-firmware
#   qcom-msm8916-wcnss-*-nv

DISABLE_PKGS="
kmod-qcom-rproc-modem
kmod-rpmsg-wwan-ctrl
kmod-bam-dmux
rmtfs

qmi-modem-410-init
modemmanager
modemmanager-rpcd
luci-app-modemmanager
luci-proto-modemmanager

libqmi
libqmi-glib
qmi-utils
uqmi
luci-proto-qmi

libmbim
libmbim-glib
mbim-utils
umbim
luci-proto-mbim

libqrtr
libqrtr-glib
qrtr
qrtr-ns

wwan
chat
comgt
comgt-ncm
comgt-directip

DbusSmsForwardCPlus
luci-app-dbus-sms-forward
luci-app-sms-tool
sms-tool

kmod-usb-net-qmi-wwan
kmod-usb-net-cdc-mbim
kmod-usb-net-cdc-ncm
kmod-usb-net-huawei-cdc-ncm
kmod-usb-serial-option
kmod-usb-serial-wwan
kmod-usb-wdm
"

disable_pkg() {
  local p="$1"

  sed -i "/^CONFIG_PACKAGE_${p}=/d" .config
  sed -i "/^# CONFIG_PACKAGE_${p} is not set/d" .config
  sed -i "/^CONFIG_DEFAULT_${p}=/d" .config
  sed -i "/^# CONFIG_DEFAULT_${p} is not set/d" .config

  echo "# CONFIG_PACKAGE_${p} is not set" >> .config
  echo "# CONFIG_DEFAULT_${p} is not set" >> .config
}

for p in $DISABLE_PKGS; do
  disable_pkg "$p"
done

# Disable every MSM8916 OpenStick modem firmware package already selected in .config
MODEM_FW_SYMBOLS="$(grep -E '^CONFIG_(PACKAGE|DEFAULT)_qcom-msm8916-modem-openstick-.*-firmware=y' .config \
  | sed -E 's/^CONFIG_(PACKAGE|DEFAULT)_//' \
  | sed -E 's/=y$//' \
  | sort -u || true)"

for p in $MODEM_FW_SYMBOLS; do
  echo "Disable modem firmware: $p"
  disable_pkg "$p"
done

# Fallback: explicitly disable common MSM8916/OpenStick modem firmware packages
for p in \
  qcom-msm8916-modem-openstick-ufi001c-firmware \
  qcom-msm8916-modem-openstick-ufi001b-firmware \
  qcom-msm8916-modem-openstick-ufi103s-firmware \
  qcom-msm8916-modem-openstick-qrzl903-firmware \
  qcom-msm8916-modem-openstick-w001-firmware \
  qcom-msm8916-modem-openstick-ufi003-firmware \
  qcom-msm8916-modem-openstick-uz801-firmware \
  qcom-msm8916-modem-openstick-mf32-firmware \
  qcom-msm8916-modem-openstick-mf601-firmware \
  qcom-msm8916-modem-openstick-wf2-firmware \
  qcom-msm8916-modem-openstick-jz02v10-firmware \
  qcom-msm8916-modem-openstick-sp970v10-firmware \
  qcom-msm8916-modem-openstick-sp970v11-firmware
do
  disable_pkg "$p"
done

# Keep Wi-Fi/WCNSS related packages enabled
KEEP_WIFI_PKGS="
kmod-rproc-wcnss
kmod-wcn36xx
wpad-basic-wolfssl
"

for p in $KEEP_WIFI_PKGS; do
  sed -i "/^# CONFIG_PACKAGE_${p} is not set/d" .config
  sed -i "/^CONFIG_PACKAGE_${p}=/d" .config
  echo "CONFIG_PACKAGE_${p}=y" >> .config
done

echo "===== Keep Wi-Fi/WCNSS related entries ====="
grep -E 'wcnss|wcn36xx|rproc-wcnss|wpad-basic' .config || true

echo "===== Disabled baseband/modem related entries ====="
grep -E 'modem|qmi|mbim|wwan|qrtr|bam-dmux|rmtfs|sms|DbusSms' .config || true
