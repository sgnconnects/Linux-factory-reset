# Linux-factory-reset
scripts used in factory reset, partition auto clonning

##### Why
 * Have the device loose all user data by resetting it to known good factory image
 * Image is corrupted, reset-to-factory it and recover it.
 
##### Quick sollution for small images
 * Identical images on 2 partitions. WHen second boot;s on it replicates to first. 

##### Alternative for larger image that wont fit on both partitions
 
 * You can have in second partiton a minimal linux 80K like th eone here: https://github.com/circinusX1/minimarmfs 
 * Have the rootfs tar.gz-ed
 * Chnage the installation script to untar, instead of sync like:
 
     tar  --checkpoint=.1024 --checkpoint-action=exec=/bin/sync  --warning=no-timestamp -xhpf ${TARFILE} -C ${FACT_D}/


##### How:
 * By holoding a GPIO down for 10 seconds after Reset or on Power On it initiates a factory reset.
 
 * Make u-boot changes. The chnages makes u-boot to boot from second partiton than the default one
     * I did it for iMX6 and Beaglebone.
     * iMX6 would boot from <block_device>p3 instead <block_device>p2 when GPIO 120 is LOW. 
         * (default is down, pull it up with a resistor)
     * am335 would boot from <block_device>p2 instead <block_device>p1 when GPIO 48 is LOW
 * Partition the Sdcard or eMMC with the partitioning script.
     * Will create an extra partittion on remainig space (give some 500M by configuration) for /var/log and /usr/share 
         * Will reduce writes to  / and peserve it in case of accidental power intrerruptions
     * Edit and make changes according to your eMMC size and Linux image size. 
     * Tweak the % so the image would fit in P1 and P2, respectevily P3
 * Put same stock image on LIVE and FACT.  
     * LIVE for Beaglebone would be P1 and for iMX P2
     * FACY for Beaglebone would be P2 and for iMX P3
 * Configure the clonning script so it exist when image boots from LIVE (P1-am335 P2-iMX6ull)
 * Enable the service on both. Make it to call the clonning script.
 
 
 


#### imx6 The eMMC is parttioned as follow
 [50M free] P1(boot / FAT) 2-live 3-fact 4-data 
 
 * imx5 u-boot chnages patch to boot from P3 when GPIO 120 is Down. 
        * By default  is down so it has to be pulled up to boot from P2

#### am335 (beaglebone) The emmc is partitionned [50M free] P1-root-live P2-facr p3-data
 * the u-boot patch has also the am335 patches but look for MCO_*. That makes BBB to boot from P2 when GPIO 48 os LOW 
     
    
   
