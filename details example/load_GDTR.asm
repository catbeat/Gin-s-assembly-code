; a boot sector code
; author: gin


mov ax, cs
mov ss, ax
mov sp, 0x7c00

; calculate the gdb segment address
mov ax, [cs:gdt_phybase+0x7c00]
mov dx, [cs:gdt_phybase+0x7c00+0x02]
mov bx, 0x10
div bx
mov ds, ax									; ds:bx point to thr gbd_phybase
mov bx, dx		

; now we set all the descriptor
; First, null descriptor
mov dword [bx+0x00], 0x00
mov dword [bx+0x04], 0x00

;Second, code descriptor
mov dword [bx+0x08], 0x7c0001ff
mov dword [bx+0x0c], 0x00409800

;Third, data descriptor, here I point to the video cache
mov dword [bx+0x10], 0x8000ffff
mov dword [bx+0x14], 0x0040920b

;Finally, stack descriptor
mov dword [bx+0x18], 0x00007a00
mov dword [bx+0x1c], 0x00409600

; initialize GDTR
mov word [cs:gdt_size+0x7c00], 31

lgdt [cs:gdt_size+0x7c00]

; now we have to set A20 to be open
in al, 0x92
or al, 00000010B
out 0x92, al

;switch to protect mode
;prevent any potential interrupt as when switching to the 32bit protect mode then the original interrupt table is no longer available
cli

; revise the PE bit to be 1
mov eax, cr0
or eax, 1
mov cr0, eax

;clear the pipeline and revise the descriptor cache
jmp dword 0x0008:flush

	[bits 32]

flush:
		; now we show "Protect Mode On" 
		mov cx, 00000000000_10_000B
		mov ds, cx
		
		mov byte [0x00],'P'  
		mov byte [0x02],'r'
        mov byte [0x04],'o'
        mov byte [0x06],'t'
        mov byte [0x08],'e'
        mov byte [0x0a],'c'
        mov byte [0x0c],'t'
        mov byte [0x0e],' '
        mov byte [0x10],'m'
        mov byte [0x12],'o'
        mov byte [0x14],'d'
        mov byte [0x16],'e'
        mov byte [0x18],' '
        mov byte [0x1a],'O'
        mov byte [0x1c],'n'
		
		hlt
;        mov cx,00000000000_11_000B         ;加载堆栈段选择子
;        mov ss,cx
;        mov esp,0x7c00

;        mov ebp,esp                        ;保存堆栈指针 
;        push byte '.'                      ;压入立即数（字节）
         
;        sub ebp,4
;        cmp ebp,esp                        ;判断压入立即数时，ESP是否减4 
;        jnz ghalt                          
;        pop eax
;        mov [0x1e],al                      ;显示句点 
      
;  ghalt:     
;        hlt 

gdt_size	dw	0x0000
gdt_phybase	dd	0x00007e00

times 510-($-$$) db 0
				 db 0x55, 0xaa