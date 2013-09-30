﻿;
; AutoHotkey (Tested) Version: 1.1.13.00
; Author:         Joe DF  |  http://joedf.co.nr  |  joedf@users.sourceforge.net
; Date:           September 29th, 2013
; Library Version: 1.0.2.0
;
;	LibCon - AutoHotkey Library For Console Support
;
;///////////////////////////////////////////////////////

;Default settings
	SetWinDelay, 0
	SetBatchLines,-1

;Get Arguments
	if 0 != 0
	{
		argc=%0%
		args:=[]
		args[0]:=argc
		
		Loop, %0%
		{
			args.Insert(%A_Index%)
			args["CSV"]:=args["CSV"] """" %A_Index% "" ((A_Index==args[0]) ? """" : """,")
		}
	}	

;Console Constants ;{
	LibConDebug := 0 ;Enable/Disable DebugMode
	LibConErrorLevel := 0 ;Used For DebugMode
	
	;Type sizes // http://msdn.microsoft.com/library/aa383751 // EXAMPLE: SHORT is 2 bytes, etc..
	sType := Object("SHORT", 2, "COORD", 4, "WORD", 2, "SMALL_RECT", 8, "DWORD", 4, "LONG", 4)

	;Console Color Constants
	Black:=0x0
	DarkBlue:=0x1
	DarkGreen:=0x2
	Turquoise:=0x3
	DarkGreenBlue:=0x3
	GreenBlue:=0x3
	DarkRed:=0x4
	Purple:=0x5
	Brown:=0x6
	Gray:=0x7
	Grey:=0x7
	DarkGray:=0x8
	DarkGrey:=0x8
	Blue:=0x9
	Green:=0xA
	Cyan:=0xB
	Red:=0xC
	Magenta:=0xD
	Pink:=0xD
	Yellow:=0xE
	White:=0xF
;}

;Console Functions + More... ;{
	SmartStartConsole() { ;will run accordingly
		if (A_IsCompiled) {
			winget,x,ProcessName,A
			if (x="explorer.exe")
				return StartConsole()
			else
				return AttachConsole()
		} else {
			return StartConsole()
		}
	}

	StartConsole() {
		global Stdout
		global Stdin
		global LibConErrorLevel
		
		ERROR_INVALID_PARAMETER := 87 ;see http://msdn.microsoft.com/library/ms683150
		if (!DllCall("FreeConsole")) {
			LibConErrorLevel:=ErrorLevel
			if (A_LastError!=ERROR_INVALID_PARAMETER) ;if was attached and error occured..
				return LibConError("FreeConsole") ;return error
		} ;otherwise means no console was attached
		
		x:=AllocConsole()
		Stdout:=getStdoutObject()
		Stdin:=getStdinObject()
		return x
	}
	
	;AttachConsole() http://msdn.microsoft.com/library/ms681952
	;Defaults to calling process... ATTACH_PARENT_PROCESS = (DWORD)-1
	AttachConsole(cPID:=-1) {
		global LibConErrorLevel
		global Stdout
		global Stdin
		x:=DllCall("AttachConsole", "UInt", cPID, "Cdecl int")
		if ((!x) or (LibConErrorLevel:=ErrorLevel)) and (cPID!=-1) ;reject error if ATTACH_PARENT_PROCESS is set
			return LibConError("AttachConsole",cPID) ;Failure
		Stdout:=getStdoutObject()
		Stdin:=getStdinObject()
		return x
	}
	
	;AllocConsole() http://msdn.microsoft.com/library/ms681944
	AllocConsole() {
		global LibConErrorLevel
		x:=DllCall("AllocConsole")
		if (!x) or (LibConErrorLevel:=ErrorLevel)
			return LibConError("AllocConsole") ;Failure
		return x
	}

	;FreeConsole() http://msdn.microsoft.com/library/ms683150
	FreeConsole() {
		global LibConErrorLevel
		x:=DllCall("FreeConsole")
		if (!x) or (LibConErrorLevel:=ErrorLevel)
			return LibConError("FreeConsole") ;Failure
		return x
	}
	
	;GetStdHandle() http://msdn.microsoft.com/library/ms683231
	getStdinObject() {
		global LibConErrorLevel
		x:=FileOpen(DllCall("GetStdHandle", "int", -10, "ptr"), "h `n")
		if (!x) or (LibConErrorLevel:=ErrorLevel)
			return LibConError("getStdinObject") ;Failure
		return x
	}

	getStdoutObject() {
		global LibConErrorLevel
		x:=FileOpen(DllCall("GetStdHandle", "int", -11, "ptr"), "h `n")
		if (!x) or (LibConErrorLevel:=ErrorLevel)
			return LibConError("getStdoutObject") ;Failure
		return x
	}
	
	;Get the console's window Handle
	;GetConsoleWindow() http://msdn.microsoft.com/library/ms683175
	getConsoleHandle() {
		global LibConErrorLevel
		hConsole := DllCall("GetConsoleWindow","UPtr") ;or WinGet, hConsole, ID, ahk_pid %cPID%
		if (!hConsole) or (LibConErrorLevel:=ErrorLevel)
			return LibConError("getConsoleHandle") ;Failure
		else
			return %hConsole% ;Success
	}
	
	newline(x=1) {
	loop %x%
		puts()
	}
	
	/* Deprecated old method
	--------------------------------
	puts(string="") {
		global Stdout
		Stdout.WriteLine(string) ;Stdout.write(string . "`n")
		Stdout.Read(0)
	}
	
	print(string="") {
		global Stdout
		if strlen(string) > 0
			Stdout.write(string)
		Stdout.Read(0)
	}
	
	Removed/Deprecated
	--------------------------------
	;Unicode Printing Support http://msdn.microsoft.com/library/ms687401
	;Fails (with SetConsoleInputCP(65001) = Unicode (UTF-8) ), if the current (console) font does not have Unicode support
	;Seems to function otherwise...
	printW(str) {
		global Stdout
		global LibConErrorLevel
		e:=DllCall("WriteConsole","Ptr",Stdout.__Handle,"WStr",str,"UInt",StrLen(str),"UInt",charsWritten,"Ptr*",0)
		LibConErrorLevel:=ErrorLevel
		if (!e) or (LibConErrorLevel)
			return LibConError("printW",str)
		return 1
	}
	
	putsW(str) {
		return printW(str . "`n")
	}
	*/
	
	;New Method - Supports Both Unicode and ANSI
	;------------------
	print(string=""){
		global Stdout
		global LibConErrorLevel
		
		if (!StrLen(string))
			return 1
		
		e:=DllCall("WriteConsole" . ((A_IsUnicode) ? "W" : "A")
				, "UPtr", Stdout.__Handle
				, "Str", string
				, "UInt", strlen(string)
				, "UInt*", Written
				, "uint", 0)
		LibConErrorLevel:=ErrorLevel
		
		if (!e) or (LibConErrorLevel)
			return LibConError("getColor") ;Failure
		Stdout.Read(0)
		return e
	}
	
	puts(string="") {
		global Stdout
		r:=print(string . "`n")
		Stdout.Read(0)
		return r
	}
	
	;fork of 'formatprint' :  http://www.autohotkey.com/board/topic/60731-printf-the-ahk-way/#entry382968
	printf(msg, vargs*) {
		for each, varg in vargs
			StringReplace,msg,msg,`%s, % varg ;msg:=RegExReplace(msg,"i)`%.",varg)
		return print(msg)
	}
	
	putsf(msg, vargs*) {
		for each, varg in vargs
			StringReplace,msg,msg,`%s, % varg ;msg:=RegExReplace(msg,"i)`%.",varg)
		return puts(msg)
	}
	
	/* Removed/Deprecated - Old Method
	printWf(msg, vargs*) {
		for each, varg in vargs
			StringReplace,msg,msg,`%s, % varg ;msg:=RegExReplace(msg,"i)`%.",varg)
		return printW(msg)
	}
	
	putsWf(msg, vargs*) {
		for each, varg in vargs
			StringReplace,msg,msg,`%s, % varg ;msg:=RegExReplace(msg,"i)`%.",varg)
		return putsW(msg)
	}
	*/
	
	ClearScreen() {
		global LibConErrorLevel
		;http://msdn.microsoft.com/en-us/library/ms682022.aspx
		;Currently too lazy to do it programmatically...
		runwait %ComSpec% /c cls.exe %n%,,UseErrorLevel
		LibConErrorLevel:=ErrorLevel
		if LibConErrorLevel = ERROR
			return LibConError("ClearScreen") ;Failure
		return LibConErrorLevel
	}
	
	cls() {
		ClearScreen()
	}
	
	Clear() {
		ClearScreen()
	}
	
	/* Deprecated Old Method
	gets(ByRef var="") {
		global LibConErrorLevel
		global Stdin
		var:=RTrim(Stdin.ReadLine(), "`n")
		flushInput() ;Flush the input buffer
		return var
	}
	*/
	; New Method - Supports Both Unicode and ANSI
	;Forked from the German CMD Lib
	;http://www.autohotkey.com/de/forum/topic8517.html
	gets(ByRef str="") {
		global StdIn
		global LibConErrorLevel
		
		BufferSize:=8192 ;65536 bytes is the maximum
		charsRead:=0
		Ptr := (A_PtrSize) ? "uptr" : "uint"
		
		VarSetCapacity(str,BufferSize)
		e:=DllCall("ReadConsole" . ((A_IsUnicode) ? "W" : "A")
				,Ptr,stdin.__Handle
				,Ptr,&str
				,"UInt",BufferSize
				,Ptr "*",charsRead
				,Ptr,0
				,UInt)
		LibConErrorLevel:=ErrorLevel
		
		if (e) and (!charsRead)
			return ""
		if (!e) or (LibConErrorLevel)
			return LibConError("gets",str)
		
		Loop, % charsRead
			msg .= Chr(NumGet(str, (A_Index-1) * ((A_IsUnicode) ? 2 : 1), (A_IsUnicode) ? "ushort" : "uchar"))
		StringSplit, msg, msg,`r`n
		str:=msg1
		flushInput()
		
		return str
	}
	
	;_getch() http://msdn.microsoft.com/library/078sfkak
	_getch() {
		return DllCall("msvcrt.dll\_getch","int")
	}
	
	_getchW() {
		return DllCall("msvcrt.dll\_getwch","int")
	}
	
	;FlushConsoleInputBuffer() http://msdn.microsoft.com/library/ms683147
	flushInput() {
		global LibConErrorLevel
		global stdin
		x:=DllCall("FlushConsoleInputBuffer", uint, stdin.__Handle)
		if (!x) or (LibConErrorLevel:=ErrorLevel)
			return LibConError("flushInput") ;Failure
		return x
	}

	getch(ByRef keyname="") {
		;the comments with ;//   are from my original c function
		;this is an AutoHotkey port of that function...
		flushInput()
		
		key:=_getch()
		if (key==224) or (key==0)
		skey:=_getch()
		
		if (key==3) ;//note 'c' is 63
			keyname:="Ctrl+c"
		else if (key==4) ;//note 'd' is 64
			keyname:="Ctrl+d"
		else if (key==5)  ;//therefore "Ctrl+c" = 63 - 60 = 3
			keyname:="Ctrl+e" ;//and so on...
		else if (key==6)
			keyname:="Ctrl+f"
		else if (key==7)
			keyname:="Ctrl+g"
		else if (key==8) ;//case  8: *keyname ="Ctrl+h 8"; break;
			keyname:="Backspace"
		else if (key==9) ;//case  9: *keyname ="Ctrl+i 9"; break;
			keyname:="Tab"
		else if (key==13)
			keyname:="Return"
		else if (key==26)
			keyname:="Ctrl+z"
		else if (key==27)
			keyname:="Esc"
		else if (key==32)
			keyname:="Space"
		else if (key==224) ;//or FFFFFFE0 or 4294967264 ;*keyname ="Special";
		{
			;skey:=DllCall("msvcrt.dll\_getch","int")
			if (skey==71)
				keyname:="Home"
			else if (skey=72)
				keyname:="Up"
			else if (skey=73)
				keyname:="PgUp"
			else if (skey=75)
				keyname:="Left"
			else if (skey=77)
				keyname:="Right"
			else if (skey=79)
				keyname:="End"
			else if (skey=80)
				keyname:="Down"
			else if (skey=81)
				keyname:="PgDn"
			else if (skey=83)
				keyname:="Del"
			else
				keyname:="Special"
		}
		else if (key==0) ;Function Keys?!  code: '0' (value)
		{
			;skey:=DllCall("msvcrt.dll\_getch","int")
			if (skey==59)
				keyname:="F1"
			else if (skey=60)
				keyname:="F2"
			else if (skey=61)
				keyname:="F3"
			else if (skey=62)
				keyname:="F4"
			else if (skey=63)
				keyname:="F5"
			else if (skey=64)
				keyname:="F6"
			else if (skey=65)
				keyname:="F7"
			else if (skey=66)
				keyname:="F8"
			else if (skey=67)
				keyname:="F9"
			else if (skey=68)
				keyname:="F10"
			else
				keyname:="FunctionKey"
		}
		else
		{
			keyname:=chr(key)
		}
		
		flushInput() ;Flush the input buffer
		
		if (key==224)
			return "224+" skey
		else if (key==0)
			return "0+" skey
		else
			return key
	}
	
	wait(timeout=0) {
		global LibConErrorLevel
		opt:=""
		if (!timeout=0)
			opt=T%timeout%
		Input, SingleKey, L1 %opt%, {LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}
		return %SingleKey%
	}
	
	;from gwarble
	;http://www.autohotkey.com/board/topic/96304-real-console-applications-command-line-apps/?hl=console
	WaitAction() {
		global LibConErrorLevel
		global Stdin
		VarSetCapacity(INPUT_RECORD, 24, 0)
		DllCall("ReadConsoleInput", uint, stdin.__Handle, uint, &INPUT_RECORD, uint, 1, "ptr*", 0)
		key := NumGet(INPUT_RECORD,14,"Short")
		flushInput() ;Flush the input buffer	
		return key
	}

	pause(show=1) {
		global LibConErrorLevel
		n:=""
		if (!show)
			n:=">NUL"
		runwait %ComSpec% /c pause.exe %n%
	}

	dec2hex(var) {
		OldFormat := A_FormatInteger
		SetFormat, Integer, Hex
		var += 0
		SetFormat, Integer, %OldFormat%
		return var
	}

	dec2shex(var) { ;dec to S(tring)Hex
		var:=("" . dec2hex(var))
		StringRight,var,var,1
		return var
	}
	
	;from Laszlo : http://www.autohotkey.com/board/topic/15951-base-10-to-base-36-conversion/#entry103624
	ToBase(n,b) { ; n >= 0, 1 < b <= 36
		Loop {
			d := mod(n,b), n //= b
			m := (d < 10 ? d : Chr(d+55)) . m
			IfLess n,1, Break
		}
		Return m
	}
	
	;Fork of http://www.autohotkey.com/board/topic/90674-ascii-progress-bar/
	sProgressBar(Length, Current, Max, Unlock = 0, fixed=1, lp="|", lba="[", lbb="]") {
		;Original Made by Bugz000 with assistance from tidbit, Chalamius and Bigvent
		Progress:=""
		Percent := (Current / Max) * 100
		if (unlock = 0)
				length := length > 97 ? 97 : length < 4 ? 4 : length
		percent := percent > 100 ? 100 : percent < 0 ? 0 : percent
		Loop % round(((percent / 100) * length), 0)
				Progress .= lp
		if (fixed)
		{
			loop % Length - round(((percent / 100) * length), 0)
					Progress .= A_Space
		}
		return lba progress lbb A_space round(percent, 2) "% Complete"
	}
	
	;SetConsoleTextAttribute() http://msdn.microsoft.com/library/ms686047
	setColor(FG="",BG="") { ;Sets the color (int Hexadecimal number)
		global LibConErrorLevel
		global Stdout
		if FG is not integer
			FG:=getFgColor()
		if BG is not integer
			BG:=getBgColor()
		FG:=abs(FG)
		BG:=abs(BG)*16
		x:=DllCall("SetConsoleTextAttribute","UPtr",Stdout.__Handle,"Int",(BG+FG))
		if (!x) or (LibConErrorLevel:=ErrorLevel)
			return LibConError("setColor",FG,BG) ;Failure
		return x
	}
	
	setFgColor(c) {
		return setcolor(c)
	}
	
	setBgColor(c) {
		return setColor("",c)
	}

	;GetConsoleScreenBufferInfo() http://msdn.microsoft.com/library/ms683171
	getColor() { ;Returns the current color (int Hexadecimal number)
		global LibConErrorLevel
		global Stdout
		global sType
		VarSetCapacity(consoleInfo,(3*sType.COORD)+sType.WORD+sType.SMALL_RECT,0)
		x:=DllCall("GetConsoleScreenBufferInfo","UPtr",Stdout.__Handle,"Ptr",&consoleInfo)
		if (!x) or (LibConErrorLevel:=ErrorLevel)
			return LibConError("getColor") ;Failure
		return dec2hex(NumGet(&consoleInfo,(2*sType.COORD),"Short"))
	}
	
	getFgColor() {
		c:=getColor()
		return dec2hex(c-(16*getBgColor()))
	}
	
	getBgColor() {
		c:=getColor()
		return dec2hex(c >> 16)
	}
	
	printcolortable() {
		f:=0
		b:=0
		cf:=getFGColor()
		cb:=getBGColor()
		
		puts("`n`t1st Digit: Background 2nd Digit: Foreground")
		puts("_______________________________________________________________")
		
		Loop, 16 
		{
			b:=(A_Index-1)
			print("`t" . "")
			Loop, 16 
			{
				setColor(f:=(A_Index-1), b)
				print(dec2shex(b) . dec2shex(f) . ((f=15 or f="F") ? "`n" : " "))
			}
			setColor(cf,cb)
		}
		puts("_______________________________________________________________")
		puts("Current Color: " . getColor())
	}
	
	;see "Code Page Identifiers" (CP) - http://msdn.microsoft.com/library/dd317756
	
	;SetConsoleOutputCP() http://msdn.microsoft.com/library/ms686036
	SetConsoleOutputCP(codepage) {
		e:=DllCall("SetConsoleOutputCP","UInt",codepage)
		LibConErrorLevel:=ErrorLevel
		if (!e) or (LibConErrorLevel)
			return LibConError("SetConsoleOutputCP",codepage) ;Failure
		return 1
	}
	
	;GetConsoleOutputCP() http://msdn.microsoft.com/library/ms683169
	GetConsoleOutputCP() {
		codepage:=DllCall("GetConsoleOutputCP","Int")
		if (!codepage) or (LibConErrorLevel)
			return LibConError("GetConsoleOutputCP") ;Failure
		return codepage
	}
	
	;SetConsoleCP() http://msdn.microsoft.com/library/ms686013
	SetConsoleInputCP(codepage) {
		e:=DllCall("SetConsoleCP","UInt",codepage)
		LibConErrorLevel:=ErrorLevel
		if (!e) or (LibConErrorLevel)
			return LibConError("SetConsoleInputCP",codepage) ;Failure
		return 1
	}
	
	;GetConsoleCP() http://msdn.microsoft.com/library/ms683162
	GetConsoleInputCP() {
		codepage:=DllCall("GetConsoleCP","Int")
		if (!codepage) or (LibConErrorLevel)
			return LibConError("GetConsoleInputCP") ;Failure
		return codepage
	}
	
	;GetConsoleOriginalTitle() http://msdn.microsoft.com/library/ms683168
	GetConsoleOriginalTitle(byRef Title) {
		VarSetCapacity(title,6400,0)
		e:=DllCall("GetConsoleOriginalTitle","Str",Title,"UInt",6400)
		LibConErrorLevel:=ErrorLevel
		if (!e) or (LibConErrorLevel)
			return LibConError("GetConsoleTitle",Title) ;Failure
		return 1
	}
	
	;GetConsoleTitle() http://msdn.microsoft.com/library/ms683174
	GetConsoleTitle(byRef Title) {
		VarSetCapacity(title,6400,0)
		e:=DllCall("GetConsoleTitle","Str",Title,"UInt",6400)
		LibConErrorLevel:=ErrorLevel
		if (!e) or (LibConErrorLevel)
			return LibConError("GetConsoleTitle",Title) ;Failure
		return 1
	}
	
	;SetConsoleTitle() http://msdn.microsoft.com/library/ms686050
	SetConsoleTitle(title="") {
		global LibConErrorLevel
		if !(title=="")
		{
			string:=title
			if strlen(string) >= 6400
				StringTrimRight,string,string,% strlen(string) - (strlen(string)-6400)
			e:=DllCall("SetConsoleTitle","Str",string)
			LibConErrorLevel:=ErrorLevel
			if (!e) or (LibConErrorLevel)
				return LibConError("SetConsoleTitle",title) ;Failure
			return 1
		}
		return 0
	}
	
	;For the Cursor of CLI -> Caret
	;getConsoleCursorPosition, GetConsoleScreenBufferInfo() http://msdn.microsoft.com/library/ms683171
	getConsoleCursorPosition(ByRef x, ByRef y) {
		global LibConErrorLevel
		global Stdout
		global sType
		hStdout := Stdout.__Handle
		VarSetCapacity(struct,(sType.COORD*3)+sType.WORD+sType.SMALL_RECT,0)
		e:=DllCall("GetConsoleScreenBufferInfo","UPtr",hStdout,"Ptr",&struct)
		LibConErrorLevel:=ErrorLevel
		x:=NumGet(&struct,sType.COORD,"UShort")
		y:=NumGet(&struct,sType.COORD+sType.SHORT,"UShort")
		if (!e) or (LibConErrorLevel)
			return LibConError("getConsoleCursorPosition",x,y) ;Failure
		return 1
	}
	
	;SetConsoleCursorPosition() http://msdn.microsoft.com/library/ms686025
	SetConsoleCursorPosition(x="",y="") {
		global LibConErrorLevel
		global Stdout
		global sType
		hStdout:=Stdout.__Handle
		getConsoleCursorPosition(ox,oy)
		if x is not Integer
			x:=ox
		if y is not Integer
			y:=oy
		VarSetCapacity(struct,sType.COORD,0)
		Numput(x,struct,"UShort")
		Numput(y,struct,sType.SHORT,"UShort")
		e:=DllCall("SetConsoleCursorPosition","Ptr",hStdout,"uint",Numget(struct,"uint"))
		if (!e) or (LibConErrorLevel)
			return LibConError("SetConsoleCursorPosition",x,y) ;Failure
		return 1
	}
	
	getConsoleCursorPos(ByRef x, ByRef y) {
		return getConsoleCursorPosition(x,y)
	}
	
	SetConsoleCursorPos(x="",y="") {
		return SetConsoleCursorPosition(x,y)
	}
	
	;Get BufferSize, GetConsoleScreenBufferInfo() http://msdn.microsoft.com/library/ms683171
	getConsoleSize(ByRef bufferwidth, ByRef bufferheight) {
		global LibConErrorLevel
		global Stdout
		global sType
		hStdout := Stdout.__Handle
		VarSetCapacity(struct,(sType.COORD*3)+sType.WORD+sType.SMALL_RECT,0)
		x:=DllCall("GetConsoleScreenBufferInfo","UPtr",hStdout,"Ptr",&struct)
		LibConErrorLevel:=ErrorLevel
		bufferwidth:=NumGet(&struct,"UShort")
		bufferheight:=NumGet(&struct,sType.SHORT,"UShort")
		if (!x) or (LibConErrorLevel)
			return LibConError("getConsoleSize",bufferwidth,bufferheight) ;Failure
		return 1
	}

	getConsoleWidth() {
		if (!getConsoleSize(bufferwidth,bufferheight))
			return 0 ;Failure
		else
			return %bufferwidth% ;Success
	}

	getConsoleHeight() {
		if (getConsoleSize(bufferwidth,bufferheight))
			return 0 ;Failure
		else
			return %bufferheight% ;Success
	}
	
	;GetCurrentConsoleFont() http://msdn.microsoft.com/library/ms683176
	getFontSize(Byref fontwidth, ByRef fontheight) {
		global LibConErrorLevel
		global sType
		global Stdout
		hStdout:=Stdout.__Handle
		;CONSOLE_FONT_INFO cmdft;
		;GetCurrentConsoleFont(hStdout,FALSE,&cmdft);
		;COORD fontSize = GetConsoleFontSize(hStdout,cmdft.nFont);
		;return fontSize.X;
		
		;typedef struct _CONSOLE_FONT_INFO {
		;	DWORD nFont;
		;	COORD dwFontSize;
		; } CONSOLE_FONT_INFO, *PCONSOLE_FONT_INFO;
		
		VarSetCapacity(struct,sType.DWORD+sType.COORD,0)
		x:=DllCall("GetCurrentConsoleFont","Ptr",hStdout,"Int",0,"Ptr",&struct)
		LibConErrorLevel:=ErrorLevel
		;VarSetCapacity(structb,sType.COORD,0)
		;structb:=DllCall("GetConsoleFontSize","Ptr",hStdout,"UInt",NumGet(&struct,"Int"))
		
		fontwidth:=NumGet(&struct,sType.DWORD,"UShort")
		fontheight:=NumGet(&struct,sType.DWORD+sType.SHORT,"UShort")
		
		if (!x) or (LibConErrorLevel)
			return LibConError("getFontSize",fontwidth,fontheight) ;Failure
		return 1
	}

	getFontWidth() {
		if (getFontSize(fontwidth,fontheight))
		{
			return 0 ;Failure
		}
		else
			return %fontwidth% ;Success
	}

	getFontHeight() {
		if (getFontSize(fontwidth,fontheight))
		{
			return 0 ;Failure
		}
		else
			return %fontheight% ;Success
	}
	
	;SetConsoleScreenBufferSize() http://msdn.microsoft.com/library/ms686044
	;set Console window size ; - Width in Columns and Lines : (Fontheight and Fontwidth)
	setConsoleSize(width,height,SizeHeight=0) {
		global LibConErrorLevel
		global sType
		global Stdout
		hStdout:=Stdout.__Handle
		hConsole:=getConsoleHandle()
		
		getConsoleSize(hcW,cH) ;buffer size
		WinGetPos,wX,wY,,wH,ahk_id %hConsole% ;window size
		getFontSize(fW,fH) ;font size
		
		;MsgBox % "rqW: " width "`nrqH: " height
		
		newBuffer := Object("w",(width*fW),"h",(height*fH))
		oldBuffer := Object("w",(cW*fW),"h",(cH*fH))
		
		VarSetCapacity(bufferSize,sType.COORD,0)
		NumPut(width,bufferSize,"UShort")
		NumPut(height,bufferSize,sType.SHORT,"UShort")
		
		if ( (newBuffer.w >= oldBuffer.w) and (newBuffer.h >= oldBuffer.h) )
		{
			if (DllCall("SetConsoleScreenBufferSize","Ptr",hStdout,"uint",Numget(bufferSize,"uint"))
				and DllCall("MoveWindow","Ptr",hConsole,"Int",wX,"Int",wY,"Int",newBuffer.w,"Int",newBuffer.h,"Int",1))
			{
				if (SizeHeight)
					WinMove,ahk_id %hConsole%,,,,,wH
				return 1
			}
			else
			{
				LibConErrorLevel := ErrorLevel
				return LibConError("setConsoleSize",width,height,SizeHeight) ;Failure
			}
		}
		else
		{
			if (DllCall("MoveWindow","Ptr",hConsole,"Int",wX,"Int",wY,"Int",newBuffer.w,"Int",newBuffer.h,"Int",1)
				and DllCall("SetConsoleScreenBufferSize","Ptr",hStdout,"uint",Numget(bufferSize,"uint")))
			{
				if (SizeHeight)
					WinMove,ahk_id %hConsole%,,,,,wH
				return 1
			}
			else
			{
				LibConErrorLevel := ErrorLevel
				return LibConError("setConsoleSize",width,height,SizeHeight) ;Failure
			}
		}
	}
	
	;Msgbox for Errors (DebugMode Only)
	LibConError(fname:="",arg1:="",arg2:="",arg3:="",arg4:="") {
		global LibConDebug
		global LibConErrorLevel
		;calling function name: msgbox % Exception("",-2).what ; from jethrow
		;http://www.autohotkey.com/board/topic/95002-how-to-nest-functions/#entry598796
		if !IsFunc(fname) ;or fname is space
			fname := Exception("",-2).what
		if !IsFunc(fname) ;try again since sometime it return -2() meaning not found...
			fname := "Undefined"
		if (LibConDebug)
		{
			MsgBox, 262194, LibConError, %fname%() Failure`nErrorlevel: %LibConErrorLevel%`nA_LastError: %A_LastError%`n`nWill now Exit.
			IfMsgBox, Abort
				ExitApp
			IfMsgBox, Ignore
				return 0
			IfMsgBox, Retry
			{
				return %fname%(arg1,arg2,arg3,arg4)
			}
		}
		return 0
	}
;}

