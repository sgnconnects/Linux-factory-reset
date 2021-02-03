# Linux-factory-reset
scripts used in factory reset, partition auto clonning


#### imx6 The eMMC is parttioned [50M free] P1(boot / FAT) 2-live 3-fact 4-data 
   * imx5 u-boot chnages patch to boot from P3 when GPIO 120 is Down. 
        * By default  is down so it has to be pulled up to boot from P2

#### am335 (beaglebone) The emmc is partitionned [50M free] P1-root-live P2-facr p3-data
    * the usboot patch has also the am335 patches but look for MCO_* That is the change for booting from P2 when PGIO 48 is LOW
    
    
   
