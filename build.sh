#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/shell/shaders"
for c in qsb qsb6 qsb-qt6 /usr/lib/qt6/bin/qsb; do
  if command -v "$c" >/dev/null 2>&1; then QSB="$c"; break; fi
done
: "${QSB:?qsb не найден: sudo pacman -S qt6-shadertools}"

fail=0
for f in crt.frag map.frag; do
  if [ ! -f "$f" ]; then echo "[шейдер] нет файла $f"; fail=1; continue; fi
  if "$QSB" --qt6 -o "$f.qsb" "$f"; then
    echo "[шейдер] $f -> $f.qsb"
  else
    echo "[шейдер] ОШИБКА в $f. Первые строки файла:"; head -n 6 "$f"; fail=1
  fi
done

for f in *.frag; do
  case "$f" in crt.frag|map.frag) ;; *) echo "[шейдер] лишний файл $f (игнорируется)";; esac
done
[ "$fail" = 0 ] && echo "shaders built" || { echo "shaders FAILED"; exit 1; }
