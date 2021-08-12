#!/bin/bash

shopt -s extglob
sed -i '/telephony/d' feeds.conf.default
sed -i '/routing/d' feeds.conf.default
echo "src-git custom https://github.com/kiddin9/openwrt-packages.git" >>feeds.conf.default
./scripts/feeds update -a
rm -rf feeds/custom/{xray-core,.github,diy,mt-drivers,miniupnpd,shortcut-fe,luci-app-mtwifi,mtk_apcli,.gitignore,LICENSE,README.md}

for ipk in $(find ./feeds/custom/*/ -maxdepth 0 -type d);
do
	[ -n "$(grep "KernelPackage" "$ipk/Makefile")" ] && rm -rf $ipk || true
done

rm -Rf feeds/luci/{applications,collections,protocols,themes,libs,docs}
rm -Rf feeds/luci/modules/!(luci-base)
# rm -rf feeds/packages/libs/!(libev|c-ares|cjson|boost|lib*|expat|tiff|freetype|udns|pcre2)
rm -Rf feeds/packages/!(lang|libs|devel|utils|net|multimedia)
rm -Rf feeds/packages/multimedia/!(gstreamer1)
rm -Rf feeds/packages/utils/!(pcsc-lite|xz)
rm -Rf feeds/packages/net/!(mosquitto|curl)
rm -Rf feeds/packages/lang/!(python|golang|node|node-yarn)
rm -Rf feeds/base/package/{kernel,firmware}
rm -Rf feeds/base/package/network/!(services)
rm -Rf feeds/base/package/network/services/!(ppp)
rm -Rf feeds/base/package/utils/!(util-linux|lua)
rm -Rf feeds/base/package/system/!(opkg|ubus|uci)
rm -Rf feeds/custom/luci-app-*/po/!(zh_Hans)

./scripts/feeds update -a
./scripts/feeds install -a

sed -i 's/Os/O2/g' include/target.mk
#rm -rf ./feeds/packages/lang/golang
#svn co https://github.com/immortalwrt/packages/trunk/lang/golang feeds/packages/lang/golang
sed -i "s/+nginx\( \|$\)/+nginx-ssl\1/g"  package/feeds/custom/*/Makefile
sed -i 's/+python\( \|$\)/+python3/g' package/feeds/custom/*/Makefile
sed -i 's?../../lang?$(TOPDIR)/feeds/packages/lang?g' package/feeds/custom/*/Makefile
for ipk in $(find package/feeds/custom/* -maxdepth 0); do	
	if [[ ! -d "$ipk/patches" && ! "$(grep "codeload.github.com" $ipk/Makefile)" ]]; then
		find $ipk/ -maxdepth 1 -name "Makefile" ! -path *tcping* ! -path *rblibtorrent* ! -path *n2n_v2* \
		| xargs -i sed -i "s/PKG_SOURCE_VERSION:=[0-9a-z]\{15,\}/PKG_SOURCE_VERSION:=HEAD/g" {}
	fi
done
sed -i 's/$(VERSION) &&/$(VERSION) ;/g' include/download.mk

cp -f devices/common/.config .config
mv feeds/base feeds/base.bak
mv feeds/packages feeds/packages.bak
make defconfig
rm -Rf tmp
mv feeds/base.bak feeds/base
mv feeds/packages.bak feeds/packages
sed -i 's/CONFIG_ALL=y/CONFIG_ALL=n/' .config

cp -f devices/common/po2lmo staging_dir/host/bin/po2lmo
chmod +x staging_dir/host/bin/po2lmo

sed -i 's,$(STAGING_DIR_HOST)/bin/upx,upx,' package/feeds/custom/*/Makefile

sed -i "/mediaurlbase/d" package/feeds/*/luci-theme*/root/etc/uci-defaults/*

sed -i '/WARNING: Makefile/d' scripts/package-metadata.pl

