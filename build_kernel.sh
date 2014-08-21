#!/bin/sh
start_time=`date +'%d/%m/%y %H:%M:%S'`
export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE=`readlink -f $KERNELDIR/ramfs`
#export USE_SEC_FIPS_MODE=true
export TOOLBASE="/home/mojo/android/tools"

if [ "${1}" != "" ];then
  export KERNELDIR=`readlink -f ${1}` 
fi

RAMFS_TMP="/home/mojo/android/temp/ramfs"


pre_build_folder="../builds/"
suff_build_folder=`date +'%d_%m_%y_%H_%M'`
build_folder="$pre_build_folder""$suff_build_folder"
mkdir -p $build_folder
echo ".............................................................Created Build Folder............................................................."


echo ".............................................................Building new ramdisk............................................................."
#remove previous ramfs files
rm -rf $RAMFS_TMP > /dev/null 2>&1 
rm -rf $RAMFS_TMP.cpio > /dev/null 2>&1 
rm -rf $RAMFS_TMP.cpio.lz4 > /dev/null 2>&1 
#copy ramfs files to tmp directory
cp -R $RAMFS_SOURCE $RAMFS_TMP
cd $KERNELDIR
$TOOLBASE/mkbootfs $RAMFS_TMP > $RAMFS_TMP.cpio
ls -lh $RAMFS_TMP.cpio
lz4 -l -9 $RAMFS_TMP.cpio

echo "...............................................................Compiling kernel..............................................................."
#remove previous out files
rm $KERNELDIR/dt.img > /dev/null 2>&1 
rm $KERNELDIR/boot.img > /dev/null 2>&1 
rm $KERNELDIR/*.ko > /dev/null 2>&1 
#compile kernel
cd $KERNELDIR
make -j8 || exit 1

echo "..............................................................Making new dt image............................................................."
$TOOLBASE/dtbtool -o $KERNELDIR/dt.img -s 2048 $KERNELDIR/arch/arm/boot/

echo ".............................................................Making new boot image............................................................"
$TOOLBASE/dt-mkbootimg --base 0x0 --kernel $KERNELDIR/arch/arm/boot/zImage --ramdisk_offset 0x2000000 --tags_offset 0x1e00000 \
--pagesize 2048 --cmdline 'console=null androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 ehci-hcd.park=3' \
--ramdisk $RAMFS_TMP.cpio.lz4 --dt $KERNELDIR/dt.img -o $KERNELDIR/boot.img



echo ".....................................................................done....................................................................."
find . -name "boot.img"
find . -name "*.ko" -exec mv {} . \;
${CROSS_COMPILE}strip --strip-unneeded ./*.ko

echo "..............................................................Copying outputs to build folder............................................................."
cp $KERNELDIR/dt.img $build_folder
cp $KERNELDIR/arch/arm/boot/zImage $build_folder
cp $KERNELDIR/boot.img $build_folder
cp $RAMFS_TMP.cpio.lz4 $build_folder
find . -name "*.ko" -exec $build_folder mv {} . \;


echo "Started  : $start_time"
echo "Finished : `date +'%d/%m/%y %H:%M:%S'`"
echo "Files in: $build_folder:"
ls -l $build_folder
