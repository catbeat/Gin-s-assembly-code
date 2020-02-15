assume cs:code

; this program interprets hwo to use the Dos interrupt program

; author : gin

data segment
	db "Catbeat comes here!", '$'
data ends

code segment

start:		mov ah, 2
		mov bh, 0
		mov dh, 5
		mov dl, 12
		int 10h

		mov ax, data
		mov ds, ax
		mov dx, 0
		mov ah, 9	;use the 9th sub program
		int 21H 

		mov ax, 4c00H
		int 21H

code ends

end start





