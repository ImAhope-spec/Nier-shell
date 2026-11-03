# nierbars — заголовки окон со срезанными углами

Патч к плагину **hyprbars** (hyprwm/hyprland-plugins, лицензия BSD-3-Clause), сделанный на исходниках под Hyprland 0.56.2
(коммит плагинов в `nierbars/BASE-COMMIT.txt`).

Что добавлено (весь diff в `nierbars.patch`):
- `plugin:hyprbars:bevel_size` — размер среза верхних углов в px (0 = выключено, поведение как у оригинала).
- `plugin:hyprbars:square_buttons` — квадратные кнопки вместо круглых.
- заголовок рисуется полосками по 1 px с полупрозрачным пикселем на диагонали (сглаживание для угла 45°), только вызовами `renderRect`, которые плагин уже использует.

Ограничения: срезаются **верхние** углы (заголовок). Нижние углы окна Hyprland срезать не умеет.

Сборка и проверка:
```bash
hyprpm update                 # если нет заголовков Hyprland
bash build-nierbars.sh        # собирает ~/.local/share/nier-shell/nierbars.so
bash run-nested.sh            # сначала проверь во вложенном окне!
```
Отключить: `NIER_NO_BARS=1` в окружении или удалить `~/.local/share/nier-shell/nierbars.so`.
После обновления Hyprland плагин нужно пересобрать (`bash build-nierbars.sh`): версии должны совпадать.

## Обновление: выравнивание кнопки и нижняя планка
- `button_bevel` — срез угла крайней кнопки у среза заголовка (`-1` = подобрать автоматически: диагонали параллельны, зазор постоянен).
- `footer_height` — нижняя планка со срезанными нижними углами. Код планки под `#ifdef NIER_FOOTER`: `build-nierbars.sh` сначала собирает с ней и, если не вышло, собирает без неё (в логе `~/.local/share/nier-shell/build-footer.log`).
- Применять `nierbars.patch` вручную не нужно: исходники в `plugin/nierbars/` уже пропатчены. Если захочешь применить к чистому hyprbars:
  `cd <папка hyprbars> && patch -p1 < nierbars.patch`.

## Включение в основной сессии
Плагин работает внутри Hyprland, поэтому ошибка в нём может уронить всю сессию. Поэтому:
1. `bash build-nierbars.sh`, затем `bash run-nested.sh` — плагин грузится во вложенном окне; если что-то не так, падает только оно.
2. Если всё в порядке, включи его в основной сессии: `touch ~/.local/share/nier-shell/nierbars.enable`.
3. Выключить: `rm ~/.local/share/nier-shell/nierbars.enable` (или `NIER_NO_BARS=1`).
Отчёты о падениях Hyprland лежат в `~/.cache/hyprland/`.
