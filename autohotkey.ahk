#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Turn off Capslock toggling, key will still work for shortcuts though
SetCapsLockState, AlwaysOff

; Swap Capslock with Ctrl
CapsLock & 1::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{1 Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{1 up}
CapsLock & 2::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{2 Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{2 up}
CapsLock & 3::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{3 Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{3 up}
CapsLock & 4::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{4 Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{4 up}
CapsLock & 5::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{5 Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{5 up}
CapsLock & 6::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{6 Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{6 up}
CapsLock & F::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{F Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{F up}
CapsLock & E::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{E Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{E up}
CapsLock & Z::Send {Shift down}{Ctrl down}{Alt down}{LWin down}{Z Down}{Shift up}{LWin up}{Ctrl up}{Alt up}{Z up}