#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "Будет установлено из: $ROOT"
read -r -p "Продолжить? [y/N] " ans
[[ "${ans:-}" =~ ^[yY]$ ]] || { echo "Отменено."; exit 1; }

bash "$ROOT/build.sh"

mkdir -p "$HOME/.config/quickshell" "$HOME/.config/hypr/nier" "$HOME/.local/bin"
ln -sfn "$ROOT/shell" "$HOME/.config/quickshell/nier"
ln -sfn "$ROOT/session/hyprland.lua" "$HOME/.config/hypr/nier/hyprland.lua"

cat > "$HOME/.local/bin/nier-session" <<EOS
#!/bin/sh
exec start-hyprland -- --config "$HOME/.config/hypr/nier/hyprland.lua"
EOS
chmod +x "$HOME/.local/bin/nier-session"

sudo tee /usr/share/wayland-sessions/nier.desktop >/dev/null <<EOS
[Desktop Entry]
Name=NieR Shell
Comment=Hyprland + NieR:Automata shell
Exec=$HOME/.local/bin/nier-session
Type=Application
DesktopNames=Hyprland
EOS

echo "Готово. Выйди из сессии и выбери \"NieR Shell\" в SDDM."
