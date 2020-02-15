assume cs:code

; program: interrupt code for calculating a number's square

; author : gin





code segment
		; install 7cH program
		; ds:[si] to be the orgin 7cH program
start:		mov ax, cs
		mov ds, ax
		mov si, offset square

		; es:[di] to be the destination address, which is 0:200H
		mov ax, 0
		mov es, ax
		mov di, 200H

		mov cx, offset squareend - offset square
		cld
		rep movsb

		; set the start address in interrupt vector map
		mov ax, 0
		mov es, ax
		mov word ptr es:[7cH*4], 200H
		mov word ptr es:[7cH*4+2], 0

main:		mov ax, 100H
		int 7cH

		mov ax, 4c00H
		int 21H


		; 7cH program
square:		mul ax
		iret

squareend:	nop



code ends

end start
		
