assume cs:code

data segment
	db 128 dup (0)
data ends

stack segment
	db 128 dup (0)
stack ends

code segment

start:		mov ax, data
		mov ds, ax
		mov bx, 0

		mov ax, stack
		mov ss, ax
		mov sp, 128

		mov ax, 0D620H
		mov dx, 0013H

		mov cx, 10
	
		push ax
		mov bp, sp
	
		call dividw

		mov ax, 4c00H
		int 21H

dividw:		mov ax, dx
		mov dx, 0
		
		div cx
		; ax store quotient and dx store remainder

		push ax
		mov ax, ss:[bp]
		
		div cx
		
		pop dx
		
		ret

		




code ends

end start




	
