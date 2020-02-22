; boot sector code
; set up the kernel program
; author: gin

core_base_address equ 0x00040000
core_start_sector equ 0x00000001

mov eax, cs
mov ss, eax
mov esp, 0x7c00

mov eax, [cs:pgdt+0x7c00+0x02]
xor edx, edx
mov ebx, 16
div ebx

mov ds, eax											; ds:ebx point to the GDT address
mov ebx, edx

;First, set null descriptor
;Second, set data segment descriptor
mov dword [bx+0x08], 0x0000ffff
mov dword [bx+0x0c], 0x00cf9200

;Third, set code segment descriptor
mov dword [bx+0x10], 0x7c0001ff
mov dword [bx+0x14], 0x00409800

;Fourth set stack segment descriptor
mov dword [bx+0x18], 0x7c00fffe
mov dword [bx+0x1c], 0x00cf9600

;Finally, set the video cache segment descriptor
mov dword [bx+0x20], 0x80007fff
mov dword [bx+0x24], 0x00409200

; initializw the GDTR table size
mov word [cs:pgdt+0x7c00], 39

lgdt [cs:pgdt+0x7c00]

in al, 0x92
or al, 0000_0010B
out 0x92, al

cli

mov eax, cr0
or eax, 0000_0001B
mov cr0, eax

jmp dword 0x0010:flush

	[bits 32]
flush:	
	mov eax, 0x0008
	mov ds, eax
	
	mov eax, 0x0018
	mov ss, eax
	mov esp, 0
	
	mov edi, core_base_address				; ds:edi point to the start address of installed code
	
	mov eax, core_start_sector
	mov ebx, edi							; set the install start address
	call read_hard_disk_0
	
	mov eax, [ebx]							; get the length of the code
	xor edx, edx
	mov ecx, 512
	div ecx
	
	cmp eax, 0								; code <= 512 bytes
	jz setup
	
	xor edx, edx
	jnz @1
	dec eax									; already read in one sector
	
@1:
	mov ecx, eax
	mov eax, core_start_sector
	inc eax
	
@2:	
	add ebx, 512
	call read_hard_disk_0
	inc eax
	loop @2
	
	
setup:										; update the GDT about the kernel 
	mov esi, [0x7c00+pgdt+0x02]
	
	mov eax, [edi+0x04]						; set the public routine offset address
	mov ebx, [edi+0x08]						; get the central data offset address
	
	sub ebx, eax							; calculate the length of the public routine segment
	dec ebx						
	
	add eax, edi							; get the public routine address
	mov ecx, 0x00409800
	call make_gdt_descriptor
	
	mov dword [esi+0x28], eax
	mov dword [esi+0x2c], edx
	
	mov eax, [edi+0x08]						; set the central data offset address
	mov ebx, [edi+0x0c]
	sub ebx, eax
	dec ebx
	
	add eax, edi
	mov ecx, 0x00409200
	call make_gdt_descriptor
	
	mov dword [esi+0x30], eax
	mov dword [esi+0x34], edx
	
	mov eax, [edi+0x0c]
	mov ebx, [edi]
	sub ebx, eax
	dec ebx
	
	add eax, edi
	mov ecx, 0x00409800
	call make_gdt_descriptor
	
	mov dword [esi+0x38] ,eax
	mov dword [esi+0x3c], edx
	
	mov esi, [0x7c00+pgdt]
	mov word [esi], 83
	
	lgdt [esi]
	
	jmp far [edi+0x10]
	
	
	
;----------------------------------------------------------------------------
read_hard_disk_0:							; ds:ebx point to the installing address			
	push ebx								; eax store the sector number
	push ecx 	
	push edx
	push eax
	
	mov dx, 0x1f2
	mov al, 1
	out dx, al
	
	inc dx
	pop eax
	out dx, al
	
	inc dx
	mov ecx, 8
	shr eax, cl
	out dx, al
	
	inc dx
	shr eax, cl
	out dx, al
	
	inc dx
	shr eax, cl
	or al, 0xe0
	out dx, al
	
	inc dx
	mov al, 0x20
	out dx, al
	
	.waits:
		in al, dx
		and al, 0x08
		cmp al, 0x08
		jnz .waits
		
	mov ecx, 256
	mov dx, 0x1f0
	.readw:
		in ax, dx
		mov [ebx], ax
		add ebx, 2
		loop .readw
		
	pop edx
	pop ecx
	pop ebx
	
	ret
	
;-------------------------------------------------------------------------------------------
; make descriptor
; eax store the base address
; ebx store the length of the code
; ecx store the TYPE
; return edx:eax as the descriptor
make_gdt_descriptor:						
	mov edx, eax
	shl eax, 16
	or ax, bx									;mov ax, bx
	
	rol edx, 8
	bswap edx
	and edx, 0xFF0000FF

	and ebx, 0x000f0000
	or ecx, ebx
	or edx, ecx
	
	ret
	
;---------------------------------------------------------------------------------------------
pgdt	dw 0x00
		dd 0x00007e00
		
;---------------------------------------------------------------------------------------------
times 510-($-$$) db 0x00
				 db 0x55, 0xaa