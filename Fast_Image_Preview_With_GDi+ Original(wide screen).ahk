#NoEnv
#Persistent
; #NoTrayIcon
#Include Gdip_All.ahk
CoordMode, Mouse, Screen
SW = 1920
SH = 1080

; Initialize GDI+
If !pToken := Gdip_Startup()
{
    MsgBox, 48, GDI+ error, GDI+ failed to start. Please ensure you have GDI+ on your system
    ExitApp
}

OnExit, Exit

~LCtrl::
settimer, pic, 200
Keywait, LCtrl, u
if errorlevel = 0
{
    Settimer, Pic, off
    if (hBitmap)
    {
        Gdip_DisposeImage(hBitmap)
        hBitmap := 0
    }
    Gui, Destroy
}
return

GetNameOfIconUnderMouse() {
    MouseGetPos, , , hwnd, CtrlClass
    WinGetClass, WinClass, ahk_id %hwnd%
    try if (WinClass = "CabinetWClass" && CtrlClass = "DirectUIHWND3") {
        oAcc := Acc_ObjectFromPoint()
        Name := Acc_Parent(oAcc).accValue(0)
        Name := Name ? Name : oAcc.accValue(0)
    } else if (WinClass = "Progman" || WinClass = "WorkerW") {
        oAcc := Acc_ObjectFromPoint(ChildID)
        Name := ChildID ? oAcc.accName(ChildID) : ""
    }
    Return Name
}

GetFullPathUnderMouse() {
    MouseGetPos, , , hwnd, CtrlClass
    WinGetClass, WinClass, ahk_id %hwnd%
    
    ; Desktop
    if (WinClass = "Progman" || WinClass = "WorkerW") {
        fileName := GetNameOfIconUnderMouse()
        if (fileName != "")
            return A_Desktop "\" fileName
    }
    
    ; Windows Explorer
    else if (WinClass = "CabinetWClass") {
        fileName := GetNameOfIconUnderMouse()
        if (fileName != "") {
            ; Get current folder path from Explorer
            for window in ComObjCreate("Shell.Application").Windows {
                if (window.HWND = hwnd) {
                    folderPath := window.Document.Folder.Self.Path
                    return folderPath "\" fileName
                }
            }
        }
    }
    
    return ""
}

Acc_Init() {
    Static h
    If Not h
        h:=DllCall("LoadLibrary","Str","oleacc","Ptr")
}

Acc_ObjectFromPoint(ByRef _idChild_ = "", x = "", y = "") {
    Acc_Init()
    If DllCall("oleacc\AccessibleObjectFromPoint", "Int64", x==""||y==""?0*DllCall("GetCursorPos","Int64*",pt)+pt:x&0xFFFFFFFF|y<<32, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild,8+2*A_PtrSize,0)*0+&varChild)=0
    Return ComObjEnwrap(9,pacc,1), _idChild_:=NumGet(varChild,8,"UInt")
}

Acc_Parent(Acc) { 
    try parent:=Acc.accParent
    return parent?Acc_Query(parent):
}

Acc_Query(Acc) {
    try return ComObj(9, ComObjQuery(Acc,"{618736e0-3c3d-11cf-810c-00aa00389b71}"), 1)
}

Pic:
FilePath := GetFullPathUnderMouse()

; Only proceed if we have a valid file path
if (FilePath = "" || !FileExist(FilePath))
{
    if (hBitmap)
    {
        Gdip_DisposeImage(hBitmap)
        hBitmap := 0
    }
    gui, destroy
    OLDGIUM =
    return
}

GetKeyState, state, Lbutton

; Check for all common image formats
if InStr(FilePath, ".ico") || InStr(FilePath, ".png") || InStr(FilePath, ".jpg") || InStr(FilePath, ".jpeg") || InStr(FilePath, ".bmp") || InStr(FilePath, ".gif") || InStr(FilePath, ".tif") || InStr(FilePath, ".tiff") || InStr(FilePath, ".webp")
{
    If (FilePath != OLDGIUM) ; If new file DOESN'T match old.
    {
        ; Clean up old bitmap if exists
        if (hBitmap)
        {
            Gdip_DisposeImage(hBitmap)
            hBitmap := 0
        }
        
        ; Load image with GDI+
        hBitmap := Gdip_CreateBitmapFromFile(FilePath)
        if (!hBitmap)
            return
            
        ; Get original image dimensions
        iW := Gdip_GetImageWidth(hBitmap)
        iH := Gdip_GetImageHeight(hBitmap)
        
        MouseGetPos, x1, y1
        X2 := (x1 + 50)
        Gui, destroy
        
        ; Calculate scaled dimensions (max 800px on longest side)
        maxSize := 800
        if (iW > iH)
        {
            scale := maxSize / iW
            newW := maxSize
            newH := Floor(iH * scale)
        }
        else
        {
            scale := maxSize / iH
            newH := maxSize
            newW := Floor(iW * scale)
        }
        
        ; Position calculations
        If (iw > iH) 
        {
            CNih := (Y1 + newH)
            
            If (x1 > 1000)
            {
                x2 := (x1 - 900)
                If (CNih > Sh)
                {
                    oh1 := (CNih - sh)
                    y1 := (y1 - oh1)
                }
            }
            
            If ((x1 - 820) < 0)
            {
                OhL := (820 + x1)
                x2 := !ohl
                
                If (y1 > 540)
                {
                    Oh1b := (sh - (820 + y1))
                    y1 := !oh1b
                }
                Else if (y1 < 600)
                {
                    y1 := (Y1 + 10)
                }
            }
        }
        else
        {
            If (x1 > 900)
            {
                x2 := (x1 - newW - 100)
            }
            
            If ((y1 + 820) > SH)
            {
                oh2 := ((y1 + 820) - sh)
                y1 := (y1 - oh2)
            }
        }
        
        ; Create GUI with proper size
        Gui, +LastFound +AlwaysOnTop +ToolWindow -Caption +E0x80000
        Gui, Show, NA x%x2% y%y1% w%newW% h%newH%
        
        ; Get window handle and create graphics
        hwnd := WinExist()
        hdc := GetDC(hwnd)
        hbm := CreateDIBSection(newW, newH)
        hdc2 := CreateCompatibleDC()
        obm := SelectObject(hdc2, hbm)
        G := Gdip_GraphicsFromHDC(hdc2)
        
        ; Set high quality rendering
        Gdip_SetInterpolationMode(G, 7) ; HighQualityBicubic
        Gdip_SetSmoothingMode(G, 4) ; AntiAlias
        
        ; Draw scaled image
        Gdip_DrawImage(G, hBitmap, 0, 0, newW, newH)
        
        ; Update window
        UpdateLayeredWindow(hwnd, hdc2, x2, y1, newW, newH)
        
        ; Cleanup
        SelectObject(hdc2, obm)
        DeleteObject(hbm)
        DeleteDC(hdc2)
        Gdip_DeleteGraphics(G)
        ReleaseDC(hwnd, hdc)
        
        OLDGIUM = %FilePath%
    }
}
else If (FilePath = "" Or state = "D")
{
    if (hBitmap)
    {
        Gdip_DisposeImage(hBitmap)
        hBitmap := 0
    }
    gui, destroy
    OLDGIUM = 
}
return

Exit:
Gdip_Shutdown(pToken)
ExitApp