[bits 16]

%include "bpb.inc"

bpb equ 0x7C03

SECTOR_STORAGE equ 0x4500

; This bootloader only supports FAT16 for now, this allows for hard disks with 
; up to 32 MiB at 512 byte per cluster which should be enough for a while

[org 0x0500]
start:
    ; setup registers to a known state
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ax, 0x7C00
    mov ss, ax
    xor sp, sp

    mov [bootdrive], dl

    ; set video mode to 80x25
    xor ax, ax
    mov al, 0x03
    int 0x10

    ; print welcome message
    mov si, msgWelcome
    call print_string

    call check_lba_support

load_root_dir:
    ; compute size of root directory and store in "cx"
    xor cx, cx
    xor dx, dx
    mov ax, 0x20    ; one directory entry is 32 bytes long
    mul word [bpb + BPB.root_entry_count]
    div word [bpb + BPB.bytes_per_sector]
    xchg ax, cx

    ; compute location of root directory and store in "ax"
    mov al, byte [bpb + BPB.table_count]
    mul word [bpb + BPB.table_size_16]
    add ax, word [bpb + BPB.reserved_sector_count]
    mov word [datasector], ax
    add word [datasector], cx

    mov bx, SECTOR_STORAGE
    call read_sectors

    ; find stage 2 bootloader
    mov cx, word [bpb + BPB.root_entry_count]
    mov di, SECTOR_STORAGE
.loop:
    push cx
    mov cx, 0xB         ; 11 characters
    mov si, stage2Name
    push di
    rep cmpsb
    pop di
    je load_fat
    pop cx
    add di, 0x20
    loop .loop
    mov si, msgNotFoundError
    call print_string
    jmp failure

    jmp hang

load_fat:

hang:
    mov si, msgHang
    call print_string
    cli
    hlt
    jmp hang

; read sectors from disk
; AX     starting sector (LBA)
; CX     number of sectors to read
; ES:BX  read buffer
read_sectors:
;     mov bl, byte [lba_supported]
;     cmp bl, 1
;     jne read_sectors_chs

; read_sectors_lba:
    mov di, 5                   ; 5 retries
.loop:
    mov word [disk_access_packet + 2], cx
    mov word [disk_access_packet + 4], bx
    mov word [disk_access_packet + 6], es
    mov word [disk_access_packet + 8], ax
    push ax
    push bx
    push cx
    xor ax, ax
    mov ah, 0x42
    mov dl, [bootdrive]
    mov si, disk_access_packet
    int 0x13
    jnc short .success
    mov ah, 1
    int 0x13
    mov [disk_error], ah
    xor ax, ax
    int 0x13
    dec di
    pop cx
    pop bx
    pop ax
    jnz .loop
    mov si, msgDiskError
    call print_string
    mov al, [disk_error]
    call print_hex_byte
    jmp failure
.success:
    pop cx
    pop bx
    pop ax
    ret

; read_sectors_chs:
; .next_sector:
;     mov di, 5                   ; 5 retries
; .loop:
;     push ax
;     push bx
;     push cx
;     call convert_to_chs
;     mov ah, 2
;     mov al, 1
;     mov ch, byte [cylinder]
;     mov cl, byte [sector]
;     mov dh, byte [head]
;     mov dl, byte [bootdrive]
;     int 0x13
;     jnc .success
;     mov ah, 1
;     int 0x13
;     mov [disk_error], ah
;     xor ax, ax
;     int 0x13
;     dec di
;     pop cx
;     pop bx
;     pop ax
;     jnz .loop
;     mov si, msgDiskError
;     call print_string
;     mov al, [disk_error]
;     call print_hex_byte
;     jmp failure
; .success:
;     mov si, msgProgress
;     call print_string
;     pop cx
;     pop bx
;     pop ax
;     add bx, word [bpb + BPB.bytes_per_sector]
;     inc ax
;     loop .next_sector
;     ret

; convert_to_chs:
;     xor dx, dx
;     div word [bpb + BPB.sectors_per_track]
;     inc dl
;     mov byte [sector], dl
;     xor dx, dx
;     div word [bpb + BPB.head_side_count]
;     mov byte [head], dl
;     mov byte [cylinder], al
;     ret

failure:
    ; call print_string
    ; mov si, msgError
    ; call print_string
    cli 
    hlt
    jmp $







; print_oem_name:
;     mov di, 8
;     mov ah, 0x0E
;     mov si, bpb + BPB.oem_name
; .loop:
;     lodsb

;     or al, al
;     jz .done

;     int 0x10
;     dec di
;     jnz .loop

; .done:

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

; prints a byte as hex to the screen
; AL     byte to print
print_hex_byte:
    push ax
    push bx

    mov bl, al
    shr al, 4
    cmp al, 10
    sbb al, 0x69
    das

    mov ah, 0x0E
    int 0x10

    mov al, bl
    and al, 0xF
    cmp al, 10
    sbb al, 0x69
    das

    mov ah, 0x0E
    int 0x10

    pop bx
    pop ax
    ret

print_hex_word:
    push ax
    push bx

    mov bl, al
    mov al, ah
    call print_hex_byte
    mov al, bl
    call print_hex_byte

    pop bx
    pop ax
    ret

check_lba_support:
    push ax
    push bx
    push dx

    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, [bootdrive]
    int 0x13
    jc .no_lba
    mov byte [lba_supported], 1


.no_lba:
    ; mov si, msgLBAError
    ; call print_string
    ; jmp failure
    pop dx
    pop bx
    pop ax
    ret

; ---- data ----
bootdrive db 0
datasector dw 0

sector db 0
track db 0
head db 0
cylinder db 0

disk_error db 0
lba_supported db 0

disk_access_packet:
    db 0x10
    db 0
    dw 0x20
    dd 0x7E00
    dq 1

; ---- read only data ----
stage2Name db "boot.exe"

msgWelcome db "tulip boot stage1 v0.1", 0x0A, 0x0D, 0
msgProgress db "*", 0
msgHang db 0x0A, 0x0D, "----- HANG -----", 0x0A, 0x0D, 0
msgCRLF db 0x0A, 0x0D, 0

;msgLBAError db "LBA not supported, cannot load image", 0x0A, 0x0D, 0
msgDiskError db "Disk Error: ", 0
msgNotFoundError db "Stage2 bootloader not found!", 0x0A, 0x0D, 0

times 15872-($-$$) hlt