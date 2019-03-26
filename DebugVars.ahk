﻿
#Include *i DebugVarsGui.ahk
#Include *i tools\DebugVars\DebugVarsGui.ahk

; g_config := { script: { ignoreRegEx: ".", allowRegEx: ".*" }, var: { ignoreRegEx: ".^", allowRegEx: "(Adress|Address)" } }
; g_config := { script: { ignoreRegEx: ".^", allowRegEx: "\bgi-every" }, var: { ignoreRegEx: ".^", allowRegEx: ".", logFileAddress: "var.log.txt" } , alwaysontop: "true" , closeGui_soonAsPossible: "true"  }
; "(\bprefs_|\bicon|\bhelpinfo_|\bDBA|\bgDBA|\bdft\|A_|Collection|config|clipboard)"
; run,tools\DebugVars\DebugVars.ahk
#Include %A_ScriptDir% ; Setzt das Arbeitsverzeichnis für folgende Includes
; SetWorkingDir %A_ScriptDir% ; see: https://www.autohotkey.com/boards/viewtopic.php?f=76&t=62795&p=267949#p267949
; if(!FileExist("ignVarNames.conf.inc.ahk"))
;    msgbox,% "ups !FileExist(ignVarNames.conf.inc.ahk)`n(" A_ThisFunc " " RegExReplace(A_LineFile,".*\\") ":"  A_LineNumber ")"
#include, ignVarNames.conf.inc.ahk
; G:\fre\git\github\global-IntelliSense-everywhere-Nightly-Build\Source\tools\DebugVars\DebugVars.ahk
; G:\fre\git\github\global-IntelliSense-everywhere-Nightly-Build\Source\tools\DebugVars\ignVarNames.conf.inc.ahk
ignVarNames := RegExReplace( trim(ignVarNames) , "m)[\n\r\t]+", "|" )
global g_config
g_config := { script: { ignoreRegEx: ".^", allowRegEx: "\bgi-every" }, var: { ignoreRegEx: "(" ((ignVarNames) ? ignVarNames : ".^" ) ")" , allowRegEx: "." }, logFileAddress: "var.log.txt" , alwaysontop: 1 , closeGui_soonAsPossible: 1  }
alw := g_config["var"]["allowRegEx"]
ign  := g_config["var"]["ignoreRegEx"]
; tooltip,% alw ign "(" A_LineNumber " " RegExReplace(A_LineFile, ".*\\", "") ")"

FileDelete, % A_ScriptDir "\" g_config.logFileAddress
FileDelete, % A_ScriptDir "\" "varnames-" g_config.logFileAddress
fileappend, % "alw##ign:" alw "##" ((strlen(ign)>100) ? substr(ign,1,90) "..." : ign ) "(" A_LineNumber " " RegExReplace(A_LineFile, ".*\\", "") ")", % A_ScriptDir "\" g_config.logFileAddress, UTF-8
fileappend, % "ignVarNames = `n(`n", % A_ScriptDir "\" "varnames-" g_config.logFileAddress, UTF-8

#SingleInstance,Off
DetectHiddenWindows Off
If(WinExist( "Variables ahk_class AutoHotkeyGUI"  )){
	WinActivate,
	ExitApp
}
; #NoTrayIcon



global ShortValueLimit := 64
global MaxChildren := 1000

global PendingThreads := {}
global DbgSessions := {}

DBGp_OnBegin("DebugBegin")
DBGp_OnBreak("DebugBreak")
DBGp_OnEnd("DebugEnd")

DBGp_StartListening()

GroupAdd all, % "ahk_class AutoHotkeyGUI ahk_pid " DllCall("GetCurrentProcessId", "uint")
OnExit("CloseAll")
CloseAll(exitReason:="") {

	WinGetPos,x,y,w,h,Variables ahk_class AutoHotkeyGUI
	if(x && y && w && h){
        RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\sl5net\gi\%A_ScriptName%,w, % w
        RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\sl5net\gi\%A_ScriptName%,h, % h
        RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\sl5net\gi\%A_ScriptName%,x, % x
        RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\sl5net\gi\%A_ScriptName%,y, % y
	}

    DetectHiddenWindows Off

    if exitReason && WinExist("ahk_group all") {
        ; Start a new thread which can be interrupted (OnExit can't).
        SetTimer CloseAll, -10
        return true
    }
    GroupClose all
    ExitApp
}











OnMessage(2, Func("OnWmDestroy"))
OnWmDestroy(wParam, lParam, msg, hwnd) {
    if !DebugVarsGui.Instances.MaxIndex() {
        DetachAll()
        ExitApp
    }
}

(new DebugVarsGui(new DvAllScriptsNode)).Show()

class DvAllScriptsNode extends DvNodeBase
{
    GetChildren() {
        children := []
        for i, script_id in this.GetScripts()
            children.Push(new DvScriptNode(script_id))
        return children
    }
    
    GetScripts() {
        DetectHiddenWindows On
        script_ids := []
        WinGet scripts, List, ahk_class AutoHotkey
        loop % scripts {
            script_id := scripts%A_Index%
            if (script_id = A_ScriptHwnd)
                continue
            PostMessage 0x44, 0, 0,, ahk_id %script_id%  ; WM_COMMNOTIFY, WM_NULL
            if ErrorLevel  ; Likely blocked by UIPI (won't be able to attach).
                continue



			WinGetTitle, WinTitleScriptLong , ahk_id %script_id% ; , WinText, ExcludeTitle, ExcludeText
			;MsgBox, % substr("gi-everywhere.ahk", 1, strlen("gi-everywhere.ahk"))

            global g_config

            ;msgbox,% g_config["script"]["ignoreRegEx"]
            if(!RegExMatch(WinTitleScriptLong,g_config["script"]["allowRegEx"]))
                continue
            if(RegExMatch(WinTitleScriptLong,g_config["script"]["ignoreRegEx"]))
                continue


            script_ids.Push(script_id)
        }
        return script_ids
    }
    
    GetWindowTitle() {
        return "Variables"
    }
    
    Update(tlv) {
        nc := 1
        new_scripts := this.GetScripts()
        children := this.children
        while nc <= children.Length() {
            node := children[nc]
            ns := 0
            while ++ns <= new_scripts.Length() {
                if (new_scripts[ns] == node.hwnd) {
                    new_scripts.RemoveAt(ns), ++nc
                    continue 2
                }
            }
            tlv.RemoveChild(this, nc)
        }
        for ns, script_id in new_scripts {
            tlv.InsertChild(this, nc++, new DvScriptNode(script_id))
        }
        base.Update(tlv)
    }
}

class DvScriptNode extends Dv2ContextsNode
{
    __new(hwnd) {
        this.hwnd := hwnd
        WinGetTitle title, ahk_id %hwnd%
        title := RegExReplace(title, " - AutoHotkey v\S*$")
        SplitPath title, name, dir
        this.values := [name, format("0x{:x}", hwnd) "  -  " dir]
    }
    
    GetChildren() {
        static attach_msg := DllCall("RegisterWindowMessage", "str", "AHK_ATTACH_DEBUGGER", "uint")
        thread_id := DllCall("GetWindowThreadProcessId", "ptr", this.hwnd, "ptr", 0, "uint")
        if !this.dbg := DbgSessions[thread_id] {
            PendingThreads[thread_id] := this
            PostMessage % attach_msg,,,, % "ahk_id " this.hwnd
            began := A_TickCount
        }
        Loop {
            if this.dbg
                break
            if (A_TickCount-began > 5000) || ErrorLevel {
                PendingThreads.Delete(thread_id)
                return [{values: ["", "Failed to attach."]}]
            }
            Sleep 15
        }
        return base.GetChildren()
    }
    
    GetWindowTitle() {
        return format("Variables - {} (0x{:x})", this.values[1], this.hwnd)
    }
}

DebugBegin(dbg, initPacket) {
    if !(node := PendingThreads.Delete(dbg.thread += 0))
        return dbg.detach(), dbg.Close()
    dbg.feature_set("-n max_depth -v 0")
    dbg.feature_set("-n max_data -v " ShortValueLimit)
    dbg.feature_set("-n max_children -v " MaxChildren)
    dbg.feature_get("-n language_version", response)
    dbg.version := RegExReplace(DvLoadXml(response).selectSingleNode("response").text, " .*")
    dbg.no_base64_numbers := dbg.version && dbg.version <= "1.1.24.02" ; Workaround.
    dbg.run()
    node.dbg := dbg
    DbgSessions[dbg.thread] := dbg
}

DebugBreak() {
    ; This shouldn't be called, but needs to be present.
}

DebugEnd(dbg) {
    DbgSessions.Delete(dbg.thread)
    close := []
    for hwnd, dv in VarTreeGui.Instances {
        tlv := dv.TLV, root := tlv.root
        if (dbg == root.dbg) {
            close.Push(dv)
            continue
        }
        n := 1, children := root.children
        while n <= children.Length() {
            if (dbg == children[n].dbg)
                tlv.RemoveChild(root, n)
            else
                ++n
        }
    }
    for i, dv in close
        dv.Hide()
}

DetachAll() {
    for thread, session in DbgSessions.Clone()
        session.detach(), session.Close()
}
