#!/bin/bash
set -e

echo "=== Добавляем устройство xiaomi_mir3g-nor (v1 с перепаянным SPI) ==="

# =====================================================
# 1. DTS — описание железа
#    Основа: оригинальный mir3g v1 (256MB RAM, USB)
#    Разметка флеша: W25Q128 / GD25Q128, 16MB NOR
#    Фикс зависания: &pcie disabled
# =====================================================

cat > target/linux/ramips/dts/mt7621_xiaomi_mir3g-nor.dts << 'DTSEOF'
// SPDX-License-Identifier: GPL-2.0-or-later

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
		bootargs = "console=ttyS0,115200n8";
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
			gpios =
