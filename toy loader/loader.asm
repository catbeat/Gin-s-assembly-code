; loader
; author: gin

		app_lba_start equ 100    ; the user program's start sector number
		
SECTION loader align=16 vstart=0x7c00
		
		mov ax, 0
		mov ss, ax
		mov sp, ax
		
		mov ax, [cs:phybase]
		mov dx, [cs:phybase+0x02]
		mov bx, 0x10
		div bx
		mov ds, ax						; let ds and es to point to the destination address's segment address
		mov es, ax
		
		; at least load the header into memory
		xor bx, bx
		mov si, app_lba_start
		xor di, di
		call read_start_disk_0
		
		;based on the header to load the program
		mov ax, [ds:0x00]
		mov dx, [ds:0x02]
		mov bx, 512
		div bx
		cmp dx, 0
		jnz non_integer_sector
		dec ax							; as the header is already loaded, so we decrease one
		
non_integer_sector:
		cmp ax, 0
		jz direct

		mov cx, ax
		push ds
integer_sector:
		xor bx, bx						; set bx ( the offset address ) to be zero
		
		; after loading a sector, increase the destination address for 512 bytes, just 20H in segment address
		mov ax, ds
		add ax, 0x20	
		mov ds, ax
		
		inc si
		call read_start_disk_0
		
		loop integer_sector
		
		pop ds							; ds = 0x1000

; redirect the start segment address
direct:
		mov dx, [ds:0x08]
		mov ax, [ds:0x06]
		call cal_seg_addr
		mov [ds:0x06], ax
		
		; now redirect all the code segment address
		mov cx, [ds:0x0a]
		mov bx, 0x0c
		realloc:
				mov dx, [ds:bx+0x02]
				mov ax, [ds:bx]
				call cal_seg_addr
				mov [ds:bx], ax
				add bx, 0x04
				loop realloc
			
		jmp far [ds:0x04]
;-----------------------------------------------------------------------------------------------------------
cal_seg_addr:
		push dx
		
		add ax, [cs:phybase]
		adc dx, [cs:phybase+0x02]
		shr ax, 4
		ror dx, 4
		and dx, 0xf000
		or ax, dx
		
		pop dx
		ret
		
;------------------------------------------------------------------------------------------------------------
; di store the start sector number ( high ), si store the start sector number ( low )
; ds:bx is the to-load address, bx should be better to start from 0
; it just read one sector
read_start_disk_0:
		push dx
		push ax
		push bx
		push cx

		; set how many sectors to read
		mov dx, 0x1f2
		mov al, 0x01
		out dx, al
		
		; set the 28 bit sector number
		inc dx							; dx: 0x1f3
		mov ax, si
		out dx, al
		
		inc dx							; dx: 0x1f4
		mov al, ah
		out dx, al
		
		inc dx							; dx: 0x1f5
		mov ax, di
		out dx, al
		
		inc dx							; dx: 0x1f6
		mov al, 0xe0
		or al, ah
		out dx, al
		
		; the operation is to read
		inc dx							; dx; 0x1f7				
		mov al, 0x20
		out dx, al
		
		; wait until the disk is ready to transport information
		.wait:
				in al, dx
				and al, 0x88
				cmp al, 0x08
				jnz .wait
				
		mov cx, 256
		mov dx, 0x1f0
		.readw:
				in ax, dx
				mov [ds:bx], ax
				add bx, 2
				loop .readw
				
		pop cx
		pop bx
		pop ax
		pop dx
		
		ret
		
;-----------------------------------------------------------------------------------------------------------
		phybase dd 0x10000		; the destination address for loading the user program
		
times 510-($-$$) db 0x00
				 db 0x55, 0xaa