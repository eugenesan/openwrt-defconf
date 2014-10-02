#!/bin/sh -e

# OpenWRT distribution script
# v1.4

RELEASE="14.07" # $(date +%Y%m%d-%H%M)
TARGET="kirkwood"
PROFILE="legacy"
SRC="$(dirname ${0})"
TRG="$(pwd)"

case "${1}" in
pack)
	echo "Construction OpenWRT distribution package from [${SRC}] to [${TRG}]"
	read -p "Press enter to pack or cancel by CTRL+C"

	echo -e "|${RELEASE}-${TARGET}-${PROFILE}|" | tee openwrt-${RELEASE}-${TARGET}-${PROFILE}.git.log

	for git in . feeds/{luci,management,oldpackages,packages,routing,telephony}; do
		echo -e "\n[${git}]" | tee -a openwrt-${RELEASE}-${TARGET}-${PROFILE}.git.log
		GIT_DIR="${SRC}/${git}/.git" git remote show origin | grep Fetch | tee -a openwrt-${RELEASE}-${TARGET}-${PROFILE}.git.log
		GIT_DIR="${SRC}/${git}/.git" git branch -vv | grep "*" | tee -a openwrt-${RELEASE}-${TARGET}-${PROFILE}.git.log
		GIT_DIR="${SRC}/${git}/.git" git log -n1 | tee -a openwrt-${RELEASE}-${TARGET}-${PROFILE}.git.log
		GIT_DIR="${SRC}/${git}/.git" git gc --aggressive
	done
	tar -C "${SRC}" -cvf "${TRG}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.git.tar" .git feeds/{luci,management,oldpackages,packages,routing,telephony}/.git
	tar -C "${SRC}" -cvf "${TRG}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.dl.tar" dl
	if [ -d "${SRC}" ]; then
		cd "${SRC}"
		rsync -ri "$(basename ${0})" "target/linux/${TARGET}/README" "${TRG}/"
		rsync -ri ".config" "${TRG}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.config"
		rsync -ri "feeds.conf" "${TRG}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.feeds.conf"
		cd -
	fi
	if [ -d "${SRC}/bin/${TARGET}" ]; then
		cd "${SRC}/bin/${TARGET}"
		rsync -ri openwrt*${TARGET}*${PROFILE}*{rootfs.ubi,rootfs.tar.gz,uImage} "${TRG}/"
		cd -
	fi

	echo "Constructed OpenWRT distribution"
	;;
unpack)
	echo "Reconstructing OpenWRT tree in [${TRG}] from [${SRC}]"
	read -p "Press enter to unpack or cancel by CTRL+C"

	tar -C ${TRG} -xaf "${SRC}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.git.tar"
	[ -r "${SRC}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.dl.tar" ] && tar -C ${TRG} -xaf "${SRC}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.dl.tar"

	git checkout --force HEAD

	for git in . feeds/{luci,management,oldpackages,packages,routing,telephony}; do
		cd ${TRG}/${git}; git checkout --force HEAD; cd -
	done

	[ -r "${SRC}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.config" ] && cp -vf "${SRC}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.config" "${TRG}/.config"
	[ -r "${SRC}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.feeds.conf" ] && cp -vf "${SRC}/openwrt-${RELEASE}-${TARGET}-${PROFILE}.feeds.conf" "${TRG}/feeds.conf"
	[ -r "${SRC}/$(basename ${0})" ] && cp -vf "${SRC}/$(basename ${0})" "${TRG}/"

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
build)
	echo "Building OpenWRT binaries in [${TRG}]"
	read -p "Press enter to build or cancel by CTRL+C"

	make V=s -j16

	echo "Built OpenWRT binaries"
	;;
*)
	echo "Usage: ${0} <pack/unpack>"
	exit 255
	;;
esac
