; Sudoku Game - x86 Assembly (MASM) + Win32 API (GDI) 
; COAL Lab - Final Project - BCS-3J-03 - 25K-0918 - 25K-0808

; Assembler Directives
.386
.model flat, stdcall
option casemap:none

; Windows API Libraries
includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib

; Windows API Function Prototypes
GetModuleHandleA PROTO :DWORD
ExitProcess      PROTO :DWORD
GetTickCount     PROTO
CreateFileA      PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ReadFile         PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
WriteFile        PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
CloseHandle      PROTO :DWORD
LoadCursorA      PROTO :DWORD,:DWORD
RegisterClassExA PROTO :DWORD
CreateWindowExA  PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
AdjustWindowRect PROTO :DWORD,:DWORD,:DWORD
ShowWindow       PROTO :DWORD,:DWORD
UpdateWindow     PROTO :DWORD
DestroyWindow    PROTO :DWORD
SendMessageA     PROTO :DWORD,:DWORD,:DWORD,:DWORD
lstrlenA         PROTO :DWORD
GetMessageA      PROTO :DWORD,:DWORD,:DWORD,:DWORD
TranslateMessage PROTO :DWORD
DispatchMessageA PROTO :DWORD
DefWindowProcA   PROTO :DWORD,:DWORD,:DWORD,:DWORD
PostQuitMessage  PROTO :DWORD
BeginPaint       PROTO :DWORD,:DWORD
EndPaint         PROTO :DWORD,:DWORD
InvalidateRect   PROTO :DWORD,:DWORD,:DWORD
FillRect         PROTO :DWORD,:DWORD,:DWORD
SetTimer         PROTO :DWORD,:DWORD,:DWORD,:DWORD
KillTimer        PROTO :DWORD,:DWORD
MessageBoxA      PROTO :DWORD,:DWORD,:DWORD,:DWORD
CreateMenu       PROTO
CreatePopupMenu  PROTO
AppendMenuA      PROTO :DWORD,:DWORD,:DWORD,:DWORD
wsprintfA        PROTO C :DWORD,:DWORD,:VARARG
GetStockObject   PROTO :DWORD
CreateSolidBrush PROTO :DWORD
CreatePen        PROTO :DWORD,:DWORD,:DWORD
CreateFontA      PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SelectObject     PROTO :DWORD,:DWORD
DeleteObject     PROTO :DWORD
MoveToEx         PROTO :DWORD,:DWORD,:DWORD,:DWORD
LineTo           PROTO :DWORD,:DWORD,:DWORD
SetBkMode        PROTO :DWORD,:DWORD
SetTextColor     PROTO :DWORD,:DWORD
SetTextAlign     PROTO :DWORD,:DWORD
TextOutA         PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD

; Windows API Structures
RECT STRUCT
    left   SDWORD ?
    top    SDWORD ?
    right  SDWORD ?
    bottom SDWORD ?
RECT ENDS

WNDCLASSEX STRUCT
    cbSize        DWORD ?
    style         DWORD ?
    lpfnWndProc   DWORD ?
    cbClsExtra    DWORD ?
    cbWndExtra    DWORD ?
    hInstance     DWORD ?
    hIcon         DWORD ?
    hCursor       DWORD ?
    hbrBackground DWORD ?
    lpszMenuName  DWORD ?
    lpszClassName DWORD ?
    hIconSm       DWORD ?
WNDCLASSEX ENDS

MSG STRUCT
    hwnd    DWORD ?
    message DWORD ?
    wParam  DWORD ?
    lParam  DWORD ?
    time    DWORD ?
    pt_x    DWORD ?
    pt_y    DWORD ?
MSG ENDS

PAINTSTRUCT STRUCT
    hdc         DWORD ?
    fErase      DWORD ?
    rcPaint     RECT <>
    fRestore    DWORD ?
    fIncUpdate  DWORD ?
    rgbReserved BYTE 32 dup(?)
PAINTSTRUCT ENDS

; Windows API Constants
NULL = 0
FALSE = 0
WM_CREATE = 01h
WM_DESTROY = 02h
WM_PAINT = 0Fh
WM_KEYDOWN = 100h
WM_CHAR = 102h
WM_COMMAND = 111h
WM_TIMER = 113h
WM_LBUTTONDOWN = 201h
VK_LEFT = 25h
VK_UP = 26h
VK_RIGHT = 27h
VK_DOWN = 28h
VK_DELETE = 2Eh
WINSTYLE = 00CA0000h        
CW_USEDEFAULT = 80000000h
SW_SHOW = 5
IDC_ARROW = 32512
MF_STRING = 0
MF_POPUP = 10h
MB_OK_INFO = 40h            
MB_OK_ERROR = 10h           
TRANSPARENT = 1
TA_LEFT = 0
TA_CENTER = 6
GENERIC_READ = 80000000h
GENERIC_WRITE = 40000000h
CREATE_ALWAYS = 2
OPEN_EXISTING = 3
INVALID_HANDLE_VALUE = -1

; Game Constants
CELL = 50                   
MARGIN = 10                 
GRIDSZ = CELL * 9           
GRIDEND = MARGIN + GRIDSZ   
CLIENTW = GRIDSZ + 2*MARGIN 
CLIENTH = 520               
STATY = 472                
MAXMIST = 3                 
IDM_NEW = 1                 
IDM_SAVE = 2
IDM_LOAD = 3
IDM_EXIT = 4
IDM_MAIN = 5                
IDM_EASY = 10               
IDM_MEDIUM = 11
IDM_HARD = 12
IDM_HELP = 20
IDM_SCORES = 21
ID_TIMER = 1
SCR_MENU = 0                
SCR_LEVEL = 1
SCR_GAME = 2
BTNX = 115                  
BTNW = 240
BTNY = 150
BTNH = 50
BTNSTEP = 70                

; Macros
CELLRECT MACRO rowreg, colreg, rcname
    imul colreg, CELL
    add  colreg, MARGIN
    mov  rcname.left, colreg
    add  colreg, CELL
    mov  rcname.right, colreg
    imul rowreg, CELL
    add  rowreg, MARGIN
    mov  rcname.top, rowreg
    add  rowreg, CELL
    mov  rcname.bottom, rowreg
ENDM

SETCOLOR MACRO hdcval, clr
    invoke SetTextColor, hdcval, clr
ENDM


.data
; Game State
PUZZLE db 81 dup(0)
SOLUTION db 81 dup(0)
BOARD db 81 dup(0)
gDiff dd 0
gSecs dd 0
gMoves dd 0
gMist dd 0
gHints dd 3
gState dd 0
SAVESIZE = $ - PUZZLE

gSel dd 0
gScreen dd SCR_MENU
scores dd 3 dup(0)
chDigit db 0, 0











