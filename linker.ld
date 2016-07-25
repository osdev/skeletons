/*
 * The bootloader will look at this image and start execution at the
 * symbol designated as the entry point.
 */
ENTRY(_start)

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
	.boot ALIGN(4k): {
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
	 * The .text section contains all the code for the kernel
	 * other than the bootstrap code.
	 */
	.text ALIGN(4k): {
		*(.text.*)
		*(.text)
	}

	/* Read-only data. */
	.rodata ALIGN(4k): {
		*(.rodata.*)
		*(.rodata)
	}

	/* Read-write data (initialized) */
	.data ALIGN(4K): {
		*(.data.*)
		*(.data)
	}

	/* Read-write data (uninitialized) and stack */
	.bss ALIGN(4K): {
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
