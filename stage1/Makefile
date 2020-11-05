BUILDDIR ?= build

.PHONY: all
all: $(BUILDDIR)/boot.img

$(BUILDDIR)/boot.img: $(BUILDDIR)/boot0.bin $(BUILDDIR)/boot1.bin
	cat $^ > $@
	# 20480 sectors total - 32 reserved 
	dd if=/dev/zero bs=512 count=20448 >> $@

$(BUILDDIR)/%.bin: %.asm
	@mkdir -p $(dir $@) 
	nasm -f bin $< -o $@ -l $@.lst

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)

.PHONY: qemu
qemu: $(BUILDDIR)/boot.img
	qemu-system-i386 -blockdev driver=file,node-name=hd0,filename=$< -device ide-hd,drive=hd0 -boot order=a

.PHONY: qemu_debug
qemu_debug: $(BUILDDIR)/boot.img
	qemu-system-i386 -blockdev driver=file,node-name=hd0,filename=$< -device ide-hd,drive=hd0 -S -gdb tcp::1234