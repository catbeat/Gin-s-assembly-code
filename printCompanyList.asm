assume cs:code

data segment
	db '1975','1976','1977','1978','1979','1980','1981','1982','1983'
	db '1984','1985','1986','1987','1988','1989','1990','1991','1992'
	db '1993','1994','1995'

	dd 16,22,382,1356,2390,8000,16000,24486,50065,97479,140417,187514
	dd 345980,590827,803530,1183000,1843000,2759000,3753000,4649000,5937000

	dw 3,7,9,13,28,38,130,220,476,778,1001,1442,2258,2793,4037,5635,8226
	dw 11542,14430,15257,17800
data ends

table segment
	db 21 dup ('year summ ne ?? ')
table ends

cache segment
	dw 21*80 dup (0720H)
cache ends

stack segment
	db 128 dup (0)
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
		add si, 2
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

; ============================================
		mov si, 0			; data: es:si
		
		mov ax, cache		
		mov ds, ax
		mov bx, 0			; destination: ds:bx

		mov cx, 21

main:		push bx
		push si
	
		call insert_year

		add bx, 20
		add si, 5

		call insert_sum
		
		add bx, 20
		add si, 5

		mov ax, es:[si+2]
		push ax
		mov ax, 0
		mov es:[si+2], ax

		call insert_ne

		pop ax
		mov es:[si+2], ax

		add bx, 20
		add si, 3

		mov ax, es:[si+2]
		push ax
		mov ax, 0
		mov es:[si+2], ax

		call insert_qm

		pop ax
		mov es:[si+2], ax

		pop si
		pop bx

		add bx, 160
		add si, 16
		loop main

	video_mem:	mov ax, 0b800H
			mov es, ax
			mov si, 1*160

			mov bx,0

			mov cx, 21*80
			
	store_in:	mov ax, ds:[bx]
			mov es:[si], ax
			
			add si, 2
			add bx, 2
			loop store_in

		mov ax, 4c00H
		int 21H

; ================================================
insert_year:	push si
		push cx
		push ax
		push dx
		push bx

		mov cx, 4
	i_year:	mov al, es:[si]		
		mov ds:[bx], al

		inc si
		add bx,2
		
		loop i_year
		
		pop bx
		pop dx
		pop ax
		pop cx
		pop si
		ret

; ================================================
insert_sum:	call dtoc
		ret

; ================================================
insert_ne:	call dtoc
		ret

; ================================================
insert_qm:	call dtoc
		ret

; ================================================
dtoc:		push bp
		push si
		push bx
		push ax
		push dx
		push cx

		mov ax, es:[si]
		mov dx, es:[si+2]

		mov cx, 0
		push cx				; cx as counter

		mov cx, dx			; if only 16 bit int, we just go to the low bit
		jcxz low_bit_b
		
		pop cx				; else we pop out the cx which is counter
		push ax

	get_dd_rem:	mov ax, dx

			mov dx, 0
			inc cx
			push cx

			mov cx, 10
			div cx
			; ax store the quotient, dx store the remainder

			
			pop cx		
			mov bp, ax
	
			pop ax		; use the remainder*10000H + ax to calculate the true remainder

			push cx
			mov cx, 10

			div cx
			; ax store the quotient, dx store the remainder

			pop cx

			push dx

			push cx

			mov dx, bp
			
			mov cx, dx
			jcxz low_bit_b
			
			pop cx
			push ax

			jmp get_dd_rem 
				
			
	low_bit_b:	pop cx

	low_bit:	mov dx, 0
		
			inc cx
			push cx

			mov cx, 10

			div cx
			; ax store the quotient, dx store the remainder

			pop cx

			push dx

			push cx

			mov cx, ax
			jcxz dtoc_mid

			pop cx
			jmp low_bit

	dtoc_mid:	pop cx
			
	store:		pop dx
			add dx, 30H

			mov byte ptr ds:[bx], dl
			
			add bx, 2
			
			loop store

			pop cx
			pop dx
			pop ax
			pop bx
			pop si
			pop bp
			ret

;==========================================

code ends

end start




	
