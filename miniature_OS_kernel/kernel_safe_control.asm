; file: kernel_safe_control.asm
; a toy kernel which provide safety check
; author: gin
; date: 2020/03/10
;======================================================================================

		; constant data
		core_code_seg		equ 0x38		; kernel code segment descriptor
		core_data_seg		equ 0x30		; kernel data segment descriptor
		core_routine_seg	equ 0x28		; kernel routine segment descriptor
		video_ram_seg		equ 0x20		; video cache segment descriptor
		core_stack_seg		equ 0x18		; kernel stack segment descriptor
		whole_mem_seg		equ 0x08		; 4 GB data segment
		

		[bits 32]
;=========================================================================================
SECTION header vstart=0
		
		core_length		dd core_end			; the length of the kernel code
		
		core_routine	dd section.core_routine.start	; the absolute address of core routine segment
		
		core_data		dd section.core_data.start		; the absolute address of core data segment
		
		core_code		dd section.core_code.start		; the absolute address of core code segment
		
		code_entry		dd start
						dw core_code_seg
		
		
	
;==========================================================================================
SECTION core_routine vstart=0		

;------------------------------------------------------------------------------------------
;============ public routine
; put a string end with '0' in the video cache
; input: ds:ebx point to the start of the string
put_string:

		push ecx
		
	.getchar:
		mov cl, [ebx]
		or cl, cl					;cmp cl, 0
		jz .exit
		call put_char				; print this character
		
		; to next char
		inc ebx
		jmp .getchar
		
	.exit:
		pop ecx
		retf
		
;------------------------------------------------------------------------------	
; put a char at the current cursor
; update the cursor after putting the char
; cl store the char	
put_char:
		pushad

		mov edx, 0x3d4
		mov al, 0x0e
		out dx, al
		
		inc dx						; store the high address word of the cursor
		in al, dx
		mov ah, al
		
		dec dx
		mov al, 0x0f
		out dx, al
		
		inc dx						; store the low address word of the cursor
		in al, dx					
		mov bx, ax					; now bx also store the address of cursor

		cmp cl, 0x0d				; check if enter symbol
		jnz	.if_new_line			; if not, check if new line symbol
		
		mov ax, bx
		mov bl, 80					; calculate start address of the current line
		div bl
		mul bl
		mov bx, ax					; bx store the result
		jmp .set_cursor
		
		
	.if_new_line:
		cmp cl, 0x0a				; check if new line symbol
		jnz .put_normal_char
		
		add bx, 80
		jmp .roll_screen
				
				
	.put_normal_char:
		push es
		mov eax, video_ram_seg
		mov es, eax
		shl bx, 1
		mov [es:bx], cl
		pop es
		
		shr bx, 1
		inc bx


	.roll_screen:
		cmp bx, 2000				; check if the cursor over the screen
		jl .set_cursor				; if small than 2000 then not over the screen, directly jump to set cursor
		
		push ds
		push es
		
		mov eax, video_ram_seg
		mov es, eax
		mov ds, eax
		
		mov edi, 0x00
		mov esi, 0xa0
		
		cld
		mov ecx, 1920
		rep movsd
		
		mov ebx, 3840
		mov ecx, 80
	.cls:							; just called by .roll_screen
		mov word [es:ebx], 0x0720
		add ebx, 2
		loop .cls
		
		pop es
		pop ds

		mov bx, 1920				; after clean bx should be the start of the last line
	.set_cursor:					; bx should store the update cursor position
		mov dx, 0x3d4
		mov al, 0x0e
		out dx, al
		
		inc dx
		mov al, bh
		out dx, al
		
		dec dx
		mov al, 0x0f
		out dx, al
		
		inc dx
		mov al, bl
		out dx, al
		
		popad
		ret		
		
;------------------------------------------------------------------------------
; ================== public routine
; read one sector
; input: 
;		eax : the sector number
;		ds:ebx : the start address for loading the sector
read_hard_disk_0:
		push eax
		push ecx
		push edx
		
		push eax

		mov dx, 0x1f2
		mov al, 1
		out dx, al
		
		; provide sector number
		inc dx
		pop eax
		out dx, al
		
		inc dx
		mov cl, 8
		shr eax, cl
		out dx, al
		
		inc dx
		shr eax, cl
		out dx, al
		
		inc dx
		shr eax, cl
		or al, 0xe0
		out dx, al
		
		; request for reading the hard disk
		inc dx
		mov al, 0x20
		out dx, al
		
	.waits:
		in al, dx
		and al, 0x88
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
		pop eax
		
		retf
		
;-------------------------------------------------------------------------------------------
; ================ public routine
; show the content in edx in the current cursor
; input: edx
; no return 
put_hex_word:
		pushad
		push ds

		mov eax, core_data_seg
		mov ds, eax
		mov ebx, bin_hex
		
		mov ecx, 8
	.show_byte_edx:
		rol edx, 4
		mov eax, edx
		and eax, 0x0000000f
		
		xlat
		
		push ecx
		mov cl, al
		call put_char
		
		pop ecx
		
		loop .show_byte_edx
		
		pop ds
		popad
		
		retf



;------------------------------------------------------------------------------------------
; ========= Non public routine
; input: ecx: the length of the memory we needed
; return: ecx: the start address
allocate_memory:

		push ds
		push eax
		push ebx

		mov eax, core_data_seg
		mov ds, eax
		
		mov eax, [ram_alloc]				; give the start address of the available memory
		add eax, ecx						; calculate out the start address for next allocating
		
		mov ecx, [ram_alloc]				; now we need to return the start address of this allocate

		; test whether it over the whole memory
		;cmp eax, ecx
		;jng .ret_alloca_addr
		
		;hlt
		
	.ret_alloca_addr:
		; although the ecx may already divides 512, for common use, we make it divides 4
		mov ebx, eax
		and ebx, 0xfffffffc
		add ebx, 4
		test eax, 0x00000003				; test whether the last two digits are zero or not
		cmovnz eax, ebx								; if not zero, we use ebx
		
		mov [ram_alloc], eax
		
		pop ebx
		pop eax
		pop ds
		
		retf

;------------------------------------------------------------------------------------------
; ========= Non public routine
; input: edx:eax store the descriptor
; return: cx store the selector
set_up_gdt_descriptor:

		push ds
		push es
		
		push eax
		push ebx
		push edx
		
		mov ebx, core_data_seg
		mov ds, ebx
		
		sgdt [pgdt]
		
		mov ebx, whole_data_seg						; let es to point to the whole memory
		mov es, ebx
		
		movzx ebx, word [pgdt]						; let bx store the bound of the gdt (offset)
		inc bx										; avoid unecessary overflow so we don't inc ebx
		add ebx, [pgdt+0x02]						; so we get the next descriptor absolute address
		
		mov [es:ebx], eax
		mov [es:ebx+0x04], edx
		
		add word [pgdt], 8							; update the bound of the gdt
		
		lgdt [pgdt]
		
		mov ax, [pgdt]								; give eax the bound of the gdt(always the multiple of 8 - 1)
		mov ecx, 8
		xor edx, edx
		div cx
		mov cx, ax									; we don't need the remainder and now we get how many it is in the gdt
		shl cx, 3
		
		pop edx
		pop ebx
		pop eax
		
		pop es
		pop ds
		
		retf

;-------------------------------------------------------------------------------------------
; ========= Non public routine
; input:
;		eax: the offset address of routine
;		 bx: the descriptor of routine's segment
;		 cx: the property of gate
; output:
;		edx:eax; the whole gate descriptor
make_gate_descriptor:
		push ebx
		push ecx

		mov edx, eax
		and edx, 0xFFFF0000
		or dx, cx
		
		shl ebx, 16
		and eax, 0x0000FFFF
		or eax, ebx

		pop ecx
		pop ebx
		
		retf
		
;===========================================================================================
SECTION core_data vstart=0

pgdt		dw 0				; it store the size of gdt
			dd 0				; it store the start address of gdt

; C-salt
salt:
salt_1:		db '@PrintString'
			times 256-($-salt_1) db 0
			dd put_string
			dw core_routine_seg
			
salt_2:		db '@ReadDiskData'
			times 256-($-salt_2) db 0
			dd read_hard_disk_0
			dw core_routine_seg
			
salt_3:		db '@PrintDwordAsHexString'
			times 256-($-salt_3) db 0
			dd put_hex_word
			dw core_routine_seg
		
salt_4:		db '@TerminateProgram'
			times 256-($-salt_4) db 0
			dd return_point
			dw core_code_seg
			
salt_item_lens:	db ($-salt_4)
salt_items:		db ($-salt)/salt_item_lens

bin_hex:	db '0123456789ABCDEF'

message_1:	db "Protection mode on.", 0x0d, 0x0a, 0
message_2:	db ' System CALL-GATE mounted', 0x0d, 0x0a, 0
message_3:	db 0x0d, 0x0a, '	Load User program...', 0

cpu_brand0:	db 0x0d, 0x0a, '  ', 0
cpu_brand: 	times 52 db 0
cpu_brand1:	db 0x0d, 0x0a, 0x0d, 0x0a, 0



;============================================================================================
SECTION core_code vstart=0		
		
		
		
start:	mov eax, core_data_seg
		mov ds, eax

		mov ebx, message_1							; "Protection mode on"
		call core_routine_seg:put_string
		
		; get the maximum support No.
		mov eax, 0
		cpuid
		
		cmp eax, 0x80000004
		jl return_point
		
		mov eax, 0x80000002
		cpuid
		
		mov [cpu_brand+0x00], eax
		mov [cpu_brand+0x04], ebx
		mov [cpu_brand+0x08], ecx
		mov [cpu_brand+0x0c], edx
		
		mov eax, 0x80000003
		cpuid 
		mov [cpu_brand+0x10], eax
		mov [cpu_brand+0x14], ebx
		mov [cpu_brand+0x18], ecx
		mov [cpu_brand+0x1c], edx
		
		mov eax, 0x80000004
		cpuid
		mov [cpu_brand+0x20], eax
		mov [cpu_brand+0x24], ebx
		mov [cpu_brand+0x28], ecx
		mov [cpu_brand+0x2c], edx
		
		mov ebx, cpu_brand0
		call core_routine_seg:put_string
		mov ebx, cpu_brand
		call core_routine_seg:put_string
		mov ebx, cpu_brand1
		call core_routine_seg:put_string
		
		; install call gate for the kernel
		; every item we need to provide a corresponding call gate
		mov edi, salt
		mov ecx, salt_items							; the loop number is # of items
	.install_gates:
		push ecx									; store ecx as later it will use to store the property of gate
		
		mov eax, [edi+256]							; eax store the offset address in routine segment( stored in salt )
		mov bx, [edi+260]							; bx store the descriptor of the segment including routine
		mov cx, 1_11_0_1100_000_00000B				; P:1	DPL: 11	0	TYPE:code and depend	000	parametr_#: 00000
		call core_routine_seg:make_gate_descriptor
		call core_routine_seg:set_up_gdt_descriptor

		; re-write cx( the routine's gate descriptor ) to core_data_segment
		mov word [edi+260], cx
		add edi, salt_item_lens						; jump to next routine

		pop ecx										; get the loop number pop out
		loop .install_gates
		
		; after make the gate descriptor
		; test PrintString gate
		mov ebx, message_2
		call far [salt_1+256]

		; show the message of " Loading User program..."
		mov ebx, message_3
		call core_routine_seg:put_string

		; begin to allocate user's program
		; establish a TCB for task
		mov ecx, 0x46
		call core_routine_seg:allocate_memory

return_point:

		hlt
		
;===========================================================================================
SECTION trail

		core_end:	
