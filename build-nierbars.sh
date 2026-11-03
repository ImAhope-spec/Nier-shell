#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/plugin/nierbars"
OUT="$HOME/.local/share/nier-shell"

command -v pkg-config >/dev/null || { echo "Нужен pkg-config (sudo pacman -S pkgconf)"; exit 1; }
command -v g++ >/dev/null        || { echo "Нужен g++ (sudo pacman -S gcc)"; exit 1; }
if ! pkg-config --exists hyprland; then
  echo "Не найдены заголовки Hyprland. Выполни: hyprpm update  (он поставит заголовки под твою версию)"; exit 1
fi

echo "Заголовки Hyprland: $(pkg-config --modversion hyprland)"
echo "Исходники плагина сняты с: $(head -n1 "$SRC/BASE-HYPRLAND.txt")"
mkdir -p "$OUT"
rm -f "$SRC/nierbars.so"
VARIANT=""

if [ "${NIER_FOOTER:-1}" = "1" ]; then
  LOG="$OUT/build-footer.log"
  echo "Собираю вариант с нижней планкой..."
  if make -C "$SRC" all NIER_DEFS="-DNIER_FOOTER" >"$LOG" 2>&1; then
    VARIANT="с нижней планкой"
  else
    echo "Не удалось собрать вариант с нижней планкой (полный лог: $LOG). Последние строки:"
    tail -n 15 "$LOG"
    echo "Собираю обычный вариант (только заголовок)..."
    rm -f "$SRC/nierbars.so"
  fi
fi

if [ -z "$VARIANT" ]; then
  if make -C "$SRC" all >"$OUT/build.log" 2>&1; then
    VARIANT="только заголовок"
  else
    echo "Сборка не удалась. Полный лог: $OUT/build.log"; tail -n 25 "$OUT/build.log"; exit 1
  fi
fi

cp "$SRC/nierbars.so" "$OUT/nierbars.so"
echo "$VARIANT" > "$OUT/nierbars.variant"
echo "Готово ($VARIANT): $OUT/nierbars.so"
echo "Дальше: bash run-nested.sh (проверка во вложенном окне)."
echo "Если всё хорошо и вложенное окно не падает, включи плагин в основной сессии:  touch $OUT/nierbars.enable"
echo "Выключить: rm $OUT/nierbars.enable"
