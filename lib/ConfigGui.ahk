#Requires AutoHotkey v2.0
MRUListMap := Map(

	'•MRU Recent'       , 'Recently Opened Files and folders'            ,
	'•MRU Open/Save'    , 'Recently Open/Save Dialog Box Entries'        ,
	'•MRU Run'          , 'Recently Run-Dialog Box Entries'              ,
	'•MRU Explorer Path', 'Recently Typed Paths in Explorer Address Bar' ,
	'•MRU Search'       , 'Recent Search Terms'                          ,
)
; AutoSuggester Settings / Config Gui
; ConfigGui.AddRadio( ' h20 +Center', 'FUZZY').OnEvent('click',Radio)
; ConfigGui.AddRadio( 'x10 h20 +Center', 'ORDERED CHARACTERS').OnEvent('click',Radio)
; ConfigGui.AddRadio( 'x10 h20 +Center', 'UNORDERED CHARACTERS').OnEvent('click',Radio)
; ConfigGui.AddRadio( 'x10 h20 +Center', 'ORDERED WORDS').OnEvent('click',Radio)
; ConfigGui.AddRadio( 'x10 h20 +Center', 'UNORDERED WORDS').OnEvent('click',Radio)
; ConfigGui.AddRadio( 'x10 h20 +Center', 'Ngram').OnEvent('click',Radio)

; *********************** new gui
ConfigGui := Gui('','AutoSuggester:Settings')
ConfigGui.SetFont('norm')
ConfigGui.Options := 'oc' ; filter default option
ConfigGui.Toggle := true  ; onoff  default toggle
ConfigGui.AddGroupBox('w90 h' 26 * 6, 'Search Options')
ConfigGui.AddRadio('xp+10 yp+25 h20 +Center vRadio Checked', 'FUZZY').OnEvent('click',eventhandler)
Radio2 := ConfigGui.AddRadio('h20 +Center ', 'EXACT')
Radio2.OnEvent('click',eventhandler)
Radio3 := ConfigGui.AddRadio('h20 +Center ', '&LEFT')
Radio3.OnEvent('click',eventhandler)
Radio4 := ConfigGui.AddRadio('h20 +Center ', 'R&IGHT')
Radio4.OnEvent('click',eventhandler)

ConfigGui.AddGroupBox('ym x+m+50 w150 h' 24 * 4, 'Parameters')

ConfigGui.AddText('xp+10 yp+20 w60 Section right' ,'Font Size')
ConfigGui.AddComboBox('x+m yp-3 w60 Choose5 vLVFont',[8,9,10,11,12,13,14]).onEvent('change',eventhandler)
ConfigGui.AddText('xs w60 right','Max Results')
ConfigGui.AddComboBox('x+m yp-3 w60 Choose2 vMaxSugCount',[5,10,15,20]).onEvent('change',eventhandler)
ConfigGui.AddText('xs w60 right','Trigger at')
ConfigGui.AddComboBox('x+m yp-3 w60 Choose3 vMinTrigger',['1 Char','2 Chars','3 Chars','4 Chars','5 Chars','6 Chars','7 Chars','8 Chars','9 Chars'])

ConfigGui.AddGroupBox('xs-10 y+m+5 w150 h' 30 * 2, 'Case')
ConfigGui.AddRadio( 'xp+10 yp+20 h12 +Center vCase', 'Case-Sensitive').OnEvent('click',eventhandler)
ConfigGui.AddRadio( 'h12 +Center  Checked', 'Case-Insensitive').OnEvent('click',eventhandler)

ConfigGui.AddGroupBox('ym x+m+50 w300 h' 26 * 6, 'Hotkeys')
ToggleOn := ConfigGui.AddRadio( 'xp+10 yp+25 Section h12 +Center vToggle Checked', 'On')
ToggleOn.OnEvent('click',eventhandler)
ToggleOff := ConfigGui.AddRadio( 'x+m h12 +Center ', 'Off')
ToggleOff.OnEvent('click',eventhandler)

ConfigGui.AddCheckBox("x+m+14 vonoffWK", "Win") ;.onEvent('click',eventhandler)
ConfigGui.AddHotkey( "x+m yp-3 vonoffHK")       ;.onEvent('change',eventhandler)
ConfigGui['onoffWK'].value := IniRead(Script.config,'Hotkeys','onoffWK',0)
ConfigGui['OnoffHK'].value := IniRead(Script.config,'Hotkeys','onoffHK','^+a')

ConfigGui.AddText('xs y+m+10','Add to Default List: ')
ConfigGui.AddCheckBox( "x+m+4 vAddWordWK", "Win") ;.onEvent('click',eventhandler)
ConfigGui.AddHotkey( "x+m yp-3 vAddWordHK")       ;.onEvent('change',eventhandler)
ConfigGui['AddwordWK'].value := IniRead(Script.config,'Hotkeys','AddwordWK',0)
ConfigGui['AddwordHK'].value := IniRead(Script.config,'Hotkeys','AddwordHK','+^Insert')

ConfigGui.AddText('xs y+m+10','Multi to Single Line:')
ConfigGui.AddCheckBox( "x+m+5 vSingleWK", "Win") ;.onEvent('click',eventhandler)
ConfigGui.AddHotkey( "x+m yp-3 vSingleHK")       ;.onEvent('change',eventhandler)
ConfigGui['SingleWK'].value := IniRead(Script.config,'Hotkeys','SingleWK',0)
ConfigGui['SingleHK'].value := IniRead(Script.config,'Hotkeys','SingleHK','+^NumpadAdd')

ConfigGui.AddText('xs y+m+10','Change Search Opt:')
ConfigGui.AddCheckBox( "x+m vSerOptWK", "Win") ;.onEvent('click',eventhandler)
ConfigGui.AddHotkey( "x+m yp-3 vSerOptHK")     ;.onEvent('change',eventhandler)
ConfigGui['SerOptWK'].value := IniRead(Script.config,'Hotkeys','SerOptWK',0)
ConfigGui['SerOptHK'].value := IniRead(Script.config,'Hotkeys','SerOptHK','+^NumpadDot')

PreviousMRUStatus := (IniRead(script.config,'EnableMRU','MRU',false) = true ? '+': '-')

ConfigGui.AddText('xm','Include Word List:  (Double click to open file)')
ConfigGui.AddCheckbox('x+m+90 vMRUCheck ' PreviousMRUStatus 'checked','Include MRU').OnEvent('click',IncludeMRUinLV) ; Include MRU
ConfigGui.SetFont('S12','Courier New')
WordLV := ConfigGui.AddListView('xm r10 w610 checked',['Name','Source'])
Note := ConfigGui.AddText('x50 y250 hidden','Drag and Drop Text files here or use Add button')
WordLV.OnEvent('DoubleClick',WordLV_Doubleclick)
; *********************** new gui end

ConfigGui.SetFont()
ImageListID := IL_Create(2)  ; Create an ImageList to hold 10 small icons.
IL_Add(ImageListID, "shell32.dll", 301)
IL_Add(ImageListID, "shell32.dll", 132)
WordLV.SetImageList(ImageListID)  ; Assign the above ImageList to the current ListView.
IncludeWordlists() ; building WordList LV

ConfigGui.OnEvent('DropFiles',(mainctr,ctl,Filearray,*)=> AddTxtFile(Filearray))
ConfigGui.AddButton('xm w80','Add').OnEvent('click',(*) => AddTxtFile(FileSelect('MS3',,'AutoSuggester:Add WordList','Word Lists (*.txt)')))
DelBtn := ConfigGui.AddButton('x+m w80 disabled','Remove')
DelBtn.OnEvent('click',DelTxtfile)
ConfigGui.AddButton('x+m+260 w80','Apply').OnEvent('click',SetupHotkeys)
ConfigGui.AddButton('x+m w80','Close').OnEvent('click',SaveSetting)

; update inifileabout enabled word txt files
WordLV.OnEvent('ItemCheck',WordLV_ItemCheck)
; enable delbtn incase item selected
WordLV.OnEvent('ItemSelect',(*) => (WordLV.GetNext(0)?DelBtn.Opt('-disabled'):DelBtn.Opt('+disabled')))

if WordLV.GetCount() = 0
{
	WordLV.Opt('+hidden')
	Note.Opt('-hidden')
}

ConfigGui.Show()
; setup hotkeys
SetupHotkeys()


WordLV_ItemCheck(ctrl, Item, Checked)
{
	ConfigGui.Opt('+OwnDialogs +disabled')
	txtName := WordLv.GetText(item)
	source := WordLv.GetText(item,2)

	if !(txtName ~= '^•MRU')
	&& !FileExist(WordListFiles[txtName])
	{
		ctrl.Modify(item,'-check Icon2')
		LisIcon[txtName] := 'Icon2'
		Checked := 0
	}
	else
	{
		ctrl.Modify(item,'Icon1')
		LisIcon[txtName] := 'Icon1'
	}

	if LisIcon[txtName] = 'Icon2'
	{
		ctrl.Modify(item,'-check')
		msgbox 'File does not exist,`n' WordListFiles[txtName] '`n`nPlease restore file or Delete it from the list', 'AutoSuggester: Warning!'
		ListsEnabled[txtName] := 0
		ConfigGui.Opt('-OwnDialogs -disabled')
		; DelBtn.Opt('+disabled')
		return
	}
	ConfigGui.Opt('-OwnDialogs -disabled')
	ListsEnabled[txtName] := Checked
	
	if txtName ~= '^•MRU'
		iniList := 'MRUList'
	else
		iniList := 'EnableWordList'
	IniWrite(Checked,Script.config,iniList,WordLv.GetText(item))
}

AddTxtFile(targets)
{
	ConfigGui.Opt('+OwnDialogs')
	for i, Source in targets
	{
		SplitPath(Source,,,&ext,&FileName)
		if !(ext ~= 'txt|csv|tsv') ; if dropped non txt
		{
			Notify.show({BDText:'File formate ' ext  ' is not supported',HDText:'AutoSuggester: Warning!'})
			continue
		}
		IniWrite(Source,script.config,'Paths',FileName)
	}
	ConfigGui.Opt('-OwnDialogs')
	; rebuild LV
	IncludeWordlists()
}

DelTxtfile(*)
{
	row :=0
	loop
	{
		row := WordLV.GetNext(row)
		if !row
			Break
		txtName := WordLV.GetText(row)
		; delete Wordlist Link
		IniDelete(script.config,'Paths',txtName)
		; Delete file enable or disable
		IniDelete(script.config,'EnableWordList',txtName)
	}
	; rebuild LV
	IncludeWordlists()
	DelBtn.Opt('+disabled')
}

IncludeMRUinLV(*)
{
	if ConfigGui['MRUCheck'].value
	{
		IniWrite(true,script.config,'EnableMRU','MRU')
		;IniWrite(List,script.config,'Paths','MRU')
	}
	else
	{
		IniWrite(false,script.config,'EnableMRU','MRU')
		;IniWrite(List,script.config,'Paths','MRU')
	}
	IncludeWordlists()
}

IncludeWordlists()
{
	global WordListFiles, ListsEnabled, LisIcon, SuggessionsList, ListArray
	WordLV.Delete()
	LisIcon := Map()
	ListsEnabled := Map()
	WordListFiles := Map()
	SuggessionsList := Map()
	ListArray := []
	try Paths := iniread(script.config,'Paths')
	catch{
		; Hide list view and mentioned big text saying drag and drop text files here
		return
	}

	if Defaultlistname := IniRead(Script.config,'Paths','DefaultWordList',0)
	{
		Defaultstatus := IniRead(script.config,'EnableWordList','FileName','unknown')
		Defaultlistpath := A_ScriptDir '\WordLists\DefaultWordList.txt'
		icon := FileExist(Defaultlistpath) ? 'Icon1' : 'Icon2'
		WordLV.Add((Defaultstatus? '+Check': '-Check') ' ' Icon, 'DefaultWordList',Defaultlistpath)
		; ListArray.Push(Defaultlistname)
	}

	for i, iniline in StrSplit(paths,'`n')
	{
		listPath := iniread(script.config,'Paths',StrSplit(iniline,'=')[1],0)
		SplitPath(listPath,,&dir,,&FileName)
		icon := FileExist(listPath) ? 'Icon1' : 'Icon2'
		status := IniRead(script.config,'EnableWordList',FileName,'unknown')
		switch Status
		{
			case 'unknown':
				IniWrite(true,script.config,'EnableWordList',FileName)
				status := true
			case true     :
			case false    :
		}
		if Icon = 'Icon2'
			status := false
		ListArray.Push(FileName)
		LisIcon[FileName] := Icon
		ListsEnabled[FileName] := status
		WordListFiles[FileName] := listPath
		if FileExist(listPath)
			SuggessionsList[FileName] := FileRead(listPath,'utf-8')
		if FileName = 'DefaultWordList'
			continue
		WordLV.Add((status? '+Check': '-Check') ' ' Icon,FileName,listPath)
	}

	; MRU list inclusion
	MRUStatus := IniRead(script.config,'EnableMRU','MRU',false)
	for Name, Purpose in MRUListMap
	{
		if MRUStatus
		{
			status := iniread(script.config,'MRUList',Name,false)
			
			switch Name, 0
			{
				case '•MRU Recent'        : SuggessionsList[Name] := GetRecentDocs()
				case '•MRU Open/Save'     : SuggessionsList[Name] := GetOpenSaveMRU()
				case '•MRU Run'           : 
					if RunMRU := GetRunMru()
						SuggessionsList[Name] := RunMRU
					else
					{
						status := !status
						IniWrite(status,script.config,'MRUList',Name)
						continue
					}
				case '•MRU Explorer Path' : SuggessionsList[Name] := GetTypedPathsMru()
				case '•MRU Search'        : SuggessionsList[Name] := GetSearchMRU()
			}
			ListArray.Push(Name)
			LisIcon[Name] := 'Icon1'
			ListsEnabled[Name] := status
			WordListFiles[Name] := '*MRU'	
			WordLV.Add((status? '+Check': '-Check') ' Icon1',Name,Purpose)
		}
	}
	
	if 	!MRUStatus
	{
		mrurow  := 0
		loop WordLV.GetCount()
		{
			if WordLV.GetText(a_index) ~= '^•MRU'
				WordLV.Delete(a_index)
		}
	}


	WordLV.ModifyCol()
	if WordLV.GetCount() = 0
	{
		WordLV.Opt('+hidden')
		Note.Opt('-hidden')
	}
	else
	{
		WordLV.Opt('-hidden')
		Note.Opt('+hidden')
	}
}

WordLV_Doubleclick(ctrl,info)
{
	; ListViewGetContent is failing  due to non selection on row, sometime clicking deselect row and we get error (see line 164)
	; so we are using focused
	path := ListViewGetContent('focused col2', WordLV)

	;path := WordLV.GetText(info,2) ; also woking
	if !path
	{
		ToolTip('failed due to non selection')
		settimer((*)=>tooltip(),-500)
		return
	}
	path := StrSplit(path,'`n')[1]
	SplitPath(Path,,&dir)
	if GetKeyState('Ctrl','p')
	{
		if FileExist(Path)
			Run(path)
		else
		{
			ToolTip('files does not exist!')
			settimer((*)=>tooltip(),-500)
		}
	}
	else
		Run(Dir)
}


SaveSetting(*)
{
	ConfigGui.Hide()
}

ChangeSearchOpt(*)
{
	Static Select := 'Radio'
	ctrl := ConfigGui.Submit(0)
	Switch(ctrl.Radio)
	{
		Case 1  : 
			Radio2.Value := 1
			ConfigGui.Options := 'OC'
			Option := 'FUZZY'
		Case 2  : 
			Radio3.Value := 1
			ConfigGui.Options := 'IN'
			Option := 'EXACT'
		Case 3  : 
			Radio4.Value := 1
			ConfigGui.Options := 'LEFT'
			Option := 'LEFT'
		Case 4  : 
			ConfigGui['Radio'].Value := 1
			ConfigGui.Options := 'RIGHT'
			Option := 'RIGHT'
	} 
	Notify.show({BDText:Option,HDFontColor: (ConfigGui.Toggle ? 'Green' : 'Red')})
}

/*
onoffWin.value := IniRead(Script.config,'Hotkeys','onoffWK',0)
OnoffHK.value := IniRead(Script.config,'Hotkeys','onoffHK','^+a')
ConfigGui['AddwordWK'].value := IniRead(Script.config,'Hotkeys','AddwordWK',0)
ConfigGui['AddwordHK'].value := IniRead(Script.config,'Hotkeys','AddwordHK','+^Insert')
ConfigGui['SingleWK'].value := IniRead(Script.config,'Hotkeys','SingleWK',0)
ConfigGui['SingleHK'].value := IniRead(Script.config,'Hotkeys','SingleHK','+^NumpadAdd')
*/
SetupHotkeys(*)
{
	ctrl := ConfigGui.Submit()
	getfunc := Map('onoff',onofftoggle,
					'Addword',AddtoWordlist,
					'Single',SingleLine,
					'SerOpt',ChangeSearchOpt)
	for i, current_hk in ['onoff','Addword','Single','SerOpt']
	{

		wk := iniread(Script.config,'Hotkeys',current_hk 'WK',0)
		HK := iniread(Script.config,'Hotkeys',current_hk 'HK',0)
		if WK
			HK := '#' HK
		if HK
			Hotkey HK, getfunc[current_hk], 'OFF'

		if ConfigGui[current_hk 'HK'].value
		{
			if ConfigGui[current_hk 'WK'].value
				HK := '#' ConfigGui[current_hk 'HK'].value
			else
				HK := ConfigGui[current_hk 'HK'].value
			; disableHotkey(onofftoggle,'onoffWK','onoffHK')
			if HK
			{
				IniWrite(ConfigGui[current_hk 'WK'].value,Script.config,'Hotkeys',current_hk 'WK')
				IniWrite(ConfigGui[current_hk 'HK'].value,Script.config,'Hotkeys',current_hk 'HK')
				Hotkey HK, getfunc[current_hk], 'ON'
			}
		}
	}
	Notify.show({BDText:'Hotkeys are set',HDFontColor:'Green'})
}

eventhandler(*)
{
	Global FontSize, MaxResults, MinChar
	ctrl := ConfigGui.Submit(0)
	; SetupHotkeys(ctrl)
	FontSize := ctrl.LVFont
	MaxResults := ctrl.MaxSugCount
	MinChar := RegExReplace(ctrl.MinTrigger,'(\d)(.*)','$1')
	LV.SetFont('s' FontSize)


	; main.SetFont('s' FontSize)
	; LV.Opt('0x2000')
	Switch(ctrl.Radio)
	{
		Case 1  : ConfigGui.Options := 'OC' ; FUZZY
		Case 2  : ConfigGui.Options := 'IN'
		Case 3  : ConfigGui.Options := 'LEFT' ;'LEFT'
		Case 4  : ConfigGui.Options := 'RIGHT'
		; Case 5  : ConfigGui.Options := 'UC' ; Fuzzy
		; Case 6  : ConfigGui.Options := 'OC'
		; Case 7  : ConfigGui.Options := 'UC'
		; Case 8  : ConfigGui.Options := 'OW'
		; Case 9  : ConfigGui.Options := 'UW'
		; Case 10 :
		; 	if (ConfigGui.Options = "NGRAM")
		; 		ConfigGui['Case'].value := 0
		; 	ConfigGui.Options := "NGRAM"
	}
	Switch(ctrl.Case)
	{
		Case 1: ConfigGui.Options := Format('{:U}',ConfigGui.Options)
		Case 2: ConfigGui.Options := Format('{:L}',ConfigGui.Options)
	}


	onofftoggle()
	; Switch(ctrl.Toggle)
	; {
	; 	Case 1:
	; 		ConfigGui.Toggle := true
	; 		Prompt.start() ; start input hook
	; 		tray.check('On/Off Toggle                   Ctrl+Shift+a')
	; 		;Notify.show({BDText:'On',HDFontColor:'Green'})
	; 	Case 2:
	; 		ConfigGui.Toggle := false
	; 		Prompt.stop() ; stop input hook
	; 		main.hide()   ; hide suggetion
	; 		LV.Delete()   ; reset suggetion list
	; 		tray.Uncheck('On/Off Toggle                   Ctrl+Shift+a')
	; 		;Notify.show({BDText:'Off',HDFontColor:'Red'})
	; }
}