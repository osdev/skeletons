// Declare constants for the multiboot header.
.set ALIGN,    1<<0             # align loaded modules on page boundaries
.set MEMINFO,  1<<1             # provide memory map
.set FLAGS,    ALIGN | MEMINFO  # this is the Multiboot 'flag' field
.set MAGIC,    0x1BADB002       # 'magic number' lets bootloader find the header
.set CHECKSUM, -(MAGIC + FLAGS) # checksum of above, to prove we are multiboot

// get PHYS() and VIRT_BASE defines
#include "phys_virt.h"
	
/*
 * Declare a multiboot header that marks the program as a kernel.
 * These are magic values that are documented in the multiboot
 * standard. The bootloader will search for this signature in the
 * first 8 KiB of the kernel file, aligned at a 32-bit boundary. The
 * signature is in its own section so the header can be forced to be
 * within the first 8 KiB of the kernel file.
 */
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/*
 * The linker script specifies _start as the entry point to the kernel
 * and the bootloader will jump to this position once the kernel has
 * been loaded. It doesn't make sense to return from this function as
 * the bootloader is gone.
 */
.section .bootstrap, "ax"
.global _start
.type _start, @function
_start:
	/*
	 * The bootloader has loaded us into 32-bit protected mode on
	 * a x86 machine. Interrupts are disabled. Paging is disabled.
	 * The processor state is as defined in the multiboot
	 * standard. The kernel has full control of the CPU. The
	 * kernel can only make use of hardware features and any code
	 * it provides as part of itself. There's no printf function,
	 * unless the kernel provides its own <stdio.h> header and a
	 * printf implementation. There are no security restrictions,
	 * no safeguards, no debugging mechanisms, only what the
	 * kernel provides itself. It has absolute and complete power
	 * over the machine.
	 */

	/*
	 * Create boot page tables.
	 * The physical memory is identity mapped because enabling
	 * paging does not change the PC. The CPU will read the next
	 * instruction from the address after enabling pages but now
	 * that address is virtual. The identity map garantees that it
	 * just keeps on going as if nothing has changed. Without this
	 * identity mapping the CPU would instead page fault.
	 */

	// physical address of boot_page_table
	lea PHYS(boot_page_table), %edi
	// start identity map from 0 as "present, writable"
	lea 0x003, %eax
	// number of pages to the kernel address space
	lea VIRT_BASE >> 12, %ecx

1:	// set page table entry
	mov %eax, (%edi)

	// address of next physical page
	add $0x1000, %eax
	// address of next entry in boot_page_table
	add $4, %edi
	// loop till we reach the kernel address space
	dec    %ecx
	jnz     1b

	/*
	 * Continue page tables
	 * Map the physical memory again but into the kernel address
	 * space. This is where we want to run in the long run.
	 * Everything up to now was just so the CPU does not page
	 * fault while switching to higher half.
	 */

	// reset to physical 0, again as "present, writable"
	lea 0x003, %edx
	// number of pages in the kernel address space
	lea ((0x100000000 - VIRT_BASE) >> 12), %ecx

2:	// set page table entry
	mov %edx, (%edi)

	// address of next physical page
	add $0x1000, %edx
	// address of next entry in boot_page_table
	add $4, %edi
	// loop till we reach the end of the kernel address space
	dec    %ecx
	jnz     2b

	/*
	 * The page directory tells the CPU where to find the page
	 * table for each 4MB segment of virtual address space. This
	 * code has all the page tables in one continious chunk of
	 * memory so filling the directory is rather simple.
	 */

	// physical address of boot_page_directory
	lea PHYS(boot_page_directory), %edi
	// physical address of boot_page_table plus "present, writable"
	lea PHYS(boot_page_table) + 0x003, %edx
	// number of entries in the directory
	lea 0x400, %ecx

3:	// set directoy entry
	mov %edx, (%edi)

	// address of next page of boot_page_table
	add $0x1000, %edx
	// address of next entry in boot_page_directory
	add $4, %edi
	// loop till we reach the end of the directory
	dec    %ecx
	jnz     3b

	/*
	 * Paging is activated by writing the physical address of the
	 * page directory to CR3 and enabling the paging bit in CR0.
	 * The code also sets the write-protect bit even though all
	 * pages are mapped writable anyway. A real kernel will later
	 * switch page tables with more strict flags.
	 */

	// physical address of the boot_page_directory.
	lea PHYS(boot_page_directory), %ecx
	movl %ecx, %cr3
	//Enable paging and the write-protect bit.
	movl %cr0, %ecx
	orl $0x80010000, %ecx
	movl %ecx, %cr0

	/*
	 * The kernel is now mapped to higher half but the CPU is
	 * still running in lower half. Jump to higher half with an
	 * absolute jump.
	 */
	lea _higher_half, %ecx
	jmp *%ecx
/*
 * Set the size of the _start symbol to the current location '.' minus
 * its start. This is useful when debugging or when you implement call
 * tracing. "objdump -t" will show the location and size of each symbol.
 */
.size _start, . - _start

.section .text
.global _higher_half
.type _higher_half, @function
_higher_half:
	/*
	 * At this point the code runs in higher half with virtual
	 * addresses. The identity mapping of phyiscal memory in the
	 * lower half still exists but is now obsolete and can be
	 * unmapped. From here on only virtual addresses must be
	 * used, which is actually easier.
	 */

	// physical address of boot_page_directory
	lea PHYS(boot_page_directory), %edi
	// number of directory entries below the kernel address space
	lea VIRT_BASE >> 12 >> 10, %ecx

4:	// set directoy entry not present
	movl $0, (%edi)

	// address of next entry in boot_page_directory
	add $4, %edi
	// loop till we reach the end of the directory
	dec    %ecx
	jnz     4b

	/*
	 * To set up a stack, we set the esp register to point to the
	 * top of our stack (as it grows downwards on x86
	 * systems). This is necessarily done in assembly as languages
	 * such as C cannot function without a stack.
	 */
	mov $stack_top, %esp

	/*
	 * This is a good place to initialize crucial processor state
	 * before the high-level kernel is entered. It's best to
	 * minimize the early environment where crucial features are
	 * offline. Note that the processor is not fully initialized
	 * yet: Features such as floating point instructions and
	 * instruction set extensions are not initialized yet. The GDT
	 * should be loaded here. C++ features such as global
	 * constructors and exceptions will require runtime support to
	 * work as well.
	 *
	 * Note: C can have constructors too. It's a compiler
	 * extension but can be verry usefull.
	 */

	// Enter the high-level kernel.
	call kernel_main

	/*
	 * If the system has nothing more to do, put the computer into
	 * an infinite loop. To do that:
	 * 1) Disable interrupts with cli (clear interrupt enable in
	 *    eflags). They are already disabled by the bootloader, so
	 *    this is not needed. Mind that you might later enable
	 *    interrupts and return from kernel_main (which is sort of
	 *    nonsensical to do). 
	 * 2) Wait for the next interrupt to arrive with hlt (halt
	 *    instruction). Since they are disabled, this will lock up
	 *    the computer. 
	 * 3) Jump to the hlt instruction if it ever wakes up due to a
	 *    non-maskable interrupt occurring or due to system
	 *    management mode.
	*/
	cli
1:	hlt
	jmp 1b

	/*
	 * Usefull for debugging if something goes wrong early.
	 * Increments a char on the VGA text console forever.
	 */
twirl:
        addw    $0x1,0xb8140
        jmp     twirl

/*
 * Set the size of the _higher_half symbol to the current location '.'
 * minus its start. This is useful when debugging or when you
 * implement call tracing. "objdump -t" will show the location and
 * size of each symbol. 
 */
.size _higher_half, . - _higher_half

/*
 * The multiboot standard does not define the value of the stack
 * pointer register (esp) and it is up to the kernel to provide a
 * stack. This allocates room for a small stack by creating a symbol
 * at the bottom of it, then allocating 16384 bytes for it, and
 * finally creating a symbol at the top. The stack grows downwards on
 * x86. The stack is in the .bss section, which means it will not be
 * included in the actual kernel file, only it's size will be
 * recorded. The bootloader will reserve space for the .bss section
 * and initialize it with zeroes.
 *
 * Note: The x86 C calling conventions specify that the stack is to be
 * 16 byte aligned at the call site.
 */
.section .bss
.align 16
stack_bottom:
.skip 16384 # 16 KiB
stack_top:

/*
 * Reserve pages used for paging. Don't hard-code addresses and assume
 * they are available, as the bootloader might have loaded its
 * multiboot structures or modules there. This lets the bootloader
 * know it must avoid the addresses. Reserve enough for all 4GB of
 * address space.
 */
.section .bss
.align 4096
boot_page_directory:
	.skip 4096
boot_page_table:
	.skip 4096 * 1024
