/*
TODO
make platform struct
make it jumpable

*/




/*
mouseHandler PROC wmsg:DWORD, wParam:DWORD, lParam:DWORD
; extract the mouse coordinates from the mouse message in lParam
mov eax, lParam
shl eax, 16
shr eax, 16
mov mx, eax
mov eax, lParam
shr eax, 16
mov my, eax
; buttons info in wParam
mov eax, wParam
and eax, MK_LBUTTON
mov pressed, eax
ret
mouseHandler ENDP

invoke drd_setMouseHandler, offset mouseHandler

keyHandler PROC vkey:DWORD
cmp vkey, VK_UP
jne @F
sub my, 5
@@:
cmp vkey, VK_DOWN
jne @F
add my, 5
@@:
cmp vkey, VK_LEFT
jne @F
sub mx, 5
@@:
cmp vkey, VK_RIGHT
jne @F
add mx, 5
@@:
ret
keyHandler ENDP
*/