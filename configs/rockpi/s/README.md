# Rockpi S Notes

## Bootloader

The bootloader process is described here:

Current problem is building the bootloader - it requires a u-boot TPL and SPL as
detailed here:

 http://opensource.rock-chips.com/wiki_Boot_option

Unfortunately the board is not marked as supporting SPL or TPL in u-boot. Until
this boot approach is supported by rockchip / rockpi, the other approach is
required.

RockChip provides pre-compiled x86 host tools in their "rkbin" repository. The
rockpi configuration in Buildroot will execute these host tools from the GitHub
repository. As a general rule, we avoid executing pre-compiled host tools in
Buildroot / Skiff. This is therefore a short term stop-gap solution until
Rockchip supports building the SPL and TPL from source, or releases the source
code for their host tools.

