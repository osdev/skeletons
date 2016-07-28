/*
 * The bootloader will look at this image and start execution at the
 * symbol designated as the entry point.
 */
ENTRY(_start)

/*
 * Base address of the kernel address space. For a 2GB:2GB split of
 * user and kernel this is 0x80000000. For a 3GB:1GB split it would be
 * 0xC0000000. This must match the value in phys_virt.h.
 */
VIRT_BASE = 0x80000000;

/*
 * Tell where the various sections of the object files will be put in
 * the final kernel image.
 */
SECTIONS
{
	/*
	 * Begin putting sections at 1 MiB, a conventional place for
	 * kernels to be loaded at by the bootloader. Align all
	 * sections to pages so they can later be individually mapped
	 * or reused by the kernel.
	 */
	. = 1M;

	/*
	 * First put the multiboot header, as it is required to be put
	 * very early early in the image or the bootloader won't
	 * recognize the file format. Next the bootstrap code.
	 */
	.boot : ALIGN(4k) {
		*(.multiboot)
		*(.bootstrap)
		/*
		 * The linker wants to be smart and puts the tiny
		 * .boot section in a hole later in the file between
		 * other sections. But the multiboot header must be
		 * in the first 8k of the *file*. Enlarge section to
		 * the end of page so it won't fit in any hole.
		 */
		. = ALIGN(4k);
	}
	/*
	 * From here on virtual addresses are used. The bootstrap code
	 * takes care of mapping the code to higher half.
	 */
	. = . + VIRT_BASE;
	/*
	 * The .text section contains all the code for the kernel
	 * other than the bootstrap code.
	 */
	.text : AT(ADDR(.text) - VIRT_BASE) ALIGN(4k) {
		*(.text.*)
		*(.text)
	}

	/* Read-only data. */
	.rodata : AT(ADDR(.rodata) - VIRT_BASE) ALIGN(4k) {
		*(.rodata.*)
		*(.rodata)
	}

	/* Read-write data (initialized) */
	.data : AT(ADDR(.data) - VIRT_BASE) ALIGN(4K) {
		*(.data.*)
		*(.data)
	}

	/* Read-write data (uninitialized) and stack */
	.bss : AT(ADDR(.bss) - VIRT_BASE) {
		*(.bss.*)
		*(.bss)
		*(COMMON)
	}

	/*
	 * The compiler may produce other sections, by default it will
	 * put them in a segment with the same name. Simply add stuff
	 * as needed.
	 */

	/* Sections to be discarded */
	/DISCARD/ : {
		*(.text.exit)
		*(.data.exit)
		*(.exitcall.exit)
	}

	/* Stabs debugging sections.  */
	.stab 0 : { *(.stab) }
	.stabstr 0 : { *(.stabstr) }
	.stab.excl 0 : { *(.stab.excl) }
	.stab.exclstr 0 : { *(.stab.exclstr) }
	.stab.index 0 : { *(.stab.index) }
	.stab.indexstr 0 : { *(.stab.indexstr) }
	.comment 0 : { *(.comment) }
}
