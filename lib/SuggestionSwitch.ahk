#Requires AutoHotkey v2.0

; suggestion Switch Gui will follow the mouse and indicate auto suggester is on or off
SSGui := Gui('-Caption +AlwaysOnTop')
SSGui.BackColor := 'Green'
SSGui.Show('h4 w4')
SetTimer(followMouse,200)


followMouse(*)
{
	CoordMode 'mouse', 'screen'
	MouseGetPos(&x,&y)
	ssGui.Move(x+10,y+10)
}
