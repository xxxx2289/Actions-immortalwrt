#!/bin/bash
set -e

# ============================================================
# diy-part2.sh for Actions-immortalwrt
# 功能：
# 1. 保留常用自定义：默认 IP、Argon 主题、温度/CPU 状态插件、短信转发插件
# 2. 修复 glib2 拆分依赖导致的 libmbim/libqmi/ModemManager 编译问题
# 3. 对 UZ801 / UFI003 / UFI103S 关闭 LTE 基带相关编译
# 4. 对 UZ801 / UFI003 / UFI103S 关闭 MPSS/Modem reserved-memory，释放基带预留内存
# 注意：不会删除 WCNSS/WiFi 固件，避免板载 WiFi 失效
# ============================================================

echo "===== diy-part2: start ====="

# ------------------------------------------------------------
# Basic customizations
# ------------------------------------------------------------

# Modify default IP
if [ -f package/base-files/files/bin/config_generate ]; then
    sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate || true
fi

# Modify default theme
if [ -f feeds/luci/collections/luci/Makefile ]; then
    sed -i 's/luci-theme-material/luci-theme-argon/g' feeds/luci/collections/luci/Makefile || true
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile || true
fi

# Optional LuCI apps
[ -d package/luci-app-cpu-perf ] || git clone --depth=1 https://github.com/lkiuyu/luci-app-cpu-perf package/luci-app-cpu-perf || true
[ -d package/luci-app-cpu-status ] || git clone --depth=1 https://github.com/lkiuyu/luci-app-cpu-status package/luci-app-cpu-status || true
[ -d package/luci-app-cpu-status-mini ] || git clone --depth=1 https://github.com/gSpotx2f/luci-app-cpu-status-mini package/luci-app-cpu-status-mini || true
[ -d package/luci-app-temp-status ] || git clone --depth=1 https://github.com/lkiuyu/luci-app-temp-status package/luci-app-temp-status || true

# DbusSmsForwardCPlus
[ -d package/DbusSmsForwardCPlus ] || git clone --depth=1 https://github.com/lkiuyu/DbusSmsForwardCPlus package/DbusSmsForwardCPlus || true

# ------------------------------------------------------------
# Fix glib2 split dependency issue
# ------------------------------------------------------------

echo "===== Fix GLib2 split dependencies ====="

for f in \
    feeds/packages/libs/libmbim/Makefile \
    feeds/packages/libs/libqrtr-glib/Makefile \
    feeds/packages/libs/libqmi/Makefile \
    feeds/packages/net/modemmanager/Makefile

do
    if [ -f "$f" ]; then
        sed -i -E 's/\+glib2([[:space:]\\]|$)/+glib2-core +glib2-gobject +glib2-gio\1/g' "$f" || true
    fi
done

# Fix possible glib2 meta package typo
if [ -f feeds/packages/libs/glib2/Makefile ]; then
    sed -i 's/DEPENDS:+glib2-gthread/DEPENDS:=+glib2-gthread/g' feeds/packages/libs/glib2/Makefile || true
fi

# Force required split glib2 packages
for p in glib2-core glib2-gmodule glib2-gobject glib2-gio glib2-gthread; do
    sed -i "/^CONFIG_PACKAGE_${p}=/d" .config 2>/dev/null || true
    sed -i "/^# CONFIG_PACKAGE_${p} is not set/d" .config 2>/dev/null || true
    echo "CONFIG_PACKAGE_${p}=y" >> .config
done

# ------------------------------------------------------------
# Disable modem userspace packages
# ------------------------------------------------------------

echo "===== Disable modem userspace packages ====="

for p in \
    libmbim \
    mbim-utils \
    libqmi \
    qmi-utils \
    libqrtr-glib \
    libqrtr \
    modemmanager \
    modemmanager-rpcd \
    luci-proto-mbim \
    luci-proto-qmi \
    luci-proto-modemmanager \
    luci-app-modemmanager \
    qmi-modem-410-init \
    qrtr-ns

do
    sed -i "/^CONFIG_PACKAGE_${p}=/d" .config 2>/dev/null || true
    sed -i "/^# CONFIG_PACKAGE_${p} is not set/d" .config 2>/dev/null || true
    echo "# CONFIG_PACKAGE_${p} is not set" >> .config
done

# ------------------------------------------------------------
# Disable baseband/modem only for UZ801 / UFI003 / UFI103S
# ------------------------------------------------------------

echo "===== Check target for baseband disable patch ====="

if grep -qE 'CONFIG_TARGET_msm89xx_msm8916_DEVICE_openstick[-_](uz801|ufi003|ufi103s)=y|CONFIG_TARGET.*DEVICE.*(uz801|ufi003|ufi103s)=y' .config 2>/dev/null; then
    echo ">>> Target is UZ801 / UFI003 / UFI103S: disabling modem/baseband build"

    # 1. Remove baseband kernel modules and rmtfs from msm89xx default packages
    if [ -f target/linux/msm89xx/Makefile ]; then
        sed -i -E 's/[[:space:]]+kmod-rpmsg-wwan-ctrl//g' target/linux/msm89xx/Makefile
        sed -i -E 's/[[:space:]]+kmod-bam-dmux//g' target/linux/msm89xx/Makefile
        sed -i -E 's/[[:space:]]+kmod-qcom-rproc-modem//g' target/linux/msm89xx/Makefile
        sed -i -E '/^[[:space:]]*DEFAULT_PACKAGES[[:space:]]*\+=[[:space:]]*rmtfs[[:space:]]*$/s/^/# disabled modem: /' target/linux/msm89xx/Makefile
    fi

    # 2. Remove modem firmware from device packages.
    # Keep WCNSS/WiFi firmware. Do NOT remove qcom-msm8916-openstick-*-wcnss-firmware or qcom-msm8916-wcnss-*-nv.
    if [ -f target/linux/msm89xx/image/msm8916.mk ]; then
        sed -i -E 's/[[:space:]]+qcom-msm8916-modem-openstick-(ufi003|ufi103s|uz801)-firmware//g' target/linux/msm89xx/image/msm8916.mk
    fi

    # 3. Disable MPSS/modem reserved-memory in DTS.
    # UFI003 and UFI103S inherit/use msm8916-thwc-ufi001c.dts.
    for DTS in \
        target/linux/msm89xx/dts/msm8916-yiming-uz801v3.dts \
        target/linux/msm89xx/dts/msm8916-thwc-ufi001c.dts
    do
        if [ -f "$DTS" ] && ! grep -q "disable modem to free MPSS memory" "$DTS"; then
            cat >> "$DTS" <<'DTS_EOF'

/* disable modem to free MPSS memory */
&bam_dmux {
	status = "disabled";
};

&bam_dmux_dma {
	status = "disabled";
};

&mpss {
	status = "disabled";
};

&mba_mem {
	status = "disabled";
};

&mpss_mem {
	reg = <0x0 0x86800000 0x0 0x0>;
	status = "disabled";
};
DTS_EOF
        fi
    done

    # 4. Prevent make defconfig from selecting modem/baseband packages again
    for p in \
        kmod-rpmsg-wwan-ctrl \
        kmod-bam-dmux \
        kmod-qcom-rproc-modem \
        rmtfs \
        qcom-msm8916-modem-openstick-ufi003-firmware \
        qcom-msm8916-modem-openstick-ufi103s-firmware \
        qcom-msm8916-modem-openstick-uz801-firmware
    do
        sed -i "/^CONFIG_PACKAGE_${p}=/d" .config 2>/dev/null || true
        sed -i "/^# CONFIG_PACKAGE_${p} is not set/d" .config 2>/dev/null || true
        echo "# CONFIG_PACKAGE_${p} is not set" >> .config
    done

    echo ">>> Baseband disabled for UZ801 / UFI003 / UFI103S"
else
    echo ">>> Current target is not UZ801 / UFI003 / UFI103S; skip baseband DTS patch"
fi

# ------------------------------------------------------------
# Debug output
# ------------------------------------------------------------

echo "===== GLib dependency patch check ====="
grep -n "DEPENDS" feeds/packages/libs/libmbim/Makefile 2>/dev/null || true
grep -n "DEPENDS" feeds/packages/libs/libqrtr-glib/Makefile 2>/dev/null || true
grep -n "DEPENDS" feeds/packages/libs/libqmi/Makefile 2>/dev/null || true
grep -n "DEPENDS" feeds/packages/net/modemmanager/Makefile 2>/dev/null || true

echo "===== Disabled modem userspace packages ====="
grep -E "CONFIG_PACKAGE_(libmbim|mbim-utils|libqmi|qmi-utils|libqrtr-glib|libqrtr|modemmanager|modemmanager-rpcd|luci-proto-mbim|luci-proto-qmi|luci-proto-modemmanager|luci-app-modemmanager|qmi-modem-410-init|qrtr-ns)" .config || true

echo "===== Disabled baseband packages ====="
grep -E "CONFIG_PACKAGE_(kmod-rpmsg-wwan-ctrl|kmod-bam-dmux|kmod-qcom-rproc-modem|rmtfs|qcom-msm8916-modem-openstick-(ufi003|ufi103s|uz801)-firmware)" .config || true

echo "===== diy-part2: done ====="
