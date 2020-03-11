; protection mode kernel
; author: gin

;----------------------------------------------------------------------------
; global constant variable
		core_code_seg		equ 0x38
		core_data_seg		equ 0x30
		core_routine_seg	equ 0x28
		video_ram_seg		equ 0x20
		core_stack_seg		equ 0x18
		whole_data_seg		equ 0x08
		
;----------------------------------------------------------------------------
; the kernel's header

		core_length dd code_end
		
		core_routine_seg_addr	dd section.sys_routine.start
		
		core_data_seg_addr		dd section.sys_data.start
		
		core_code_seg_addr		dd section.sys_code.start
		
		code_entry		dd start
						dw core_code_seg


		[bits 32]
;==============================================================================
SECTION sys_routine	vstart=0

; put a string end with '0' in the video cache
; ds:ebx point to the start of the string
put_string:

		push ecx
		
	.getchar:
		mov cl, [ebx]
		or cl, cl					;cmp cl, 0
		jz .exit
		call put_char
		
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
		
;------------------------------------------------------------------------------
; record the next start of the available memory and sent back the attributed start address to store
; input : ecx: the length of the code
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
		
;-------------------------------------------------------------------------------------------------------------------
; make descriptor
; eax store the base address
; ebx store the length of the code - 1 to stand for the bound
; ecx store the TYPE
; return edx:eax as the descriptor
make_gdt_descriptor:

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
		
;-------------------------------------------------------------------------------------------------------------------
; set up the descriptor in the GDT
; edx: eax store the descriptor
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
		
;-------------------------------------------------------------------------------------------------------------------
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


;===================================================================================================================
SECTION sys_data	vstart=0

pgdt:	dw 0								; the low 2B store the size of gdt
		dd 0								; the high 4B store the start addr of gdt

ram_alloc:	dd 0x00100000					; the start address when you want to allocate the memory

;-------------------------------------------------------------------------------------------------------------------
; SALT
salt:
salt_1	db '@PrintString'
		times 256-($-salt_1) db 0
		dd put_string
		dw core_routine_seg
		
salt_2	db '@ReadDiskData'
		times 256-($-salt_2) db 0
		dd read_hard_disk_0
		dw core_routine_seg
		
salt_3	db '@PrintDwordAsHexString'
		times 256-($-salt_3) db 0
		dd put_hex_word
		dw core_routine_seg
		
salt_4	db '@TerminateProgram'
		times 256-($-salt_4) db 0
		dd return_point
		dw core_code_seg
		
salt_item_lens equ ($-salt_4)
salt_items	equ	($-salt)/salt_item_lens

messege_1:
		db "Welcome to the Protection mode", 0x0d, 0x0a, 0
		
messege_5:
		db "Loading user program...", 0x0d, 0x0a, 0
		
do_status:
		db "Done.", 0x0d, 0x0a, 0
		
message_6  db  0x0d,0x0a,0x0d,0x0a,0x0d,0x0a
           db  '  User program terminated,control returned.',0
		
bin_hex:
		db "0123456789abcdef"
		
core_buf:	times 2048 db 0x00				; a special allocated memory space to temporarily store the data for laoding disks or other exchanging behavior

esp_pointer:	dd 0						; to store the stack pointer of kernel

cpu_brand0:	db 0x0d, 0x0a, '  ', 0
cpu_brand:	times 52 db 0x00
cpu_brand1:	db 0x0d, 0x0a, 0x0d, 0x0a, 0

;-------------------------------------------------------------------------------
SECTION sys_code	vstart=0
; load and locate the user's program
; input : esi -> logic sector number 
; output: ax store the segment descriptor of the usr's program
load_allocate_program:
		push ebx
		push ecx
		push edx
		
		push esi
		push edi
		
		push es
		push ds

		mov eax, core_data_seg
		mov ds, eax
		
		mov eax, esi
		mov ebx, core_buf
		call core_routine_seg:read_hard_disk_0
		
		; let eax store the length of the usr's program
		mov eax, [core_buf]
		
		;expanded the program into a group of 512 bytes block, so the program length divides 512
		mov ebx, eax
		and ebx, 0xfffffe00
		add ebx, 512
		
		test eax, 0x000001ff					; test whether the origin usr's program length divides 512
		cmovnz eax, ebx						; if not then use the new length in ebx
		
		mov ecx, eax						; transport to ecx to allocate memory
		call core_routine_seg:allocate_memory

		mov ebx, ecx						; let ebx store the start address of allocated memory
		push ebx							; save the start address, as later ebx will be used to load problem from hard disk
		
		; here eax still store the length of the code which divides 512
		mov ecx, 512						
		xor edx, edx
		div ecx
		
		mov ecx, eax						; ecx store how many sectors to read for loop.
		
		mov eax, whole_data_seg
		mov ds, eax
		
		mov eax, esi						; give the start sector number
	.loading:
		call core_routine_seg:read_hard_disk_0
		inc eax
		loop .loading
		
		; loading finished, now we need to attribute all kinds of segment to it and set segment descriptor for it
		pop edi								; now we pop out the start address
		
		; make the segment descriptor of the header
		mov eax, edi						; eax store the start address
		mov ebx, [edi+0x04]					; ebx store the bound of the segment
		dec ebx
		mov ecx, 0x00409200					; ecx store the type: data segment
		call core_routine_seg:make_gdt_descriptor
		call core_routine_seg:set_up_gdt_descriptor
		mov [edi+0x04], cx
		
		; make the segment descriptor of the code
		mov eax, edi
		add eax, [edi+0x14]					; eax store the start address of the code segment
		mov ebx, [edi+0x18]					; ebx store the bound of the segment
		dec ebx
		mov ecx, 0x00409800					; ecx store the type: code segment
		call core_routine_seg:make_gdt_descriptor
		call core_routine_seg:set_up_gdt_descriptor
		mov [edi+0x14], cx
		
		; make the segment descriptor of the data
		mov eax, edi
		add eax, [edi+0x1c]					; eax store the start address of the code's data segment
		mov ebx, [edi+0x20]					; ebx store the bound of the segment
		dec ebx
		mov ecx, 0x00409200
		call core_routine_seg:make_gdt_descriptor
		call core_routine_seg:set_up_gdt_descriptor
		mov [edi+0x1c], cx
		
		; set the stack and its segment descriptor
		mov ecx, [edi+0x0c]					; ecx store the size of the code ( in 4KB unit )
		mov ebx, 0x000fffff					; ebx store the bound of the segment
		sub ebx, ecx						
		mov eax, 4096
		mul dword [edi+0x0c]
		mov ecx, eax								; ecx store the size of the code in Byte
		call core_routine_seg:allocate_memory		; apply for a memory after the code for stack
		
		; now ecx contain the start address of the stack segment
		add eax, ecx								; but for a from top to down stack segment, it need top address as the base address for the descriptor
		mov ecx, 0x00c09600							; ecx store the type
		call core_routine_seg:make_gdt_descriptor
		call core_routine_seg:set_up_gdt_descriptor
		mov [edi+0x08], cx							; stack segment finished
		
		
		; redirect the salt of program
		mov eax, [edi+0x04]							; now what we get is the header descriptor of the user program
		mov es, eax									; es -> the header of program
		mov eax, core_data_seg						
		mov ds, eax 								; ds -> the data segment of kernel
		
		cld
		
		; compare every entry in the user salt to all entry in the kernel
		mov ecx, [es:0x24]							; ecx store how many public routine the user program called
		mov edi, 0x28								; es:edi -> the salt of usr program
	.cmp_all_entry:
		
		push ecx
		push edi
		
		mov ecx, salt_items							; how many entry in kernel's salt to compare
		mov esi, salt								; now ds:esi -> the salt of kernel
	.cmp_entry:	
	
		push ecx
		push esi
		push edi
		
		mov ecx, 64
		repe cmpsd
		jnz .entry_ne
		
		; if equal
		mov eax, [esi]
		mov dword [es:edi-256], eax
		mov	eax, [esi+4]
		mov word [es:edi-252], ax
		
	; if not equal	
	.entry_ne:	
		
		pop edi
		pop esi
		pop ecx
		
		add esi, salt_item_lens						; to next salt entry of kernel
		loop .cmp_entry
		
		pop edi
		pop ecx
		
		add edi, 256
		loop .cmp_all_entry
		
		mov ax, [es:0x04]
		
		pop ds
		pop es
		
		pop edi
		pop esi
		
		pop edx
		pop ecx
		pop ebx
		
		ret

start:	
		mov eax, core_data_seg
		mov ds, eax
		
		mov ebx, messege_1
		call core_routine_seg:put_string

		;show information about the brand of CPU
		; test the maximum function number which the current CPU support
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
		
		mov ebx, messege_5
		call core_routine_seg:put_string
		
		mov esi, 50										; the user program in #50 sector
		call load_allocate_program
		
		mov ebx, do_status							; tell the usr that his program is already loaded and allocated
		call core_routine_seg:put_string
		
		mov [esp_pointer], esp							; save the kernel esp
		
		mov ds, ax										; give ds -> header of usr program
		
		jmp far [0x10]									; 0x10 is the just start of the usr program
		
; user program return to here after executed and finished
return_point:
	
		mov eax, core_data_seg
		mov ds, eax
		
		mov eax, core_stack_seg
		mov ss, eax
		
		mov esp, [esp_pointer]

		mov ebx, message_6
		call core_routine_seg:put_string

		hlt


;---------------------------------------------------------------------------------
SECTION code_trail

code_end:
