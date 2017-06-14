;TODO 
;PUSH PLATS
;RED PLAT
include \masm32\include\masm32rt.inc

includelib msvcrt.lib
include drd.inc
includelib drd.lib

WIN_WIDTH equ 1920		; Window's width constant
WIN_HEIGHT equ 1080		; Wondow's height constant

GREEN equ 000FF00h		; Green color constant



.data       

	Option STRUCT
		x DWORD ?
		y DWORD ?
		isChosen DWORD ?
		image DWORD ?
	Option ENDS

	start_game Option <>

	how_to_play Option <>

	enable_only_red Option <>

	enable_no_gravity Option <>

	enable_easy_plats Option <>
	
	screenId DWORD 0

	counter DWORD ?								; General purpose counter variable

	caption  byte "My Score: ",0				; The Message Box title

	Text BYTE ?									; Will hold the score

	Cheat STRUCT								
		easy_plats DWORD ?						; Platforms will spawn in a line, making it easy to jump
		no_gravity DWORD ?						; Doodle wont fall down. never.
		only_red_plats DWORD ?
	Cheat ENDS

	cheats Cheat {0,0,0}

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
	platform_red Img {}
	welcome Img {}
	start_option Img {}
	help_option Img {}

    filename_doodle_left BYTE "GameObjects\DoodleLeft.bmp",0
	filename_doodle_right BYTE "GameObjects\DoodleRight.bmp",0								
	filename_platform_red BYTE "GameObjects\platform_red.bmp",0
	filename_platform BYTE "GameObjects\platform.bmp",0
	filename_background BYTE "background.bmp",0
	filename_welcome BYTE "WelcomeScreen\WelcomeScreen.bmp",0
	filename_start_option BYTE "WelcomeScreen\Start.bmp",0
	filename_how_to_play_option BYTE "WelcomeScreen\Help.bmp",0
    							
								
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

	random_num DWORD 1

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





;		***************************************************************

;							UTILS FUNCTIONS

;		***************************************************************





QuickBreak PROC
	pusha

	invoke GetAsyncKeyState, VK_LSHIFT

	.if eax != 0
		xor eax, eax
	.endif

	popa
	ret
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

Random PROC min:DWORD, max:DWORD
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

	; multiplies eax by the current miliseconds and seconds (ax and bx)
	; (seed * some big number)
	; following java's lcg generation.
	mul ecx
	mul random_num
	add eax, 11

	shr eax, 11

	; reset edx to prevent integer overflow 
	 xor edx, edx

	; divides the value in eax by the max value (reminder will be in edx)
	; (seed * some big number) % (max - min + 1)


	.if max == 0
		mov max, 1
	.endif

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






;		***************************************************************

;							PLATFORMS FUNCTIONS

;		***************************************************************



; Initialize all the platforms

InitPlatforms PROC
	pusha

	mov counter, 0
	mov edi, offset platforms

	.while counter < 4
	mov eax, WIN_WIDTH
	sub eax, platform.iwidth

	invoke Random, 1, eax			; Random X value between 0 and (screen width - picture width)

	mov eax, sizeof exPlatform

	mov ecx, counter
	mul ecx

	.if cheats.easy_plats != 1
		mov ebx, random_num
	.else 
		mov ebx, doodle.x
	.endif

	mov [edi + eax], ebx				; Moving the random X val to the  array

	mov ecx, eax						; Holding eax in ecx because of multiplication later
	
	; Calculation Y value
	X	mov eax, counter	\	mov ebx, 250	\	mul ebx	\	add eax, 250	\	sub eax, platform.iheight

	mov [edi + ecx + 4], eax			; Moving the Y val to the platform
	
	; Moving the platform image offset and jump type to the platform struct 

	invoke Random, 1, 2

	.if cheats.only_red_plats == 1
		mov random_num, 1
	.endif

	.if random_num != 1
		mov [edi + ecx + 8], offset platform 
		mov platforms[ecx].jump_type, 1				;first jump type
	.else
		; High jump
		mov [edi + ecx + 8], offset platform_red
		mov platforms[ecx].jump_type, 2				;second jump type
	.endif

	inc counter
	
	.endw

	popa
	ret
InitPlatforms ENDP

; Draws every platform in the array

DrawPlatforms PROC
	pusha
	
	mov counter,0
	mov edi, offset platforms

	.while counter < 4

	X	mov eax, sizeof exPlatform	\	mov ecx, counter	\	mul ecx
	
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

	add [edi + eax + 4], ebx


	inc counter
	.endw

	ret
	popa
PushPlatforms ENDP

MakePlatform PROC plat:DWORD
	pusha

	mov edi, offset platforms

	mov ebx, WIN_WIDTH
	sub ebx, platform.iwidth

	mov eax, sizeof exPlatform
	mov ecx, plat
	mul ecx

	invoke Random, 1, ebx					; Random X value between 0 and (screen width - picture width)

	.if cheats.easy_plats != 1
		mov ebx, random_num
	.else 
		mov ebx, doodle.x
	.endif

	mov platforms[eax].x, ebx					; Moving the random X val to the  array

	mov platforms[eax].y, 0						; Moving the Y val to the platform
	
	; Moving the platform image offset and jump type to the platform struct 

	invoke Random, 1, 10

	.if cheats.only_red_plats == 1
		mov random_num, 1
	.endif

	add ecx, 4
	.if random_num != 1
		mov platforms[eax].image, offset platform 
		mov platforms[eax].jump_type, 1				;first jump type
	.else
		; High jump
		mov platforms[eax].image, offset platform_red
		mov platforms[eax].jump_type, 2				;second jump type
	.endif


	popa
	ret
MakePlatform ENDP

HandlePlatforms PROC
	pusha

	X	mov counter, 0	\	mov edi, offset platforms

	.while counter < 4
	
	mov eax, sizeof exPlatform

	X	mov ecx, counter	\	mul ecx	\	mov edx, eax \ mov eax, WIN_HEIGHT

	.if platforms[edx].y >= eax

	invoke MakePlatform, ecx

	.endif

	inc counter
	.endw

	popa
	ret
HandlePlatforms ENDP


;		***************************************************************

;							BACKGROUND FUNCTIONS

;		***************************************************************

; changing the background height

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





;		***************************************************************

;							DOODLE FUNCTIONS

;		***************************************************************



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
	.if doodle.jump_val == 0
		.if jumptype == 1
			mov doodle.jump_val, 700
			add total_jump_score, 5

		.elseif jumptype == 2
			mov doodle.jump_val, 1600
			add total_jump_score, 15
			inc doodle.diry

		.endif
	.endif
	ret
Jump ENDP

;David's check collision
;puts in eax 1 if there is collision, 0 if not.

DidCollide PROC x1: DWORD, y1: DWORD, w1: DWORD, h1: DWORD, x2: DWORD, y2: DWORD, w2: DWORD, h2: DWORD

	 ;checks if right of the platform
	 X mov eax, x2 \ add eax, w2 \ cmp x1, eax \ jg noCollision 
 
	 ;checks if left of the platform
	 X sub eax, w2 \ sub eax, w1 \ cmp x1, eax \ jl noCollision 
 
	 ;checks if below the platform
	 X mov eax, y2 \ add eax, h2 \ cmp y1, eax \ jg noCollision 
 
	 ;checks if above the platform
	 X sub eax, h2 \ sub eax, h1 \ cmp y1, eax \ jl noCollision 

	 ;if comes to here there is collision
	 mov eax, 1
	 jmp Exit

	 noCollision:
	 mov eax, 0
	 Exit:
	 ret
DidCollide ENDP

; checking if doodle colides with a given platform

Collide PROC plat:DWORD
	pusha
	mov edi,  dword ptr plat

	mov eax, doodle.y					; Platform's X value
	add eax, doodle_right.iheight
	sub eax, 20

	mov ebx, [edi + 8]				; platform's image pointer.

	mov ecx, doodle_right.iwidth
	mov edx, doodle.x

	.if doodle.side == 1			; fine tuning the collision
		sub ecx, 60
	.elseif doodle.side == 0
		sub ecx, 120
		add edx, 60
	.endif

	invoke DidCollide, edx, eax, ecx, 2,0 [edi], [edi + 4], [ebx  + 4], [ebx  + 8]

	.if eax == 1
		invoke Jump, [edi + 12]
	.endif
	popa
	ret
Collide ENDP


; Collide wrapper

CheckCollision PROC
	pusha

	mov counter,0
	mov edi, offset platforms

	.while counter < 4

	mov eax, sizeof exPlatform
	mov ecx, counter
	mul ecx

	invoke QuickBreak

	invoke Collide, addr platforms[eax]

	inc counter
	.endw

	popa
	ret
CheckCollision ENDP





MoveY PROC	
	;This is in charge of the doodle's movement on axis Y

	pusha

	; cheats
	.if cheats.no_gravity == 1
		invoke Jump, 2
		mov  eax, doodle.diry
		add doodle.jump_val, eax
	.endif

	.if doodle.y <= 200			;doodle reached the top

		invoke PushBackground, doodle.diry
	.elseif doodle.y > WIN_HEIGHT	
			invoke ShowResult, total_jump_score
	.endif

	
	.if doodle.jump_val <= 0

		X	mov eax, doodle.diry	\	add doodle.y, eax	\	mov doodle.jump_val,0
		
	.elseif doodle.jump_val > 3000
		;something cant be right
		X	mov doodle.jump_val, 0

	.else

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
		invoke CheckCollision

	.endif

	popa
	ret

MovementManger ENDP





;		***************************************************************

;							GAMEPLAY FUNCTIONS

;		***************************************************************

Draw PROC
	pusha
	invoke drd_pixelsClear, 0
	invoke drd_imageDrawCrop, offset background, 0, 0, 0, background_src_y, WIN_WIDTH, WIN_HEIGHT

	invoke DrawPlatforms

	.if doodle.side == 1
		invoke drd_imageDraw, offset doodle_right, doodle.x, doodle.y
	.elseif doodle.side == 0
		invoke drd_imageDraw, offset doodle_left, doodle.x, doodle.y
	.endif

	popa
	ret
Draw ENDP

; The main doodle jump game proc
MainGame PROC
	pusha

	invoke MovementManger
	invoke Draw
	invoke HandlePlatforms

	popa
	ret
MainGame ENDP

WelcomeScreen PROC
	pusha

	invoke drd_imageDraw, offset background,0,0
	invoke drd_imageDraw, offset welcome, 0, 0

	invoke GetAsyncKeyState, VK_RETURN
	

	popa
	ret
WelcomeScreen ENDP

init PROC	
	pusha
	; load files, 
	
	invoke drd_imageLoadFile, offset filename_start_option, offset start_option
	invoke drd_imageLoadFile, offset filename_how_to_play_option, offset help_option
	invoke drd_imageLoadFile, offset filename_welcome, offset welcome
	invoke drd_imageLoadFile, offset filename_doodle_left , offset doodle_left
	invoke drd_imageLoadFile, offset filename_doodle_right , offset doodle_right
	invoke drd_imageLoadFile, offset filename_background , offset background
	invoke drd_imageLoadFile, offset filename_platform , offset platform
	invoke drd_imageLoadFile, offset filename_platform_red , offset platform_red

	; init all the none constant variables that wont change during the run. 
	X	mov eax, WIN_WIDTH \ sub eax, doodle_left.iwidth  \ mov doodle.limit_x, eax
	X	mov eax, WIN_HEIGHT \ sub eax, doodle_left.iheight  \	sub eax, 150	\	mov doodle.limit_y, eax
	X	mov eax, background.iheight	\	sub eax, WIN_HEIGHT	\	mov background_src_y, eax
	

	X	mov eax, start_option	\	mov start_game.image, eax
	X	mov eax, help_option	\	mov how_to_play.image, eax

	; Clearing the green screen off the images
	invoke drd_imageSetTransparent, offset doodle_left, GREEN
	invoke drd_imageSetTransparent, offset doodle_right, GREEN
	invoke drd_imageSetTransparent, offset platform, GREEN
	invoke drd_imageSetTransparent, offset platform_red, GREEN
	invoke drd_imageSetTransparent, offset welcome, GREEN

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

	invoke drd_init, WIN_WIDTH, WIN_HEIGHT, INIT_WINDOWFULL
	invoke init


	welcomeLoop:

		invoke WelcomeScreen
		invoke drd_processMessages
		invoke drd_flip
		invoke CheckQuit

		jmp welcomeLoop

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