assume cs:code

stack segment
	db 128 dup (0)
stack ends

code segment

start:		mov ax, stack
		mov ss, ax
		mov sp ,128

		;set the new address of 7CH program
		mov ax, 0
		mov es, ax
		
		mov ax, cs
		mov es:[7cH*4+2], ax

		mov ax, OFFSET int_7C
		mov es:[7cH*4], ax

		mov ah, 1
		mov al, 1
		int 7cH
		call sleep

		mov al, 2
		mov ah, 2
		int 7cH
		call sleep
		
		mov ah, 3
		int 7cH
		call sleep

		mov ah, 0
		int 7cH
		call sleep

		mov ax, 4c00H
		int 21H

;======================================
;sleep function
sleep:		push ax
		push dx

		mov ax, 1000H
		mov dx, 10H

sleepMain:	sub ax, 1
		sbb dx, 0
		cmp dx, 0
		je sleepRet
		jmp sleepMain	

sleepRet:	pop dx
		pop ax
		ret



;======================================
;int 7cH program
;ah choose which subprogram
int_7C:		jmp int_7C_m

		table dw cleanScreen, setFgColor, setBgColor, resizeVC

int_7c_m:	cmp ah, 3
		ja int_7C_ret
		mov bl, ah
		mov bh, 0
		add bx, bx

		call word ptr table[bx]

int_7C_ret:	iret


;========================================
;clean the video cache
cleanScreen:	push bx
		push es
		push di
		push cx

		mov bx, 0b800H
		mov es, bx
		mov di, 0
		mov cx, 2000

clScreenMain:	mov byte ptr es:[di], ' '
		add di, 2
		loop clScreenMain

clScreenRet:	pop cx
		pop di
		pop es
		pop bx
		ret		 

;==========================================
;set the frontground color
;al store the color
setFgColor:	push bx
		push es
		push di
		push cx

		mov bx, 0B800H
		mov es, bx
		mov di, 1
		mov cx, 2000
	
stFgClrMain:	and byte ptr es:[di], 11111000B
		or byte ptr es:[di], al
		add di, 2
		loop stFgClrMain

stFgClrRet:	pop cx
		pop di
		pop es
		pop bx
		ret

;============================================
;set the background color
;al store the color
setBgColor:	push bx
		push es
		push di
		push cx

		mov bx, 0B800H
		mov es, bx
		mov di, 1
		mov cl, 4
		shl al, cl
		mov cx, 2000

stBgClrMain:	and byte ptr es:[di], 10001111B
		or byte ptr es:[di], al
		add di, 2
		loop stBgClrMain

stBgClrRet:	pop cx
		pop di
		pop es
		pop bx
		ret

;===============================================
;mov the whole video cache into the previous line
resizeVC:	push bx
		push es
		push ds
		push si
		push di

		; es:di point to the nth line, ds:si point to the n+1th line
		mov bx, 0B800H
		mov es, bx
		mov ds, bx
		mov si, 160
		mov di, 0

		cld
		mov cx, 24

resizeVCMain:	push cx
		mov cx, 160
		rep movsb
		pop cx
		loop resizeVCMain

resizeVCret:	pop di
		pop si
		pop ds
		pop es
		pop bx
		ret




code ends

end start














