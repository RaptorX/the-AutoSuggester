#HotIf !WinActive(main)
&& prompt.Input
&& LV.GetCount()
Down::
up::
{
	LV.Modify(2,'+select +focus')
	main.show()

}

#HotIf !WinActive(main)
&& prompt.Input
~backspace::CheckPrompt(Prompt, 'BS')

~*Lbutton::
~*Rbutton::
~^BackSpace::
~*Left::
~*Right::
~*Home::
~*End::
~*Enter::
~*Tab::
{
	hideSuggest()
}

#HotIf WinActive(main) ;LV.Visible
Enter::
NumpadEnter::
Tab::
{
	send '{enter up}'
	send '{control up}'
	send '{shift up}'

	Prompt.stop()
	row := LV.GetNext(0,'F')
	
	clipsave := A_Clipboard
	A_Clipboard := ''
	A_Clipboard := InputNewLInes(LV.GetText(row,1)) . ' ' 
	if !ClipWait(1)
		msgbox 'unable to set clicpboard'

	main.hide()
	LV.Delete()
	if !row
	{
		Prompt.Start()
		return
	}
	WinActivate(LV.LastTitle) ; waiting for last active title 
	WinWaitActive(LV.LastTitle,,5)
	; This 15ms delay fixes issues with notepad and MS Office programs
	; because they process every keystroke and when backspacing
	; they dont receive the paste command below
	SetKeyDelay 20
	SendEvent '{BS ' StrLen(RegexReplace(Prompt.input, "\R+")) '}'
	sleep 20
	Send '^v'

	sleep 500
	A_Clipboard := clipsave
	Prompt.Start()
}

InputNewLInes(str) ; '¶'
{
	return str := StrReplace(str,'¶','`n')
}

~Esc::
~BackSpace::
{
	hideSuggest()
}
#Hotif

SingleLine(*) ;Send '{U+B6}' ;PILCROW sign / paragraph mark
{
	clipsave := A_Clipboard
	A_Clipboard := ''
	send '^c'
	if !ClipWait(1)
		return msgbox('clipboard: copy failed')
	changeclineReturns()
	send '^v'
	sleep 100
	A_Clipboard := clipsave
}

changeclineReturns(sep:='¶')
{
	str := StrReplace(A_Clipboard,'`r')
	A_Clipboard := StrReplace(str,'`n',' ' sep)
}

AddtoWordlist(*)
{
	send '{ctrl up}'
	send '{shift up}'
	clipsave := A_Clipboard
	A_Clipboard := ''
	send '^c'
	if !ClipWait(1)
		return msgbox('clipboard: copy failed')
	InsertWordtoDefaultList(A_Clipboard)
	sleep 100
	A_Clipboard := clipsave
}

InsertWordtoDefaultList(words)
{
	static WordListDir := A_ScriptDir '\WordLists'
	static DefaultList := WordListDir '\DefaultWordList.txt'
	if !FileExist(WordListDir)
		DirCreate(WordListDir)
	fileobj := FileOpen(DefaultList, "a-w",'utf-8')
	for index, word in StrSplit(words,'`n','`r')
	{
		if !word
			continue
		if InStr(FileRead(DefaultList,'utf-8'),word)
		{
			Notify.show('word "' word '" already exist in Default Word List' )
			continue
		} 
		fileobj.WriteLine(Trim(word))
	
	}
	Notify.show({HDtext:'Following Added to the Default List',BDText:words})
	fileobj.Close()
	AddTxtFile([DefaultList])

	WordLV.Modify(1,'+check')
	ListsEnabled['DefaultWordList'] := 1
}

