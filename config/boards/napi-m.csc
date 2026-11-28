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
INCLUDE_HOME_DIR="yes" # the napi user is created at build time; without /home its desktop session cannot start

# Raspberry Pi compatible DSI display on J11 (Radxa 39p-to-15p cable, contacts up).
# The overlay and its helper are always installed; NAPI_M_DSI_DISPLAY=yes also enables the overlay.
NAPI_M_DSI_DISPLAY="${NAPI_M_DSI_DISPLAY:-no}"
NAPI_M_DSI_OVERLAY="napi-rk3562-dsi-rpi-display"

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

function custom_kernel_config__napi_m_dsi_touch() {
	opts_m+=("TOUCHSCREEN_RASPITS_FT5426") # polling touch driver: the 15-pin display cable has no interrupt line
}

function post_family_tweaks__napi_m_dsi_display() {
	declare src="${SRC}/packages/bsp/napi-m-dsi"
	declare dtso="${SRC}/patch/kernel/rk35xx-vendor-6.1/overlay/${NAPI_M_DSI_OVERLAY}.dtso"

	display_alert "${BOARD}" "installing the DSI display overlay and helper" "info"
	run_host_command_logged mkdir -p "${SDCARD}/boot/overlay-user"
	run_host_command_logged dtc -@ -q -I dts -O dtb -o "${SDCARD}/boot/overlay-user/${NAPI_M_DSI_OVERLAY}.dtbo" "${dtso}"
	run_host_command_logged install -m 755 "${src}/napi-dsi-rebind" "${SDCARD}/usr/sbin/napi-dsi-rebind"
	run_host_command_logged install -m 644 "${src}/napi-dsi-rebind.service" "${SDCARD}/etc/systemd/system/napi-dsi-rebind.service"
	chroot_sdcard "systemctl --no-reload enable napi-dsi-rebind.service"
	# raspits_ft5426 has no module alias, so it is not loaded by the device tree node alone
	echo "raspits_ft5426" > "${SDCARD}/etc/modules-load.d/napi-dsi-touch.conf"

	if [[ "${NAPI_M_DSI_DISPLAY}" == yes && "${BUILD_DESKTOP}" == yes ]]; then
		display_alert "${BOARD}" "desktop autologin for user napi (DSI display)" "info"
		run_host_command_logged mkdir -p "${SDCARD}/etc/lightdm/lightdm.conf.d"
		printf '[Seat:*]\nautologin-user=napi\nautologin-user-timeout=0\n' > "${SDCARD}/etc/lightdm/lightdm.conf.d/50-napi-autologin.conf"
	fi
	return 0
}

function image_specific_armbian_env_ready__napi_m_dsi_display() {
	[[ "${NAPI_M_DSI_DISPLAY}" == yes ]] || return 0
	display_alert "${BOARD}" "enabling overlay ${NAPI_M_DSI_OVERLAY}" "info"
	printf 'user_overlays=%s\n' "${NAPI_M_DSI_OVERLAY}" >> "${SDCARD}/boot/armbianEnv.txt"
	return 0
}
