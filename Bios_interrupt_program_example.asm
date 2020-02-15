assume cs:code

; this program interpret how to use bios interrupt program

; author : gin

code segment

start:	mov ah, 2	;use the 2th sub program, which sets the cursor
	mov bh, 0	;set the page number to be 0th page
	mov dh, 5	;set the line number to be 5th line
	mov dl, 12	;set the column number to be 12th column
	int 10h		;These are done by 10th interrupt program

	mov ah, 9	;use the 9th sub program, which shows the char at the current cursor
	mov al, 'a'	;al to store which char to show
	mov bl, 11001010B	;use bl to store the property of char
	mov bh, 0	;set the page number to be 0th page
	mov cx, 3	;how many times to repeat the char
	int 10h

	mov ax, 4c00H
	int 21H
	

code ends

end start








