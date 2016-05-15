#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Turn off Capslock toggling, key will still work for shortcuts though
SetCapsLockState, AlwaysOff

; Swap Capslock with Ctrl
CapsLock::Ctrl

; Size 50% to the left
CapsLock & a::Send #{Left}

; Size 50% to the right
CapsLock & s::Send #{Right}

; Fullscreen
CapsLock & f::Send #{Up}

CapsLock & {Left}::Send +#{Left}

RunOrActivate(Target, WinTitle = "")
{
	; Get the filename without a path
	SplitPath, Target, TargetNameOnly

	Process, Exist, %TargetNameOnly%
	If ErrorLevel > 0
		PID = %ErrorLevel%
	Else
		Run, %Target%, , , PID

	; At least one app (Seapine TestTrack wouldn't always become the active
	; window after using Run), so we always force a window activate.
	; Activate by title if given, otherwise use PID.
	If WinTitle <>
	{
		SetTitleMatchMode, 2
		WinWait, %WinTitle%, , 3
		TrayTip, , Activating Window Title "%WinTitle%" (%TargetNameOnly%)
		WinActivate, %WinTitle%
	}
	Else
	{
		WinWait, ahk_pid %PID%, , 3
		TrayTip, , Activating PID %PID% (%TargetNameOnly%)
		WinActivate, ahk_pid %PID%
	}


	SetTimer, RunOrActivateTrayTipOff, 1500
}

; Turn off the tray tip
RunOrActivateTrayTipOff:
	SetTimer, RunOrActivateTrayTipOff, off
	TrayTip
Return

CapsLock & z::
run,explorer.exe,,max
return

CapsLock & 1::RunOrActivate("devenv.exe")

CapsLock & 2::RunOrActivate("ConEmu64.exe")

CapsLock & 3::RunOrActivate("chrome.exe")
