# mir3g v1 OpenWRT NOR SPI
Xiaomi 3G v1 OpenWRT для тех, кто использует NOR SPI вместо NAND, если та просто перестала работать.</BR>
Дело в том, что NAND память капризная, и что бы ее не перепаивать, не прошивать, можно просто использовать SPI память.</BR>
В моем случае я использую 16Mb вариант. А также, в моем роутере сгорел WiFi модуль, в логах загрузки следующее:</BR>
```LOG
[    0.000000] clocksource: GIC: mask: 0xffffffffffffffff max_cycles: 0xcaf478abb4, max_idle_ns: 440795247997 ns
[    0.000000] clocksource: MIPS: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 4343773742 ns
[    0.000021] sched_clock: 32 bits at 440MHz, resolution 2ns, wraps every 4880645118ns
[    0.007976] Calibrating delay loop... 586.13 BogoMIPS (lpj=2930688)
[    0.074132] pid_max: default: 32768 minimum: 301
[    0.079031] Mount-cache hash table entries: 1024 (order: 0, 4096 bytes)
[    0.085543] Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes)
[    0.095918] Hierarchical SRCU implementation.
[    0.101614] smp: Bringing up secondary CPUs ...
[    1.033887] Primary instruction cache 32kB, VIPT, 4-way, linesize 32 bytes.
[    1.033904] Primary data cache 32kB, 4-way, PIPT, no aliases, linesize 32 bytes
[    1.033927] MIPS secondary cache 256kB, 8-way, linesize 32 bytes.
[    1.034215] CPU1 revision is: 0001992f (MIPS 1004Kc)
[    0.166713] Synchronize counters for CPU 1: done.
[    8.108657] Primary instruction cache 32kB, VIPT, 4-way, linesize 32 bytes.
[    8.108669] Primary data cache 32kB, 4-way, PIPT, no aliases, linesize 32 bytes
[    8.108681] MIPS secondary cache 256kB, 8-way, linesize 32 bytes.
[    8.108794] CPU2 revision is: 0001992f (MIPS 1004Kc)
[    0.259230] Synchronize counters for CPU 2: done.
[    6.360948] Primary instruction cache 32kB, VIPT, 4-way, linesize 32 bytes.
[    6.360958] Primary data cache 32kB, 4-way, PIPT, no aliases, linesize 32 bytes
[    6.360969] MIPS secondary cache 256kB, 8-way, linesize 32 bytes.
[    6.361092] CPU3 revision is: 0001992f (MIPS 1004Kc)
[    0.344451] Synchronize counters for CPU 3: done.
[    0.374352] smp: Brought up 1 node, 4 CPUs
[    0.383499] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.393385] futex hash table entries: 1024 (order: 3, 32768 bytes)
[    0.400039] pinctrl core: initialized pinctrl subsystem
[    0.406343] NET: Registered protocol family 16
[    0.428377] pull PCIe RST: RALINK_RSTCTRL = 0
[    0.733100] release PCIe RST: RALINK_RSTCTRL = 7000000
[    0.738154] ***** Xtal 40MHz *****
[    0.741507] release PCIe RST: RALINK_RSTCTRL = 7000000
```
Процессор пытается инициализировать PCIe, делает две попытки, но зависает, поскольку ответа не получает. Мной было принято решение отключить этот модуль, либо вообще возможность опроса.</BR>
Вы можете поэкспериментировать, поочередно отключать чипы, вдруг заработает на каком-то одном.</BR>
Для этого в файле diy.sh найдите @pcie это общая шина, она у меня отключена, можно попробовать отключить @pcie0 или @pcie1</BR>
Ну а если вам нужна только прошивка для SPI NOR, то можно убрать эту часть в файле и собрать с работающими модулями.</BR>
