assume cs:code

data segment
	db "XuYang is dalao, isn't He?", 0
data ends

stack segment stack
	db 128 dup (0)
stack ends

code segment
	

start:		mov ax, stack
		mov ss, ax
		mov sp, 128

		; ds:[bx] point to the string
		mov ax, data
		mov ds, ax
		mov bx, 0

		; es:[si] point to the video mem
		mov ax, 0b800H
		mov es, ax
		mov si, 160*7 + 20*2

		call show_string

		mov ax, 4c00H
		int 21H


;------------------------------------------------------------

show_string:	push ax
		push ds
		push bx
		push es
		push si
		
showString:	mov ax, 0
		mov al, ds:[bx]
		
		cmp ax, 0
		je showString_ret

		call to_Capital
		

		mov es:[si], al
		inc si
		mov byte ptr es:[si], 07H

		inc bx
		inc si

		jmp showString

showString_ret:	pop si
		pop es
		pop bx
		pop ds		
		pop ax

		ret

;--------------------------------------------------------------

to_Capital:	cmp ax, 97
		jb toCapital_ret

		cmp ax, 123
		jnb toCapital_ret

		and al, 01011111B

toCapital_ret:	ret

code ends

end start

	
