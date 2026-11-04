# nier-shell

[English](README.md) | **Русский**

Shell для Hyprland в стиле NieR: Automata: HUD, уведомления, лаунчер, плеер, экран блокировки, менеджер обоев, меню питания. Сделан на Quickshell, сессия Hyprland настроена на Lua.

[![HUD](screenshots/hud.png)](screenshots/hud.png)

## Что внутри

- `shell/` — сам шелл (QML, шейдеры)
- `session/hyprland.lua` — конфиг сессии (Hyprland 0.56)
- `plugin/` — плагин `nierbars` (заголовки окон со срезанными углами, патч поверх hyprbars)
- `install.sh`, `build.sh`, `run-nested.sh` — установка, сборка шейдеров и плагина

Полный список хоткеев: [hotkeys.ru.md](hotkeys.ru.md).

## Зависимости

Hyprland 0.56, Quickshell, `qt6-shadertools` (qsb), `cliphist`, `wl-clipboard`, `brightnessctl`, NetworkManager (`nmcli`), PipeWire.

## Установка

```
git clone <repo> && cd nier-shell
bash install.sh
```

Плагин окон собирается отдельно (`bash build-nierbars.sh`), подробности в `plugin/README.md`. Собранный `.so` привязан к версии Hyprland, поэтому в репозитории его нет.

## Настройки

Опции лежат в `shell/Theme.qml`. Режим блокировки при сне, `lockWhen`:

- `"after"` — перед сном показывается заглушка, блокировка поднимается после пробуждения
- `"before"` — блокировка до сна (надёжнее, но на некоторых системах после пробуждения замирает ввод)

## Известные проблемы

<!-- TODO: раздел был пустым в доступной мне версии; вставьте сюда оригинальное содержимое -->
