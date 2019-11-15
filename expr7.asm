assume cs:code ds:data ss:stack

data segment
	; year
	db '1975','1976','1977','1978','1979','1980','1981','1982','1983','1984','1985'
	db '1986','1987','1988','1989','1990','1991','1992','1993','1994','1995'		

	; income
	dd 16,22,382,1356,2390,8000,16000,24486,50065,97479,140417,197514
	dd 345980,590827,803530,1183000,1843000,2759000,3753000,4649000,5937000

	; employee
	dw 3,7,9,13,28,38,130,220,476,778,1001,1442,2258,2793,4037,5635,8226,11542,14430,15257,17800
data ends

table segment
	db 21 dup('year summ ne ?? ')
table ends

stack segment stack
	db 128 dup(0)
stack ends

code segment

	start:	mov ax, data
		mov ds, ax
		mov bx, 0			; bx to track the data segment
			
		mov ax, stack
		mov ss, ax
		mov sp, 128

		mov ax, table
		mov es, ax			; es to point to table segment
		mov si, 0			; si to track the table segment

		mov cx, 21
		mov ax, 0
		mov di, 42*4			; di to track employee part in data segment

import:		mov ax, [bx]
		mov es:[si], ax
		add sie 2
		mov ax, [bx+2]
		mov es:[si], ax
		add si, 3

		mov ax, [bx+84]
		mov dx, [bx+86]
		mov es:[si],ax
		mov es:[si+2],dx
		add bx, 4
		add si, 5
		
		push dx
		mov dx, ds:[di]
		mov es:[si], dx
		pop dx
		
		div word ptr ds:[di]
		add di, 2
		add si, 3

		mov es:[si], ax
		add si, 3
		
		loop import
		

		mov ax,4c00H
		int 21H
code ends

end start

























	
