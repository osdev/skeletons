#ifndef KERNEL__PHYS_VIRT_H
#define KERNEL__PHYS_VIRT_H 1

#define VIRT_BASE 0x80000000
#define	PHYS(x) ((x) - VIRT_BASE)
#define	VIRT(x) ((x) + VIRT_BASE)

#endif
