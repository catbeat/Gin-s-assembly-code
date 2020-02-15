assume cs:code ds:data ss:stack

data segment
	db 'BASIC'
	db 'UNIX'
	db 'KERNEL'
	db 'POOL'
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

		mov cx, 19
		mov ax, 0

lowercase:	mov al, [bx]
		or al, 00100000B
		mov [bx], al

		inc bx
		loop lowercase


		mov ax, 4c00H
		int 21H
code ends

end start
	
