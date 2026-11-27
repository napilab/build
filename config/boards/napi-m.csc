# Rockchip RK3562 quad core 2GB LPDDR3 eMMC GbE 100MbE USB3

BOARD_NAME="NAPI-M"
BOARD_VENDOR="napilab"
BOARDFAMILY="napi"
BOARD_MAINTAINER=""

BOOT_SOC="rk3562"
BOOTCONFIG="napi-m-rk3562_defconfig"
BOOT_FDT_FILE="rockchip/rk3562-napi-m.dtb"

# U-Boot: "vendor" is the Rockchip 2017.09 tree, "mainline" is U-Boot v2026.07 with
# the RK3562 family support of the KICKPI K3B. Choose with NAPI_M_UBOOT=mainline.
NAPI_M_UBOOT="${NAPI_M_UBOOT:-vendor}"
case "${NAPI_M_UBOOT}" in
	vendor) BOOT_SCENARIO="spl-blobs" ;;
	mainline) BOOT_SCENARIO="binman" ;;
	*) exit_with_error "NAPI_M_UBOOT must be vendor or mainline" "${NAPI_M_UBOOT}" ;;
esac

KERNEL_TARGET="vendor,vendor-next"
IMAGE_PARTITION_TABLE="gpt"
BOOT_LOGO="no"
FULL_DESKTOP="no"
DEFAULT_CONSOLE="serial"

ROOTPWD="napilinux"
CONSOLE_AUTOLOGIN="no"

PACKAGE_LIST_BOARD="avahi-daemon vim net-tools minicom tcpdump screen memtester xxd tree i2c-tools util-linux-extra"

function post_family_config__napi_m_uboot() {
	declare -g BOOTDIR="u-boot-${BOARD}"
	declare -g BOOTDELAY=2
	if [[ "${NAPI_M_UBOOT}" == mainline ]]; then
		display_alert "${BOARD}" "mainline U-Boot v2026.07" "info"
		declare -g BOOTSOURCE="https://github.com/u-boot/u-boot.git"
		declare -g BOOTBRANCH="tag:v2026.07"
		# The RK3562 family comes with the KICKPI K3B patches; board_napi-m adds the board.
		declare -g BOOTPATCHDIR="v2026.07 v2026.07/board_kickpi-k3b"
		return 0
	fi
	declare -g BOOTSOURCE="https://github.com/QwaSeeK/u-boot.git"
	declare -g BOOTBRANCH="branch:rk3562-vendor"
	declare -g BOOTPATCHDIR="none"
}

function custom_kernel_config__napi_m_soc() {
	opts_y+=("CPU_RK3562" "CLK_RK3562" "ROCKCHIP_CSU")
}
