assume cs:code

data segment
	db  "zzy", 0
	db  "wsx", 0
	db  "yzht", 0
	db  "xy", 0

	dw  0, 4, 8, 13

data ends

stack segment stack
	db 128 dup (0)
stack ends

code segment

	start:	mov ax, stack
		mov ss, ax
		mov sp, 128

		call init_reg

		mov bx, 0                        ; bx to track data
		mov si, 160*10 + 30*2            ; si to track screen

		call showOption

		mov ax,4c00H
		int 21H


; init register
init_reg:	push ax
		mov ax, 0B800H
		mov es, ax

		mov ax, data
		mov ds, ax

init_reg_ret:	pop ax
		ret


; respectively show the four char array
showOption:	push bx
		
		mov bx, 16			 ; the address of the pointer to the string
		mov cx, 4			 ; totally four char stirng

showOption_l:	call showString
		add bx, 2
		add si, 160
		loop showOption_l

showOption_ret:	pop bx
		ret


; show a char string array
showString:	push cx
		push bx
		push ax
		push si

		mov bx, ds:[bx]
		mov cx, 0

showString_l:	mov cl, ds:[bx]
		jcxz showString_ret                            ; judge whether the end of the char array
		mov es:[si], cl
		mov byte ptr es:[si+1], 02 

		inc bx
		add si, 2

		jmp showString_l

showString_ret:	pop si
		pop ax
		pop bx
		pop cx
		ret

		

code ends

end start



















	
