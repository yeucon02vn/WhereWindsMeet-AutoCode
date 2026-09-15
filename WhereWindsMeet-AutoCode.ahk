#Requires AutoHotkey v2.0
#SingleInstance Force

SetTitleMatchMode 2
SendMode "Event"
SetMouseDelay 20
SetKeyDelay 30, 30

if A_IsCompiled {
    TraySetIcon A_ScriptFullPath, , true
} else {
    iconPath := A_ScriptDir "\assets\logo.ico"
    if FileExist(iconPath)
        TraySetIcon iconPath, , true
}

; ============================================================
; SETTINGS
; ============================================================

global GAME_TITLE := "Where Winds Meet"

global DEFAULT_ACTION_DELAY := 350
global DEFAULT_LINE_DELAY := 400

; Hidden Point 1 color detection
global COLOR_TOLERANCE := 30
global COLOR_INITIAL_WAIT := 350
global COLOR_CHECK_TIMEOUT := 1200
global COLOR_CHECK_INTERVAL := 100

; ============================================================
; POINTS
; ============================================================

global P1X := 0
global P1Y := 0
global P1Color := 0
global P1Set := false

global P2X := 0
global P2Y := 0
global P2Set := false

global P3X := 0
global P3Y := 0
global P3Set := false

; ============================================================
; STATE
; ============================================================

global IsRunning := false
global StopRequested := false

global ConfigFile := A_ScriptDir "\WWM_AutoCode.ini"

LoadSettings()

; ============================================================
; MINI GUI
; ============================================================

global MainGui := Gui(, "WWM Auto Code")

MainGui.SetFont("s8 Bold", "Segoe UI")

MainGui.AddText(
    "x10 y8 w300 Center",
    "WHERE WINDS MEET - AUTO CODE"
)

MainGui.SetFont("s8 Norm", "Segoe UI")

; ============================================================
; CODE LIST
; ============================================================

MainGui.AddText(
    "x10 y30 w300",
    "Code List - One code per line:"
)

global CodeBox := MainGui.AddEdit(
    "x10 y48 w300 h125 Multi VScroll"
)

; ============================================================
; POINT 1
; ============================================================

MainGui.AddText(
    "x10 y188 w25",
    "P1:"
)

global P1Text := MainGui.AddText(
    "x38 y188 w145",
    PointText(1)
)

global BtnP1 := MainGui.AddButton(
    "x205 y182 w105 h26",
    "SET (F1)"
)

BtnP1.OnEvent(
    "Click",
    (*) => SetPointFromButton(1)
)

; ============================================================
; POINT 2
; ============================================================

MainGui.AddText(
    "x10 y220 w25",
    "P2:"
)

global P2Text := MainGui.AddText(
    "x38 y220 w145",
    PointText(2)
)

global BtnP2 := MainGui.AddButton(
    "x205 y214 w105 h26",
    "SET (F2)"
)

BtnP2.OnEvent(
    "Click",
    (*) => SetPointFromButton(2)
)

; ============================================================
; POINT 3
; ============================================================

MainGui.AddText(
    "x10 y252 w25",
    "P3:"
)

global P3Text := MainGui.AddText(
    "x38 y252 w145",
    PointText(3)
)

global BtnP3 := MainGui.AddButton(
    "x205 y246 w105 h26",
    "SET (F3)"
)

BtnP3.OnEvent(
    "Click",
    (*) => SetPointFromButton(3)
)

; ============================================================
; DELAYS
; ============================================================

MainGui.AddText(
    "x10 y288 w45",
    "Action:"
)

global DelayEdit := MainGui.AddEdit(
    "x55 y284 w45",
    DEFAULT_ACTION_DELAY
)

MainGui.AddText(
    "x103 y288 w18",
    "ms"
)

MainGui.AddText(
    "x160 y288 w35",
    "Line:"
)

global CodeDelayEdit := MainGui.AddEdit(
    "x195 y284 w45",
    DEFAULT_LINE_DELAY
)

MainGui.AddText(
    "x243 y288 w18",
    "ms"
)

; ============================================================
; START / STOP
; ============================================================

global BtnStart := MainGui.AddButton(
    "x10 y316 w145 h30",
    "START (F5)"
)

global BtnStop := MainGui.AddButton(
    "x165 y316 w145 h30",
    "STOP (ESC)"
)

BtnStart.OnEvent(
    "Click",
    (*) => StartAutomation()
)

BtnStop.OnEvent(
    "Click",
    (*) => StopAutomation()
)

; ============================================================
; INSTRUCTIONS
; ============================================================

MainGui.AddText(
    "x10 y358 w300 h25 Center",
    "F1/F2/F3 = Set | F5 = Start | ESC = Stop"
)

MainGui.OnEvent(
    "Close",
    (*) => ExitApp()
)

MainGui.Show("w320 h385")

; ============================================================
; GAME WINDOW
; ============================================================

GetGameHwnd()
{
    global GAME_TITLE
    return WinExist(GAME_TITLE)
}

; ============================================================
; GAME ACTIVE
; ============================================================

IsGameActive()
{
    hwnd := GetGameHwnd()

    if !hwnd
        return false

    return WinActive("ahk_id " hwnd) != 0
}

; ============================================================
; MENU ACTIVE
; ============================================================

IsMenuActive()
{
    global MainGui
    return WinActive("ahk_id " MainGui.Hwnd) != 0
}

; ============================================================
; ACTIVATE GAME
; ============================================================

ActivateGame()
{
    hwnd := GetGameHwnd()

    if !hwnd
    {
        MsgBox(
            "Where Winds Meet was not found.`n`n"
            . "Please open the game first.",
            "WWM Auto Code",
            "Icon!"
        )
        return false
    }

    try
    {
        WinActivate("ahk_id " hwnd)
    }
    catch
    {
        MsgBox(
            "Unable to activate Where Winds Meet.",
            "WWM Auto Code",
            "Icon!"
        )
        return false
    }

    if !WinWaitActive(
        "ahk_id " hwnd,
        ,
        3
    )
    {
        MsgBox(
            "Unable to focus Where Winds Meet.`n`n"
            . "Try running this tool as Administrator.",
            "WWM Auto Code",
            "Icon!"
        )
        return false
    }

    Sleep 300
    return true
}

; ============================================================
; SET POINT FROM BUTTON
; ============================================================

SetPointFromButton(Number)
{
    if !ActivateGame()
        return

    ToolTip(
        "Move mouse to Point "
        . Number
        . "`nand press F"
        . Number
    )

    SetTimer(
        () => ToolTip(),
        -2500
    )
}

; ============================================================
; SET GAME POINT
; ============================================================

SetGamePoint(Number)
{
    global P1X, P1Y, P1Color, P1Set
    global P2X, P2Y, P2Set
    global P3X, P3Y, P3Set

    global P1Text
    global P2Text
    global P3Text

    hwnd := GetGameHwnd()

    if !hwnd
        return

    if !WinActive("ahk_id " hwnd)
        return

    CoordMode "Mouse", "Screen"

    MouseGetPos(
        &ScreenX,
        &ScreenY
    )

    ClientOriginToScreen(
        hwnd,
        &ClientScreenX,
        &ClientScreenY
    )

    X := ScreenX - ClientScreenX
    Y := ScreenY - ClientScreenY

    WinGetClientPos(
        &GameX,
        &GameY,
        &GameW,
        &GameH,
        "ahk_id " hwnd
    )

    if (
        X < 0
        || Y < 0
        || X >= GameW
        || Y >= GameH
    )
    {
        ToolTip(
            "Point must be inside Where Winds Meet."
        )

        SetTimer(
            () => ToolTip(),
            -1500
        )

        return
    }

    switch Number
    {
        ; ====================================================
        ; POINT 1
        ; ====================================================

        case 1:

            P1X := X
            P1Y := Y

            CoordMode "Pixel", "Screen"

            try
            {
                P1Color := PixelGetColor(
                    ScreenX,
                    ScreenY,
                    "RGB"
                )
            }
            catch
            {
                MsgBox(
                    "Unable to capture Point 1.",
                    "WWM Auto Code"
                )
                return
            }

            P1Set := true

            P1Text.Text :=
                "X:" P1X " Y:" P1Y

        ; ====================================================
        ; POINT 2
        ; ====================================================

        case 2:

            P2X := X
            P2Y := Y
            P2Set := true

            P2Text.Text :=
                "X:" P2X " Y:" P2Y

        ; ====================================================
        ; POINT 3
        ; ====================================================

        case 3:

            P3X := X
            P3Y := Y
            P3Set := true

            P3Text.Text :=
                "X:" P3X " Y:" P3Y
    }

    SaveSettings()

    ToolTip(
        "Point "
        . Number
        . " saved"
    )

    SetTimer(
        () => ToolTip(),
        -1000
    )
}

; ============================================================
; CLIENT ORIGIN -> SCREEN
; ============================================================

ClientOriginToScreen(
    hwnd,
    &x,
    &y
)
{
    pt := Buffer(8, 0)

    NumPut(
        "Int",
        0,
        pt,
        0
    )

    NumPut(
        "Int",
        0,
        pt,
        4
    )

    DllCall(
        "ClientToScreen",
        "Ptr",
        hwnd,
        "Ptr",
        pt
    )

    x := NumGet(
        pt,
        0,
        "Int"
    )

    y := NumGet(
        pt,
        4,
        "Int"
    )
}

; ============================================================
; GAME POINT -> SCREEN
; ============================================================

GamePointToScreen(
    hwnd,
    ClientX,
    ClientY,
    &ScreenX,
    &ScreenY
)
{
    pt := Buffer(8, 0)

    NumPut(
        "Int",
        ClientX,
        pt,
        0
    )

    NumPut(
        "Int",
        ClientY,
        pt,
        4
    )

    DllCall(
        "ClientToScreen",
        "Ptr",
        hwnd,
        "Ptr",
        pt
    )

    ScreenX := NumGet(
        pt,
        0,
        "Int"
    )

    ScreenY := NumGet(
        pt,
        4,
        "Int"
    )
}

; ============================================================
; CLICK GAME POINT
; ============================================================

ClickGamePoint(
    ClientX,
    ClientY
)
{
    global StopRequested

    if StopRequested
        return false

    hwnd := GetGameHwnd()

    if !hwnd
        return false

    if !WinActive("ahk_id " hwnd)
    {
        if !ActivateGame()
            return false
    }

    GamePointToScreen(
        hwnd,
        ClientX,
        ClientY,
        &ScreenX,
        &ScreenY
    )

    CoordMode "Mouse", "Screen"

    MouseMove(
        ScreenX,
        ScreenY,
        0
    )

    Sleep 50

    if StopRequested
        return false

    Click "Left"

    return true
}

; ============================================================
; SAFE SLEEP
; ============================================================

SleepSafe(ms)
{
    global StopRequested

    elapsed := 0

    while elapsed < ms
    {
        if StopRequested
            return false

        amount := Min(
            50,
            ms - elapsed
        )

        Sleep amount
        elapsed += amount
    }

    return true
}

; ============================================================
; CTRL+A + PASTE CODE
; ============================================================

ReplaceInputWithCode(Code)
{
    global StopRequested

    if StopRequested
        return false

    ; Select existing text
    SendEvent "^a"

    if !SleepSafe(100)
        return false

    ; Backup clipboard
    Backup := ClipboardAll()

    A_Clipboard := ""
    A_Clipboard := Code

    if !ClipWait(1)
    {
        A_Clipboard := Backup
        return false
    }

    ; Paste
    SendEvent "^v"

    Sleep 100

    ; Restore clipboard
    A_Clipboard := Backup

    return true
}

; ============================================================
; GET CURRENT POINT 1 COLOR
; ============================================================

GetCurrentP1Color()
{
    global P1X
    global P1Y

    hwnd := GetGameHwnd()

    if !hwnd
        return -1

    GamePointToScreen(
        hwnd,
        P1X,
        P1Y,
        &ScreenX,
        &ScreenY
    )

    CoordMode "Pixel", "Screen"

    try
    {
        return PixelGetColor(
            ScreenX,
            ScreenY,
            "RGB"
        )
    }
    catch
    {
        return -1
    }
}

; ============================================================
; COLOR COMPARISON
; ============================================================

ColorSimilar(
    Color1,
    Color2,
    Tolerance
)
{
    R1 := (Color1 >> 16) & 0xFF
    G1 := (Color1 >> 8) & 0xFF
    B1 := Color1 & 0xFF

    R2 := (Color2 >> 16) & 0xFF
    G2 := (Color2 >> 8) & 0xFF
    B2 := Color2 & 0xFF

    return (
        Abs(R1 - R2) <= Tolerance
        && Abs(G1 - G2) <= Tolerance
        && Abs(B1 - B2) <= Tolerance
    )
}

; ============================================================
; CHECK POINT 1 COLOR
;
; TRUE:
; Point 1 is back to reference color.
; Next code starts from P1.
;
; FALSE:
; Point 1 is different.
; Next code starts directly from P2.
; ============================================================

WaitForP1NormalColor()
{
    global P1Color
    global COLOR_TOLERANCE
    global COLOR_INITIAL_WAIT
    global COLOR_CHECK_TIMEOUT
    global COLOR_CHECK_INTERVAL
    global StopRequested

    if !SleepSafe(
        COLOR_INITIAL_WAIT
    )
        return false

    elapsed := 0

    while elapsed <= COLOR_CHECK_TIMEOUT
    {
        if StopRequested
            return false

        CurrentColor :=
            GetCurrentP1Color()

        if CurrentColor != -1
        {
            if ColorSimilar(
                CurrentColor,
                P1Color,
                COLOR_TOLERANCE
            )
            {
                return true
            }
        }

        if !SleepSafe(
            COLOR_CHECK_INTERVAL
        )
            return false

        elapsed +=
            COLOR_CHECK_INTERVAL
    }

    return false
}

; ============================================================
; START AUTOMATION
; ============================================================

StartAutomation()
{
    global IsRunning
    global StopRequested

    global P1Set
    global P2Set
    global P3Set

    global P1X
    global P1Y

    global P2X
    global P2Y

    global P3X
    global P3Y

    global CodeBox
    global DelayEdit
    global CodeDelayEdit

    global DEFAULT_ACTION_DELAY
    global DEFAULT_LINE_DELAY

    ; Already running
    if IsRunning
        return

    ; ========================================================
    ; CHECK POINTS
    ; ========================================================

    if (
        !P1Set
        || !P2Set
        || !P3Set
    )
    {
        MsgBox(
            "Please set all three points first.",
            "WWM Auto Code"
        )

        return
    }

    ; ========================================================
    ; CODE LIST
    ; ========================================================

    Raw := CodeBox.Value

    if Trim(Raw) = ""
    {
        MsgBox(
            "Please enter at least one code.",
            "WWM Auto Code"
        )

        return
    }

    Codes := []

    Loop Parse, Raw, "`n", "`r"
    {
        Code := Trim(A_LoopField)

        if Code != ""
            Codes.Push(Code)
    }

    if Codes.Length = 0
        return

    ; ========================================================
    ; ACTION DELAY
    ; ========================================================

    try
    {
        Delay :=
            Integer(
                DelayEdit.Value
            )
    }
    catch
    {
        Delay :=
            DEFAULT_ACTION_DELAY
    }

    Delay :=
        Max(
            50,
            Delay
        )

    ; ========================================================
    ; LINE DELAY
    ; ========================================================

    try
    {
        LineDelay :=
            Integer(
                CodeDelayEdit.Value
            )
    }
    catch
    {
        LineDelay :=
            DEFAULT_LINE_DELAY
    }

    LineDelay :=
        Max(
            50,
            LineDelay
        )

    ; ========================================================
    ; FOCUS GAME
    ; ========================================================

    if !ActivateGame()
        return

    ; ========================================================
    ; START STATE
    ; ========================================================

    IsRunning := true
    StopRequested := false

    ; TRUE:
    ; P1 -> P2 -> Paste -> P3
    ;
    ; FALSE:
    ; P2 -> Paste -> P3
    NeedPoint1 := true

    CompletedAllCodes := true

    if !SleepSafe(300)
    {
        IsRunning := false
        return
    }

    ; ========================================================
    ; MAIN LOOP
    ; ========================================================

    for Index, Code in Codes
    {
        if StopRequested
        {
            CompletedAllCodes := false
            break
        }

        ; ====================================================
        ; KEEP GAME ACTIVE
        ; ====================================================

        if !IsGameActive()
        {
            if !ActivateGame()
            {
                CompletedAllCodes := false
                StopRequested := true
                break
            }

            if !SleepSafe(300)
            {
                CompletedAllCodes := false
                break
            }
        }

        ; ====================================================
        ; POINT 1
        ; ====================================================

        if NeedPoint1
        {
            if !ClickGamePoint(
                P1X,
                P1Y
            )
            {
                CompletedAllCodes := false
                break
            }

            if !SleepSafe(
                Delay
            )
            {
                CompletedAllCodes := false
                break
            }
        }

        ; ====================================================
        ; POINT 2
        ; ====================================================

        if !ClickGamePoint(
            P2X,
            P2Y
        )
        {
            CompletedAllCodes := false
            break
        }

        if !SleepSafe(
            Delay
        )
        {
            CompletedAllCodes := false
            break
        }

        ; ====================================================
        ; CTRL+A + PASTE
        ; ====================================================

        if !ReplaceInputWithCode(
            Code
        )
        {
            CompletedAllCodes := false
            break
        }

        if !SleepSafe(
            Delay
        )
        {
            CompletedAllCodes := false
            break
        }

        ; ====================================================
        ; POINT 3 - SUBMIT
        ; ====================================================

        if !ClickGamePoint(
            P3X,
            P3Y
        )
        {
            CompletedAllCodes := false
            break
        }

        ; ====================================================
        ; CHECK POINT 1
        ; ====================================================

        IsNormal :=
            WaitForP1NormalColor()

        if StopRequested
        {
            CompletedAllCodes := false
            break
        }

        ; ====================================================
        ; SAME COLOR
        ;
        ; Next code:
        ; P1 -> P2 -> Paste -> P3
        ; ====================================================

        if IsNormal
        {
            NeedPoint1 := true
        }

        ; ====================================================
        ; DIFFERENT COLOR
        ;
        ; Do NOT press ESC.
        ;
        ; Next code:
        ; P2 -> Ctrl+A -> Paste -> P3
        ; ====================================================

        else
        {
            NeedPoint1 := false
        }

        ; ====================================================
        ; LINE DELAY
        ; ====================================================

        if !SleepSafe(
            LineDelay
        )
        {
            CompletedAllCodes := false
            break
        }
    }

    ; ========================================================
    ; FINISHED
    ; ========================================================

    IsRunning := false

    ; ========================================================
    ; STOPPED BY ESC
    ; ========================================================

    if StopRequested
    {
        StopRequested := false

        ToolTip(
            "Automation stopped."
        )

        SetTimer(
            () => ToolTip(),
            -1500
        )

        return
    }

    ; ========================================================
    ; ALL CODES COMPLETED
    ; ========================================================

    if CompletedAllCodes
    {
        ToolTip(
            "All codes completed!"
        )

        SetTimer(
            () => ToolTip(),
            -2500
        )

        return
    }

    ToolTip(
        "Automation stopped."
    )

    SetTimer(
        () => ToolTip(),
        -1500
    )
}

; ============================================================
; STOP
; ============================================================

StopAutomation()
{
    global IsRunning
    global StopRequested

    if !IsRunning
        return

    StopRequested := true
}

; ============================================================
; SAVE SETTINGS
; ============================================================

SaveSettings()
{
    global ConfigFile

    global P1X
    global P1Y
    global P1Color
    global P1Set

    global P2X
    global P2Y
    global P2Set

    global P3X
    global P3Y
    global P3Set

    try
    {
        ; P1
        IniWrite(
            P1X,
            ConfigFile,
            "POINTS",
            "P1X"
        )

        IniWrite(
            P1Y,
            ConfigFile,
            "POINTS",
            "P1Y"
        )

        IniWrite(
            P1Color,
            ConfigFile,
            "POINTS",
            "P1COLOR"
        )

        IniWrite(
            P1Set ? 1 : 0,
            ConfigFile,
            "POINTS",
            "P1SET"
        )

        ; P2
        IniWrite(
            P2X,
            ConfigFile,
            "POINTS",
            "P2X"
        )

        IniWrite(
            P2Y,
            ConfigFile,
            "POINTS",
            "P2Y"
        )

        IniWrite(
            P2Set ? 1 : 0,
            ConfigFile,
            "POINTS",
            "P2SET"
        )

        ; P3
        IniWrite(
            P3X,
            ConfigFile,
            "POINTS",
            "P3X"
        )

        IniWrite(
            P3Y,
            ConfigFile,
            "POINTS",
            "P3Y"
        )

        IniWrite(
            P3Set ? 1 : 0,
            ConfigFile,
            "POINTS",
            "P3SET"
        )
    }
}

; ============================================================
; LOAD SETTINGS
; ============================================================

LoadSettings()
{
    global ConfigFile

    global P1X
    global P1Y
    global P1Color
    global P1Set

    global P2X
    global P2Y
    global P2Set

    global P3X
    global P3Y
    global P3Set

    if !FileExist(
        ConfigFile
    )
        return

    try
    {
        ; P1
        P1X :=
            Integer(
                IniRead(
                    ConfigFile,
                    "POINTS",
                    "P1X",
                    "0"
                )
            )

        P1Y :=
            Integer(
                IniRead(
                    ConfigFile,
                    "POINTS",
                    "P1Y",
                    "0"
                )
            )

        P1Color :=
            Integer(
                IniRead(
                    ConfigFile,
                    "POINTS",
                    "P1COLOR",
                    "0"
                )
            )

        P1Set :=
            IniRead(
                ConfigFile,
                "POINTS",
                "P1SET",
                "0"
            ) = "1"

        ; P2
        P2X :=
            Integer(
                IniRead(
                    ConfigFile,
                    "POINTS",
                    "P2X",
                    "0"
                )
            )

        P2Y :=
            Integer(
                IniRead(
                    ConfigFile,
                    "POINTS",
                    "P2Y",
                    "0"
                )
            )

        P2Set :=
            IniRead(
                ConfigFile,
                "POINTS",
                "P2SET",
                "0"
            ) = "1"

        ; P3
        P3X :=
            Integer(
                IniRead(
                    ConfigFile,
                    "POINTS",
                    "P3X",
                    "0"
                )
            )

        P3Y :=
            Integer(
                IniRead(
                    ConfigFile,
                    "POINTS",
                    "P3Y",
                    "0"
                )
            )

        P3Set :=
            IniRead(
                ConfigFile,
                "POINTS",
                "P3SET",
                "0"
            ) = "1"
    }
}

; ============================================================
; POINT TEXT
; ============================================================

PointText(Number)
{
    global P1X
    global P1Y
    global P1Set

    global P2X
    global P2Y
    global P2Set

    global P3X
    global P3Y
    global P3Set

    switch Number
    {
        case 1:

            if P1Set
                return "X:" P1X " Y:" P1Y

        case 2:

            if P2Set
                return "X:" P2X " Y:" P2Y

        case 3:

            if P3Set
                return "X:" P3X " Y:" P3Y
    }

    return "Not set"
}

; ============================================================
; HOTKEYS
; ============================================================

; ============================================================
; F1 - SET POINT 1
; ============================================================

F1::
{
    if IsGameActive()
    {
        SetGamePoint(1)
        return
    }

    if IsMenuActive()
    {
        if !ActivateGame()
            return

        ToolTip(
            "Move mouse to Point 1`n"
            . "and press F1 again."
        )

        SetTimer(
            () => ToolTip(),
            -2000
        )

        return
    }
}

; ============================================================
; F2 - SET POINT 2
; ============================================================

F2::
{
    if IsGameActive()
    {
        SetGamePoint(2)
        return
    }

    if IsMenuActive()
    {
        if !ActivateGame()
            return

        ToolTip(
            "Move mouse to Point 2`n"
            . "and press F2 again."
        )

        SetTimer(
            () => ToolTip(),
            -2000
        )

        return
    }
}

; ============================================================
; F3 - SET POINT 3
; ============================================================

F3::
{
    if IsGameActive()
    {
        SetGamePoint(3)
        return
    }

    if IsMenuActive()
    {
        if !ActivateGame()
            return

        ToolTip(
            "Move mouse to Point 3`n"
            . "and press F3 again."
        )

        SetTimer(
            () => ToolTip(),
            -2000
        )

        return
    }
}

; ============================================================
; F5 - START
; ============================================================

F5::
{
    if (
        IsGameActive()
        || IsMenuActive()
    )
    {
        StartAutomation()
    }
}

; ============================================================
; ESC - STOP
;
; While automation is running:
; ESC = stop tool
;
; When automation is NOT running:
; ESC remains a normal game key.
; ============================================================

#HotIf IsRunning

Esc::
{
    StopAutomation()
}

#HotIf