#!/bin/bash
#
# Copyright (C) [2021] by [O. Marius C.] / CircinusX1@github
#
########################################################################
BLK=/dev/mmcblk1 # k0=SDcard on BBB k1 eMMC configured to clone P2 to P1 (am335)
		 # configure sccordingly to your partitions		
FACT=p2   # this partition, call ir factory because is used in
#FACT=p3  # iMx6ull
          # restoring primary partition p1(rootfs / live) from p2(fact)
          # system boots here when a GPIO is pressed.  
LIVE=p1   # destination partiion (live, when system boots normally)
#live=P2  # iMx6ull

DATA=p3   # data partition. I ln -s /var/log & /usr/share to /data in p2
# DATA=p4 #iMx6ull
# BOOT=p1 #iMxull
########################################################################

[[ -z $(which rsync) ]] && "THE /usr/bin/rsync IS REQUIRED" && exit 1
[[ -z $(which sfdisk) ]] && "THE /sbin/sfdisk IS REQUIRED" && exit 1

#BOOT_P=${BLK}${BOOT} # iMX6ull
LIVE_P=${BLK}${LIVE}
FACT_P=${BLK}${FACT}
DATA_P=${BLK}${DATA}

LIVE_D=/tmp/live
DATA_D=/tmp/data
FACT_D=/
#BOOT_D=/boot

#
# cannot use this as destination & canot use another one as (this) source
#
THISP=$(mount | grep "/ " | awk '{print $1}')
[[ ${THISP} =~ ${LIVE_P} ]] && echo "${THISP} == ${LIVE_P} ABORTING" && exit 0
[[ ${THISP} != ${FACT_P} ]] && echo "${THISP} != ${FACTP_P} ABORTING" && exit 0


clear
echo "---------------------------------------------------------------"
echo "RESETTING TO FACTORY $LIVE_P"
echo "BOOTED FROM: ${THISP}  as /"
echo "FLASHING FROM THIS PART: ${THISP} AS [/] -> ${LIVE_P}"
echo "ALL BLOCK DEVICES WE FOUND"
echo "---------------------------------------------------------------"
sfdisk -l | grep "/dev"
echo "---------------------------------------------------------------"
echo "WANNA ENTER NEW PARAMETERS (y/n/Ctrl+C)"
read YN
if [[ $YN == 'y' ]];then
	echo -n "ENTER BLOCK DEVICE WE WOULD FLASH. EG: /dev/mmcblk0 or /dev/mmcblk1: "
	read BLK
	[[ ! -b ${BLK} ]] && echo "NO SUCH ${BLK}  BLOCK DEVICE" && exit 1
	echo -n "ENTER PARTITION  WE WOULD FLASH. EG: p1 p2 or p3 : "
	read  LIVE
	[[ ! -b ${BLK}${LIVE} ]] && echo "NO SUCH ${BLK}${LIVE} PARTITION" && exit 1
fi

LIVE_P=${BLK}${LIVE}
FACT_P=${BLK}${FACT}
DATA_P=${BLK}${DATA}

echo "---------------------------------------------------------------"
echo "RESETTING TO FACTORY $LIVE_P"
echo "BOOTED FROM: ${THISP}  as /"
echo "FLASHING FROM THIS PART: ${THISP} AS [/] -> ${LIVE_P}  (Ctrl+C to ABORT)"
read YN

this_sz=$(df | grep ${THISP} | awk {'print $3'})
this_sz=$((this_sz*1024))
echo "FACTORY OS IMAGE SIZE IS: ${this_sz} Bytes"
dest_sz=$(sfdisk -l ${LIVE_P} | grep Disk | awk {'print $5'})
echo "NEW PARTITION WE FLASH SIZE IS: ${dest_sz} Bytes"
ROOM=$((dest_sz-this_sz))
echo "DESTINATION FREE SPACE AFTER BURNING:  ${ROOM}"
if [[ $ROOM < 200000 || ${ROOM} < 0 ]];then
	echo "NOT ENGOUH ROOM ON ${LIVE_P} OF ${dest_sz} Bytes TO BURN / OF ${this_sz}" && exit 1
else
	echo "BURNING / -> ${LIVE_P}. YOU WILL HAVE ${ROOM} Bytes FREE. CONTINUE ? (y/Ctrl+C)"
	read YN
fi



function drop()
{
    sync
    pushd / > /dev/zero
        /bin/umount ${LIVE_P}
        /bin/umount ${DATA_P}
	[[ ! -z ${BOOT_P} ]] && /bin/umount ${BOOT_P}
	
        rm -rf ${DATA_D}
        rm -rf ${LIVE_D}
	[[ ! -z ${BOOT_D} ]] && rm -rf ${BOOT_D}
	
    popd > /dev/zero
}

#
#   sig
#
trap drop SIGINT
drop

#
# check
#
echo "USING ${LIVE_P} ${LIVE_D} AND ${DATA_P} ${DATA_D}"
sleep 5
echo "CHECKING BLOCK DEVICES"
[[ ! -b $LIVE_P ]] && echo "CANNOT FIND $LIVE_P" && exit 1
[[ ! -b $DATA_P ]] && echo "CANNOT FIND $DATA_P" && exit 1

#
# u-boot and MLO if any
#
if [[ -f /boot/u-boot.img && -f /boot/MLO ]];then
    echo "COPYING UBOOT "
    /bin/dd if=/boot/MLO of=${BLK} count=1 seek=1 bs=128k; sync
    /bin/dd if=/boot/u-boot.img of=${BLK} count=2 seek=1 bs=384k; sync
# iMX6ull
# /bin/dd if=/boot/SPL.mmc of=${BLK} bs=1K seek=1; sync
# /bin/dd if=/boot/u-boot.img.mmc of=${BLK} bs=1K seek=69; sync
fi


#
# format LIVE
#
echo "FORMATING BLOCK DEVICES"
drop
/sbin/mkfs.ext4 -F ${LIVE_P} -Llive
/sbin/mkfs.ext4 -F ${DATA_P} -Ldata
/bin/sync

#
# mount
#
echo "MOUNTING BLOCK DEVICES"
[[ -d ${LIVE_D} ]] && echo "WHY THERE IS A FOLDER: ${LIVE_D}" && exit 1
[[ -d ${LIVE_D} ]] && echo "WHY THERE IS A FOLDER: ${DATA_D}" && exit 1

/bin/mkdir -p ${LIVE_D}
/bin/mkdir -p ${DATA_D}
/bin/mkdir -p ${BOOT_D}

/bin/mount ${LIVE_P} ${LIVE_D}
/bin/mount ${DATA_P} ${DATA_D}
[[ ! -z ${BOOT_P} ]] && /bin/mount ${BOOT_P} ${BOOT_D}

#
# checking
#
echo "CHECKING MOUNT POINTS"
[[ ! -d $LIVE_D ]] && drop && echo "CANNOT FIND $LIVE_D" && exit 1
[[ ! -d $DATA_D ]] && drop && echo "CANNOT FIND $DATA_D" && exit 1
/bin/sync
rm -rf /${LIVE_D}/*
rm -rf /${DATA_D}/*
/bin/sync

#
# uboot and MLO
#
if [[ -f /boot/u-boot.img && -f /boot/MLO ]];then
    echo "COPYING UBOOT "
    /bin/dd if=/boot/MLO of=${BLK} count=1 seek=1 bs=128k
    /bin/dd if=/boot/u-boot.img of=${BLK} count=2 seek=1 bs=384k
# iMX6ull
# /bin/dd if=/boot/SPL.mmc of=${BLK} bs=1K seek=1; sync
# /bin/dd if=/boot/u-boot.img.mmc of=${BLK} bs=1K seek=69; sync
fi


#
# replicating
#
echo "REPLICATING"
/usr/bin/rsync -avxHAX --progress \
--exclude ${LIVE_D} \
--exclude ${DATA_D} \
--exclude /dev/ \
--exclude /proc/ \
--exclude /sys/ \
--exclude /run/ \
--exclude /mnt/ \
--exclude /tmp/ \
--exclude /lost+found \
--numeric-ids / ${LIVE_D} > /dev/null

for D in /dev \
	 /proc \
	 /sys \
	 /run \
	 /mnt \
	 /tmp;do
	[[ ! -d ${LIVE_D}${D} ]] && echo MAKING ${LIVE_D}${D}&&  mkdir -p ${LIVE_D}${D}
done
/bin/sync && /bin/sync

#
# u-boot and MLO if any again
#
if [[ -f /boot/u-boot.img && -f /boot/MLO ]];then
    echo "COPYING UBOOT "
    /bin/dd if=/boot/MLO of=${BLK} count=1 seek=1 bs=128k
    /bin/dd if=/boot/u-boot.img of=${BLK} count=2 seek=1 bs=384k
fi


echo "UPDATING INITRAMFS AT ${LIVE_D}"
cat << EOF | chroot ${LIVE_D}
	 update-initramfs -u
EOF

#
# GENERATE FSTAB
#
echo "GENERATING FSTAB TO  ${LIVE_D}"
echo "# generated by recvoery.sh at $(date)" > ${LIVE_D}/etc/fstab
echo "${LIVE_P}  /      ext4  noatime,errors=remount-ro  0  1" >> ${LIVE_D}/etc/fstab
echo "${DATA_P}  /data  ext4  noatime,nodev              0  0"  >> ${LIVE_D}/etc/fstab
# echo "${FACT_P}  /fact  ext4  noatime,nodev              0  0"  >> ${LIVE_D}/etc/fstab
[[ ! -z ${BOOT_P} ]] && echo "${BOOTP_P}  /bootm  ext4  noatime,nodev              0  0"  >> ${LIVE_D}/etc/fstab

# BBB only
echo "debugfs  /sys/kernel/debug  debugfs  mode=755,uid=root,gid=gpio,defaults  0  0"  >> ${LIVE_D}/etc/fstab

#
# LOGS AND USR SHARE
#
echo "REDIRECTING /var/log TO /data/var/log"

rm -r ${DATA_D}/*
/bin/sync
/bin/mkdir -p ${LIVE_D}/data
/bin/mkdir -p ${LIVE_D}/fact

for FLD in "var/log" "usr/share";do
    mkdir -p ${DATA_D}/${FLD}
    /usr/bin/rsync -ra ${FACT_D}/${FLD}/ ${DATA_D}/${FLD}/
    mv ${LIVE_D}/${FLD} ${LIVE_D}/${FLD}-disabled
    ln -s "/data/${FLD}" ${LIVE_D}/${FLD}
done

[[ ! -z ${BOOT_P} ]] && rm -rf ${BOOT_D}/bootfact
/bin/sync
echo "DONE"
drop
# uncomment when all looks good
reboot
