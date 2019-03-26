﻿CoordMode, Caret, Screen
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, Menu, Screen

if( instr(A_LineFile, A_ScriptName ))
	exitapp

; SetTimer,% Func("WinMoveThis"),1000
SetTimer(Func("WinMoveThis"),400)
; SetTimer(Func("WinMoveThis"),800)

WinMoveThis(){
	RegRead, x, HKEY_CURRENT_USER, SOFTWARE\sl5net\gi\%A_ScriptName%, x
	RegRead, y, HKEY_CURRENT_USER, SOFTWARE\sl5net\gi\%A_ScriptName%, y

	RegRead, h, HKEY_CURRENT_USER, SOFTWARE\sl5net\gi\%A_ScriptName%, h
	RegRead, w, HKEY_CURRENT_USER, SOFTWARE\sl5net\gi\%A_ScriptName%, w
	h := ((h) ? h : 50) ; 300*(A_ScreenDPI/96)
	w := ((w) ? w : 500*(A_ScreenDPI/96) )

	x := ((x) ? x : " x" 200)
	y := ((y) ? y : " y" 300)
	DetectHiddenWindows,Off
	SetTitleMatchMode,1
	ifwinexist,Variables ahk_class AutoHotkeyGUI
	{
	WinMove,,,% x, % y,% w, % h
	global g_config
	; msgbox, % g_config.alwaysontop " = g_config.alwaysontop"
	WinActivate
	WinWaitActive,,,4
	if(g_config.alwaysontop){
	    Winset, Alwaysontop, ,Variables ahk_class AutoHotkeyGUI
		; msgbox,Alwaysontop
    }
	;/¯¯¯¯ unfold ¯¯ 190224205428 ¯¯ 24.02.2019 20:54:28 ¯¯\
	; autohotkey unfold SysListView 321
	IfWinActive
	{
		suspend,on
		; send,{down} ; open the list
		; sleep,500
		; SetKeyDelay,290,125 ;
		; send,{right} ; open the list
		; send,{right} ; open the list
		; MouseClick , WhichButton, X, Y, ClickCount, Speed, DownOrUp, Relative
        MouseGetPos,mX,mY
		MouseClick, left, % x + 18, % y + 67,,1
		; here the script is waiting some seconds. moves to next line if all vars are readed
        MouseMove, % mX,% mY,0
		suspend,off
	}
    ;\____ unfold __ 190224205435 __ 24.02.2019 20:54:35 __/
	tooltip, % "Variables ahk_class AutoHotkeyGUI,," x "," y ", " w "," h
	SetTimer(Func("WinMoveThis"),"Off")
	run,% A_ScriptDir "\" g_config.logFileAddress
	if(g_config.closeGui_soonAsPossible)
	    exitapp
	}

}

SetTimer(timer,period){
	if(!IsFunc(timer)&&!IsLabel(timer))
		return
	if(period == "Off")
		SetTimer,%timer%,Off
	else
		SetTimer,%timer%,%period%
}


/*
    VarTreeGui
    
    Public interface:
        vtg := new VarTreeGui(RootNode)
        vtg.TLV
        vtg.Show()
        vtg.Hide()
        vtg.OnContextMenu := Func(vtg, node, isRightClick, x, y)
        vtg.OnDoubleClick := Func(vtg, node)
*/
class VarTreeGui extends TreeListView._Base
{
    static Instances := {} ; Hwnd:Object map of *visible* instances
    
    __New(RootNode) {
        restore_gui_on_return := new TreeListView.GuiScope()
        Gui New, hwndhGui LabelVarTreeGui +Resize
        this.hGui := hGui
        Gui Margin, 0, 0
        Gui -DPIScale
        this.TLV := new this.Control(RootNode
            , "w" 500*(A_ScreenDPI/96) " h" 300*(A_ScreenDPI/96) " LV0x10000 -LV0x10 -Multi", "Name|Value") ; LV0x10 = LVS_EX_HEADERDRAGDROP
    }
    
    class Control extends TreeListView
    {
        static COL_NAME := 1, COL_VALUE := 2
        
        MinEditColumn := 2
        MaxEditColumn := 2
        
        AutoSizeValueColumn() {
            LV_ModifyCol(this.COL_VALUE, "AutoHdr")
        }
        
        AfterPopulate() {
            LV_ModifyCol(this.COL_NAME, 150*(A_ScreenDPI/96))
            this.AutoSizeValueColumn()
            if !LV_GetNext(,"F")
                LV_Modify(1, "Focus")
        }
        
        ExpandContract(r) {
            base.ExpandContract(r)
            this.AutoSizeValueColumn()  ; Adjust for +/-scrollbars
        }
        
        BeforeHeaderResize(column) {
            if (column != this.COL_NAME)
                return true
            ; Collapse to fit just the value so that scrollbars will be
            ; visible only when needed.
            LV_ModifyCol(this.COL_VALUE, "Auto")
        }
        
        AfterHeaderResize(column) {
            this.AutoSizeValueColumn()
        }
        
        SetNodeValue(node, column, value) {
            if (column != this.COL_VALUE)
                return
            if (node.SetValue(value) = 0)
                return
            if !(r := this.RowFromNode(node))
                return
            LV_Modify(r, "Col" column, value)
            if (!node.expandable && node.children) {
                ; Since value is a string, node can't be expanded
                LV_Modify(r, "Icon1")
                this.RemoveChildren(r+1, node)
                node.children := ""
                node.expanded := false
            }
        }
        
        OnDoubleClick(node) {
            if (vtg := VarTreeGui.Instances[this.hGui]) && vtg.OnDoubleClick
                vtg.OnDoubleClick(node)
        }
    }
    
    Show(options:="", title:="") {
        this.RegisterHwnd()
        Gui % this.hGui ":Show", % options, % title
    }
    
    Hide() {
        Gui % this.hGui ":Hide"
        this.UnregisterHwnd()
    }
    
    RegisterHwnd() {
        VarTreeGui.Instances[this.hGui] := this
    }
    
    UnregisterHwnd() {
        VarTreeGui.Instances.Delete(this.hGui)
    }
    
    __Delete() {
        Gui % this.hGui ":Destroy"
    }
    
    ContextMenu(ctrlHwnd, eventInfo, isRightClick, x, y) {
        if (ctrlHwnd != this.TLV.hLV || !this.OnContextMenu)
            return
        node := eventInfo ? this.TLV.NodeFromRow(eventInfo) : ""
        this.OnContextMenu(node, isRightClick, x, y)
    }
}

VarTreeGuiClose(hwnd) {
    VarTreeGui.Instances[hwnd].UnregisterHwnd()
}

VarTreeGuiEscape(hwnd) {
    VarTreeGui.Instances[hwnd].Hide()
}

VarTreeGuiSize(hwnd, e, w, h) {
    GuiControl Move, SysListView321, w%w% h%h%
    VarTreeGui.Instances[hwnd].TLV.AutoSizeValueColumn()
}

VarTreeGuiContextMenu(hwnd, prms*) {
    VarTreeGui.Instances[hwnd].ContextMenu(prms*)
}

#Include *i TreeListView.ahk
#Include *i tools\DebugVars\TreeListView.ahk
