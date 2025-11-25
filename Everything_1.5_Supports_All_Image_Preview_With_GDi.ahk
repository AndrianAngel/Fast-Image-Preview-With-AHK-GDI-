#NoEnv
#Persistent
; #NoTrayIcon
#Include Gdip_All.ahk
CoordMode, Mouse, Screen

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
    
    ; Everything 1.5 Support - IMPROVED
    if (WinClass = "EVERYTHING_TASKDLG" || WinClass = "EVERYTHING") {
        return GetEverythingPath(hwnd, CtrlClass)
    }
    
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

GetEverythingPath(hwnd, CtrlClass) {
    ; Only proceed if we're over the ListView
    if (CtrlClass != "SysListView321")
        return ""
    
    ; Get the ListView handle directly
    ControlGet, listHwnd, Hwnd,, SysListView321, ahk_id %hwnd%
    if (!listHwnd)
        return ""
    
    ; Get the focused/selected item index
    SendMessage, 0x100C, -1, 0x0002, , ahk_id %listHwnd% ; LVM_GETNEXTITEM with LVNI_FOCUSED
    focusedRow := ErrorLevel
    
    if (focusedRow < 0 || focusedRow = "") {
        ; Try getting selected item if no focused item
        SendMessage, 0x100C, -1, 0x0001, , ahk_id %listHwnd% ; LVM_GETNEXTITEM with LVNI_SELECTED
        focusedRow := ErrorLevel
    }
    
    if (focusedRow < 0 || focusedRow = "")
        return ""
    
    ; Method 1: Try to get the full path by combining Name (column 0) and Path (column 1)
    fileName := GetListViewItemText(listHwnd, focusedRow, 0)  ; Name column
    folderPath := GetListViewItemText(listHwnd, focusedRow, 1) ; Path column
    
    if (fileName != "" && folderPath != "") {
        fullPath := folderPath "\" fileName
        if (FileExist(fullPath))
            return fullPath
    }
    
    ; Method 2: Try to get from column 0 directly (sometimes it contains full path)
    fullPath := GetListViewItemText(listHwnd, focusedRow, 0)
    if (FileExist(fullPath))
        return fullPath
    
    ; Method 3: Use Everything's Copy Full Path command
    clipboardBackup := ClipboardAll
    Clipboard := ""
    
    ; Ensure the item is selected
    ControlFocus, SysListView321, ahk_id %hwnd%
    Sleep, 50
    
    ; Send Ctrl+Shift+C (Everything's copy full path shortcut)
    ControlSend, SysListView321, ^+c, ahk_id %hwnd%
    ClipWait, 1
    
    if (!ErrorLevel && Clipboard != "") {
        fullPath := Clipboard
        Clipboard := clipboardBackup
        if (FileExist(fullPath))
            return fullPath
    }
    
    Clipboard := clipboardBackup
    return ""
}

GetListViewItemText(hwnd, row, col) {
    ; Allocate memory for LVITEM structure and text buffer
    VarSetCapacity(text, 2048, 0)
    VarSetCapacity(LVITEM, 60, 0)
    
    ; Set up LVITEM structure
    NumPut(1, LVITEM, 0, "UInt")                           ; mask = LVIF_TEXT
    NumPut(row, LVITEM, 4, "Int")                          ; iItem
    NumPut(col, LVITEM, 8, "Int")                          ; iSubItem
    NumPut(&text, LVITEM, 20 + (A_PtrSize - 4), "Ptr")    ; pszText
    NumPut(1024, LVITEM, 20 + A_PtrSize + (A_PtrSize - 4), "Int") ; cchTextMax
    
    ; Send LVM_GETITEMTEXTW message
    SendMessage, 0x1073, %row%, &LVITEM, , ahk_id %hwnd%  ; LVM_GETITEMTEXTW = 0x1073
    
    ; Get the text
    result := StrGet(&text, "UTF-16")
    return result
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
        
        ; Get mouse position
        MouseGetPos, mouseX, mouseY
        
        ; Get monitor dimensions for the current mouse position
        SysGet, monCount, MonitorCount
        Loop, %monCount%
        {
            SysGet, mon, Monitor, %A_Index%
            if (mouseX >= monLeft && mouseX <= monRight && mouseY >= monTop && mouseY <= monBottom)
            {
                monitorLeft := monLeft
                monitorTop := monTop
                monitorRight := monRight
                monitorBottom := monBottom
                monitorWidth := monRight - monLeft
                monitorHeight := monBottom - monTop
                break
            }
        }
        
        ; Fallback to primary monitor if not found
        if (!monitorWidth)
        {
            SysGet, mon, MonitorWorkArea
            monitorLeft := monLeft
            monitorTop := monTop
            monitorRight := monRight
            monitorBottom := monBottom
            monitorWidth := monRight - monLeft
            monitorHeight := monBottom - monTop
        }
        
        Gui, destroy
        
        ; Calculate scaled dimensions (max 80% of monitor or 800px, whichever is smaller)
        maxSize := Min(800, Floor(monitorWidth * 0.8), Floor(monitorHeight * 0.8))
        
        if (iW > iH)
        {
            scale := maxSize / iW
            newW := Floor(Min(iW, maxSize))
            newH := Floor(iH * scale)
        }
        else
        {
            scale := maxSize / iH
            newH := Floor(Min(iH, maxSize))
            newW := Floor(iW * scale)
        }
        
        ; Padding from screen edges and mouse cursor
        padding := 20
        mouseGap := 100  ; Minimum gap from mouse cursor
        
        ; Try placing to the right of mouse first
        x2 := mouseX + mouseGap
        y1 := mouseY
        
        ; Check if it fits on the right side
        if (x2 + newW > monitorRight - padding)
        {
            ; Try placing to the left of mouse
            x2 := mouseX - newW - mouseGap
        }
        
        ; If still doesn't fit on left, clamp to screen edges
        if (x2 < monitorLeft + padding)
        {
            ; Not enough space on either side, place to right and clamp
            x2 := mouseX + mouseGap
            if (x2 + newW > monitorRight - padding)
                x2 := monitorRight - newW - padding
        }
        
        ; Ensure not off left edge after all adjustments
        if (x2 < monitorLeft + padding)
            x2 := monitorLeft + padding
        
        ; Now handle vertical positioning to avoid mouse overlap
        ; First, try aligning with mouse Y position
        y1 := mouseY
        
        ; Check if mouse would overlap horizontally with the preview
        mouseOverlapsX := (mouseX >= x2 - mouseGap) && (mouseX <= x2 + newW + mouseGap)
        
        if (mouseOverlapsX)
        {
            ; Mouse could overlap, adjust vertical position
            ; Try placing below mouse first
            y1 := mouseY + mouseGap
            
            ; If doesn't fit below, try above
            if (y1 + newH > monitorBottom - padding)
            {
                y1 := mouseY - newH - mouseGap
            }
            
            ; If still doesn't fit above, clamp to bottom
            if (y1 < monitorTop + padding)
            {
                y1 := monitorBottom - newH - padding
            }
        }
        
        ; Final boundary checks
        if (y1 + newH > monitorBottom - padding)
        {
            y1 := monitorBottom - newH - padding
        }
        
        if (y1 < monitorTop + padding)
            y1 := monitorTop + padding
        
        ; Final safety check - ensure dimensions fit on screen
        if (newW > monitorWidth - (padding * 2))
            newW := monitorWidth - (padding * 2)
        if (newH > monitorHeight - (padding * 2))
            newH := monitorHeight - (padding * 2)
        
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