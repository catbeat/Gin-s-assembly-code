assume cs:code

; author: gin

code segment

start:		; es:di to store the destination address
		mov ax, 0
		mov es, ax
		mov di, 0200H

		; ds:si point to the interrupt program #0
		mov ax, cs
		mov ds, ax
		mov si, offset d0

		; set teh length of whole interrupt program #0
		mov cx, offset d0_end - offset d0
		cld
		rep movsb

		mov ax, 0
		mov es, ax
		mov word ptr es:[0*4], 0200H
		mov word ptr es:[0*4+2], 0

		mov ax, 1000H
		mov bx, 1
		div bl

		mov ax, 4c00H
		int 21H


d0:		jmp short d0_start
		db "overflow!"

d0_start:	; set es:di to store the video cache where to show "overflow"
		mov ax, 0B800H
		mov es, ax
		mov di, 12*160+36*2

		; set ds:si to point to the "overflow" string address
		mov ax, cs
		mov ds, ax
		mov si, 0202H

		mov cx, 9
	store:	mov al, ds:[si]
		mov es:[di], al
		inc si
		add di, 2
		loop store

		; return back to os
		mov ax, 4c00H
		int 21H

d0_end:		nop

code ends

end start


		
