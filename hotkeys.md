# nier-shell hotkeys (Hyprland)

**English** | [Русский](hotkeys.ru.md)

`Mod` = **SUPER** in a regular session and **ALT** when running in nested mode (`NIER_NESTED=1`).

## Applications

| Shortcut          | Action                  |
|-------------------|-------------------------|
| `Mod + Q`         | Terminal (kitty)        |
| `Mod + Shift + T` | Terminal (kitty)        |
| `Mod + E`         | File manager (dolphin)  |

## Shell panels (quickshell)

| Shortcut                  | Action            |
|---------------------------|-------------------|
| `Mod + Space`             | Launcher          |
| `Mod + R`                 | Launcher          |
| `Mod + S`                 | Control panel     |
| `Mod + Shift + V`         | Control panel     |
| `Mod + Shift + O`         | Media             |
| `Mod + Shift + P`         | Power menu        |
| `Mod + Shift + X`         | Do Not Disturb    |
| `Mod + Shift + W`         | Wallpapers        |
| `Mod + V`                 | Clipboard history |
| `Mod + T`                 | Tray              |
| `Mod + ,`                 | Settings          |
| `Mod + Shift + Backspace` | Settings          |

## System

| Shortcut          | Action                                                                                          |
|-------------------|-------------------------------------------------------------------------------------------------|
| `Mod + Shift + L` | Lock screen                                                                                     |
| `Mod + Shift + S` | Region screenshot (grim + slurp), saved to `~/Pictures/Screenshots` and copied to the clipboard |
| `Mod + Shift + K` | Kill mode: clicking a window kills its process                                                  |
| `Mod + M`         | Exit Hyprland                                                                                   |

## Windows

| Shortcut                     | Action                                                  |
|------------------------------|---------------------------------------------------------|
| `Mod + C`                    | Close window                                            |
| `Mod + F`                    | Toggle floating                                         |
| `Mod + Shift + F`            | Fullscreen                                              |
| `Mod + P`                    | Pseudo mode (dwindle)                                   |
| `Mod + J`                    | Change split direction (togglesplit)                    |
| `Mod + ←/→/↑/↓`              | Move focus                                              |
| `Mod + Shift + ←/→/↑/↓`      | Move window                                             |
| `Ctrl + Shift + ←/→/↑/↓`     | Resize window by 40 px (repeats while held)             |
| `Mod + LMB` (drag)           | Move window                                             |
| `Mod + RMB` (drag)           | Resize window                                           |

Double-clicking a window title bar (hyprbars) maximizes/restores the window.

## Workspaces

| Shortcut                        | Action                                    |
|---------------------------------|-------------------------------------------|
| `Mod + 1…9, 0`                  | Go to workspace 1–10 (`0` = 10)           |
| `Mod + Shift + 1…9, 0`          | Move window to workspace 1–10             |
| `Mod + scroll down`             | Next workspace                            |
| `Mod + scroll up`               | Previous workspace                        |
| ``Mod + ` ``                    | Show/hide the `magic` special workspace   |
| ``Mod + Shift + ` ``            | Move window to `special:magic`            |
| Three-finger horizontal swipe   | Switch workspaces (touchpad)              |

## Keyboard layout

| Shortcut      | Action                                         |
|---------------|------------------------------------------------|
| `Alt + Shift` | Switch us / ru (outside nested mode only)      |

## Multimedia keys

These also work on the lock screen.

| Key                                | Action                          |
|------------------------------------|---------------------------------|
| `XF86AudioRaiseVolume`             | Volume +5% (max 100%)           |
| `XF86AudioLowerVolume`             | Volume −5%                      |
| `XF86AudioMute`                    | Mute/unmute audio               |
| `XF86AudioMicMute`                 | Mute/unmute microphone          |
| `XF86MonBrightnessUp`              | Brightness + (OSD drawn by the shell) |
| `XF86MonBrightnessDown`            | Brightness − (OSD drawn by the shell) |
| `XF86AudioPlay` / `XF86AudioPause` | Play/Pause (playerctl)          |
| `XF86AudioNext`                    | Next track                      |
| `XF86AudioPrev`                    | Previous track                  |
