assume cs:code, ds:data
code	segment

start:
	cli
	mov	ax,0b800h	;beginning of video memory
	mov	ds,ax	;set ES to the first place in video memory
;clearing the screen
	mov	bl,0	;row counter
	mov	bh,0	;column counter
	mov	cl,80	;column limit
	mov	ch,' '	;print my empty strings
	mov	dx,0
clearColumn:
	mov	ax,0	;prep ax
	mov	dl,bh

	mov	al,bl	;prep for mult
	mul	cl	;row number * 80
	add	ax,dx	;previous line + column
	add	ax,ax	;previous line * 2
	
	mov	si,ax	;video memory address is ax
	mov	[si],ch	;put the empty string in video memory

	add	bh,1	;move to the next column
	cmp	bh,80	;have we reached the final column?
	jl	clearColumn	;if not, keep on clearing columns

clearRow:
	add	bl,1	;if so, add 1 to the counter
	mov	bh,0	;reset columns
	cmp	bl,25	;have we finished every row?
	jl	clearColumn	;if not move onto the next row

;fill with black asterisks

	mov	bl,0	;set rows to 0
	mov	bh,1	;set columns to 0
	mov	cl,80	;max of 80 columns
	mov	ch,'*'	;set up to print out an asterisk
	mov	dx,0	;store color

columnAsterisk:
	mov	ax,0
	mov	dl,bh

	mov	al,bl	;prep for mult
	mul	cl	;row number *80
	add	ax,dx	;previous line + column number
	add	ax,ax	;previous line * 2

	mov	si,ax	;video memory address is ax
	mov	[si],ch	;put asterisk in video memory
	add	si,1	;increase the memory address by 1
	mov	[si],dh	;set color to black

	add	bh,1	;next column
	cmp	bh,10	;are the columns less or equal to 10?
	jle	columnAsterisk ;if so, restart the loop

rowAsterisk:
	add	bl,1	;if not, move to the next row
	mov	bh,0	;set column to 0
	cmp	bl,20	;is the row less than 20?
	jl	columnAsterisk	;if so, repeat loop

;drawing my borders
	mov	bx,0	;set loop value to 0
	mov	ch,'|'	;set character to '|'
	mov	dh,7	;make color white
sideBorders:
	mov	al,160	;left border counter
	mul	bl	;multiplication for getting column/row

	mov	si,ax	;video memory address is in ax
	mov	[si],ch	;put character in video memory
	add	si,1	;move up by 1 byte in memory
	mov	[si],dh	;set color to white

	mov	al,80	;right side max is set to 80
	mul	bl	;multiply row number *80
	add	ax,11	;add 11 to previous line
	add	ax,ax	;double previous line

	mov	si,ax	;video memory address is in ax
	mov	[si],ch	;put | in video memory
	add	si,1	;move up 1 byte in memory
	mov	[si],dh	;set color to white

	add	bl,1	;add 1 to the loop counter
	cmp	bl,20	;is the row number is less than 20
	jl	sideBorders	;; if so, repeat loop
	
	mov	bl,0	;if not, prep for bottom border
	mov	cl,20	;set limit to 20
	mov	ch,'-'	;set the character to '-'

bottomBorder:	
	mov	al,80	;set up multiplication
	mul	cl	;multiply 80*the bottom row
	add	ax,bx	;add column number to previous line
	add	ax,ax	;previous line * 2

	mov	si,ax	;video memory address is in ax
	mov	[si],ch	;put the dash in video memory
	add	si,1	;next byte in memory
	mov	[si],dh	;set color to white

	add	bl,1	;add 1 to loop counter
	cmp	bl,11	;is the column number is less than or equal to 11?
	jle	bottomBorder	;if so, repeat loop

setupDone:
	call	beginGame

;here are my set pixel, get pixel functions

setPixel:
	push	ax	;back up ax to the stack
	push	bx	;back up bx to the stack
	push	cx
	
	mov	ax,0	;set ax to 0
	add	bh,1	;add 1 to column counter
	mov	cx,0

	mov	al,bl	;standard multiplication process:
	mov	cx,80	
	mul	cx	
	add	al,bh	
	mov	cx,2	
	mul	cx	
	add	ax,1	
	
	mov	si,ax	;set video memory address to ax
	pop	cx
	pop	bx	;get bx value
	pop	ax	;get ax value
	mov	[si],al	;put the color value in video memory
	ret		;return

getPixel:
	push	ax
	push	bx	
	push	cx

	mov	ax,0	
	add	bh,1	
	mov	cx,0	
	
	mov	al,bl	;standard multiplication process
	mov	cx,80	
	mul	cx	
	add	al,bh	
	mov	cx,2	
	mul	cx	
	add	ax,1	

	mov	si,ax	;video memory address is in ax
	pop	cx
	pop	bx	
	pop	ax
	mov	al,[si]	;put color in video memory

	ret		;return

;set the tetris piece

setPiece:
	push	ds
	push	cx
	push	dx
	push	ax	;put ax into the stack
	
	mov	ax,data
	mov	ds,ax
	pop	ax

	mov	si,ax	;memory address in si
	mov	cx,0	;clear cx
	mov	dx,0	;clera dx
	
pieceLoop:
	mov	dl,[si]	;put video memory into dl
	push	dx	;push to the stack
	add	si,1	;move 1 byte in memory

	add	cl,1	;add 1 to the loop
	cmp	cl,8	;is the loop value less than 8?
	jl	pieceLoop	;if so, repeat loop
	
	mov	cl,0	;if not, reset cl
	mov	si,offset currentPiecex	;put the first pixel of the piece in si
	add	si,7	;point to the last pixel in the shape
	
setPiece2:
	pop	dx	;access the stack
	mov	[si],dl	;put the piece address into memory
	sub	si,1	;move down one byte in memory
	
	add	cl,1	;add 1 to the looping value
	cmp	cl,8	;has it looped 8 times?
	jl	setPiece2	;if not, repeat loop?

	pop	dx
	pop	cx
	pop	ds
	ret		;return

; display or hide the piece

showCurrentPiece:
	push	ax	
	push	bx
	push	cx
	push	ds

	mov	ax,data
	mov	ds,ax	
	mov	si,offset currentPiecex	
	mov	ax,0
	mov	ax,7	
	mov	cx,0	

showCurrentPieceLoop:
	add	si,cx
	mov	bh,[si]	
	add	si,4	
	mov	bl,[si]	
	
	pop	ds 

	push	ax
	mov	ax,0b800h
	mov	ds,ax
	pop	ax

	call	setPixel	
		
	push	ds
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax
	mov	si,offset currentPiecex
	add	cx,1	
	cmp	cx,4	
	jl	showCurrentPieceLoop
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	ret		

hideCurrentPiece:

	push	ax	
	push	bx
	push	cx
	push	ds 

	mov	ax,data
	mov	ds,ax	
	mov	si,offset currentPiecex	
	mov	ax,0
	mov	ax,0	
	mov	cx,0	
hideCurrentPieceLoop:
	add	si,cx
	mov	bh,[si]	
	add	si,4	
	mov	bl,[si]	
	
	pop	ds

	push	ax
	mov	ax,0b800h
	mov	ds,ax
	pop	ax

	call	setPixel	

	push	ds
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax
	mov	si,offset currentPiecex
	add	cx,1	
	cmp	cx,4	
	jl	hideCurrentPieceLoop	
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	ret		

;piece movement

canMoveDown:  
	push	bx
	push	cx
	push	ds

	mov	cx,0
	call	hideCurrentPiece
	mov	ax,data
	mov	ds,ax
canMoveLoop:
	mov	ax,data
	mov	ds,ax
	mov	si,offset currentPiecex
	add	si,cx
	v	bh,[si]
	add	si,4
	mov	bl,[si]
	add	bl,1

	push	ax
	mov	ax,0b800h
	mov	ds,ax
	pop	ax
	call	getPixel
	cmp	al,7
	je	canMoveFailure
	add	cx,1
	cmp	cx,4
	jl	canMoveLoop
	call	showCurrentPiece
	mov	al,1

	pop	ds
	pop	cx
	pop	bx
	ret
canMoveFailure:	
	call	showCurrentPiece
	mov	al,0
	pop	ds
	pop	cx
	pop	bx
	ret
	
endGame2:
	jmp	beginGame

	;The game starts HERE
beginGame:
	;the piece is in the data segment
	push	ds	;ds is currently video memory address
	mov	ax,data
	mov	ds,ax
	
moveLoop:
	mov	cx,0
	mov	si,offset currentPieceNum
	mov	cl,[si] 
	add	cl,1	
	cmp	cl,7	
	je	resetPieceNum
	cmp	cl,7
	jne	movePiece

resetPieceNum:
	mov	cl,1

movePiece:
	mov	[si],cl
	mov	ax,8
	mul	cx
	add	ax,offset currentPiecex
	call	setPiece
	push	cx 
	mov	cx,0
	
bigLoop:
	push	ax
	mov	ax,1234h
	pop	ax

	cmp	cx,4
	je	nextLoop

	mov	si,offset currentPiecex
	add	si,cx

	mov	bh,[si]
	add	si,4
	mov	bl,[si]

	pop	ds
	push	ax
	mov	ax,0b800h
	mov	ds,ax
	pop	ax
	call	getPixel
	push	ds

	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax

	cmp	al,7
	je	endGame2
	add	si,1
	add	cx,1
	jmp	bigLoop

nextLoop:
	call	canMoveDown
	cmp	al,1
	jne	moveLoop
	call	hideCurrentPiece

	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax

	mov	si,offset currentPiecex
	add	si,4
	mov	cx,0
yCoor:
	cmp	cx,4
	je	getKey
	mov	bh,[si]
	add	bh,1
	mov	[si],bh
	add	si,1
	add	cx,1
	jmp	yCoor

nothingLoop:
	cmp	ax,60000
	je	nextLoop
	add	ax,1
	jmp	nothingLoop

;; --------- KEY BOARD ------------
getKey:
	mov	ax,1234h

	in	al,64h	;check for keystroke
	and	al,1
	jz	noKey	;if there wasn’t a key stroke, go to hokey 
	in	al,60h	;if there was a key stroke, read in the key
	cmp	al,4bh	;is it a left arrow?
	jz	leftKey	;if so, go to left key
	cmp	al,4dh	;is it a right arrow?
	jz	rightKey ;if so, go to right key
	
noKey:
	call 	clearKey
	call	showCurrentPiece
	jmp	nothingLoop
	
leftKey:
	call 	clearKey
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax

	mov	si,offset currentPiecex
	mov	cx,0
downX:
	cmp	cx,4
	je	nextDone
	mov	bh,[si]
	sub	bh,1
	mov	[si],bh
	add	si,1
	add	cx,1
	jmp	downX
	
rightKey:
	call clearKey
	;; move it right
	push	ax
	mov	ax,data
	mov	ds,ax
	pop	ax

	mov	si,offset currentPiecex
	mov	cx,0
xCoor:
	cmp	cx,4
	je	nextDone
	mov	bh,[si]
	add	bh,1
	mov	[si],bh
	add	si,1
	add	cx,1
	jmp	xCoor
nextDone:
	call	showCurrentPiece
	jmp	nothingLoop
	
clearKey:
	in	al,60h	
	in	al,64h	
	and	al,1	
	jnz	clearKey
	ret	
		
code	ends

data	segment
currentPiecex  	db     	0,0,0,0
currentPiecey  	db     	0,0,0,0
piecex_line	db	5,5,5,5
piecey_line    	db     	0,1,2,3
piecex_l       	db     	5,6,7,5
piecey_l       	db     	0,0,0,1
piecex_r       	db     	5,6,7,7
piecey_r       	db     	0,0,0,1
piecex_s       	db     	5,6,6,7
piecey_s       	db     	1,1,0,0
piecex_z       	db      5,6,6,7
piecey_z       	db     	0,0,1,1
piecex_t      	db     	5,6,7,6
piecey_t        db     	0,0,0,1
piecex_box	db	5,6,5,6
piecey_box      db     	0,0,1,1
currentPieceNum	db	0
data	ends

	end	start