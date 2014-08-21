#!/bin/bash

export KERNELDIR=`readlink -f .`
DEFCONFIG=aurora_msm8974_"$1"_defconfig

echo ".............................................................Checking configs............................................................"

if [ -z "$1" ]; then
	echo "Need variant type!!!!"
	exit -1
fi

if [ ! -e arch/arm/configs/$DEFCONFIG ]; then
	echo "No such variant : arch/arm/configs/$DEFCONFIG"
	echo "msm8974_sec_hlte_"$1"_defconfig"
	exit -1
fi

echo "Using defconfig:"
echo $DEFCONFIG
echo ""


echo ".............................................................Cleaning all............................................................."
cd $KERNELDIR
env KCONFIG_NOTIMESTAMP=true \
make mrproper
echo "made mrproper"


echo "...............................................................Making config..............................................................."
env KCONFIG_NOTIMESTAMP=true \
cp arch/arm/configs/$DEFCONFIG .config



# run menuconfig
env KCONFIG_NOTIMESTAMP=true \
make menuconfig ARCH=arm



