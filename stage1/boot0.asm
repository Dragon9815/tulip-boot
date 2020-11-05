[org 0x7C00]
[bits 16]

BOOT1_SECTOR_COUNT equ 10
BOOT1_LOAD_ADDRESS equ 0x0500

; jump over BPB
jmp start
nop ; whatever

bpb:
dummy_bpb:
    db "TULIP   "
    dw 512
    db 4 ; 4 sectors per cluster
    dw 32
    db 2
    dw 512
    dw 20480 ; 10 MiB
    db 0xF8
    dw 20 ; 20 sectors per fat
    dw 32 ; 32 sectors per track
    dw 64 ; 64 heads
    dd 0  ; partition starts a beginning of disk
    dd 0  ; sectors < 655535 -> 0
    db 0x80
    db 0
    db 0x29
    dd 0xD00FC0DE ; serial number
    db "TULIP DISK "
    db "FAT16   " 

start:
; no interrupts which setting up registers
cli

; some BIOSes start us up at 7C00:0000 instead of 0000:7C00
jmp 0x0000:start_segment_fix
start_segment_fix:

; initialize segments
xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax

; setup stack at 7C00:0000
mov ax, 0x7C00
mov ss, ax
xor sp, sp

sti

; save bootdrive
mov [bootdrive], dl

; reset disk system
xor ax, ax
int 0x13
jc failure

; load boot1 from reserved sectors

; check if lba addressing is available
mov ah, 0x41
mov bx, 0x55AA
; dl is already set to bootdrive
int 0x13
jc read_chs

read_lba:
    mov cx, 5                       ; 5 retries
    xor ax, ax
.loop:
    mov si, disk_access_packet
    mov ah, 0x42
    ; dl is already set to bootdrive
    int 0x13
    jnc start_boot1
    xor ax, ax
    int 0x13
    dec cx
    jnz .loop
    jmp failure

read_chs:
    mov di, 5                       ; 5 retries
    mov bx, BOOT1_LOAD_ADDRESS
.loop:
    mov ah, 0x02
    mov al, BOOT1_SECTOR_COUNT
    mov ch, 0
    mov cl, 2
    mov dh, 0
    ; dl is already set to bootdrive
    int 0x13                        ; read sectors
    jnc start_boot1
    xor ax, ax
    int 0x13                        ; reset disk controller
    dec di
    jnz .loop
    jmp failure

start_boot1:
    mov si, msgBoot
    call print_string
    mov dl, [bootdrive]
    jmp 0:BOOT1_LOAD_ADDRESS

failure:
    mov si, msgFailure
    call print_string
    cli
    hlt

print_string:
    mov ah, 0x0E
.loop:
    lodsb

    or al, al
    jz .done

    int 0x10
    jmp .loop

.done:
    ret

; -------- data -------------------
bootdrive db 0
msgFailure db "DISK ERROR", 0
msgBoot db "Loading boot image...", 0

disk_access_packet:
    db 0x10
    db 0
    dw BOOT1_SECTOR_COUNT
    dd BOOT1_LOAD_ADDRESS ; load to segment 0
    dq 1                  ; start at second sector (LBA 1)


times 509-($-$$) hlt
lba_supported db 0 ; flag for stage1 bootloader
db 0x55
db 0xAA
