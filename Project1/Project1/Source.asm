.486
.model flat, stdcall
option casemap :none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\msvcrt.inc
includelib msvcrt.lib
include drd.inc
includelib drd.lib

.data
;init
	;isInit DWORD 1
	w_width DWORD 1500
	w_height DWORD 800
    panPng BYTE "platform.bmp", 0
	panImg Img <0,0,0,0>
	screenPng BYTE "background.bmp", 0
	screenImg Img <0,0,0,0>
	EggPng1 BYTE "DoodleLeft.bmp", 0
	eggImg1 Img <0,0,0,0>
	pan_limit_x DWORD w_width
	pan_limit_y DWORD w_height
	egg_limit_x DWORD w_width
	egg_limit_y DWORD w_height

;create struct for eggs and also a dup for them
Egg struct 
	x DWORD ?
	y DWORD 0
Egg ends
eggs Egg 2 dup(<>)

;pan movement
	x DWORD 600
	y DWORD 671
	dirx DWORD 0
	turn DWORD 0

;random
	numerator DWORD 13
	denominator DWORD 10
	ran DWORD 0
	STime SYSTEMTIME  {} 

;adding eggs
	doEgg1 DWORD 1
	doEgg2 DWORD 0
	;isStart DWORD 1

;egg movement
	egg1 Egg <>
	egg2 Egg <>
	;currentEgg DWORD 0
	;eggDirY DWORD 1

.code
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
 
;uses the values in numerator and denominator, puts result in random
Random PROC	
	pusha
	xor eax, eax
	invoke GetSystemTime ,addr STime
	mov ax, STime.wMilliseconds
	X	mov ebx, numerator \ mov ecx, denominator
	mul ebx
	div ecx
	mov ran, eax
	popa

	ret
Random ENDP

moveEggs1 PROC
	pusha 
	;Our first egg is moving
	X cmp egg1.y, 600 \ jle dontReset
	invoke Random
	X mov eax, ran \  mov egg1.x, eax
	X mov egg1.y, 0 \ jmp exit
	dontReset:
		inc egg1.y
	exit:
		popa 
		ret
moveEggs1 ENDP

moveEggs2 PROC
	pusha 
	;Our second egg is moving
	X cmp egg2.y, 500 \ jle dontReset
	invoke Random
	X mov eax, ran \  mov egg2.x, eax
	X mov egg2.y, 1 \ jmp exit
	dontReset:
		inc egg2.y
	exit:
		popa 
		ret
moveEggs2 ENDP

MoveX PROC	
	pusha
	X	mov eax, x \ add eax, dirx \ mov x, eax			
	X   mov eax, pan_limit_x \ cmp x, eax \ jle next
	sub x, 5	
	next:
	X  cmp x, 0 \ jge exit \ add x, 5
	exit: 
		popa
		ret
MoveX ENDP

MovementManger PROC
	pusha
	X	mov eax, turn \ inc eax \ mov turn, eax
	X	cmp turn, 5 \ je doTurn
	jmp exit

	doTurn:
		mov turn, 0
		;X mov eax, doEgg1 \ add eax, doEgg2 \ cmp eax, 0 \ je checkStart 
		;checkStart:
			;X	cmp isStart, 1 \ jne notStart
			;X	mov currentEgg, 0 \ invoke moveEggs1	\ jmp cont
		;notStart:
			;X	mov currentEgg, 0 \ invoke moveEggs2 \ mov currentEgg, 1 
		cont:
			X	invoke GetAsyncKeyState, VK_RIGHT \ cmp eax, 0 \ mov dirx, 5 \ jne lblMoveX
			X	invoke GetAsyncKeyState, VK_LEFT \ cmp eax, 0 \ mov dirx, -5 \ jne lblMoveX
	
	lblMoveX:
		invoke MoveX

	exit:
		popa
		ret
MovementManger ENDP


init PROC	
	pusha
	X	mov eax, w_width \ mov pan_limit_x, eax
	X	mov eax, pan_limit_x \ sub eax, panImg.iwidth \ sub eax, 1 \ mov pan_limit_x, eax

	X	mov eax, w_height \ mov pan_limit_y, eax
	X	mov eax, pan_limit_y \ sub eax, panImg.iheight \ sub eax, 1 \ mov pan_limit_y, eax

	X	mov eax, w_width \ mov egg_limit_x, eax
	X	mov eax, egg_limit_x \ sub eax, eggImg1.iwidth \ sub eax, 1 \ mov egg_limit_x, eax

	popa
	ret
init ENDP

main PROC
	;Xcmp isInit, 1 \ jne again
	invoke drd_init, w_width, w_height, INIT_WINDOW	
	xor eax,eax
	mov egg1.y, 0
	mov egg2.y, 0
	invoke Random
	mov eax, ran
	mov egg1.x,eax
	invoke Random
	mov eax, ran
	mov egg2.x, eax
	invoke drd_imageLoadFile,offset EggPng1, offset eggImg1
	invoke drd_imageLoadFile,offset panPng, offset panImg
	invoke drd_imageLoadFile,offset screenPng, offset screenImg
	invoke init
	;mov isInit, 0
	again:
		invoke drd_imageDraw, offset screenImg, 0, 0
		invoke drd_imageDraw, offset panImg, x, y
		invoke drd_imageDraw, offset eggImg1, egg1.x, egg1.y
		invoke drd_imageDraw, offset eggImg1, egg2.x, egg2.y
		;X cmp isStart, 1 \ je next
		;next:
		invoke MovementManger
		invoke moveEggs1
		invoke moveEggs2
		invoke drd_processMessages
		invoke drd_flip
		jmp again
	ret
main ENDP
end main