assume cs:code

data segment
	db 128 dup (0)
data ends

stack segment
	db 128 dup (0)
stack ends

code segment

start:		mov ax, stack
		mov ss, ax
		mov sp, 128

		mov ax, data
		mov ds, ax
		mov bx, 0

;=============================================
; save the origin int9 program
		mov ax, 0
		mov es, ax
		cli

; save it into ds:0		
		push es:[9*4]
		pop ds:[0]
		push es:[9*4+2]
		pop ds:[2]
		
; set the new int 9
		mov word ptr es:[9*4], offset int_9
		mov es:[9*4+2], cs

		mov ax, 0B800H
		mov es, ax
		mov ah, 'a'

		sti

main:		mov es:[160*12+40*2],ah
		call delay
		inc ah
		cmp ah, 'z'
		jna main

		mov ax, 4c00H
		int 21H

;============================================
;sleep function
delay:		push dx
		push ax
		mov dx, 10H
		mov ax, 0

delay_main:	sub ax, 1
		sbb dx, 0
		cmp ax, 0
		jne delay_main
		cmp dx, 0
		jne delay_main

delay_ret:	pop ax
		pop dx
		ret

;=============================================
;new int 9

int_9:		push ax
		push es

		in al, 60H

; call the origin int 9 program to deal with the hardware details
		pushf
		call dword ptr ds:[0]

		cmp al, 1
		jne int_9_ret

		mov ax, 0B800H
		mov es, ax
		inc byte ptr es:[160*12+40*2+1]

int_9_ret:	pop es
		pop ax
		iret
		
code ends

end start
