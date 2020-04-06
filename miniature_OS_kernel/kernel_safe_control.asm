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
		whole_data_seg		equ 0x08		; 4 GB data segment
		

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
; return: ebx : the end after loading
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
; make descriptor
; input: 
;		eax store the base address
; 		ebx store the length of the code - 1 to stand for the bound
; 		ecx store the TYPE
; return edx:eax as the descriptor
make_seg_descriptor:

		mov edx, eax
		shl eax, 16
		or ax, bx									;mov ax, bx
	
		rol edx, 8
		bswap edx
		and edx, 0xFF0000FF

		and ebx, 0xffff0000
		or edx, ebx
		or edx, ecx
	
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

tcb_chain_header	dd 0		; it store the absolute address of the header of TCB linked list

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

do_status:	db "Done.", 0x0d, 0x0a, 0

cpu_brand0:	db 0x0d, 0x0a, '  ', 0
cpu_brand: 	times 52 db 0
cpu_brand1:	db 0x0d, 0x0a, 0x0d, 0x0a, 0



;============================================================================================
SECTION core_code vstart=0

;--------------------------------------------------------------------------------------------
; update the descriptor to LDT
; input:
;		edx:eax the descriptor
;		ebx the address of current task's TCB
; output:
;		cx: the selector of the descriptor in LDT
fill_descriptor_to_LDT:

		push eax
		push ebx
		push edx
		push ds

		mov ecx, whole_data_seg
		mov ds, ecx

		mov edi, [ebx+0x0c]							; get the base addr of LDT

		xor ecx, ecx
		mov cx, [ebx+0x0a]							; cx is the bounf of LDT
		inc cx										; the start addr for next descriptor

		; install
		mov [edi+ecx+0x00], eax
		mov [edi+ecx+0x04], edx

		; update the bound of LDT
		add cx, 8
		dec cx
		mov [ebx+0x0a], cx

		; return selector of descriptor
		mov ax, cx
		xor dx, dx
		mov cx, 8
		div cx

		mov cx, ax
		shr cx, 3
		or cx, 0000_0000_0000_0100B					; set the T1 to be 1

		pop ds
		pop edx
		pop ebx
		pop eax

		ret

;--------------------------------------------------------------------------------------------
; load the user program
; input:	PUSH sector number
; 			PUSH the address of corresponding TCB
load_allocate_program:
		pushad

		push ds
		push es

		mov ebp, esp					
		
		mov eax, whole_data_seg
		mov	es, eax

		mov esi, [ebp+11*4]						; let esi store the address of TCB

		; allocate LDT's memory
		mov ecx, 160							; allow 20 LDT descriptor
		call core_routine_seg:allocate_memory
		mov [es:esi+0x0c], ecx					; give the TCB the address of LDT
		mov word [es:esi+0x0a], 0xFFFF			; give the offset bound of the LDT, which is the length - 1, now it's 0 - 1

		; read the user program from hard disk
		mov eax, core_data_seg
		mov ds, eax

		mov eax, [ebp+12*4]						; get the sector number
		mov ebx, core_buf
		call core_routine_seg:read_hard_disk_0

		; get the size of the program
		mov eax, [core_buf]
		mov ebx, eax							; make it align to 512B
		and ebx, 0xfffffe00
		add ebx, 512
		test eax, 0x00001ff
		cmovnz eax, ebx

		mov ecx, eax							; give ecx the size of program
		call core_routine_seg:allocate_memory
		mov [es:esi+0x06], ecx					; update the base addr of program to TCB

		; calculate how many sectors to use
		mov ebx, ecx							; ebx store the start address to load
		xor edx, edx
		mov ecx, 512
		div ecx
		mov ecx, eax							; ecx store how many sectors to set loop

		mov eax, whole_data_seg					
		mov ds, eax

		mov eax, [ebp+12*4]						; eax to nominate the sector nuber
	.read_each_sector:
		call core_routine_seg:read_hard_disk_0
		inc eax
		loop .read_each_sector

		; set descriptor for the parts of user program
		mov edi, [es:esi+0x06]					; edi store the start address of program

		; set the descriptor for the program' header
		mov eax, edi							; the start addr of header
		mov ebx, [es:edi+0x04]					; the bound of header
		dec ebx
		mov ecx, 0x0040f200						; in Byte, data type, DPL 3
		call core_routine_seg:make_seg_descriptor

		; update the desrciptor to LDT
		mov ebx, esi
		call fill_descriptor_to_LDT			

		or cx, 0000_0000_0000_0011B				; set the RPL to be 3

		mov [es:esi+0x44], cx					; update the selector of header descriptor to TCB
		mov [edi+0x04], cx						; together in the program

		; set the descriptor for the program's code segment
		mov eax, edi
		add eax, [edi+0x14]						; the start addr of code seg
		mov ebx, [edi+0x18]						; the bound of code seg
		dec ebx
		mov ecx, 0x0040f800						; in Byte, data type, DPL 3
		call core_routine_seg:make_seg_descriptor

		mov ebx, esi
		call fill_descriptor_to_LDT

		or cx, 0000_0000_0000_0011B				; RPL 3
		mov [edi+0x14], cx						; update the selector of code seg to header

		; set the descriptor for the program's data segment
		mov eax, edi
		add eax, [edi+0x1c]						; the start addr of data seg
		mov ebx, [edi+0x20]						; the bound of data seg
		dec ebx
		mov ecx, 0x0040f200						; in byte, data type, DPL 3
		call core_routine_seg:make_seg_descriptor

		mov ebx, esi
		call fill_descriptor_to_LDT

		or cx, 0000_0000_0000_0011B				; RPL 3
		mov [edi+0x1c], cx						; update the selector of data seg to header

		; set the descriptor for the program's local stack segment
		mov ecx, [edi+0x0c]						; in 4KB
		mov ebx, 0x000fffff						; the bound of stack
		sub ebx, ecx
		mov eax, 4096
		mul ecx
		mov ecx, eax							; the size to allocate memory for stack
		call core_routine_seg:allocate_memory

		add eax, ecx							; the start addr for stack
		mov ecx, 0x00c0f600						; in 4KB, stack type, DPL 3
		call core_routine_seg:make_seg_descriptor

		mov ebx, esi
		call fill_descriptor_to_LDT

		or cx, 0000_0000_0000_0011B
		mov [edi+0x08], cx

		; redirect the user program salt
		mov eax, whole_data_seg
		mov es, eax

		cld

		mov ecx, [es:edi+0x24]					; how many salt items
		add edi, 0x28							; redirect edi to the start of salt

	.cmp_each_salt_items:
		push ecx
		push edi

		mov ecx, salt_items
		mov esi, salt
	.cmp_a_salt_item:
		push ecx
		push edi
		push esi

		mov ecx, 64
		repe cmpsd

		jnz .

		mov eax, [esi]
		mov [es:edi-256], eax
		mov ax, [esi+0x04]
		or ax, 0000_0000_0000_0011B				; give the call gate CPL
		mov [es:edi-252], ax

	.not_cop_gate:

		pop esi
		pop edi
		pop ecx

		add esi, salt_item_lens

		loop .cmp_a_salt_item					; cmp next one in C-salt

		pop edi
		pop ecx
		add edi, 256
		loop .cmp_each_salt_items				; cmp next one in user salt

		mov esi, [bp+11*4]						; esi store the start addr of TCB

		; create DPL 0, 1, 2 stack for user program
		; create DPL 0 stack
		mov ecx, 4096
		mov eax, ecx							; prepare for calculating the top address of stack
		mov [es:esi+0x1a], ecx
		shr dword [es:esi+0x1a], 12				; The size should be in 4KB unit
		call core_routine_seg:allocate_memory

		add eax, ecx							; get the top(start) addr of 0 stack
		mov [es:esi+0x1e], eax					; update it in TCB
		mov ebx, 0x000ffffe						; set the bound of 
		mov ecx, 0x00c09600						; DPL 0, in 4KB, type stack

		call core_routine_seg:make_seg_descriptor
		mov ebx, esi
		call fill_descriptor_to_LDT				; update the descriptor to LDT

		mov [es:esi+0x22], cx					; the RPL of the selector are already zero
		mov dword [es:esi+0x24], 0				; give the initial ESP value

		; create DPL 1 stack
		mov ecx, 4096
		mov eax, ecx							; prepare for calculating the top address of stack
		mov [es:esi+0x28], ecx
		shr dword [es:esi+0x28], 12				; The size should be in 4KB unit
		call core_routine_seg:allocate_memory

		add eax, ecx							; get the top(start) addr of 0 stack
		mov [es:esi+0x2c], eax					; update it in TCB
		mov ebx, 0x000ffffe						; set the bound of 
		mov ecx, 0x00c0b600						; DPL 1, in 4KB, type stack

		call core_routine_seg:make_seg_descriptor
		mov ebx, esi
		call fill_descriptor_to_LDT				; update the descriptor to LDT

		or cx, 0000_0000_0000_0001B				; the RPL should be 1
		mov [es:esi+0x30], cx					
		mov dword [es:esi+0x32], 0				; give the initial ESP value

		; create DPL 2 stack
		mov ecx, 4096
		mov eax, ecx							; prepare for calculating the top address of stack
		mov [es:esi+0x36], ecx
		shr dword [es:esi+0x36], 12				; The size should be in 4KB unit
		call core_routine_seg:allocate_memory

		add eax, ecx							; get the top(start) addr of 0 stack
		mov [es:esi+0x3a], eax					; update it in TCB
		mov ebx, 0x000ffffe						; set the bound of 
		mov ecx, 0x00c0d600						; DPL 2, in 4KB, type stack

		call core_routine_seg:make_seg_descriptor
		mov ebx, esi
		call fill_descriptor_to_LDT				; update the descriptor to LDT

		or cx, 0000_0000_0000_0010B				; the RPL should be 1
		mov [es:esi+0x3e], cx					
		mov dword [es:esi+0x40], 0				; give the initial ESP value

		; load LDT descriptor to GDT
		mov eax, [es:esi+0x0c]					; base addr for LDT
		movzx ebx, word [es:esi+0x0a]			; zero extended the bound
		mov ecx, 0x00408200						; LDT descriptor, DPL = 0

		call core_routine_seg:make_seg_descriptor
		call core_routine_seg:set_up_gdt_descriptor
		mov [es:esi+0x10], cx					; register the selector to TCB

		; create the user program TSS
		mov ecx, 104							; the basic size of TSS
		mov [es:esi+0x12], cx
		dec word [es:esi+0x12]					; register the bound to the TCB
		call core_routine_seg:allocate_memory
		mov [es:esi+0x14], ecx					; register TSS base addr to TCB

		; update the TSS
		mov word [es:ecx+0], 0					; the previous task is 0 here.

		mov edx, [es:esi+0x24]					; update the DPL 0 stack original esp
		mov [es:ecx+4], edx

		mov dx, [es:esi+0x22]					; update the DPL 0 stack segment
		mov [es:ecx+8], dx

		mov edx, [es:esi+0x32]					; update the DPL 1 stack original esp
		mov [es:ecx+12], edx

		mov dx, [es:esi+0x30]					; update the DPL 1 stack segment
		mov [es:ecx+16], dx		

		mov edx, [es:esi+0x40]					; update the DPL 2 stack original esp
		mov [es:ecx+20], edx

		mov dx, [es:esi+0x3e]					; update the DPL 2 stack segment
		mov [es:ecx+24], dx

		mov dx, [es:esi+0x10]					; update the LDT selector						
		mov [es:ecx+96], dx					

		mov dx, [es:esi+0x12]					; update the task's I/O offset
		mov [es:ecx+102], dx

		mov word [ es:ecx+100], 0				; update the T bit

		; update TSS descriptor to GDT
		mov eax, ecx							; give the base addr
		movzx ebx, word [es:esi+0x12]			; give the bound
		mov ecx, 0x00408900
		call core_routine_seg:make_seg_descriptor
		call core_routine_seg:set_up_gdt_descriptor
		mov [es:esi+0x18]						; update the descriptor to TCB

		pop es
		pop ds

		popad

		ret 8


;--------------------------------------------------------------------------------------------
; append to TCB link list
; input: ecx: the start address of the TCB to append
; return: ecx: origin value
append_to_TCB_link:
		push eax
		push edx
		push ds
		push es

		; let ds point to the core data segment because the address of header of the TCB linked list in it
		mov eax, core_data_seg
		mov ds, eax

		; let es point to the whole data because ecx should be the absolute address of TCB
		mov eax, whole_data_seg
		mov es, eax

		mov dword [es:ecx+0x00], 0				; the next TCB pointer should be zero

		mov eax, [tcb_chain_header]				; get the address of next TCB pointer
		or eax, eax								; check whether the next pointer is 0
		jz TCB_link_is_empty					; if 0 that means currently TC linked list is empty

	; otherwise the TCB linked list is not empty, looply get to the trail
	.TCB_link_to_trail:
		mov edx, eax
		mov eax, [es:edx+0x00]					; get the next TCB address
		or eax, eax								; see if it's 0
		jnz .TCB_link_to_trail					; not 0 means not trail

		; if trail
		mov [es:edx+0x00], ecx
		jmp .append_to_TCB_link_ret

	.TCB_link_is_empty:
		mov [tcb_chain_header], ecx				; the current is the header

	.append_to_TCB_link_ret:
		pop es
		pop ds
		pop edx
		pop eax
		ret


;--------------------------------------------------------------------------------------------
; main program
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
		call append_to_TCB_link

		; give where is the user program and prepare for it
		push dword 50
		push ecx
		call load_allocate_program

		; after we relocate the user program to make it prepared for control by OS
		mov ebx, do_status												; print debug message for finishing
		call core_routine_seg:put_string

		mov eax, whole_data_seg
		mov ds, eax

		ltr [ecx+0x18]								; from TCB load the TSS
		lldt [ecx+0x10]							    ; from TCB load the LDT

		mov eax, [ecx+0x44]							; from TCB load the header selector of user program
		mov ds, eax

		; to call the user program, we pretend we are return back from a call gate, basically treat the whole OS as a called gate
		push dword [0x08]							; push the stack selector
		push dword 0								; push esp

		push dword [0x14]							; push the code selector
		push dword [0x10]							; push eip

		retf

return_point:
		mov eax, core_data_seg
		mov ds, eax

		mov ebx, message_6
		call core_routine_seg:put_string

		hlt
		
core_code_end:
;===========================================================================================
SECTION trail

core_end:	
