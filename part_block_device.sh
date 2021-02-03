#!/bin/bash
#
# Copyright (C) [2021] by [O. Marius C.] / CircinusX1@github
#
##########################################################################################
# partition config
#                    - pname                    +X starts previous + 1 sector
#                    |    - label               |   -uses 30% from total sectors
#                    |    |  |start             |   |
#                    |    |  |    - size        |   |     |type                             | END->fills up
# 4 partitions
# readonly CONFIG=("P1 BOOT 5M 100M c" "P2 ROOT +1 30% 83" "P3 FACT +1 20% 83" "P4 DATA +1 END 83")
# 3 partitons
readonly CONFIG=("P1 ROOT 5M 30% 83" "P2 FACT +1 20% 83" "P3 DATA +1 END 83")
#
# the 5M space isn case you have to dd the u-boot and or SPL or MLO
# the P1 fat in case you have to copy it in first FAT partition
# also you can put there the kernel and dts files
#
readonly NODE=/dev/mmcblk1
readonly CFG=/tmp/sfdisk.conf
###########################################################################################
[[ $(whoami) != "root" ]] && echo "run as root"

echo "PARTITIONING ${NODE} INTO 4 PARTITIONS. Ctrl+C TO ABORT"
read YN
###########################################################################################
[[ ! -b ${NODE} ]] && echo "no emmc at ${NODE}"
THISP=$(mount | grep "/ " | awk '{print $1}')
[[ ${THISP} =~ ${NODE} ]] && echo "DANGER!!! YOU ARE ABOUT TO WIPE OUT CURRENT ROOT PARTITION. CHECK NODE VARIABLE !!! " && exit 1


BYTES=$(fdisk -l ${NODE}  | grep bytes | grep ${NODE} | awk {'print $5'})
SECTS=$(fdisk -l ${NODE}  | grep bytes | grep ${NODE} | awk {'print $7'})
SECTOR=$((BYTES/SECTS))
echo "# DEVICE: ${NODE}"
echo "# BYTES ${BYTES}"
echo "# SECTORS ${SECTS}"
echo "# SECTOR ${SECTOR}"

echo "INFO BEFORE RUNNING. Ctrl+C TO ABORT"
read YN

accum=0
check_sects=0;

LABEL=$(echo date | md5sum)
LABEL=${LABEL:0:8}
echo "label-id: 0x${LABEL}" > $CFG
echo "device: ${NODE}" >> $CFG
echo "unit: sectors" >> $CFG
echo "" >> $CFG

for P in "${CONFIG[@]}";do
	pname=$(echo $P | awk '{print $1}')
	label=$(echo $P | awk '{print $2}')
	start=$(echo $P | awk '{print $3}')
	size=$(echo $P | awk '{print $4}')
	type=$(echo $P | awk '{print $5}')
	[[ ${start} =~ "M" ]] && start=${start: :-1} && start=$((start*1000000)) && start=$((start/SECTOR))
	[[ ${start} =~ "G" ]] && start=${start: :-1} && start=$((start*1000000000)) && start=$((start/SECTOR))
	[[ ${start} =~ "+" ]] && start=${start:1} && start=$((start+accum)) # in sectors
	[[ ${size} =~ "M" ]] && size=${size: :-1} && size=$((size*1000000)) && size=$((size/SECTOR))
	[[ ${size} =~ "G" ]] && size=${size: :-1} && size=$((size*1000000000)) && size=$((size/SECTOR))
	[[ ${size} =~ "%" ]] && size=${size: :-1} && size=$((SECTS*size)) && size=$((size/100))
	[[ ${size} =~ "END" ]] && size=$((SECTS-accum-1))
	accum=$((start+size))
	check_sects=$((SECTS-accum));
	echo "${NODE}${pname} : start=${start},	size=${size},    type=${type}" >> $CFG
done
echo >> $CFG
echo "$CONFIG content"
cat $CFG
if [[ -f ${CFG} && -b $NODE ]];then
	sfdisk ${NODE} < ${CFG}
	sfdisk -l ${NODE}
fi
