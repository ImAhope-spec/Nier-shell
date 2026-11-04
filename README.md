# nier-shell

**English** | [Русский](README.ru.md)

A NieR: Automata-style shell for Hyprland: HUD, notifications, launcher, media player, lock screen, wallpaper manager, and power menu. Built with Quickshell; the Hyprland session is configured in Lua.

[![HUD](screenshots/hud.png)](screenshots/hud.png)

## What's inside

- `shell/` — the shell itself (QML, shaders)
- `session/hyprland.lua` — session config (Hyprland 0.56)
- `plugin/` — the `nierbars` plugin (window title bars with cut corners, a patch on top of hyprbars)
- `install.sh`, `build.sh`, `run-nested.sh` — installation, shader and plugin build scripts

See [hotkeys.md](hotkeys.md) for the full list of keybindings.

## Dependencies

Hyprland 0.56, Quickshell, `qt6-shadertools` (qsb), `cliphist`, `wl-clipboard`, `brightnessctl`, NetworkManager (`nmcli`), PipeWire.

## Installation

```
git clone <repo> && cd nier-shell
bash install.sh
```

The window plugin is built separately (`bash build-nierbars.sh`); see `plugin/README.md` for details. The compiled `.so` is tied to the Hyprland version, so it is not included in the repository.

## Settings

Options live in `shell/Theme.qml`. Lock mode on sleep, `lockWhen`:

- `"after"` — a placeholder is shown before sleep, and the lock appears after wake-up
- `"before"` — lock before sleep (more reliable, but on some systems input freezes after wake-up)

## Known issues

<!-- TODO: the "Known issues" section was empty in the version I could see; paste the original content here -->
