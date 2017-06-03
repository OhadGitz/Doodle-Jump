;TODO 
;
include \masm32\include\masm32rt.inc

includelib msvcrt.lib
include drd.inc
includelib drd.lib

WIN_WIDTH equ 1900		; Window's width constant
WIN_HEIGHT equ 1050		; Wondow's height constant

GREEN equ 000FF00h		; Green color constant



.data       

	counter DWORD ?								; General purpose counter variable

	caption  byte "My Score: ",0				; The Message Box title

	Text BYTE ?									; Will hold the score

	Cheat STRUCT								
		easy_plats DWORD ?						; Platforms will spawn in a line, making it easy to jump
		no_gravity DWORD ?						; Doodle wont fall down. never.
	Cheat ENDS

	cheats Cheat {0,0}

	Doodle STRUCT
		x DWORD 500								; doodle's x position on the screen
		y DWORD 500								; doodle's y position on the screen
		side DWORD 1							; 1 - draw right, 0 - draw left 
		limit_x DWORD ?							; the movement border for doodle on axis x - see Init
		limit_y DWORD ?							; the movement border for doodle on axis y - see Init
		dirx dword 4							; doodle's movement diraction  on x axis
		diry dword 2							; doodle's movement diraction  on y axis
		jump_val DWORD 0
	Doodle ENDS
	
	Platform STRUCT
		x DWORD ?								; platform's x position on the screen
		y DWORD ?								; platform's y position on the screen
		image DWORD ?							; The image of the platform
		jump_type DWORD ?						; The height the jump will add to doodle
	Platform ENDS

	STime SYSTEMTIME  {}						; Used to generate random numbers

	wndTitle BYTE "Doodle Jump",0						; Window's name     
	 
    doodle_left Img {}							; the doodle image that is looking left
	doodle_right Img {}							; the doodle image that is looking right
	background Img {}							; the background image		
	platform Img {}
	platform2 Img {}

    filename_doodle_left BYTE "DoodleLeft.bmp",0
	filename_doodle_right BYTE "DoodleRight.bmp",0								
	filename_platform2 BYTE "platform2.bmp",0
	filename_platform BYTE "platform.bmp",0
	filename_background BYTE "background.bmp",0
    							
								
	;  srcY								image draw crop meme
   ;srcX;---------------;
		;				;
		;				; cropHeight
		;				;
		;				;
		;				;
		;---------------;
	;		cropWidth
				
	background_src_y DWORD ?			; the y axis where we have to crop background.bmp

	turn DWORD 0								; is used to slow down the tick rate of the game

	jump_val DWORD 0							; will hold how much the doodle has to jump

	platforms Platform 4 dup ({})				; array of platforms (4 plats will be present on the screen at all times)

	total_jump_score DWORD 0					; will hold the score the player got			

	doodle Doodle {950, 200, 1, ?, ?, 4, 2, 0}

	random_num DWORD ?

	exPlatform Platform {}						; empty platform struct to use with sizeof later

	sumVar dword ?								; variable for debugging

	sumVar2 dword 0								; variable for debugging

.code


; Useful macro for writing multiple code instructions on one line of code:
; instead of ->
; mov eax, 1
; inc eax
; cmp eax, 0

;you can write ->
; X mov eax, 1 \ inc eax \ cmp eax, 0

X macro args:VARARG
	asm_txt TEXTEQU <>
	FORC char,<&args>
		IFDIF <&char>,<!\>
			asm_txt CATSTR asm_txt,<&char>
		ELSE
			asm_txt
			asm_txt TEXTEQU <>
		ENDIF
	ENDM
	asm_txt
endm




;		*************************
;			UTILS FUNCTIONS
;		*************************

QuickBreak PROC
	pusha

	invoke GetAsyncKeyState, VK_LSHIFT

	.if eax != 0
		xor eax, eax
	.endif

	popa
QuickBreak ENDP


; Used to pop a message box with a number in it
; Parameters - an unsigned number that will pop up

ShowResult PROC Num:DWORD
	; Prints Num

	mov eax, Num

	;---------------DWTOA---------------
	;dwtoa is a MASM function that converts
	;a number to a ascii string (eg: 35 ->
	;"35").								
	;First parameter	- number		
	;Second parameter	- string pointer

	invoke dwtoa, eax, addr Text							; DWORD to ASCII
										
	;-------------MessageBox------------
	;Windows function that pops a Message Box. 
	;Param1 -  handle to the owner window of the message box to be created. 
	;If this parameter is NULL, the message box has no owner window.
	;Param2 - The message to be displayed.
	;Param3 - The dialog box title. If this parameter is NULL, the default title is Error.
	;Param4 - The contents and behavior of the dialog box.
	;https://msdn.microsoft.com/en-us/library/windows/desktop/ms645505(v=vs.85).aspx

	invoke MessageBox, NULL, addr Text, addr caption, MB_OK	; Message Box

	;--------------ExitProcess----------
	;Ends the calling process and all its threads.
	;Param1 - The exit code for the process and all threads.

	invoke ExitProcess, NULL								; Bye Bye

	ret
ShowResult ENDP


; Pseudo Random number generator
; Parameters:
; min - the minimum value of the random number
; max - the maximum value of the random number
; seed- A number that can be used to make the number more random. 
;		Just smash your head on the keyboard or pass NULL  if you're lazy.
;		If the passed parameter is 0 the seed will be ignored.

Random PROC min:DWORD, max:DWORD, seed:DWORD
	; random = (seed * some big number) % (max - min + 1) + min
	
	pusha
	
	; calculates max - min + 1
	mov eax, max
	sub eax, min
	mov max, eax
	inc max
	
	; gets a always changing seed
	invoke GetSystemTime ,addr STime

	; moves to ax the current clock miliseconds and moves the bx the current clock seconds,
	; the two values that changes most frequently

	invoke GetTickCount
	mov ecx, eax

	mov ax, STime.wMilliseconds
	mov bx, STime.wSecond

	; multiplies eax by the current miliseconds and seconds (ax and bx)
	; (seed * some big number)
	mul ax
	mul bx
	mul ecx

	.if seed != 0
		.if seed != NULL
			mov ecx, seed
			mul ecx
		.endif
	.endif

	; reset edx to prevent integer overflow 
	 xor edx, edx

	; divides the value in eax by the max value (reminder will be in edx)
	; (seed * some big number) % (max - min + 1)

	div max
	
	; add min to the final result 
	; + min
	add edx, min

	
	; move the random number in edx to your desired variable
	mov random_num, edx

	
	
	invoke Sleep, 2
	popa
	ret
Random ENDP


;		****************************
;			PLATFORM FUNCTIONS
;		****************************





; Initialize all the platforms

InitPlatforms PROC
	pusha

	mov counter, 0
	mov edi, offset platforms

	.while counter < 4
	mov eax, WIN_WIDTH
	sub eax, platform.iwidth

	invoke Random, 0, eax, edi			; Random X value between 0 and (screen width - picture width)

	mov eax, sizeof exPlatform

	mov ecx, counter
	mul ecx
	mov ebx, random_num

	mov [edi + eax], ebx				; Moving the random X val to the  array

	mov ecx, eax						; Holding eax in ecx because of multiplication later
	
	; Calculation Y value
	mov eax, counter
	mov ebx, 250
	mul ebx
	add eax, 250
	sub eax, platform.iheight

	mov [edi + ecx + 4], eax			; Moving the Y val to the platform
	
	; Moving the platform image offset and jump type to the platform struct 

	invoke Random, 0, 5 , NULL

	.if random_num != 3
		mov [edi + ecx + 8], offset platform 
		mov platforms[ecx].jump_type, 1				;first jump type
	.else
		; High jump
		mov [edi + ecx + 8], offset platform2
		mov platforms[ecx].jump_type, 2				;second jump type
	.endif
	inc counter
	
	.endw

	popa
InitPlatforms ENDP


DrawPlatforms PROC
	pusha
	
	mov counter,0
	mov edi, offset platforms

	.while counter < 4

	mov eax, sizeof exPlatform
	mov ecx, counter
	mul ecx
	
	invoke drd_imageDraw, [edi + eax + 8] , [edi + eax], [edi + eax + 4]

	inc counter
	.endw

	popa
	ret
DrawPlatforms ENDP


; push platforms down aas doodle goes up.
; param - the number of pixels to push it down

PushPlatforms PROC pixels:DWORD
	pusha
	
	X	mov counter, 0	\	mov edi, offset platforms

	.while counter < 4
	
	mov eax, sizeof exPlatform

	X	mov ecx, counter	\	mul ecx	\	mov ebx, pixels

	add [edi + 4], ebx

	inc counter
	.endw

	ret
	popa
PushPlatforms ENDP




;		**************************
;			BACKGROUND FUNCS
;		**************************

PushBackground PROC pixels:DWORD
	; Push the background up for scrollable screen
	pusha

	; Cheacking if the BG reached its highest point and resets it.

	mov eax, WIN_HEIGHT
	.if background_src_y <= eax
	X	mov eax, background.iheight	\	sub eax, WIN_HEIGHT	\	mov background_src_y, eax
	.endif

	X	mov eax, pixels	\	sub background_src_y, eax

	add doodle.y, eax
	invoke PushPlatforms, pixels

	popa
	ret
PushBackground ENDP





;		*************************
;			DOODLE FUNCTIONS
;		*************************

; Take care of the doodle's movement on the X axis.

MoveX PROC	
	pusha

	check_keyboard:
		invoke GetAsyncKeyState, VK_RIGHT	
		.if eax != 0
		; moving right
			; checking if doodle hits the right border of the window

			X   mov eax, doodle.limit_x	\	cmp doodle.x, eax	\	jge stop
			X	mov eax, doodle.x	\	add eax, doodle.dirx	\	mov doodle.x, eax	
		mov doodle.side, 1
		.endif

		X	invoke GetAsyncKeyState, VK_LEFT
		.if eax != 0
		; moving left
			; checking if doodle hits the right border of the window

			X	cmp doodle.x, 0	\	jle stop
			X	mov eax, doodle.x	\	sub eax, doodle.dirx	\	mov doodle.x, eax	
			mov doodle.side, 0
		.endif

	stop: 
		popa
		ret
MoveX ENDP

; Jumps doodle
Jump PROC jumptype:DWORD
	pusha
	.if jumptype == 1
		mov doodle.jump_val, 500
		add total_jump_score, 5

	.elseif jumptype == 2
		mov doodle.jump_val, 1500
		add total_jump_score, 15

	.endif
	ret
Jump ENDP


MoveY PROC	
	;This is in charge of the doodle's movement on axis Y

	pusha

	; ignore
	.if cheats.no_gravity == 1
	invoke Jump, 2
	.endif

	.if doodle.y <= 200
		;doodle reached the top
		invoke PushBackground, doodle.diry
	.elseif doodle.y > WIN_HEIGHT	
			invoke ShowResult, total_jump_score
	.endif

	
	.if doodle.jump_val == 0
		X	mov eax, doodle.diry	\	add doodle.y, eax

	.else
		.if cheats.no_gravity == 1
		mov  eax, doodle.diry
		add doodle.jump_val, eax
		.endif
		X	mov eax, doodle.diry	\	sub doodle.jump_val, eax	\	sub doodle.y, eax	

	.endif
	
	popa
	ret
MoveY ENDP


MovementManger PROC	
	pusha
	inc turn

	.if turn == 5
		mov turn, 0	
		
		invoke MoveY
		invoke MoveX

	.endif

	popa
	ret

MovementManger ENDP





;		***********************
;			GAMEPLAY FUNCS
;		***********************


; The main doodle jump game proc
MainGame PROC
	pusha

	invoke MovementManger

	invoke drd_pixelsClear, 0
	invoke drd_imageDrawCrop, offset background, 0, 0, 0, background_src_y, WIN_WIDTH, WIN_HEIGHT

	.if doodle.side == 1
		invoke drd_imageDraw, offset doodle_right, doodle.x, doodle.y
	.elseif doodle.side == 0
		invoke drd_imageDraw, offset doodle_left, doodle.x, doodle.y
	.endif

	invoke DrawPlatforms

	popa
	ret
MainGame ENDP


init PROC	
	pusha
	; load files, 
	

	invoke drd_imageLoadFile, offset filename_doodle_left , offset doodle_left
	invoke drd_imageLoadFile, offset filename_doodle_right , offset doodle_right
	invoke drd_imageLoadFile, offset filename_background , offset background
	invoke drd_imageLoadFile, offset filename_platform , offset platform

	; init all the none constant variables that wont change during the run. 
	X	mov eax, WIN_WIDTH \ sub eax, doodle_left.iwidth  \ mov doodle.limit_x, eax
	X	mov eax, WIN_HEIGHT \ sub eax, doodle_left.iheight  \	sub eax, 150	\	mov doodle.limit_y, eax
	X	mov eax, background.iheight	\	sub eax, WIN_HEIGHT	\	mov background_src_y, eax

	; Clearing the green screen off the images
	invoke drd_imageSetTransparent, offset doodle_left, GREEN
	invoke drd_imageSetTransparent, offset doodle_right, GREEN
	invoke drd_imageSetTransparent, offset platform, GREEN

	; initialize all the platforms with random X values 
	invoke InitPlatforms

	popa
	ret
init ENDP

; Checking if the escape bottun was pressed and quiting if so.
CheckQuit PROC
	pusha

	invoke GetAsyncKeyState, VK_ESCAPE

	.if eax != 0
	invoke ExitProcess, 1
	.endif

	popa
	ret
	
CheckQuit ENDP



;		****************************
;					MAIN
;		****************************


main PROC

	invoke drd_init, WIN_WIDTH, WIN_HEIGHT, INIT_WINDOW
	invoke init

	mainGameLoop:

		invoke MainGame
		;invoke drd_printFps, NULL
		invoke drd_processMessages
		invoke drd_flip
		
		invoke CheckQuit
			
	jmp mainGameLoop
	ret
main ENDP

end main