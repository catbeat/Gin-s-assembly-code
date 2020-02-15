assume cs:code

data segment
	dw 123, 12666, 24, 1500, 27
	db 128 dup (0)
data ends


stack segment
	db 128 dup (0)
stack ends

code segment

start:		mov ax, data
		mov ds, ax
		mov bx, 0

		mov es, ax
		mov si, 10

		mov ax, stack
		mov ss, ax
		mov sp, 128

		mov cx, 5
		
main:		call dtoc
		add bx, 2
		inc si
		loop main

		mov si, 10

		mov ax, 0b800H
		mov ds, ax
		mov bx, 8*160+ 3*2
		
		mov cx, 5
print_res:	call show_str
		
		add bx, 160
		inc si
		loop print_res

		mov ax, 4c00H
		int 21H
		
;=============================================
dtoc:		push ax
		push dx
		push cx
		push bx

		mov ax, ds:[bx]
		mov bx, 10
		mov cx, 0

dtoc_main:	mov dx, 0
		div bx
		push dx

		inc cx
		push cx
		mov cx, ax
		jcxz dtoc_ret

		pop cx
		jmp dtoc_main

dtoc_ret:	pop cx
				
store:		pop bx
		mov bh, 0
		add bl, 30H
		mov es:[si], bl
		inc si
		loop store
		
		mov byte ptr es:[si], 0

		pop bx
		pop cx
		pop dx
		pop ax	
		ret
	
;=============================================
show_str:	push cx
		push ds
		push bx
		push es
		
		mov dh, 2

show_str_main:	mov cx, 0
		mov cl, es:[si]
		jcxz show_str_ret

		mov ds:[bx], cl
		mov ds:[bx+1], dh
		
		add bx, 2
		inc si
		loop show_str_main

show_str_ret:	pop es
		pop bx
		pop ds
		pop cx
		ret


code ends

end start


	
