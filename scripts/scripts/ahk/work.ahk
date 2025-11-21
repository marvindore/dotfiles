#Requires AutoHotKey >=2.0

^#t:: ; Ctrl+Win+t
{
    if not WinExist("ahk_exe wezterm-gui.exe")
        run "C:\Program Files\WezTerm\wezterm-gui.exe"
    WinWait "ahk_exe wezterm-gui.exe"
    WinActivate "ahk_exe wezterm-gui.exe"
}

^#d:: ; Ctrl+Win+d
{
    if not WinExist("ahk_exe datagrip64.exe")
        run "C:\Program Files (x86)\JetBrains\DataGrip 2023.3\bin\datagrip64.exe"
    WinWait "ahk_exe datagrip64.exe"
    WinActivate "ahk_exe datagrip64.exe"
}
