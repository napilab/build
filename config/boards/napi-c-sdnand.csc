# NAPI-C with SD NAND

source "${SRC}/config/boards/napi-c.csc"

BOARD_NAME="NAPI-C SD NAND"
BOOT_FDT_FILE="rockchip/rk3308-napi-c-sdnand.dtb"
BOOTPATCHDIR+=" v2024.10/board_napi-c"
