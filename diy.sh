#!/bin/bash
set -e

echo "=== Добавляем устройство xiaomi_mir3g-nor ==="

python3 << 'PYEOF'
content = """// SPDX-License-Identifier: GPL-2.0-or-later

/dts-v1/;

#include "mt7621.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

/ {
	compatible = "xiaomi,mir3g-nor", "mediatek,mt7621-soc";
	model = "Xiaomi Mi Router 3G (NOR mod)";

	aliases {
		led-boot = &led_status_yellow;
		led-failsafe = &led_status_red;
		led-running = &led_status_blue;
		led-upgrade = &led_status_yellow;
	};

	chosen {
		bootargs = "console=ttyS0,115200n8 earlycon=uart8250,mmio32,0x1e000c00";
	};

	leds {
		compatible = "gpio-leds";

		led_status_red: led-0 {
			function = LED_FUNCTION_INDICATOR;
			color = <LED_COLOR_ID_RED>;
			gpios = <&gpio 6 GPIO_ACTIVE_LOW>;
		};

		led_status_blue: led-1 {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_BLUE>;
			gpios = <&gpio 8 GPIO_ACTIVE_LOW>;
		};

		led_status_yellow: led-2 {
			function = LED_FUNCTION_INDICATOR;
			color = <LED_COLOR_ID_YELLOW>;
			gpios = <&gpio 10 GPIO_ACTIVE_LOW>;
		};
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&gpio 18 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};
	};
};

&spi0 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <10000000>;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "u-boot";
				reg = <0x0 0x30000>;
				read-only;
			};

			partition@30000 {
				label = "u-boot-env";
				reg = <0x30000 0x10000>;
			};

			factory: partition@40000 {
				label = "factory";
				reg = <0x40000 0x10000>;
				read-only;

				nvmem-layout {
					compatible = "fixed-layout";
					#address-cells = <1>;
					#size-cells = <1>;

					macaddr_factory_e000: macaddr@e000 {
						reg = <0xe000 0x6>;
					};

					macaddr_factory_e006: macaddr@e006 {
						reg = <0xe006 0x6>;
					};
				};
			};

			partition@50000 {
				compatible = "denx,uimage";
				label = "firmware";
				reg = <0x50000 0xfb0000>;
			};
		};
	};
};

&gmac0 {
	nvmem-cells = <&macaddr_factory_e000>;
	nvmem-cell-names = "mac-address";
};

&gmac1 {
	status = "okay";
	label = "wan";
	phy-handle = <&wan_phy>; /* Указываем нашу кастомную уникальную метку */

	nvmem-cells = <&macaddr_factory_e006>;
	nvmem-cell-names = "mac-address";
};

&mdio {
	/* Объявляем PHY с уникальным именем wan_phy, привязанным к 4 порту */
	wan_phy: ethernet-phy@4 {
		reg = <4>;
	};
};

&switch0 {
	ports {
		port@0 {
			status = "okay";
			label = "lan1";
		};

		port@1 {
			status = "okay";
			label = "lan2";
		};
	};
};

/* Полностью отключаем контроллер PCIe для полной изоляции Wi-Fi */
&pcie {
	status = "disabled";
};

&xhci {
	status = "okay";
};
"""

with open("target/linux/ramips/dts/mt7621_xiaomi_mir3g-nor.dts", "w") as f:
    f.write(content)

print("DTS записан успешно")

with open("target/linux/ramips/dts/mt7621_xiaomi_mir3g-nor.dts") as f:
    data = f.read()
    if '&pcie' in data and 'disabled' in data:
        print("OK: &pcie { status = disabled } найден в DTS")
    else:
        print("ОШИБКА: фикс PCIe не найден!")
        exit(1)
PYEOF

echo "✓ DTS создан"

cat >> target/linux/ramips/image/mt7621.mk << 'MKEOF'

define Device/xiaomi_mir3g-nor
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router 3G
  DEVICE_VARIANT := NOR mod
  DEVICE_COMPAT_COMPATIBLE := xiaomi,mir3g-nor
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-ledtrig-usbport uboot-envtools
endef
TARGET_DEVICES += xiaomi_mir3g-nor
MKEOF


echo "✓ Запись в mt7621.mk добавлена"

cat >> package/base-files/files/etc/board.d/02_network << 'NETEOF'

xiaomi_mir3g-nor_network() {
	ucidef_set_interfaces_lan_wan "lan1 lan2" "wan"
}
NETEOF

echo "✓ Сетевые настройки добавлены"
echo "=== Готово ==="
