assume cs:code

data segment
	dw 11, 22, 33, 44, 55, 66, 77, 88
	dd  0,  0,  0,  0,  0,  0,  0,  0
data ends

stack segment stack
	db 128 dup (0)
stack ends

code segment
	
start:		mov ax, data
		mov ds, ax
		mov bx, 0

		mov es, ax
		mov si, 16

		mov ax, stack
		mov ss, ax
		mov sp, 128

		mov cx, 8
		call cal_cubes

		mov ax, 4c00H
		int 21H



cal_cubes:	call get_cube

		add bx, 2
		add si, 4

		loop cal_cubes
		ret


get_cube:	push ax
		push dx

		mov ax, ds:[bx]
		
		mul word ptr ds:[bx]
		mul word ptr ds:[bx]
		; now ax store the low 16bit, dx store the high 16 bit

		call store_cube
		
		pop dx
		pop ax
		ret

store_cube:	mov es:[si], ax
		mov es:[si+2], dx

		ret
			
code ends

end start






















	
