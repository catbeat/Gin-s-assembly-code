assume cs:code

data segment
	db 'Welcome to masm!', 0
data ends

stack segment
	db 128 dup(0)
stack ends

code segment

start:		mov ax, data
		mov ds, ax
		mov bx, 0

		mov ax, stack
		mov ss, ax
		mov sp, 128

		mov ax, 0b800H
		mov es, ax
		mov si, 0

		mov dh, 8
		call get_row
		add si, ax

		mov dh, 3
		call get_col
		add si, ax
		
		mov dh, 2
		call show_str

		mov ax, 4c00H
		int 21H


get_row:	mov ax, 0
		mov al, 160
		mul dh
		ret

get_col:	mov ax, 0
		mov al, 2
		mul dh
		ret

show_str:	push cx
		push ds
		push bx
		push es
		push si


show_str_main:	mov cx, 0
		mov cl, ds:[bx]
		jcxz show_str_ret

		mov es:[si], cl
		mov es:[si+1], dh
		
		add si, 2
		inc bx
		loop show_str_main

show_str_ret:	pop si
		pop es
		pop bx
		pop ds
		pop cx
		ret

code ends

end start






	
