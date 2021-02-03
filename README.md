# Linux-factory-reset
scripts used in factory reset, partition auto clonning

How:
 * Make u-boot chnages. The chnages makes u-boot to boot from second partiton than the default one
     * I did it for iMX6 and Beaglebone.
     * iMX6 would boot from <block_device>p3 instead <block_device>p2 when GPIO 120 is LOW. 
         * (default is down, pull it up with a resistor)
     * am335 would boot from <block_device>p2 instead <block_device>p1 when GPIO 48 is LOW
 * Partition the Sdcard or eMMC with the partitioning script.
     * Will create an extra partittion on remainig space (give it by configuration) for /var/log and /usr/share tp repserver the root/live partition from to many writes so it can stay healthly longer
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
     
    
   
