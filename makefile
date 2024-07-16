CC=i686-elf-gcc
CFLAGS32=-g -c -O3 -mno-red-zone -nostdlib
AS=nasm
LD=i686-elf-ld
LDFLAGS=-T link.ld

CSRC := $(shell find ./ -name "*.c")
CTAR := $(patsubst %.c,%.o,$(CSRC))

all: new bios-x86
	@echo "Made default bios-x86, starting qemu"
	qemu-img resize rbm.bin --shrink 512M
	qemu-system-i386 -hda rbm.bin -m 32M -serial mon:stdio
bios-x86: $(CTAR)
	nasm src/bios/startup.s -o bin/startup.o -f elf
	nasm src/bios/boot.s -o bin/boot.bin -f bin
	$(LD) $(LDFLAGS) bin/startup.o $(shell find ./ -name "*.o" | xargs)
	cat bin/boot.bin > rbm.bin
	cat bin/rbm.bin >> rbm.bin

%.o: %.c
	$(CC) $(CFLAGS32) $< -o ./bin/$(notdir $@)

new:
	@test -d ./bin || mkdir bin