#!/bin/sh

# OpenWRT distribution script
# v1.2

RELEASE="14.07" # $(date +%Y%m%d-%H%M)
TARGET="kirkwood"
PROFILE="legacy"
SRC="$(dirname ${0})"
TRG="$(pwd)"

case "${1}" in
pack)
	echo "Construction OpenWRT distribution package from [${SRC}] to [${TRG}]"
	read -p "Press enter to chroot or cancel by CTRL+C"

	tar -C "${SRC}" -cvzf "${TRG}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.tar.gz" .git .config feeds.conf feeds/{luci,management,oldpackages,packages,routing,telephony}/.git "${SRC}/$(basename ${0})"
	rsync -ri "${SRC}/$(basename ${0})" "${SRC}/target/linux/${TARGET}/README" "${TRG}/"
	if [ -d "${SRC}/bin/${TARGET}" ]; then
		cd ${SRC}/bin/${TARGET}
		rsync -ri openwrt*${TARGET}*${PROFILE}*{rootfs.ubi,rootfs.tar.gz,uImage} "${TRG}/"
		cd -
	fi

	echo "Constructed OpenWRT distribution"
	;;
unpack)
	echo "Reconstructing OpenWRT tree in [${TRG}] from [${SRC}]"
	read -p "Press enter to chroot or cancel by CTRL+C"

	tar -C ${TRG} -xzf ${SRC}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.tar.gz

	git checkout --force HEAD

	for git in . feeds/{luci,management,oldpackages,packages,routing,telephony}; do
		cd ${TRG}/${git}; git checkout --force HEAD; cd -
	done

	cp -vf ${TRG}/.config ${TRG}/.config.orig
	cd ${TRG}/; ./scripts/feeds update -i; cd -
	cd ${TRG}/; ./scripts/feeds install -a; cd -
	cp -vf ${TRG}/.config.orig ${TRG}/.config
	make oldconfig
	if [ -n "$(diff ${TRG}/.config.orig ${TRG}/.config)" ]; then
		echo "Something went wrong, configs do not match!"
	else
		echo "Reconstructed OpenWRT tree"
	fi

	;;
*)
	echo "Usage: ${0} <pack/unpack>"
	exit 255
	;;
esac
