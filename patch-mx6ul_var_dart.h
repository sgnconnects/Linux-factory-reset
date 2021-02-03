--- ./debian_mx6uldart_variscite/src/uboot/include/configs/mx6ul_var_dart.h	2021-01-12 11:02:48.136046256 -0500
+++ ./build_scripts/linux_patches/mx6ul_var_dart.h	2020-10-21 16:24:08.988295298 -0400
@@ -12,6 +12,7 @@
 
 #include "mx6_common.h"
 
+/* this dart mco-mco*/
 /* DCDC used on DART-6UL, no PMIC */
 #undef CONFIG_LDO_BYPASS_CHECK
 
@@ -70,8 +71,8 @@
 		"bootz ${loadaddr} - ${fdt_addr}\0" \
 	"mtdids=" MTDIDS_DEFAULT "\0" \
 	"mtdparts=" MTDPARTS_DEFAULT "\0"
-
-
+/*"recovery=if gpio input 120; then mmcrootpart=3 ; else mmcrootpart=2; fi;\0" \
+	*/
 #define MMC_BOOT_ENV_SETTINGS \
 	"mmcdev="__stringify(CONFIG_SYS_MMC_ENV_DEV)"\0" \
 	"mmcblk=0\0" \
@@ -93,25 +94,43 @@
 	"loadfdt=run findfdt; " \
 		"echo fdt_file=${fdt_file}; " \
 		"load mmc ${mmcdev}:${mmcbootpart} ${fdt_addr} ${bootdir}/${fdt_file}\0" \
-	"mmcboot=echo Booting from mmc ...; " \
+	"mmcboot=echo booting from usb/emmc/sd; " \
+		"run fact; " \
+		"run gpsi; " \
 		"run mmcargs; " \
 		"run optargs; " \
 		"if test ${boot_fdt} = yes || test ${boot_fdt} = try; then " \
 			"if run loadfdt; then " \
-				"bootz ${loadaddr} - ${fdt_addr}; " \
+				"echo option 1; " \
+				"run usbb; " \
+				"if test ${gousb} = 1; then " \
+					"run mmcargs; " \
+					"run optargs; " \
+					"echo option 1-usb; " \
+					"bootz ${loadaddr} - ${fdt_addr}; " \
+				"else " \
+					"run mmcargs; " \
+					"run optargs; " \
+					"echo option 1-nonusb; " \
+					"bootz ${loadaddr} - ${fdt_addr}; " \
+				"fi; " \
 			"else " \
 				"if test ${boot_fdt} = try; then " \
+					"echo option 2; " \
 					"bootz; " \
 				"else " \
+					"echo option 3; " \
 					"echo WARN: Cannot load the DT; " \
 				"fi; " \
 			"fi; " \
 		"else " \
+			"echo option 4; " \
 			"bootz; " \
 		"fi\0" \
 
 
 #ifdef CONFIG_NAND_BOOT
+
 #define BOOT_ENV_SETTINGS	NAND_BOOT_ENV_SETTINGS
 #define CONFIG_BOOTCOMMAND \
 	"run ramsize_check; " \
@@ -119,6 +138,7 @@
 	"run netboot"
 
 #else
+
 #define BOOT_ENV_SETTINGS	MMC_BOOT_ENV_SETTINGS
 #define CONFIG_BOOTCOMMAND \
 	"run ramsize_check; " \
@@ -201,6 +221,10 @@
 				"setenv cma_size cma=64MB; " \
 			"fi; " \
 		"fi;\0" \
+	"usbb=usb stop; usb start; if load usb 0:1 0x82000000 /zImage; then echo USBBOOT; setenv loadfdt load usb 0:1 0x83000000 /imx6ull-var-dart-6ulcustomboard-emmc-wifi.dtb;setenv mmcargs setenv bootargs console=${console},${baudrate} root=/dev/sda2 rootwait rw ${cma_size}; setenv gousb 1; fi; \0"\
+	"xfile=if load mmc 1:1 0x80008000 bootfact; then setenv mmcrootpart 3; else setenv mmcrootpart 2; fi;\0" \
+	"fact=if gpio input 120; then setenv mmcrootpart 3 ; else run xfile; fi; printenv mmcrootpart;\0" \
+	"gpsi=gpio clear 131; gpio clear 116; gpio clear 4; gpio clear 5; gpio clear 9; gpio clear 38; if test ${mmcrootpart} = 2; then  gpio set 5; gpio set 9; else gpio set 38; gpio set 4 ; fi;\0" \
 	"findfdt="\
 		"if test $fdt_file = undefined; then " \
 			"if test $board_name = DART-6UL; then " \
