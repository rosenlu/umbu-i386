CP := cp
RM := rm -rf
MKDIR := mkdir -pv

BIN := umbu.bin
CFG := grub.cfg
ISO := umbu_image.iso
ISO_PATH := isodir
BOOT_PATH := $(ISO_PATH)/boot
GRUB_PATH := $(BOOT_PATH)/grub

.PHONY: all
all: boot kernel linker iso
	@echo Make has completed.

boot: boot.asm
	nasm -f elf32 -F dwarf boot.asm -o boot.o

kernel: kernel.c
	gcc -m32 -ggdb -c kernel.c -o kernel.o

linker: linker.ld boot.o kernel.o
	ld -m elf_i386 -T linker.ld -o $(BIN) boot.o kernel.o

iso: $(BIN)
	$(MKDIR) $(GRUB_PATH)
	$(CP) $(BIN) $(BOOT_PATH)
	$(CP) $(CFG) $(GRUB_PATH)
	grub-file --is-x86-multiboot $(BOOT_PATH)/$(BIN)
	grub-mkrescue -o $(ISO) $(ISO_PATH)

.PHONY: clean
clean:
	$(RM) *.o $(BIN) $(ISO) $(ISO_PATH)

run: $(ISO)
	qemu-system-i386 -curses -cdrom $(ISO) -s -S

debug: $(BIN)
	gdb -x umbu_gdb_startup $(BIN)
