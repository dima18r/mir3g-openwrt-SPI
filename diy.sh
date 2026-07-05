#!/bin/bash
set -e

echo "=== Добавляем устройство xiaomi_mir3g-nor ==="

python3 - << 'PYEOF'
dts = open("target/linux/ramips/dts/mt7621_xiaomi_mir3g-nor.dts", "w")
dts.write("""\
// SPDX-License-Identifier: GPL-2.0-or-later

/dts-v1/;

#include "mt7621.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
\tcompatible = "xiaomi,mir3g-nor", "mediatek,mt7621-soc";
\tmodel = "Xiaomi Mi Router 3G (NOR mod)";

\taliases {
\t\tled-boot = &led_status_yellow;
\t\tled-failsafe = &led_status_red;
\t\tled-running = &led_status_blue;
\t\tled-upgrade = &led_status_yellow;
\t};

\tchosen {
\t\tbootargs = "console=ttyS0,115200n8";
\t};

\tleds {
\t\tcompatible = "gpio-leds";

\t\tled_status_red: led-0 {
\t\t\tfunction = LED_FUNCTION_INDICATOR;
\t\t\tcolor = <LED_COLOR_ID_RED>;
\t\t\tgpios = <&gpio 6 GPIO_ACTIVE_LOW>;
\t\t};

\t\tled_status_blue: led-1 {
\t\t\tfunction = LED_FUNCTION_STATUS;
\t\t\tcolor = <LED_COLOR_ID_BLUE>;
\t\t\tgpios = <&gpio 8 GPIO_ACTIVE_LOW>;
\t\t};

\t\tled_status_yellow: led-2 {
\t\t\tfunction = LED_FUNCTION_INDICATOR;
\t\t\tcolor = <LED_COLOR_ID_YELLOW>;
\t\t\tgpios = <&gpio 10 GPIO_ACTIVE_LOW>;
\t\t};
\t};

\tkeys {
\t\tcompatible = "gpio-keys";

\t\treset {
\t\t\tlabel = "reset";
\t\t\tgpios = <&gpio 18 GPIO_ACTIVE_LOW>;
\t\t\tlinux,code = <KEY_RESTART>;
\t\t};
\t};
};

&spi0 {
\tstatus = "okay";

\tflash@0 {
\t\tcompatible = "jedec,spi-nor";
\t\treg = <0>;
\t\tspi-max-frequency = <10000000>;

\t\tpartitions {
\t\t\tcompatible = "fixed-partitions";
\t\t\t#address-cells = <1>;
\t\t\t#size-cells = <1>;

\t\t\tpartition@0 {
\t\t\t\tlabel = "u-boot";
\t\t\t\treg = <0x0 0x30000>;
\t\t\t\tread-only;
\t\t\t};

\t\t\tpartition@30000 {
\t\t\t\tlabel = "u-boot-env";
\t\t\t\treg = <0x30000 0x10000>;
\t\t\t};

\t\t\tfactory: partition@40000 {
\t\t\t\tlabel = "factory";
\t\t\t\treg = <0x40000 0x10000>;
\t\t\t\tread-only;

\t\t\t\tnvmem-layout {
\t\t\t\t\tcompatible = "fixed-layout";
\t\t\t\t\t#address-cells = <1>;
\t\t\t\t\t#size-cells = <1>;

\t\t\t\t\tmacaddr_factory_e000: macaddr@e000 {
\t\t\t\t\t\treg = <0xe000 0x6>;
\t\t\t\t\t};

\t\t\t\t\tmacaddr_factory_e006: macaddr@e006 {
\t\t\t\t\t\treg = <0xe006 0x6>;
\t\t\t\t\t};
\t\t\t\t};
\t\t\t};

\t\t\tpartition@50000 {
\t\t\t\tcompatible = "denx,uimage";
\t\t\t\tlabel = "firmware";
\t\t\t\treg = <0x50000 0xfb0000>;
\t\t\t};
\t\t};
\t};
};

&gmac0 {
\tnvmem-cells = <&macaddr_factory_e000>;
\tnvmem-cell-names = "mac-address";
};

&gmac1 {
\tstatus = "okay";
\tlabel = "wan";
\tphy-handle = <&ethphy4>;
\tnvmem-cells = <&macaddr_factory_e006>;
\tnvmem-cell-names = "mac-address";
};

&switch0 {
\tports {
\t\tport@0 {
\t\t\tstatus = "okay";
\t\t\tlabel = "sw0";
\t\t};

\t\tport@1 {
\t\t\tstatus = "okay";
\t\t\tlabel = "sw1";
\t\t};

\t\tport@2 {
\t\t\tstatus = "okay";
\t\t\tlabel = "sw2";
\t\t};

\t\tport@3 {
\t\t\tstatus = "okay";
\t\t\tlabel = "sw3";
\t\t};

\t\tport@4 {
\t\t\tstatus = "okay";
\t\t\tlabel = "sw4";
\t\t};

\t\tport@6 {
\t\t\tstatus = "okay";
\t\t\tlabel = "cpu";
\t\t\tethernet = <&gmac0>;
\t\t};
\t};
};

&xhci {
\tstatus = "okay";
};

&pcie {
\tstatus = "disabled";
};
""")
dts.close()

data = open("target/linux/ramips/dts/mt7621_xiaomi_mir3g-nor.dts").read()
checks = [
    ("&pcie" in data and "disabled" in data, "&pcie disabled"),
    ("port@6" in data,                        "port@6 CPU"),
    ("ethphy4" in data,                        "ethphy4"),
    ("&mdio" not in data,                      "нет дубликата &mdio"),
    ("0x50000 0xfb0000" in data,               "разметка firmware"),
]
ok = True
for result, name in checks:
    print(f"{'OK' if result else 'ОШИБКА'}: {name}")
    if not result:
        ok = False
if not ok:
    exit(1)
print("=== Все проверки пройдены ===")
PYEOF

echo "✓ DTS создан"

cat >> target/linux/ramips/image/mt7621.mk << 'MKEOF'

define Device/xiaomi_mir3g-nor
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router 3G
  DEVICE_VARIANT := NOR mod
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-ledtrig-usbport uboot-envtools
endef
TARGET_DEVICES += xiaomi_mir3g-nor
MKEOF

echo "✓ mt7621.mk обновлён"

cat >> package/base-files/files/etc/board.d/02_network << 'NETEOF'

xiaomi_mir3g-nor_network() {
	ucidef_set_interfaces_lan_wan "sw0 sw1 sw2 sw3 sw4" "wan"
}
NETEOF

echo "✓ Сетевые настройки добавлены"
echo "=== Готово ==="
