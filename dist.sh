#!/bin/sh

# OpenWRT distribution script
# v0.1

RELEASE="14.07-rc3-20140827"
TARGET="kirkwood"
SRC="$(dirname ${0})"
TRG="$(pwd)"

case "${1}" in
pack)
	echo "Construction OpenWRT distribution package from [${SRC}] to [${TRG}]"
	read -p "Press enter to chroot or cancel by CTRL+C"

	tar -C ${SRC} -cvzf ${TRG}/openwrt-${RELEASE}.tar.gz .git .config feeds.conf feeds/{luci,management,oldpackages,packages,routing,telephony}/.git "${SRC}/target/linux/${TARGET}/README" "${SRC}/$(basename ${0})"
	[ ! -d "${SRC}/bin/${TARGET}" ] || rsync -ri --exclude="${TARGET}/packages" "${SRC}/bin" "${TRG}/"
	rsync -ri "${SRC}/$(basename ${0})" "${TRG}/"

	echo "Constructed OpenWRT distribution"
	;;
unpack)
	echo "Reconstructing OpenWRT tree in [${TRG}] from [${SRC}]"
	read -p "Press enter to chroot or cancel by CTRL+C"

	tar -C ${TRG} -xzf ${SRC}/openwrt-${RELEASE}.tar.gz

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
