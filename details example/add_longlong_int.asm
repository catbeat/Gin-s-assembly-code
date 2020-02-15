assume cs:code

data segment
	dw 1020H, 3829H, 7620H, 2885H
	dw 6206H, 9921H, 1539H, 1116H
data ends

stack segment
	db 128 dup (0)
stack ends

code segment

start:		mov ax, data
		mov ds, ax
		mov bx, 0		; ds:bx point to the first 8 byte long long int
		mov si, 8		; ds:si point to the second 8 byte long long int

		mov ax, stack
		mov ss, ax
		mov sp, 128

		call add_ll_int

		mov ax, 4c00H
		int 21H

add_ll_int:	push ax
		push cx
		push si
		push di	

		sub ax, ax		; set CF = 0
		mov cx, 4

	s:	mov ax, ds:[bx]
		adc ax, ds:[si]
		mov ds:[bx], ax
		
		; inc register didn't change CF
		inc bx
		inc bx			

		inc si
		inc si

		loop s

		pop di
		pop si
		pop cx
		pop ax
		ret


code ends

end start



	
