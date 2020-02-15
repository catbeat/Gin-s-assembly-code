assume cs:code ds:data ss:stack

data segment
	db 'BASIC           '
	db 'UNIXS           '
	db 'LINUX           '
	db 'Scala           '
data ends

stack segment
	dw 0,0,0,0,0,0,0,0
stack ends

code segment

	start:	mov ax, data
		mov ds, ax
		mov bx, 0

		mov ax, stack
		mov ss, ax
		mov sp, 16

		mov cx,4

main:		push cx
		mov cx, 5
		push bx

upletter:	mov al, ds:[bx]
		or al, 00100000B
		mov ds:[bx], al
		inc bx
		loop upletter
		
		pop bx
		add bx, 16
		pop cx
		loop main

		mov ax, 4c00H
		int 21H

code ends

end start

























	
