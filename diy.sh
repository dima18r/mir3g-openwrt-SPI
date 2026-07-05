#!/bin/bash

# Создаем абсолютно чистое дерево устройств (DTS) под нашу SPI разметку 16МБ
cat << 'EOF' > openwrt/target/linux/ramips/dts/mt7621_xiaomi_mir3g-nor.dts
/dts-v1/;

#include "mt7621.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>

/ {
	compatible = "xiaomi,mi-router-3g", "mediatek,mt7621-soc";
	model = "Xiaomi Mi Router 3G (SPI NOR Mod)";

	aliases {
		led-boot = &led_blue;
		led-failsafe = &led_yellow;
		led-running = &led_blue;
		led-upgrade = &led_yellow;
	};

	chosen {
		bootargs = "console=ttyS0,115200n8 rootfstype=squashfs,jffs2";
	};

	leds {
		compatible = "gpio-leds";

		led_blue: blue {
			label = "blue";
			gpios = <&gpio 6 GPIO_ACTIVE_LOW>;
		};

		led_yellow: yellow {
			label = "yellow";
			gpios = <&gpio 8 GPIO_ACTIVE_LOW>;
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
		spi-max-frequency = <50000000>;

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

				compatible = "nvmem-cells";
				#address-cells = <1>;
				#size-cells = <1>;

				eeprom_factory_0: eeprom@0 {
					reg = <0x0 0x400>;
				};

				macaddr_factory_e000: macaddr@e000 {
					reg = <0xe000 0x6>;
				};

				macaddr_factory_e006: macaddr@e006 {
					reg = <0xe006 0x6>;
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
	phy-handle = <&wan_phy>;
	nvmem-cells = <&macaddr_factory_e006>;
	nvmem-cell-names = "mac-address";
};

&mdio {
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

&nand {
	status = "disabled";
};

&xhci {
	status = "okay";
};

/* АППАРАТНАЯ ИЗОЛЯЦИЯ: Запускаем только живой чип 5 ГГц, намертво глушим 2.4 ГГц */
&pcie {
	status = "okay";
};

&pcie0 {
	status = "okay";
	wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
		nvmem-cells = <&eeprom_factory_0>, <&macaddr_factory_e000>;
		nvmem-cell-names = "eeprom", "mac-address";
	};
};

&pcie1 {
	status = "disabled";
	/delete-property/ clocks;
	/delete-property/ clock-names;
	/delete-property/ resets;
	/delete-property/ reset-names;
};
EOF

# Регистрируем устройство в официальном Makefile mt7621.mk
cat << 'EOF' >> openwrt/target/linux/ramips/image/mt7621.mk

define Device/xiaomi_mir3g-nor
  IMAGE_SIZE := 16064k
  DEVICE_VENDOR := Xiaomi
  DEVICE_MODEL := Mi Router 3G
  DEVICE_VARIANT := SPI NOR Mod
  DEVICE_COMPAT_COMPATIBLE := xiaomi,mi-router-3g
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-storage kmod-fs-ext4 uboot-envtools kmod-mt76x2
endef
TARGET_DEVICES += xiaomi_mir3g-nor
EOF

# Настраиваем сетевые интерфейсы DSA под нашу разметку портов
mkdir -p openwrt/package/base-files/files/etc/board.d
cat << 'EOF' >> openwrt/package/base-files/files/etc/board.d/02_network
xiaomi_mir3g-nor_network() {
	ucidef_set_interfaces_lan_wan "lan1 lan2" "wan"
}
EOF
sed -i '/xiaomi,mi-router-3g|/a \\txiaomi,mir3g-nor|\\\\' openwrt/package/base-files/files/etc/board.d/02_network
