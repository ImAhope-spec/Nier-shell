
local nested      = os.getenv("NIER_NESTED") == "1"
local home        = os.getenv("HOME") or ""
local shellDir    = os.getenv("NIER_SHELL") or (home .. "/.config/quickshell/nier")

local mainMod     = nested and "ALT" or "SUPER"
local terminal    = "kitty"
local fileManager = "dolphin"
local browser     = "firefox"

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1.25",     -- как в твоём старом конфиге ("auto" давал 1.6)
})

local barsPath = home .. "/.local/share/nier-shell/nierbars.so"
local barsFile = io.open(barsPath, "r")
local barsEnabled = io.open(home .. "/.local/share/nier-shell/nierbars.enable", "r")
local useBars     = barsFile ~= nil and os.getenv("NIER_NO_BARS") ~= "1" and (nested or barsEnabled ~= nil)
if barsFile then barsFile:close() end
if barsEnabled then barsEnabled:close() end

local barsConfigured = false
local function setupBars()
    if not useBars or barsConfigured or hl.plugin == nil or hl.plugin.hyprbars == nil then return end
    barsConfigured = true

    hl.config({
        plugin = {
            hyprbars = {
                enabled                    = true,
                bar_height                 = 30,
                bar_color                  = 0xff4a4640,      -- ink
                col                        = { text = 0xffe8e4cf },   -- hudText
                bar_text_font              = "Jost",
                bar_text_size              = 13,
                bar_text_align             = "left",
                bar_padding                = 10,
                bar_button_padding         = 8,
                bar_buttons_alignment      = "right",
                bar_part_of_window         = true,
                bar_precedence_over_border = false,
                bevel_size                 = 14,              -- размер среза углов, px (0 = без среза)
                button_bevel               = -1,
                footer_height              = 14,
                square_buttons             = true,            -- квадратные кнопки
                on_double_click            = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
            },
        },
    })

    -- кнопки (справа налево): закрыть, развернуть
    hl.plugin.hyprbars.add_button({
        bg_color = 0xffe8e4cf, fg_color = 0xff4a4640, size = 18, icon = "×",
        action = "hyprctl dispatch 'hl.dsp.window.close()'",
    })
    hl.plugin.hyprbars.add_button({
        bg_color = 0xff8c8772, fg_color = 0xff4a4640, size = 18, icon = "□",
        action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
    })
end

if useBars then
    hl.plugin.load(barsPath)
    setupBars()
end

hl.on("hyprland.start", function()
    setupBars()
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("sh -c 'd=\"$HOME/.local/state/nier-shell\"; mkdir -p \"$d\"; [ -f \"$d/qs.log\" ] && mv -f \"$d/qs.log\" \"$d/qs.prev.log\"; exec qs -p " .. shellDir .. " > \"$d/qs.log\" 2>&1'")
    if not nested then
        hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    end
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 24,
        border_size = 2,
        col = {
            active_border   = "rgba(4a4640ff)",   -- ink
            inactive_border = "rgba(8c877299)",   -- inkSoft
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 0,                     -- NieR: прямые углы
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = false },
        blur   = { enabled = false },
    },

    animations = { enabled = true },

    xwayland = { force_zero_scaling = true },

    dwindle = { preserve_split = true },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        allow_session_lock_restore = true,
        key_press_enables_dpms = true,       -- экран включается от клавиши и мыши
        mouse_move_enables_dpms = true,   -- если lock-клиент упадёт, можно запустить новый
        background_color         = 0xffb5b09a,    -- пока без обоев
    },

    input = {
        kb_layout    = nested and "us" or "us,ru",
        kb_options   = nested and "" or "grp:alt_shift_toggle",   -- ALT + SHIFT: us/ru
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = { natural_scroll = false },
    },
})

-- Быстрые плоские анимации, без пружин
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},    {1, 1}    } })

hl.animation({ leaf = "global",     enabled = true, speed = 10,  bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,   bezier = "easeOutQuint", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2,   bezier = "linear",       style = "popin 92%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,   bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layers",     enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "fade" })

-- Свайп тремя пальцами: воркспейсы (тачпад)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Игнорировать запросы maximize от приложений
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.bind(mainMod .. " + Q",         hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))

hl.bind(mainMod .. " + SPACE",             hl.dsp.global("nier:launcher"))
hl.bind(mainMod .. " + R",                 hl.dsp.global("nier:launcher"))
hl.bind(mainMod .. " + S",                 hl.dsp.global("nier:control"))
hl.bind(mainMod .. " + SHIFT + V",         hl.dsp.global("nier:control"))
hl.bind(mainMod .. " + SHIFT + O",         hl.dsp.global("nier:media"))
hl.bind(mainMod .. " + SHIFT + P",         hl.dsp.global("nier:power"))
hl.bind(mainMod .. " + SHIFT + X",         hl.dsp.global("nier:dnd"))
hl.bind(mainMod .. " + SHIFT + W",         hl.dsp.global("nier:wallpaper"))
hl.bind(mainMod .. " + V",                 hl.dsp.global("nier:clipboard"))
hl.bind(mainMod .. " + T",                 hl.dsp.global("nier:tray"))
hl.bind(mainMod .. " + comma",             hl.dsp.global("nier:settings"))
hl.bind(mainMod .. " + SHIFT + BACKSPACE", hl.dsp.global("nier:settings"))

hl.bind(mainMod .. " + SHIFT + L", hl.dsp.global("nier:lock"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(
    "sh -c 'mkdir -p ~/Pictures/Screenshots; f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png; grim -g \"$(slurp)\" \"$f\" && wl-copy < \"$f\"'"))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("hyprctl kill"))   -- kill mode: клик по окну
hl.bind(mainMod .. " + M",         hl.dsp.exit())

hl.bind(mainMod .. " + C",         hl.dsp.window.close())
hl.bind(mainMod .. " + F",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

hl.bind("CTRL + SHIFT + left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
hl.bind("CTRL + SHIFT + right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
hl.bind("CTRL + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
hl.bind("CTRL + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

-- Мышь: перетаскивание и ресайз
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }))

-- Мультимедиа-клавиши. OSD громкости и яркости будет рисовать шелл сам.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),         { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),        { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),      { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.global("nier:brightnessup"),   { locked = true, repeating = true })   -- OSD рисует шелл
hl.bind("XF86MonBrightnessDown", hl.dsp.global("nier:brightnessdown"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
