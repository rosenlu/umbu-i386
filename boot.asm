bits 32
global start

MAGIC_NUMBER    equ 0x1BADB002              ; define the magic number constant
FLAGS           equ 0x0                     ; multiboot flags
CHECKSUM        equ -(MAGIC_NUMBER+FLAGS)   ; calculate the checksum


PIC1_CMD        equ 0x20
PIC1_DATA       equ 0x21
PIC2_CMD        equ 0xA0
PIC2_DATA       equ 0xA1


section .multiboot
align 4
        dd MAGIC_NUMBER
        dd FLAGS
        dd CHECKSUM

section .text
align 4



extern main                     ;defined in the C file

start:
        cli                     ;block interrupts
        mov esp, stack_top    ;set stack pointer
        
        lgdt [gdt_desc]
        
        mov eax, isr9
        mov [irq9_offset_lo], ax
        rol eax, 16
        mov [irq9_offset_hi], ax
        
        mov eax, idt_desc
        lidt [eax]
        
        
        ; setup PICs
        
        mov al, 0x11
        out PIC1_CMD, al
        out PIC2_CMD, al
        
        mov al, 8
        out PIC1_DATA, al
        mov al, 16
        out PIC2_DATA, al
        
        mov al, 4
        out PIC1_DATA, al
        mov al, 2
        out PIC2_DATA, al
        
        mov al, 1
        out PIC1_DATA, al
        mov al, 1
        out PIC2_DATA, al
        
        
        mov al, 0xfd ;enable IRQ1
        out PIC1_DATA, al ;send mask to PIC1
        
        sti ;enable interrupts
        
        
        
        
        
m0000:  mov dword [print_addr], 0x000b8000      ;vga memory area pointer

        mov byte [print_char], 'i'     ;print small 'i'
        call print
        call print
        
        mov eax, 0xdeadbeef
        mov eax, isr9
        rol eax, 16
        
        
m0100:  jmp m0100

m9000:  ;call main
        hlt                     ;halt the CPU
        
print:
        pushad
        mov ah, 0x0b ; cyan
        mov al, [print_char]
        mov ebx, dword [print_addr]
        mov word [ebx], ax      ;move to vga memory
        inc ebx                 ;ebx += 2
        inc ebx
        mov dword [print_addr], ebx
        popad
        ret
       

       
isr9:   cli
        pushad
        
        mov ax, ds
        push eax
        
        mov ax, 0x0010
        mov ds, ax
        mov es, ax
        mov ax, 0x0008
        mov fs, ax
        mov gs, ax
        
        mov al, 0x20
        out PIC1_CMD, al ;ack
        
        
i0900:  pop eax
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax

        popad
        sti
        iret
        
        



gdt_start:
        ; NULL segment selector 0x0000
        dq 0x0000000000000000
        
        ; KERNEL CODE selector 0x0008
        dw 0xffff ; limit 0:15
        dw 0x0000 ; base 0:15
        db 0x00 ; base 16:23
        db 0x9a ; access byte
        db 0xcf ; flags, limit 16:19
        db 0x00 ; base 24:31
        
        ; KERNEL DATA selector 0x0010
        dw 0xffff ; limit 0:15
        dw 0x0000 ; base 0:15
        db 0x00 ; base 16:23
        db 0x92 ; access byte
        db 0xcf ; flags, limit 16:19
        db 0x00 ; base 24:31
        
        ; USER CODE selector 0x0018
        dw 0xffff ; limit 0:15
        dw 0x0000 ; base 0:15
        db 0x00 ; base 16:23
        db 0xfa ; access byte
        db 0xcf ; flags, limit 16:19
        db 0x00 ; base 24:31
        
        ; USER DATA selector 0x0020
        dw 0xffff ; limit 0:15
        dw 0x0000 ; base 0:15
        db 0x00 ; base 16:23
        db 0xf2 ; access byte
        db 0xcf ; flags, limit 16:19
        db 0x00 ; base 24:31
gdt_end:


gdt_desc:
        dw gdt_end - gdt_start - 1
        dd gdt_start




idt_desc:
        dw idt_end - idt_start - 1
        dd idt_start




section .data



        
idt_start:

irq0:   dq 0
irq1:   dq 0
irq2:   dq 0
irq3:   dq 0
irq4:   dq 0
irq5:   dq 0
irq6:   dq 0
irq7:   dq 0
irq8:   dq 0

irq9:
irq9_offset_lo:
        dw 0  ;offset bits 0..15
        dw 0x0008    ; selector
        db 0x00      ; zero
        db 10001110b ; type_attr
irq9_offset_hi:
        dw 0  ; offset bits 16..31
        
idt_end:




section .bss

print_addr:
        resd 1      ;reserve one DWORD (32 bit)
print_char:
        resb 1




        resb 8192     ;8KB for stack
stack_top:



