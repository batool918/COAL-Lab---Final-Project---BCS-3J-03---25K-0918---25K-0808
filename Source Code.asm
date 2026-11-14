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

; Puzzle Bank
BANK LABEL BYTE
    db "040500103007003080900040057000751900394200000051300800438025019625109008170008060"  
    db "842567193567913482913842657286751934394286571751394826438625719625179348179438265"   
    db "500391604480700139030040205010009420020070900309004500000907306197000802043008090"   
    db "572391684486752139931846275715639428824175963369284517258917346197463852643528791"   
    db "900500408084001057002084000803009004620045380740803960400190000056030819000206003"  
    db "961572438384961257572384196813629574629745381745813962437198625256437819198256743"  
    db "082100004000000391109005007018903060000070000500218009304000000800300270027090500"   
    db "782139654465782391139465827218943765943576182576218439354627918891354276627891543" 
    db "310740005600013700947256800000000050009620000483000000200000473000592006000007000"  
    db "318749265652813794947256831126384957579621348483975612295168473734592186861437529"  
    db "174000050000082041005070009009007010000030590600950407300000280000710905006804000"   
    db "174369852963582741285471639859247316742136598631958427317695284428713965596824173"  
    db "000801000000030028012007004100700040000006050030040001600004000007290510000010003"   
    db "493821765576439128812567934168753249924186357735942681651374892347298516289615473"   
    db "000300000069004000205090481506480100000000000120000008694000000000070000350906000"  
    db "481352769769814235235697481576489123948231576123765948694128357812573694357946812"  
    db "008700290750000806000600000203800040070090000109000000014062000000370000000500029"  
    db "638715294751429836492683157263857941875194362149236578514962783926378415387541629" 

; Text & Names
szClass db "SudokuWnd", 0
szTitle db "Sudoku - x86 Assembly", 0
szFace db "Arial", 0
fileSave db "sudoku.sav", 0
fileScores db "sudoku.scr", 0
sGame db "Game", 0
sNew db "New Game", 0
sSave db "Save Game", 0
sLoad db "Load Game", 0
sExit db "Exit", 0
sDiff db "Difficulty", 0
sEasy db "Easy", 0
sMedium db "Medium", 0
sHard db "Hard", 0
sHelp db "Help", 0
sInstr db "Instructions", 0
sScores db "High Scores", 0
sBack db "Back", 0
sMain db "Main Menu", 0
sTitleMain db "SUDOKU", 0
sTitleLevel db "Choose Difficulty", 0
sPlaying db "Playing", 0
sSolved db "SOLVED!", 0
sOver db "GAME OVER", 0
levelName dd offset sEasy, offset sMedium, offset sHard
stateName dd offset sPlaying, offset sSolved, offset sOver

; Button Labels & Menu Command IDs
menuTexts dd offset sNew, offset sLoad, offset sHelp, offset sExit
menuCmds dd IDM_NEW, IDM_LOAD, IDM_HELP, IDM_EXIT
levelTexts dd offset sEasy, offset sMedium, offset sHard, offset sBack
levelCmds dd IDM_EASY, IDM_MEDIUM, IDM_HARD, IDM_MAIN

; Game Messages & Formatting Strings
fmtStat    db "Time %d:%02d    Moves: %d    Mistakes: %d/3    Hints left: %d", 0
fmtLine2   db "Level: %s    Status: %s", 0
fmtWin     db "Puzzle solved!", 0Dh, 0Ah, "Time: %d:%02d", 0Dh, 0Ah, "Moves: %d", 0
fmtWinBest db "Puzzle solved!", 0Dh, 0Ah, "Time: %d:%02d", 0Dh, 0Ah, "Moves: %d", 0Dh, 0Ah, "New best time!", 0
fmtScores  db "Best times in seconds (0 = no record yet)", 0Dh, 0Ah, 0Dh, 0Ah
           db "Easy: %d", 0Dh, 0Ah, "Medium: %d", 0Dh, 0Ah, "Hard: %d", 0
sInfoTitle db "Sudoku", 0
sOverMsg   db "Game over! You made 3 mistakes.", 0Dh, 0Ah, "The board is now locked. Start a New Game from the menu.", 0
sSavedMsg  db "Game saved to sudoku.sav", 0
sSaveFail  db "Could not save the game.", 0
sNoGame    db "There is no game to save yet. Start or load a game first.", 0
sNoSave    db "No valid saved game was found.", 0
sInstrMsg  db "Fill the grid so every row, column and 3x3 box contains 1-9 once.", 0Dh, 0Ah, 0Dh, 0Ah
           db "Click a cell or use the arrow keys to select it.", 0Dh, 0Ah
           db "1-9 : enter a digit      0 / Backspace / Delete : erase", 0Dh, 0Ah
           db "H : hint (3 per game)    Q : quit", 0Dh, 0Ah, 0Dh, 0Ah
           db "The menu bar (Game, Difficulty, Help) is available at all times.", 0Dh, 0Ah, 0Dh, 0Ah
           db "Black = given clue (locked), Blue = your entry, Red = conflict.", 0Dh, 0Ah
           db "A conflicting entry counts as a mistake. 3 mistakes = game over.", 0

; Rectangles
clientRect RECT <0, 0, CLIENTW, CLIENTH>      
statRect   RECT <0, STATY-6, CLIENTW, CLIENTH> 
wndRect    RECT <0, 0, CLIENTW, CLIENTH>  

; GDI Object Handles
hObjs      LABEL DWORD
hFontBold  dd 0
hFontNorm  dd 0
hFontSmall dd 0
hBrBg      dd 0
hBrSel     dd 0
hPenThin   dd 0
hPenThick  dd 0
hFontTitle dd 0
hBrBtn     dd 0
NOBJS = 9
hBrWhite   dd 0 


