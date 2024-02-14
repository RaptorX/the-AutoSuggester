mrumap := map( 
		"General MRU", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
		"Run Dialog MRU", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
		"Typed Paths MRU", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
		"File Dialog MRU", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU",
		"Search MRU", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
	)


GetRecentDocs()
{
	vDirRecent := Buffer(260*2, 0)
	DllCall("shell32\SHGetFolderPath", 'Ptr',0, 'Int',8, 'Ptr',0, 'UInt',0, 'ptr',vDirRecent)
	vDirRecent := StrGet(vDirRecent)
	Path := '' ;[]
	Loop Files, vDirRecent '\*.lnk', 'f'
	{
		try FileGetShortcut(A_LoopFileFullPath,&vTarget)
		catch
			continue

		if !FileExist(vTarget)
		|| InStr(FileExist(vTarget), "D")
			continue

		path .= vTarget '`n' ; Path.Push(vTarget)
	}
	return Trim(Path,'`n')
}

GetSearchMRU()
{
	vDirRecent := Buffer(260*2, 0)
	DllCall("shell32\SHGetFolderPath", 'Ptr',0, 'Int',8, 'Ptr',0, 'UInt',0, 'ptr',vDirRecent)
	vDirRecent := StrGet(vDirRecent)
	vDataList := RegRead(mrumap['Search MRU'],'MRUListEx')
	Searches := '' ; map()
	Loop (StrLen(vDataList)/8) - 1
	{
		vIndex := Format("{:i}", "0x" SubStr(vDataList, A_Index*8-7, 2))
		vData := RegRead(reg := mrumap['Search MRU'],vIndex)
		word := ""
		Loop Round(StrLen(vData) / 4)
		{
			vOffset := (A_Index*4)-3
			vNum := Format("{:i}", "0x" SubStr(vData, vOffset+2, 2) SubStr(vData, vOffset, 2))
			word .= Chr(vNum)
		}
		Searches .= word '`n' ;Searches[reg ',' vIndex] := Trim(word)
	}
	return Trim(Searches,'`n')
}

GetOpenSaveMRU()
{
	Exts := []
	Loop Reg, reg := mrumap['File Dialog MRU'], "K"
	{
		Exts.Push(A_LoopRegName)
	}
	Paths := '' ;map()
	for i, regKey in Exts
	{
		; Loop Reg, mrumap['File Dialog MRU'] '\' regKey
		; 	msgbox A_LoopRegName '`n' A_LoopRegType '`n' A_LoopRegKey '`n<<' regKey '>>'
		if regkey = 'Folder'
			continue
		;Paths[regKey] := GetRegKeys('File Dialog MRU',regKey,'MRUListEx')
		Paths .= GetRegKeys('File Dialog MRU',regKey,'MRUListEx') '`n'
	}
	return Trim(Paths,'`n')
}

GetTypedPathsMru()
{
	;RunList := RegRead(mrumap['Typed Paths MRU'],'MRUList')
	RunList := '' ;Map()
	Loop Reg, reg := mrumap['Typed Paths MRU']
		Runlist .= RegRead(mrumap['Typed Paths MRU'],A_LoopRegName)
		;Runlist[reg ',' A_LoopRegName] := RegRead(mrumap['Typed Paths MRU'],A_LoopRegName)
	return Trim(Runlist,'`n')
}


GetRunMru()
{
	try RunList := RegRead(reg := mrumap['Run Dialog MRU'],'MRUList')
	catch 
		return
	CMDList := '' ;map()
	for index, regkey in StrSplit(RunList)
	{
		str := RegRead(mrumap['Run Dialog MRU'],regkey)
		str := RegExReplace(str, "\\1$")
		;CMDList[reg ',' regkey] := str
		CMDList .= str '`n'
	}
	return Trim(CMDList,'`n')
}


GetRegKeys(Keypath,regKey,KeyName)
{
	vDataList := RegRead(mrumap[Keypath] '\' regKey,KeyName)
	bytes := 8
	HexBytes := 4
	vOutput := ""
	paths := '' ;map()
	Loop (StrLen(vDataList)/bytes) - 1
	{
		vIndex := Format("{:i}", "0x" SubStr(vDataList, A_Index*bytes-7, 2))
		vData := RegRead(reg := mrumap[Keypath] '\' regKey,vIndex)
		vTemp := ''
		Loop Round(StrLen(vData) / HexBytes)
		{
			vOffset := (A_Index*HexBytes)-3
			vNum := Format("{:i}", "0x" SubStr(vData, vOffset+2, 2) SubStr(vData, vOffset, 2))
			vTemp .= Chr(vNum)
		}
		path := Buffer(260*2, 0)
		DllCall("shell32\SHGetPathFromIDListA", 'int', StrPtr(vTemp), 'ptr', path)
		vPath := StrGet(path, 'utf-8')
		;paths[reg ',' vIndex] := vPath
		paths .= vPath '`n'
	}
	return Trim(paths,'`n')
}