assume cs:code

data segment

TIME_STYLE	db "YY/MM/DD HH/MM/SS",0

TIME_ORDER 	db 9,8,7,4,2,0

data ends

stack segment
	db 128 dup (0)
stack ends

code segment

start:		mov ax, stack
		mov ss, ax
		mov sp, 128

		call init_reg
		call show_clock

		mov ax, 4c00H
		int 21H




;=================================
; configure the register
init_reg:	mov ax, data
		mov ds, ax
		mov si, OFFSET TIME_STYLE

		mov ax, 0b800H
		mov es, ax
		mov di, 160*20+4*12

		ret

;===================================
; to show the clock by setting the video cache
show_clock:	call showTimeStyle

		mov si, OFFSET TIME_ORDER
		mov di, 160*20+4*12
		mov cx, 6
		
set_time:	mov al, ds:[si]
		out 70H, al
		in al, 71H

		mov ah, al
		shr ah, 1
		shr ah, 1
		shr ah, 1
		shr ah, 1
		and al, 00001111B

		add ah, 30H
		add al, 30H

		mov es:[di], ah
		mov es:[di+2], al
		add di, 6

		inc si

		loop set_time

		jmp show_clock

;===================================
; to show the style of the time
showTimeStyle:	push si
		push di
		push dx

showTSMain:	mov dl, ds:[si]
		cmp dl, 0
		je showTSRet
		mov es:[di], dl
		inc si
		add di, 2
		jmp showTSMain

showTSRet:	pop dx
		pop di
		pop si
		ret

code ends

end start


