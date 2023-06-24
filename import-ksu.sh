#!/bin/sh
set -eux

GKI_ROOT=$(pwd)

echo "[+] GKI_ROOT: $GKI_ROOT"

if test -d "$GKI_ROOT/common/drivers"; then
	DRIVER_DIR="$GKI_ROOT/common/drivers"
elif test -d "$GKI_ROOT/drivers"; then
	DRIVER_DIR="$GKI_ROOT/drivers"
else
	echo '[ERROR] "drivers/" directory is not found.'
	echo '[+] You should modify this script by yourself.'
	exit 127
fi

echo '[+] Clone KernelSU, default select latest tag'

test -d "$GKI_ROOT/KernelSU" || git clone https://github.com/tiann/KernelSU
cd "$GKI_ROOT/KernelSU"
git stash
if [ "$(git status | grep -Po 'v\d+(\.\d+)*' | head -n1)" ]; then
	git checkout main
fi
git pull
if [ -z "${1-}" ]; then
	LatestTag="$(git describe --abbrev=0 --tags)"
	Tag="$LatestTag"
	git checkout "$Tag"
else
	Tag="$1"
	git checkout "$Tag"
fi
cd "$GKI_ROOT"

echo '[+]  Done cloning KernelSU'

echo "[+] GKI_ROOT: $GKI_ROOT"
echo "[+] Copy kernel su driver to $DRIVER_DIR"

rm -rf $DRIVER_DIR/kernelsu
mkdir -p $DRIVER_DIR/kernelsu
cd "$DRIVER_DIR"
if test -d "$GKI_ROOT/common/drivers"; then
	#ln -sf "../KernelSU/kernel/" "kernelsu"
	cp -r "../KernelSU/kernel/" "kernelsu"
elif test -d "$GKI_ROOT/drivers/"; then
	#ln -sf "../KernelSU/kernel/" "kernelsu"
	cp -r "../KernelSU/kernel/" "kernelsu"
fi
cd "$GKI_ROOT"

echo "[+] Done copying kernel su driver to $DRIVER_DIR"

echo '[+] Add kernel su driver to Makefile'

DRIVER_MAKEFILE=$DRIVER_DIR/Makefile
DRIVER_KCONFIG=$DRIVER_DIR/Kconfig
grep -q "kernelsu" "$DRIVER_MAKEFILE" || printf "obj-\$(CONFIG_KSU) += kernelsu/kernel/\n" >>"$DRIVER_MAKEFILE"
grep -q "kernelsu" "$DRIVER_KCONFIG" || sed -i "/endmenu/i\\source \"drivers/kernelsu/kernel/Kconfig\"" "$DRIVER_KCONFIG"

echo '[+] Done adding kernel su driver to Makefile'

echo '[+] Add commit message'

# Use "git apply" so that changes are uncommitted
curl https://github.com/zeta96/L_soul_santoni_msm4.9/commit/fa9b7919fe336cd3f231b8bf0a69e3bd359c1e54.patch | curl https://github.com/zeta96/L_soul_santoni_msm4.9/commit/d2f1fa892f568c45986ce612ed9c968ff193616e.patch | git apply
git add "$DRIVER_MAKEFILE" && git add "$DRIVER_KCONFIG" && git add "$DRIVER_DIR/kernelsu" && git commit --message="KernelSU: Update to version $Tag"

echo '[+] Done adding commit message'

echo '[+] Done.'