# bare-bones-x86

This is a simple kernel for 32bit x86 using Bios and GRUB to boot into
protected mode. It shows how to setup the stack, call C code and
output a simple text to the VGA text console. See
http://wiki.osdev.org/Bare_bones for help.

| Architecture | Firmware / Bootloader | Tags |
| ------------ | --------------------- | ---- |
| x86 (32bit)  | Bios/GRUB             | VGA, MMU, Higher half  |

![screenshot](screenshot.gif)

# Makefile targets

| Target          |                                                 |
| :-------------- | :---------------------------------------------- |
| all             | build kernel and boot in qemu-system-i386       |
| bochs           | boot kernel in bochs from boot image            |
| boot            | boot kernel directly in qemu-system-i386        |
| boot-cdrom      | boot kernel in qemu-system-i386 from boot image |
| check-multiboot | check if the multiboot header works             |
| myos.bin        | build kernel                                    |
| myos.iso        | build CDROM/USB boot image with GRUB menu       |
