# Skeletons
Collection of skeleton kernels.

The following kernels are skeletons for getting started. Each kernel
is kept in a separate branch. Use "git checkout <branch>" to switch to
the one you want:

| Architecture | Firmware / Bootloader | Type       | Tags | Branch
| ------------ | --------------------- | ---------- | ---- | ------
| x86 (32bit)  | Bios / GRUB           | bare-bones | VGA  | bare-bones-x86
| x86 (32bit)  | Bios / GRUB           | bare-bones | VGA, MMU, Higher half  | bare-bones-x86-higher-half

Possible types are: bare-bones, skeleton, meaty
Possible tags are: MMU, Higher half, Caches, SMP, VGA, Framebuffer,
Serial

When starting a new kernel plase start by branching of
sekelton-template or the existing branch used as starting point.
