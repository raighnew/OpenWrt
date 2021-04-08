#!/bin/bash

CUSTOM_SOURCE_ARCH=
CUSTOM_IPK_ARCH=
ARCH=

if [ "$TARGET" = "x86_64" ]; then
    CUSTOM_IPK_ARCH=x86_64
    CUSTOM_SOURCE_ARCH="x86/64"
    ARCH=amd64
elif [ "$TARGET" = "rockchip" ]; then
    ARCH=armv8
    CUSTOM_IPK_ARCH=aarch64_generic
    CUSTOM_SOURCE_ARCH="rockchip/armv8"
elif [ "$TARGET" = "ar71xx_nand" ]; then
    ARCH=mips-softfloat
    CUSTOM_IPK_ARCH=mips_24kc
    CUSTOM_SOURCE_ARCH="ar71xx/nand"

    cp config/wireless files/etc/config/wireless

fi

echo "src/gz simonsmh https://github.com/cielpy/openwrt-dist/raw/packages/${CUSTOM_SOURCE_ARCH}" >> ./repositories.conf

cp custom/keys/* keys

# https://github.com/Dreamacro/clash/releases/tag/premium
CLASH_TUN_RELEASE_DATE=2021.04.08
# https://github.com/comzyh/clash/releases
CLASH_GAME_RELEASE_DATE=20210310
# https://github.com/Dreamacro/clash/releases
CLASH_VERSION=1.5.0

work_dir=$(pwd)

# Add third-party package


cd $work_dir

sudo -E apt-get -qq install gzip

cd files/etc/openclash/core/

rm -f *

function download_clash_binaries() {
    local url=$1
    local binaryname=$2
    wget $url
    
    local filename="${url##*/}"
    gunzip -c $filename > $binaryname
    chmod +x $binaryname
    rm $filename
}

download_clash_binaries https://github.com/Dreamacro/clash/releases/download/v${CLASH_VERSION}/clash-linux-${ARCH}-v${CLASH_VERSION}.gz clash
if [ "$TARGET" != "ar71xx_nand" ]; then
    download_clash_binaries https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-${ARCH}-${CLASH_TUN_RELEASE_DATE}.gz clash_tun
    download_clash_binaries https://github.com/comzyh/clash/releases/download/${CLASH_GAME_RELEASE_DATE}/clash-linux-${ARCH}-${CLASH_GAME_RELEASE_DATE}.gz clash_game
fi


cd $work_dir

echo "查看下载结果"
ls "$work_dir/files/etc/openclash/core/"

function download_missing_ipks() {
    local url=$1
    local binaryname=$2
    wget $url
    
    local filename="${url##*/}"

    cp $filename ./packages/$filename
    rm $filename
}


if [ "$OPENWRT_VERSION" = "19.07" ]; then
    download_missing_ipks https://downloads.openwrt.org/releases/packages-21.02/${CUSTOM_IPK_ARCH}/packages/libcap_2.43-1_${CUSTOM_IPK_ARCH}.ipk
    download_missing_ipks https://downloads.openwrt.org/releases/packages-21.02/${CUSTOM_IPK_ARCH}/packages/libcap-bin_2.43-1_${CUSTOM_IPK_ARCH}.ipk
fi

cat system-custom.tpl  | sed "s/CUSTOM_PPPOE_USERNAME/$CUSTOM_PPPOE_USERNAME/g" | sed "s/CUSTOM_PPPOE_PASSWORD/$CUSTOM_PPPOE_PASSWORD/g" | sed "s/CUSTOM_LAN_IP/$CUSTOM_LAN_IP/g" | sed "s~CUSTOM_CLASH_CONFIG_URL~$CUSTOM_CLASH_CONFIG_URL~g" >  files/etc/uci-defaults/system-custom
