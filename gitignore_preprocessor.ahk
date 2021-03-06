﻿#SingleInstance,Force

backupFolderExist := fileexist("gitignore_backup")
if(!backupFolderExist || !InStr(backupFolderExist, "D"))
{
	FileCreateDir,gitignore_backup
}

;/¯¯¯¯ config ¯¯ 190311182516 ¯¯ 11.03.2019 18:25:16 ¯¯\
doShowRexExAsComment := true
limit_of_endLess_to := 10
;\____ config __ 190311182518 __ 11.03.2019 18:25:18 __/


ifNotExist_gitignore_pre()
; prepareFirstLine_andBackup_gitignore()
FileRead, fileContent, .gitignore_pre
newString := main(fileContent, doShowRexExAsComment, limit_of_endLess_to)
; content := backup() ; optional
firstLine := "# not recomandet to edit this file, becouse this file is generated by: " A_ScriptName
save_gitignore(firstLine "`n" newString)

MsgBox, `n`n (line:%A_LineNumber%) `n`n`n script finished. reload?
Reload

/*
	from https://www.fossil-scm.org/xfer/doc/trunk/www/globs.md :
	*	Matches any sequence of zero or more characters
	?	Matches exactly one character
	[...]	Matches one character from the enclosed list of characters
	[^...]	Matches one character not in the enclosed list
	
	[a-d]	Matches any one of a, b, c, or d but not ä
	[^a-d]	Matches exactly one character other than a, b, c, or d
	[0-9a-fA-F]	Matches exactly one hexadecimal digit
	[a-]	Matches either a or -
	[][]	Matches either ] or [
	[^]]	Matches exactly one character other than ]
	[]^]	Matches either ] or ^
	[^-]	Matches exactly one character other than 
	
	from https://facelessuser.github.io/wcmatch/glob/:
	[[:alnum:]] POSIX style 
	
	from https://facelessuser.github.io/wcmatch/glob/#syntax:
	?(pattern_list)	The pattern matches if zero or one occurrences of any of the patterns in the pattern_list match the input string.
	^- really? i tried. not work for me. 19-03-11_16-43
	
	+(pattern_list)	The pattern matches if one or more occurrences of any of the patterns in the pattern_list match the input string.
	^- really? i tried. not work for me. 19-03-11_16-43
*/

main(fileContent, doShowRexExAsComment := true, limit_of_endLess_to := 10){
	if(!FileExist(".gitignore_pre"))
	{
		MsgBox, ERROR: NotExist, .gitignore_pre `n`n %thisLine% `n`n (line:%A_LineNumber%) `n`n`n The end of the file has been reached or there was a problem
		return
	}
	
	lastUsedTracker := {}
	
	; while(A_Index < 99999){
	;FileReadLine, thisLine , .gitignore_pre, %A_Index%
	Loop, parse, fileContent, `n, `r  ; Specifying `n prior to `r allows both Windows and Unix files to be parsed.
	{
		if ErrorLevel
			break
		thisLine := A_LoopField
		
		thisLineBackup := ""
		if(!thisLine || RegExMatch(thisLine,"^\s*\#")){
			newString .= thisLine "`n"
			if(rtrim(thisLine) == "#<<<EXIT") ; # preocess to this line. stop at this line (may useful for testing)
				return newString
			Continue
		}
		if(RegExMatch(thisLine,"\\(d|w)(\*)")){
			MsgBox, \w ... or \d(\*|\+) not suported at the moment. you could us \d{1,9} `n`n %thisLine% `n`n (line:%A_LineNumber%) `n`n`n The end of the file has been reached or there was a problem
		}
		
		; thisLine := RegExReplace(thisLine,"\\d", "[0-9]") ""
		; thisLine := RegExReplace(thisLine,"\\d", "[0-9]") ""
		;/¯¯¯¯ optional ¯¯ 190311152138 ¯¯ 11.03.2019 15:21:38 ¯¯\
		; optional ????? is not working
		; thisLine := RegExReplace(thisLine,"\\d(\+)", "[[:alnum:]]" StringRepeat("[0-9]?", 20) ) 
		; thisLine := RegExReplace(thisLine,"\\d(\*)", StringRepeat("[0-9]?", 20) )
		; thisLine := RegExReplace(thisLine,"\\d(\*|\+)", "[0-9][!a-z][0-9]" )
		;\____ optional __ 190311152146 __ 11.03.2019 15:21:46 __/
		; thisLine := RegExReplace(thisLine,"\\d\{(\d)\}", StringRepeat("[0-9]?", "$1") ) 
		
		
		if(RegExMatch(thisLine,"((\\d|\\w|i\)\\w)\+)",matchs)){
			thisLineBackup := thisLine
			if(matchs2 == "\d")
				replaceText := "[0-9]"
			else if(matchs2 == "i)\w")
				replaceText := "[a-zA-Z]"
			else
				replaceText := "[a-z]"
			; thisLine := StrReplace(thisLine,matchs1, StringRepeat(replaceText, limit_of_endLess_to) ) 
			thisLine := "# + is limited to " limit_of_endLess_to " (see config at script top)`n"
			Loop,% limit_of_endLess_to
				thisLine .= StrReplace(thisLineBackup,matchs1, StringRepeat(replaceText, A_Index ) ) "`n"
		}
		
		if(RegExMatch(thisLine,"(\\d{(\d+)})",matchs)){
			thisLineBackup := thisLine			
			thisLine := StrReplace(thisLine,matchs1, StringRepeat("[0-9]", matchs2) ) 
		}
		if(RegExMatch(thisLine,"(i\)\\w{(\d+)})",matchs)){
			thisLineBackup := thisLine
			thisLine := StrReplace(thisLine,matchs1, StringRepeat("[a-zA-Z]", matchs2) ) 
		}
		if(RegExMatch(thisLine,"(\\w{(\d+)})",matchs)){
			thisLineBackup := thisLine
			thisLine := StrReplace(thisLine,matchs1, StringRepeat("[a-z]", matchs2) ) 
		}
		if(RegExMatch(thisLine,"^[^\#]*((\\d|\\w|i\)\\w)\{(\d+),(\d+)\})",matchs)){
			thisLineBackup := thisLine
			if(matchs2 == "\d")
				replaceText := "[0-9]"
			else if(matchs2 == "i)\w")
				replaceText := "[a-zA-Z]"
			else
				replaceText := "[a-z]"
			thisLine := ""
			count := matchs4 - matchs3 + 1
			Loop,% count
				thisLine .= StrReplace(thisLineBackup,matchs1, StringRepeat(replaceText, matchs3 + A_Index -1 ) ) "`n"
			; MsgBox, %count% `n %matchs1% `n%thisLine% `n`n (line:%A_LineNumber%) `n`n`n The end of the file has been reached or there was a problem
			
		}
		; newString := rTrim(thisLine," `t`r`n")
		if(thisLineBackup){ ; then changes happend
			thisLine := rtrim(main(thisLine, doShowRexExAsComment, limit_of_endLess_to) ," `t`r`n") 
			; MsgBox,paused >>%newString%<< >>%thisLineBackup%<<
		}
		;MsgBox,% lastUsedTracker["log2"]
		;MsgBox, `n`n (line:%A_LineNumber%) `n`n`n The end of the file has been reached or there was a problem ;*[gitignore_preprocessor]
		lastUsedTracker.Insert(thisLine, A_Index) 
		
		newString .= ((doShowRexExAsComment && thisLineBackup)? "# " thisLineBackup "`n" : "")
		; newString .= RegExReplace(thisLine,"^(\!(\w[\w_]*)\/\*\*)$", "!$2`n$1") "`n"
		; folderRegEx := "[^\\\/\?\*\""\>\<\:\|]"
		folderRegEx := "[^\/\?\*]"
		if(RegExMatch(thisLine, "^((\!?" folderRegEx "*)\/\*\*)",matchs)){ ; matchs1 is everything. matchs2 first group
			if(!lastUsedTracker[matchs2]){
				newString .= matchs2 "`n" thisLine "`n"
				lastUsedTracker.Insert(matchs2, A_Index - 1) 
				; MsgBox, %thisLine% `n`n%newString%`n`n  (line:%A_LineNumber%) `n`n`n The end of the file has been reached or there was a problem
			}else newString .= thisLine "`n"
		}
		else newString .= thisLine "`n"
		; newString .= RegExReplace(thisLine,"^((\!?" folderRegEx "*)\/\*\*)", "$2`n$1") "`n"
			
	}
	return newString
	Clipboard := newString
	MsgBox, '%newString%' = newString `n`n (line:%A_LineNumber%) `n`n`n The end of the file has been reached or there was a problem
	Reload
}

StringRepeat( Str, Count ) { ; By SKAN / CD:12-04-2011
; www.autohotkey.com/community/viewtopic.php?p=435990#435990
	VarSetCapacity( S, Count * ( A_IsUnicode ? 2:1 ), 1 )
	StringReplace, S, S, % SubStr( S,1,1 ), %Str%, All
	Return SubStr( S, 1, Count * StrLen(Str) )
}

;/¯¯¯¯ prepareAndBackup_gitignore ¯¯ 190311141110 ¯¯ 11.03.2019 14:11:10 ¯¯\
prepareFirstLine_andBackup_gitignore(){
	MsgBox, deprecated 19-03-11_
	
	firstLine := "# not recomandet to edit this file, becouse this file is generated by: " A_ScriptName
	FileReadLine, thisLine , .gitignore, 1
	if(firstLine <> thisLine){
		content := backup()
		tempFileAddress := "gitignore_backup\.gitignore" A_TickCount ".temp." A_ThisFunc ".txt"
		content := firstLine "`n" content
		FileAppend, % content, % tempFileAddress
		FileCopy,% tempFileAddress, .gitignore, 1
		Sleep,100
		FileDelete,% tempFileAddress
		return content
	}
}
;\____ prepareAndBackup_gitignore __ 190311141114 __ 11.03.2019 14:11:14 __/

ifNotExist_gitignore_pre(){
	if(FileExist(".gitignore_pre"))
		return
	FileRead, content , .gitignore
	FileAppend, % content "`n", .gitignore_pre
	return content
}

backup(){
	FileRead, content , .gitignore
	tempFileAddress := "gitignore_backup\.gitignore" A_TickCount ".temp." A_ThisFunc ".txt"
	FileAppend, % content "`n", % "gitignore_backup\" tempFileAddress	
	return content
}



;/¯¯¯¯ save_gitignore ¯¯ 190311160300 ¯¯ 11.03.2019 16:03:00 ¯¯\
save_gitignore(content){
	tempFileAddress := "gitignore_backup\.gitignore" A_TickCount ".temp." A_ThisFunc ".txt"
	FileAppend, % content, % tempFileAddress
	FileCopy,% tempFileAddress, .gitignore, 1
	Sleep,100
	FileDelete, % tempFileAddress
}
;\____ save_gitignore __ 190311160307 __ 11.03.2019 16:03:07 __/





