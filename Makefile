CROSS        := i686-elf
WARN_FLAGS   := -O2 -W -Wall -Wextra
FLAGS        := -ffreestanding
ASFLAGS      := $(FLAGS) $(WARN_FLAGS)
CFLAGS       := $(FLAGS) $(WARN_FLAGS) -std=gnu99
CXXFLAGS     := $(FLAGS) $(WARN_FLAGS) -std=g++11 -fno-exceptions -fno-rtti
LDFLAGS      := $(FLAGS) -nostdlib -lgcc

CC := $(CROSS)-gcc
CXX := $(CROSS)-g++

all: boot

%.o: %.S
	$(CC) -c $(ASFLAGS) -o $@ $<

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

%.o: %.cc
	$(CXX) -c $(CXXFLAGS) -o $@ $<

clean:
	rm -rf myos.iso _isodir myos.bin *.o *~

%.bin: linker.ld 
	$(CC) -o $@ -T $+ $(LDFLAGS) 
	@grub-file --is-x86-multiboot $@ || {			\
	  printf "grub-file: error: %s is not multiboot\n" $@;	\
	  exit 1;						\
	}

myos.bin: boot.o kernel.o

check-multiboot: myos.bin
	if grub-file --is-x86-multiboot myos.bin; then	\
	  echo multiboot confirmed;			\
	else						\
	  echo the file is not multiboot;		\
	fi

myos.iso: grub.cfg myos.bin
	mkdir -p _isodir/boot/grub
	cp myos.bin _isodir/boot/
	cp grub.cfg _isodir/boot/grub/
	grub-mkrescue -o myos.iso _isodir

boot-cdrom: myos.iso
	qemu-system-i386 -cdrom myos.iso

boot: myos.bin
	qemu-system-i386 -kernel myos.bin

.PRECIOUS: %.bin %.iso
