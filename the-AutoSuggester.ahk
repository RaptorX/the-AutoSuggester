
/*
This work by the-Automator.com is licensed under CC BY 4.0

Attribution — You must give appropriate credit , provide a link to the license,
and indicate if changes were made.
You may do so in any reasonable manner, but not in any way that suggests the licensor
endorses you or your use.
No additional restrictions — You may not apply legal terms or technological measures that
legally restrict others from doing anything the license permits.
*/

#SingleInstance 
#Requires AutoHotkey v2.0

;@Ahk2Exe-SetVersion     0.2.0
;@Ahk2Exe-SetMainIcon    res\lightbulbpencil6.ico
;@Ahk2Exe-SetProductName ClipHistory
;@Ahk2Exe-SetDescription ClipHistory Suggestor

#include <sift>
#include <MRU>
#Include <HotKeys>
#include <NotifyV2>
#Include <ScriptObject\ScriptObject>

script := {
	        base : ScriptObj(),
	     version : '0.1.0',
	      author : '',
	       email : '',
	     crtdate : '',
	     moddate : '',
	   resfolder : A_ScriptDir "\res",
	    iconfile : 'mmcndmgr.dll' , ;A_ScriptDir "\res\UltimateSpybg512.ico",
	      config : A_ScriptDir "\settings.ini",
	homepagetext : "the-automator.com/AutoSuggester",
	homepagelink : "the-automator.com/AutoSuggester?src=app",
}

#include <ConfigGui>
Notify.Default.HDText := "AutoSuggester"
Notify.Default.BDFontSize := 18
Notify.Default.BDFont := 'Arial Black'

TraySetIcon A_ScriptDir '\Res\lightbulbpencil6.ico'

; 1) suggeset Recent Files checkbox (MRU)

; todo add DL to fuzzy match 
; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=39112&p=182567&hilit=fuzzy#p182567


MaxResults := 10 ;maximum number of results to display
MinChar := 3 ; minimer characters after suggestion triggers 
OffsetX := 8 ;offset in caret position in X axis
OffsetY := 16 ;offset from caret position in Y axis
FontName := 'Book Antiqua'
FontSize := 12 ; suggestion size calculated by font size and and works fine with different DPIs tested on 125% 150%
SuggestTriggerKeys := '{enter}'
LVS_NOSCROLL := 0x2000 
VScroll := 0x200000

script.hwnd := ConfigGui.hwnd

tray := A_TrayMenu
tray.Delete()
tray.Add("About",(*) => Script.About())
;tray.Add("Donate",(*) => Run(script.donateLink))
tray.Add()
tray.Add('Run with Start up',RunwithStartup)
if autostartup := IniRead(script.config,'Auto','Startup',false)
	tray.check('Run with Start up')
script.Autostart(autostartup+0)
tray.Add('On/Off Toggle                   Ctrl+Shift+a',onofftoggle)
tray.Check('On/Off Toggle                   Ctrl+Shift+a')
tray.Add('Convert many Lines to 1  Ctrl+Shift+p',onofftoggle)

tray.Add('Settings' , (*) => ConfigGui.show())
tray.default := "Settings"
tray.ClickCount := 1 ; how many clicks (1 or 2) to trigger the default action above
tray.Add()
tray.AddStandard()

; Listview
main := Gui('-Caption +ToolWindow +AlwaysOnTop +LastFound')
main.oldHwnd := 0
main.SetFont('s' FontSize,FontName)
LV := main.AddListView('x0 y0 -HDR AltSubmit' ,['suggestion'])
LV.SetFont('s' FontSize)

main.MarginX := main.MarginY := 0
LV.OnEvent('ItemSelect',SkipFirstSuggestions)
main.Show('hide') 

Prompt := InputHook('V')
Prompt.OnChar := CheckPrompt
Prompt.Start()

DllCall 'RegisterShellHookWindow', 'UInt', Main.hwnd
MsgNum := DllCall('RegisterWindowMessage', 'Str','SHELLHOOK')
OnMessage(MsgNum, changeWinfocus)

RunwithStartup(*)
{
	Global autostartup
	script.Autostart(autostartup := !autostartup)
	IniWrite(autostartup,script.config,'Auto','Startup')
	tray.ToggleCheck('Run with Start up')
}


SkipFirstSuggestions(ctrl, index, selected)
{
	if index = 1
	{
		LV.Modify(1,'-select -focus')
		LV.Modify(2,'+select +focus')
	}
}

onofftoggle(*)
{
	ConfigGui.Toggle := !ConfigGui.Toggle
	switch ConfigGui.Toggle
	{
		Case 1: 
			ToggleOn.value := 1
			ToggleOff.value := 0
			tray.check('On/Off Toggle                   Ctrl+Shift+a')
			Prompt.start() ; start input hook
			Notify.show({BDText:'On',HDFontColor:'Green'})
		Case 0:
			ToggleOn.value := 0
			ToggleOff.value := 1
			tray.Uncheck('On/Off Toggle                   Ctrl+Shift+a')
			Prompt.stop() ; stop input hook
			main.hide()   ; hide suggetion
			LV.Delete()   ; reset suggetion list
			Notify.show({BDText:'Off',HDFontColor:'Red'})
	}
}

changeWinfocus(wParam, lParam, msg, hwnd)
{
	static WS_VISIBLE := 0x10000000
	static WM_ACTIVATE := 49193
	switch msg
	{
		Case WM_ACTIVATE: ; activated window
			if  WinGetStyle(main) & WS_VISIBLE
			&& !WinActive(main)
			{
				hideSuggest()
			}
		Default: return
	}
}

; SetTimer GetSuggestion, 400 ; watching inputhook
CheckPrompt(Prompt, Char)
{
	static searching := false
	static WS_VISIBLE := 0x10000000 
 	Critical 'on'

	; DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
	; DllCall("QueryPerformanceCounter", "Int64*", &CounterBefore := 0)
	if Prompt.Input ~= '^\s'
	|| Prompt.Input ~= '^\t'
	{
		hideSuggest(true)
		return
	}

	switch Char
	{
	case '`n',Chr(27):
		hideSuggest()
	default:
		if StrLen(Prompt.Input) < MinChar
		&& WinGetStyle(main) & WS_VISIBLE = false
		{
			OutputDebug 'less than 3 and not visible`n'
			return
		}

		if Prompt.Input = ""
		{
			hideSuggest()
			return
		}

		try ; this try statement avoids catastrophic backtracking if the string is too long
		{
			if  !result := BuildResult()
			{
				hideSuggest(Prompt.Input ~= '\s$'?true:false)
				return
			}
		}
		catch
		{
			hideSuggest(false)
			return
		}

		BuildLV(Result)
		;main.Show('NA') 
		;if WinGetStyle(main) & WS_VISIBLE = false
		if Prompt.Input ~= '\s\s$'
			hideSuggest(true)
		else
			ShowSuggest()
		LV.LastTitle := WinExist("A")
		; DllCall("QueryPerformanceCounter", "Int64*", &CounterAfter := 0)
		; OutputDebug "Elapsed QPC time is " . (CounterAfter - CounterBefore) / freq * 1000 " ms`n"
		;Critical 'off'
	}
}

BuildResult()
{
	Critical 'on'
	result := ''
	for i, Filename in ListArray
	{
		if ListsEnabled[FileName]
		&& SuggessionsList.has(FileName)
			result .= Sift_Regex(SuggessionsList[FileName],Prompt.Input, ConfigGui.Options)
		else if ListsEnabled[FileName]        ; rare condition when
		&& !SuggessionsList.has(FileName)     ; user restores txt file and enables it  in wordLV
		&& FileExist(WordListFiles[FileName]) ; then we have to create SuggessionsList
		{
			SuggessionsList[FileName] := FileRead(WordListFiles[FileName],'utf-8')
			result .= Sift_Regex(SuggessionsList[FileName],Prompt.Input, ConfigGui.Options)
		}
	}
	return Trim(result)
}

BuildLV(Result)
{
	LV.Opt('-redraw')
	LV.Delete()
	i := 1
	main.MaxStrLen := 0
	main.MaxStr := ""
	LV.Add(,Prompt.input)
	for index, str in StrSplit(Result,'`n','`r')
	{
		if a_index > MaxResults
			break
		if main.MaxStrLen < StrLen(str)
		{
			main.MaxStr := str
			main.MaxStrLen := StrLen(str)
		}
		LV.Add(,StrReplace(str,'`t',' '))
		++i
	}
	LV.ModifyCol(1, 'Auto')
	LV.Opt('+redraw')
	return i 
}

ShowSuggest()
{
	if Prompt.Input = ""
		return
	OutputDebug Prompt.Input '`n' main.MaxStr '`n'
	rows := LV.GetCount()
	width := TextWidth(main.MaxStr,FontName,FontSize) + 30
	LV.Move(0,0, width > 900 ? width := 900 : width, Height := Round(rows * FontSize * ( rows>=5 ? 2.07: 3))) ; main.MaxStrLen * FontSize * 0.71 + 24
	CoordMode 'Caret', 'Screen'
	CaretGetPos(&x,&y)
	OutputDebug 'caret: ' x ' ' y '`n'
	if x && y
	{
		OutputDebug 'widthxheight: ' width 'x' Height '`n'
	}
	else
	{
		CoordMode 'mouse', 'Screen'
		MouseGetPos(&x,&y)
		OutputDebug 'mouse: ' x ' ' y '`n'
		OutputDebug 'width: ' width '`n'
	}
	CorrectPos(x,y+OffsetY,width,Height,OffsetX,OffsetY)
}

CorrectPos(x,y,w,h:=0,offsetx:=8,offsety:=8)
{
	static TPM_WORKAREA := 0x10000

	windowRect := Buffer(16), windowSize := windowRect.ptr + 8
	
	; resizing window for DLLCall 
	main.Show('hide x' x  + OffsetX ' y' y + OffsetY  ' w' w ' h' h )
	DllCall("GetClientRect", "ptr", main.hwnd, "ptr", windowRect)
	CoordMode 'Caret', 'Screen'
	;MouseGetPos &x, &y

	; ToolTip normally shows at an offset of 16,16 from the cursor.
	anchorPt := Buffer(8)
	NumPut "int", x+offsetx, "int", y+offsety, anchorPt

	; Avoid the area around the mouse pointer.
	excludeRect := Buffer(16)
	NumPut "int", x-offsetx, "int", y-offsety, "int", x+offsetx, "int", y+offsety, excludeRect

	; Windows 7 permits overlap with the taskbar, whereas Windows 10 requires the
	; tooltip to be within the work area (WinMove can subvert that, so this is just
	; for consistency with the normal behaviour).
	outRect := Buffer(16)
	DllCall "CalculatePopupWindowPosition",
		"ptr" , anchorPt,
		"ptr" , windowSize,
		"uint", VerCompare(A_OSVersion, "6.2") < 0 ? 0 : TPM_WORKAREA, ; flags
		"ptr" , excludeRect,
		"ptr" , outRect

	x := NumGet(outRect, 0, 'int')
	y := NumGet(outRect, 4, 'int')
	
	OutputDebug 'corrected: ' x ' ' y '`n'
	main.Show('NoActivate x' x ' y' y ' w' w ' h' h )

}


hideSuggest(restartinput:=1)
{
	main.hide()
	LV.Delete()
	if restartinput
	{
		Prompt.stop()
		Prompt.start()
	}
}

getCurrentDisplayPathByMouse()
{
	CoordMode("Mouse","Screen")
	MouseGetPos(&mx,&my)
	Loop MonitorGetCount()
	{
		MonitorGet(a_index, &Left, &Top, &Right, &Bottom)
		if (Left <= mx && mx <= Right && Top <= my && my <= Bottom)
			Return MonitorGetName(a_index) ; DisplayPath[MonitorGetName(a_index)]
	}
	Return 1
}


TextWidth(String,Typeface,Size)
{
    static hDC, hFont := 0, Extent
	OutputDebug String '`n' main.MaxStr  '`n' Typeface " " Size "`n" 
    If !hFont
    {
        hDC := DllCall("GetDC","UPtr",0,"UPtr")
        Height := -DllCall("MulDiv","Int",Size,"Int",DllCall("GetDeviceCaps","UPtr",hDC,"Int",90),"Int",72)
        hFont := DllCall("CreateFont","Int",Height,"Int",0,"Int",0,"Int",0,"Int",400,"UInt",False,"UInt",False,"UInt",False,"UInt",0,"UInt",0,"UInt",0,"UInt",0,"UInt",0,"Str",Typeface)
        hOriginalFont := DllCall("SelectObject","UPtr",hDC,"UPtr",hFont,"UPtr")
		Extent := Buffer(8)
    }
    DllCall("GetTextExtentPoint32","Ptr",hDC,"Str",String,"Int",StrLen(String),"Ptr",Extent)
    Return NumGet(Extent,0,'Int')
}