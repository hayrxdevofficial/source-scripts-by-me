--[[ ⚡ GEOMETRY DASH v2 — GUI EDITION ⚡
  • Настоящая физика: блоки-платформы, шипы-треугольники, жёлтые пады
  • Зажатие = авто-прыжок (как в GD), вращение куба в воздухе
  • Параллакс-фон, меняющий цвет, земля с сеткой, частицы, взрыв при смерти
  • Меню с выбором уровня и лучшим результатом (%)
  • Новый уровень GRIEF (EXTREME DEMON) с переключаемым авто-ботом
  Управление: Space / ↑ / W / ЛКМ / тап — прыжок, R — рестарт, Q — в меню, G — достать/убрать Tool
]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local CAS          = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local lp  = Players.LocalPlayer
local pg  = lp:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

-- ID музыки (необязательно): вставь rbxassetid://... если хочешь музыку
local MUSIC_ID = ""

-- ===================== CLEANUP =====================
local env = (getgenv and getgenv()) or _G
if env.__GD_CLEANUP then pcall(env.__GD_CLEANUP) end
local conns = {}
local function keep(c) conns[#conns+1] = c; return c end
env.__GD_CLEANUP = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() CAS:UnbindAction("GD_Jump") end)
    for _, n in ipairs({"GD_Menu","GD_Game"}) do
        local o = pg:FindFirstChild(n); if o then o:Destroy() end
    end
    for _, c in ipairs({lp:FindFirstChild("Backpack"), lp.Character}) do
        if c and c:FindFirstChild("GD_Tool") then c.GD_Tool:Destroy() end
    end
end
env.__GD_CLEANUP()

-- ===================== CONSTANTS =====================
local W, H       = 960, 540
local GROUND_H   = 120
local GROUND_Y   = H - GROUND_H
local T          = 40            -- размер клетки
local PX         = 260           -- экранная X куба
local PS         = 40            -- размер куба
local GRAV       = 3333
local JUMP_V     = 800           -- ~2.4 клетки высоты
local PAD_V      = 1050
local STEP       = 1/120         -- фиксированный шаг физики

local WHITE, BLACK = Color3.new(1,1,1), Color3.new(0,0,0)
local C_PRI = Color3.fromRGB(125,255,0)
local C_SEC = Color3.fromRGB(0,230,255)

-- ===================== HELPERS =====================
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function stroke(o, c, t, tr) return new("UIStroke", {Color = c, Thickness = t, Transparency = tr or 0}, o) end
local function lbl(parent, props)
    local t = new("TextLabel", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Font = Enum.Font.GothamBlack, TextColor3 = WHITE}, parent)
    for k, v in pairs(props) do t[k] = v end
    return t
end
local function btn(parent, props)
    local b = new("TextButton", {BorderSizePixel = 0, AutoButtonColor = true,
        Font = Enum.Font.GothamBlack, TextColor3 = WHITE}, parent)
    for k, v in pairs(props) do b[k] = v end
    return b
end

local function makeGui(name)
    local gui = new("ScreenGui", {Name = name, ResetOnSpawn = false, IgnoreGuiInset = true,
        Enabled = false, DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
    local back = new("Frame", {Size = UDim2.fromScale(1,1), BackgroundColor3 = BLACK, BorderSizePixel = 0}, gui)
    local stage = new("Frame", {AnchorPoint = Vector2.new(.5,.5), Position = UDim2.fromScale(.5,.5),
        Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, BorderSizePixel = 0,
        ClipsDescendants = true}, back)
    local sc = new("UIScale", {}, stage)
    local function fit()
        local vp = (workspace.CurrentCamera or cam).ViewportSize
        sc.Scale = math.max(0.3, math.min(vp.X / W, vp.Y / H))
    end
    fit()
    keep(cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
    return gui, stage
end

-- куб в стиле GD
local function makeCube(parent, size)
    local k = size / 40
    local c = new("Frame", {Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(.5,.5),
        BackgroundColor3 = C_PRI, BorderSizePixel = 0}, parent)
    stroke(c, BLACK, math.max(2, 3*k))
    local inner = new("Frame", {Size = UDim2.fromOffset(28*k, 28*k), Position = UDim2.fromOffset(6*k, 6*k),
        BackgroundColor3 = C_SEC, BorderSizePixel = 0}, c)
    stroke(inner, BLACK, math.max(1.5, 2*k))
    local function blk(x, y, w, h)
        new("Frame", {Position = UDim2.fromOffset(x*k, y*k), Size = UDim2.fromOffset(w*k, h*k),
            BackgroundColor3 = BLACK, BorderSizePixel = 0}, c)
    end
    blk(10, 12, 7, 7); blk(23, 12, 7, 7); blk(11, 25, 18, 4)
    return c
end

-- ===================== LEVELS =====================
local function buildLevel(fn)
    local objs = {}
    local api = {}
    function api.spike(c, n)
        for i = 0, (n or 1) - 1 do
            objs[#objs+1] = {t = "spike", x = (c+i)*T, y = 0, w = T, h = T}
        end
    end
    function api.block(c, r, w, h)
        objs[#objs+1] = {t = "block", x = c*T, y = r*T, w = w*T, h = h*T}
    end
    function api.pad(c, r)
        objs[#objs+1] = {t = "pad", x = c*T, y = (r or 0)*T, w = T, h = 10}
    end
    fn(api)
    return objs
end

local LEVELS = {
    {Name = "Stereo Madness", Diff = "Easy", Stars = 1, Speed = 400, Len = 160,
     C1 = Color3.fromRGB(30,100,255), C2 = Color3.fromRGB(0,190,255), Accent = Color3.fromRGB(120,240,255),
     Build = function(a)
        local spike, block, pad = a.spike, a.block, a.pad
        spike(16); spike(24,2); block(32,0,3,1); spike(40); spike(47,3); pad(57); spike(60,3)
        block(70,0,5,1); spike(77,2); spike(85); spike(92)
        block(100,0,2,1); spike(104); block(108,0,2,1); spike(112,2)
        spike(120,3); spike(129,2); pad(138); spike(141,3); spike(150)
     end},
    {Name = "Back On Track", Diff = "Normal", Stars = 2, Speed = 440, Len = 175,
     C1 = Color3.fromRGB(190,40,230), C2 = Color3.fromRGB(255,50,140), Accent = Color3.fromRGB(255,140,230),
     Build = function(a)
        local spike, block, pad = a.spike, a.block, a.pad
        spike(16,2); spike(24); spike(30,2); block(38,0,3,1); spike(43,2)
        block(52,0,6,1); spike(60,3); pad(70); spike(73,3)
        block(84,0,4,1); spike(89,3); block(93,0,4,1); spike(100); spike(106,2); spike(113,3)
        pad(122); spike(125,3); spike(134); spike(140,2)
        block(148,0,3,1); spike(153,2); spike(160,3)
     end},
    {Name = "Polargeist", Diff = "Hard", Stars = 3, Speed = 480, Len = 200,
     C1 = Color3.fromRGB(255,120,20), C2 = Color3.fromRGB(230,30,30), Accent = Color3.fromRGB(255,225,70),
     Build = function(a)
        local spike, block, pad = a.spike, a.block, a.pad
        spike(16,2); spike(24,3); block(34,0,3,1); spike(38,3); spike(48); spike(55,2)
        pad(64); spike(67,3); spike(79)
        block(88,0,4,1); spike(93,3); block(101,0,2,1); block(107,0,2,1); spike(111,2)
        pad(119); spike(122,3); spike(131,2); spike(138); spike(145,3)
        block(154,0,5,1); spike(160,3); spike(169,2)
        pad(177); spike(180,3); spike(189)
     end},
    {Name = "GRIEF", Diff = "EXTREME DEMON", Stars = 3, Speed = 600, Len = 320,
     C1 = Color3.fromRGB(15,5,25), C2 = Color3.fromRGB(105,5,25), Accent = Color3.fromRGB(255,35,65),
     Build = function(a)
        local spike, block = a.spike, a.block
        -- Оригинальная сложная трасса: группы препятствий с промежутками для честных прыжков.
        spike(18,3);  spike(31,2);  block(44,0,2,1); spike(57,4)
        spike(70,3);  block(83,0,3,1); spike(96,3);  spike(109,4)
        block(122,0,2,1); spike(135,3); spike(148,4); spike(161,2)
        block(174,0,3,1); spike(187,4); spike(200,3); spike(213,4)
        block(226,0,2,1); spike(239,3); spike(252,4); spike(265,3)
        spike(278,4); spike(291,3)
     end},
}

-- ===================== STATE =====================
local S = {sel = 1, idx = 1, state = "menu", dist = 0, py = 0, vy = 0, grounded = true,
           rot = 0, attempts = 1, objs = {}, best = {0,0,0,0}, run = 0, acc = 0,
           built = nil, trailT = 0, autoBot = false}
local keyHeld, tapHeld, botHeld = false, false, false
local function held() return keyHeld or tapHeld or botHeld end

-- ===================== MENU =====================
local menuGui, mst = makeGui("GD_Menu")
mst.BackgroundTransparency = 0; mst.BackgroundColor3 = WHITE
new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(25,40,150), Color3.fromRGB(80,15,130))}, mst)

local msq = {}
for i = 1, 10 do
    local s = math.random(40, 110)
    local f = new("Frame", {Size = UDim2.fromOffset(s,s), AnchorPoint = Vector2.new(.5,.5),
        BackgroundColor3 = WHITE, BackgroundTransparency = .9, BorderSizePixel = 0}, mst)
    msq[i] = {f = f, x = math.random(0, W), y = math.random(0, H), v = math.random(15, 45), r = math.random(-30, 30)}
end

local title = lbl(mst, {Size = UDim2.fromOffset(W, 90), Position = UDim2.fromOffset(0, 30),
    Text = "GEOMETRY DASH", TextSize = 62})
new("UIStroke", {Color = BLACK, Thickness = 5}, title)
new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255,240,90), Color3.fromRGB(255,140,20))}, title)
local iconL = makeCube(mst, 64); iconL.Position = UDim2.fromOffset(W/2 - 350, 75); iconL.Rotation = -12
local iconR = makeCube(mst, 64); iconR.Position = UDim2.fromOffset(W/2 + 350, 75); iconR.Rotation = 12

local card = new("Frame", {Size = UDim2.fromOffset(520, 230), Position = UDim2.fromOffset(W/2 - 260, 150),
    BackgroundColor3 = BLACK, BackgroundTransparency = .35, BorderSizePixel = 0}, mst)
corner(card, 16)
local cardStroke = stroke(card, WHITE, 3)
local nameLbl = lbl(card, {Size = UDim2.new(1,0,0,56), Position = UDim2.fromOffset(0,14), TextSize = 40})
local diffLbl = lbl(card, {Size = UDim2.new(1,0,0,30), Position = UDim2.fromOffset(0,72), TextSize = 24,
    TextColor3 = Color3.fromRGB(255,225,90), Font = Enum.Font.GothamBold})
local infoLbl = lbl(card, {Size = UDim2.new(1,0,0,22), Position = UDim2.fromOffset(0,108), TextSize = 16,
    TextColor3 = Color3.fromRGB(200,200,230), Font = Enum.Font.GothamMedium})
local bestLbl = lbl(card, {Size = UDim2.new(1,0,0,22), Position = UDim2.fromOffset(0,148), TextSize = 18,
    Font = Enum.Font.GothamBold})
local barBg = new("Frame", {Size = UDim2.fromOffset(440,16), Position = UDim2.fromOffset(40,180),
    BackgroundColor3 = Color3.fromRGB(20,20,40), BorderSizePixel = 0}, card)
corner(barBg, 8); stroke(barBg, WHITE, 2, .5)
local barFill = new("Frame", {Size = UDim2.new(0,0,1,0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, barBg)
corner(barFill, 8)

local function arrow(txt, x)
    local b = btn(mst, {Size = UDim2.fromOffset(64,100), Position = UDim2.fromOffset(x, 215),
        BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = .85, Text = txt, TextSize = 36})
    corner(b, 14)
    return b
end
local leftB  = arrow("◀", W/2 - 350)
local rightB = arrow("▶", W/2 + 286)

local playB = btn(mst, {Size = UDim2.fromOffset(230,72), Position = UDim2.fromOffset(W/2 - 260, 400),
    BackgroundColor3 = Color3.fromRGB(70,220,70), Text = "▶  PLAY", TextSize = 32})
corner(playB, 16); stroke(playB, BLACK, 4)

local botB = btn(mst, {Size = UDim2.fromOffset(250,72), Position = UDim2.fromOffset(W/2 + 30, 400),
    BackgroundColor3 = Color3.fromRGB(65,55,85), Text = "AUTO BOT: OFF", TextSize = 21})
corner(botB, 16); stroke(botB, BLACK, 4)

local menuClose = btn(mst, {Size = UDim2.fromOffset(44,44), Position = UDim2.fromOffset(W-58, 14),
    BackgroundColor3 = Color3.fromRGB(200,50,50), Text = "✕", TextSize = 22})
corner(menuClose, 10)

lbl(mst, {Size = UDim2.fromOffset(W,24), Position = UDim2.fromOffset(0, 495), TextSize = 14,
    Font = Enum.Font.GothamMedium, TextTransparency = .25,
    Text = "Manual: Space / ↑ / W / click / tap — jump   •   AUTO BOT — GRIEF menu toggle   •   R — restart   •   Q — menu"})

local function refreshMenu()
    local L = LEVELS[S.sel]
    cardStroke.Color = L.Accent
    nameLbl.Text = L.Name
    diffLbl.Text = string.rep("★", L.Stars) .. string.rep("☆", 3 - L.Stars) .. "   " .. L.Diff
    infoLbl.Text = string.format("Speed ×%.1f   •   Length %d blocks", L.Speed/400, L.Len)
    local b = S.best[S.sel]
    bestLbl.Text = "Best: " .. b .. "%"
    bestLbl.TextColor3 = (b >= 100) and Color3.fromRGB(110,255,110) or WHITE
    barFill.Size = UDim2.new(b/100, 0, 1, 0)
    barFill.BackgroundColor3 = L.Accent

    local botAvailable = (S.sel == 4)
    botB.Active = botAvailable
    botB.AutoButtonColor = botAvailable
    if not botAvailable then
        botB.Text = "BOT: GRIEF ONLY"
        botB.BackgroundColor3 = Color3.fromRGB(65,65,75)
    else
        botB.Text = S.autoBot and "AUTO BOT: ON" or "AUTO BOT: OFF"
        botB.BackgroundColor3 = S.autoBot and Color3.fromRGB(125,55,165) or Color3.fromRGB(65,55,85)
    end
end

-- ===================== GAME GUI =====================
local gameGui, gst = makeGui("GD_Game")
gst.BackgroundTransparency = 1

local bg = new("Frame", {Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.fromRGB(30,100,255),
    BorderSizePixel = 0, ZIndex = 1}, gst)
new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(.55,.55,.55), WHITE)}, bg)

local bgSq = {}
for i = 1, 9 do
    local s = math.random(110, 260)
    local f = new("Frame", {Size = UDim2.fromOffset(s,s), BackgroundColor3 = WHITE,
        BackgroundTransparency = (i % 2 == 0) and .93 or .9, BorderSizePixel = 0}, bg)
    bgSq[i] = {f = f, size = s, x = math.random(0, W), y = math.random(-40, GROUND_Y - s + 60),
               k = (i % 2 == 0) and 0.12 or 0.22}
end

local ground = new("Frame", {Size = UDim2.fromOffset(W, GROUND_H), Position = UDim2.fromOffset(0, GROUND_Y),
    BackgroundColor3 = Color3.fromRGB(20,40,120), BorderSizePixel = 0, ZIndex = 2, ClipsDescendants = true}, gst)
new("UIGradient", {Rotation = 90, Color = ColorSequence.new(WHITE, Color3.new(.6,.6,.6))}, ground)
local gLines = {}
for i = 1, math.ceil(W/T) + 2 do
    gLines[i] = new("Frame", {Size = UDim2.new(0,2,1,0), BackgroundColor3 = WHITE,
        BackgroundTransparency = .85, BorderSizePixel = 0}, ground)
end
new("Frame", {Size = UDim2.new(1,0,0,2), Position = UDim2.fromOffset(0, 50), BackgroundColor3 = WHITE,
    BackgroundTransparency = .88, BorderSizePixel = 0}, ground)
local groundGlow = new("Frame", {Size = UDim2.fromOffset(W, 18), Position = UDim2.fromOffset(0, GROUND_Y - 18),
    BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 2}, gst)
new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, .55)}, groundGlow)
local groundTop = new("Frame", {Size = UDim2.fromOffset(W, 4), Position = UDim2.fromOffset(0, GROUND_Y),
    BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4}, gst)

local world = new("Frame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3}, gst)

local attemptLbl = lbl(gst, {Size = UDim2.fromOffset(520, 70), Position = UDim2.fromOffset(300, 130),
    TextXAlignment = Enum.TextXAlignment.Left, TextSize = 52, TextTransparency = .1, ZIndex = 3, Text = "Attempt 1"})
new("UIStroke", {Color = BLACK, Thickness = 3}, attemptLbl)

local player = makeCube(gst, PS); player.ZIndex = 5
local fx = new("Frame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6}, gst)

-- HUD
local barBg2 = new("Frame", {Size = UDim2.fromOffset(400,14), Position = UDim2.fromOffset(W/2-200, 22),
    BackgroundColor3 = BLACK, BackgroundTransparency = .45, BorderSizePixel = 0, ZIndex = 10}, gst)
corner(barBg2, 7); stroke(barBg2, WHITE, 2, .3)
local progFill = new("Frame", {Size = UDim2.new(0,0,1,0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, barBg2)
corner(progFill, 7)
local pctLbl = lbl(gst, {Size = UDim2.fromOffset(80,30), Position = UDim2.fromOffset(W/2+210, 14), TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10, Text = "0%"})
new("UIStroke", {Color = BLACK, Thickness = 2}, pctLbl)

local tapBtn = btn(gst, {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 9})
local closeBtn = btn(gst, {Size = UDim2.fromOffset(44,44), Position = UDim2.fromOffset(W-58, 10),
    BackgroundColor3 = Color3.fromRGB(200,50,50), Text = "✕", TextSize = 22, ZIndex = 12})
corner(closeBtn, 10)

local winGroup = new("Frame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Visible = false, ZIndex = 15}, gst)
local winTitle = lbl(winGroup, {Size = UDim2.fromOffset(W,90), Position = UDim2.fromOffset(0,190),
    Text = "LEVEL COMPLETE!", TextSize = 64, TextColor3 = Color3.fromRGB(120,255,120)})
new("UIStroke", {Color = BLACK, Thickness = 5}, winTitle)
local winSub = lbl(winGroup, {Size = UDim2.fromOffset(W,40), Position = UDim2.fromOffset(0,285), TextSize = 28})
new("UIStroke", {Color = BLACK, Thickness = 3}, winSub)

local flashF = new("Frame", {Size = UDim2.fromScale(1,1), BackgroundColor3 = WHITE, BackgroundTransparency = 1,
    BorderSizePixel = 0, ZIndex = 20}, gst)
local function flash(a)
    flashF.BackgroundTransparency = a
    TweenService:Create(flashF, TweenInfo.new(.45), {BackgroundTransparency = 1}):Play()
end

local sound
if MUSIC_ID ~= "" then
    sound = new("Sound", {SoundId = MUSIC_ID, Looped = true, Volume = .6}, gameGui)
end

-- ===================== PARTICLES =====================
local pool, parts = {}, {}
local function spawn(wx, wy, vx, vy, life, size, color, g)
    if #parts > 140 then return end
    local f = table.remove(pool) or new("Frame", {BorderSizePixel = 0}, fx)
    f.BackgroundColor3 = color; f.Visible = true
    parts[#parts+1] = {f = f, wx = wx, wy = wy, vx = vx, vy = vy, life = life, max = life, size = size, g = g or 0}
end
local function updateParticles(dt, camX)
    for i = #parts, 1, -1 do
        local p = parts[i]
        p.life -= dt
        if p.life <= 0 then
            p.f.Visible = false; pool[#pool+1] = p.f; table.remove(parts, i)
        else
            p.vy -= p.g * dt
            p.wx += p.vx * dt; p.wy += p.vy * dt
            local a = p.life / p.max
            local s = p.size * (0.4 + 0.6*a)
            p.f.Size = UDim2.fromOffset(s, s)
            p.f.Position = UDim2.fromOffset(p.wx - camX - s/2, GROUND_Y - p.wy - s/2)
            p.f.BackgroundTransparency = 1 - a
        end
    end
end

-- ===================== WORLD BUILD =====================
local function createObjUI(o, accent)
    local f
    if o.t == "spike" then
        local N = 10
        f = new("Frame", {Size = UDim2.fromOffset(T, T), BackgroundTransparency = 1, BorderSizePixel = 0}, world)
        local sh = T / N
        for i = 1, N do
            local w = T * i / N
            new("Frame", {BackgroundColor3 = WHITE, BorderSizePixel = 0,
                Size = UDim2.fromOffset(w + 4, sh + 1), Position = UDim2.fromOffset((T - w - 4)/2, (i-1)*sh - 1)}, f)
        end
        for i = 1, N do
            local w = T * i / N
            new("Frame", {BackgroundColor3 = Color3.fromRGB(6,6,12), BorderSizePixel = 0,
                Size = UDim2.fromOffset(w, sh), Position = UDim2.fromOffset((T - w)/2, (i-1)*sh)}, f)
        end
    elseif o.t == "block" then
        f = new("Frame", {Size = UDim2.fromOffset(o.w, o.h), BackgroundColor3 = Color3.fromRGB(8,8,16), BorderSizePixel = 0}, world)
        stroke(f, WHITE, 2)
        local inn = new("Frame", {Position = UDim2.fromOffset(5,5), Size = UDim2.new(1,-10,1,-10),
            BackgroundTransparency = 1, BorderSizePixel = 0}, f)
        stroke(inn, accent, 1.5, .4)
    elseif o.t == "pad" then
        f = new("Frame", {Size = UDim2.fromOffset(T, o.h), BackgroundColor3 = Color3.fromRGB(255,235,40), BorderSizePixel = 0}, world)
        corner(f, 5)
        stroke(f, Color3.fromRGB(255,255,170), 2, .3)
    elseif o.t == "end" then
        f = new("Frame", {Size = UDim2.fromOffset(o.w, o.h), BackgroundColor3 = WHITE, BorderSizePixel = 0}, world)
        local g = new("Frame", {Size = UDim2.fromOffset(60, o.h), Position = UDim2.fromOffset(-60, 0),
            BackgroundColor3 = accent, BorderSizePixel = 0}, f)
        new("UIGradient", {Transparency = NumberSequence.new(1, .3)}, g)
    end
    f.Visible = false
    o.ui = f; o.vis = false
end

local function buildWorld(idx)
    world:ClearAllChildren()
    local L = LEVELS[idx]
    S.objs = buildLevel(L.Build)
    S.objs[#S.objs+1] = {t = "end", x = L.Len*T, y = 0, w = 10, h = GROUND_Y}
    for _, o in ipairs(S.objs) do createObjUI(o, L.Accent) end
    groundTop.BackgroundColor3 = L.Accent
    groundGlow.BackgroundColor3 = L.Accent
    progFill.BackgroundColor3 = L.Accent
    S.built = idx
end

-- ===================== INPUT BINDING =====================
local bound = false
local function bindJump()
    if bound then return end
    bound = true
    CAS:BindActionAtPriority("GD_Jump", function(_, st)
        if st == Enum.UserInputState.Begin then keyHeld = true
        elseif st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel then keyHeld = false end
        return Enum.ContextActionResult.Sink
    end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.Up, Enum.KeyCode.W)
end
local function unbindJump()
    if bound then bound = false; CAS:UnbindAction("GD_Jump") end
    keyHeld = false; tapHeld = false; botHeld = false
end

keep(tapBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then tapHeld = true end
end))
keep(tapBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then tapHeld = false end
end))

-- ===================== GAME FLOW =====================
local startLevel

local function leaveToMenu()
    S.state = "menu"; S.run += 1
    unbindJump()
    if sound then sound:Stop() end
    gameGui.Enabled = false; menuGui.Enabled = true
    refreshMenu()
end

local function closeAll()
    S.state = "menu"; S.run += 1
    unbindJump()
    if sound then sound:Stop() end
    gameGui.Enabled = false; menuGui.Enabled = false
end

startLevel = function(idx, retry)
    if S.built ~= idx then buildWorld(idx) end
    if not retry then S.attempts = 1 end
    S.idx = idx; S.run += 1; S.state = "play"
    S.dist = 0; S.py = 0; S.vy = 0; S.grounded = true; S.rot = 0; S.acc = 0; S.trailT = 0
    botHeld = false
    for _, o in ipairs(S.objs) do o.used = false end
    attemptLbl.Text = "Attempt " .. S.attempts .. (S.autoBot and idx == 4 and "  •  AUTO BOT" or "  •  MANUAL")
    player.Visible = true; player.Rotation = 0
    winGroup.Visible = false
    menuGui.Enabled = false; gameGui.Enabled = true
    bindJump()
    if sound then sound.TimePosition = 0; sound:Play() end
end

local function die()
    if S.state ~= "play" then return end
    S.state = "dead"
    local L = LEVELS[S.idx]
    local pct = math.floor(math.clamp(S.dist / (L.Len*T), 0, 1) * 100)
    S.best[S.idx] = math.max(S.best[S.idx], pct)
    player.Visible = false
    for i = 1, 24 do
        local a = math.rad(math.random(0, 359)); local sp = math.random(120, 430)
        spawn(S.dist, S.py + PS/2, math.cos(a)*sp, math.sin(a)*sp, math.random(50,100)/100,
              math.random(7,14), (i % 2 == 0) and C_PRI or C_SEC, 900)
    end
    flash(.55)
    if sound then sound:Stop() end
    local token = S.run
    task.delay(0.95, function()
        if S.state == "dead" and S.run == token then
            S.attempts += 1
            startLevel(S.idx, true)
        end
    end)
end

local function win()
    S.state = "won"
    S.best[S.idx] = 100
    winSub.Text = "Attempts: " .. S.attempts
    winGroup.Visible = true
    local L = LEVELS[S.idx]
    for i = 1, 40 do
        spawn(S.dist, S.py + PS/2, math.random(-250, 350), math.random(250, 650), math.random(80,160)/100,
              math.random(6,12), (i % 3 == 0) and C_PRI or ((i % 3 == 1) and C_SEC or L.Accent), 900)
    end
    flash(.6)
    local token = S.run
    task.delay(2.8, function()
        if S.state == "won" and S.run == token then leaveToMenu() end
    end)
end

-- ===================== PHYSICS =====================
local function step(dt)
    local L = LEVELS[S.idx]

    -- Авто-бот работает только на GRIEF. Он заранее ищет ближайший шип/блок
    -- и запускает прыжок так, чтобы куб успевал пролететь над препятствием.
    botHeld = false
    if S.autoBot and S.idx == 4 and S.grounded then
        local lead = math.max(55, L.Speed * 0.12)
        for _, o in ipairs(S.objs) do
            if o.t == "spike" or o.t == "block" then
                local dx = o.x - S.dist
                if dx <= lead and dx >= -PS then
                    botHeld = true
                    break
                end
            end
        end
    end

    if held() and S.grounded then S.vy = JUMP_V; S.grounded = false end
    local prevBottom = S.py
    S.vy -= GRAV * dt
    S.py += S.vy * dt
    S.dist += L.Speed * dt
    S.grounded = false
    if S.py <= 0 then S.py = 0; S.vy = 0; S.grounded = true end

    local left, right = S.dist - PS/2 + 3, S.dist + PS/2 - 3
    for _, o in ipairs(S.objs) do
        if o.x > right + 2 or o.x + o.w < left - 2 then continue end
        local bottom, top = S.py, S.py + PS - 4
        if o.t == "block" then
            if left < o.x + o.w and right > o.x and bottom < o.y + o.h and top > o.y then
                if prevBottom >= o.y + o.h - 4 and S.vy <= 0 then
                    S.py = o.y + o.h; S.vy = 0; S.grounded = true
                else
                    die(); return
                end
            end
        elseif o.t == "spike" then
            if left < o.x + T - 12 and right > o.x + 12 and bottom < o.y + 20 and top > o.y then
                die(); return
            end
        elseif o.t == "pad" then
            if not o.used and left < o.x + o.w and right > o.x and bottom < o.y + o.h and top > o.y then
                o.used = true; S.vy = PAD_V; S.grounded = false
            end
        end
    end
    if S.dist >= L.Len * T then win() end
end

-- ===================== RENDER =====================
local function draw(dt)
    local L = LEVELS[S.idx]
    local camX = S.dist - PX
    local pct = math.clamp(S.dist / (L.Len*T), 0, 1)

    local bgc = L.C1:Lerp(L.C2, pct)
    bg.BackgroundColor3 = bgc
    ground.BackgroundColor3 = bgc:Lerp(BLACK, .55)

    for _, s in ipairs(bgSq) do
        local x = (s.x - camX * s.k) % (W + s.size*2) - s.size
        s.f.Position = UDim2.fromOffset(x, s.y)
    end
    local off = camX % T
    for i, ln in ipairs(gLines) do ln.Position = UDim2.fromOffset((i-1)*T - off, 0) end

    for _, o in ipairs(S.objs) do
        local sx = o.x - camX
        local vis = sx > -T*2 and sx < W + 60
        if vis then
            o.ui.Position = UDim2.fromOffset(math.floor(sx), math.floor(GROUND_Y - o.y - o.h))
        end
        if vis ~= o.vis then o.vis = vis; o.ui.Visible = vis end
    end

    -- игрок
    if S.state == "play" or S.state == "won" then
        if S.grounded then
            local target = math.floor(S.rot / 90 + 0.5) * 90
            S.rot += (target - S.rot) * math.min(1, dt * 25)
        else
            S.rot += 410 * dt
        end
        player.Position = UDim2.fromOffset(PX, GROUND_Y - S.py - PS/2)
        player.Rotation = S.rot
        if S.state == "play" and S.grounded then
            S.trailT -= dt
            if S.trailT <= 0 then
                S.trailT = 0.04
                spawn(S.dist - PS/2, S.py + 4, math.random(-40, 0), math.random(20, 90), .35, 7, L.Accent, 0)
            end
        end
    end

    -- HUD
    progFill.Size = UDim2.new(pct, 0, 1, 0)
    pctLbl.Text = math.floor(pct * 100) .. "%"
    attemptLbl.Position = UDim2.fromOffset(PX + 60 - S.dist, 130)
    attemptLbl.Visible = (PX + 60 - S.dist) > -540

    updateParticles(dt, camX)
end

keep(RunService.RenderStepped:Connect(function(dt)
    if menuGui.Enabled then
        local t = os.clock()
        for _, s in ipairs(msq) do
            s.f.Position = UDim2.fromOffset(s.x, (s.y - t * s.v) % (H + 200) - 100)
            s.f.Rotation = t * s.r
        end
        iconL.Rotation = -12 + math.sin(t*2) * 6
        iconR.Rotation = 12 - math.sin(t*2) * 6
    end
    if not gameGui.Enabled then return end
    dt = math.min(dt, 0.1)
    if S.state == "play" then
        S.acc += dt
        local n = 0
        while S.acc >= STEP and S.state == "play" and n < 20 do
            step(STEP); S.acc -= STEP; n += 1
        end
    end
    draw(dt)
end))

-- ===================== MENU LOGIC =====================
local function selectLevel(d)
    S.sel = (S.sel - 1 + d) % #LEVELS + 1
    refreshMenu()
end
leftB.MouseButton1Click:Connect(function() selectLevel(-1) end)
rightB.MouseButton1Click:Connect(function() selectLevel(1) end)
playB.MouseButton1Click:Connect(function() startLevel(S.sel, false) end)
botB.MouseButton1Click:Connect(function()
    if S.sel == 4 then
        S.autoBot = not S.autoBot
        refreshMenu()
    end
end)
menuClose.MouseButton1Click:Connect(function() menuGui.Enabled = false end)
closeBtn.MouseButton1Click:Connect(leaveToMenu)
refreshMenu()

-- ===================== TOOL =====================
local tool = Instance.new("Tool")
tool.Name = "GD_Tool"; tool.RequiresHandle = false
tool.CanBeDropped = false; tool.ToolTip = "Geometry Dash"

local function bindTool(t)
    t.Equipped:Connect(function()
        if not gameGui.Enabled then menuGui.Enabled = true; refreshMenu() end
    end)
    t.Unequipped:Connect(closeAll)
end

local function giveTool()
    local bp = lp:FindFirstChild("Backpack")
    if bp and not bp:FindFirstChild("GD_Tool") then
        local t = tool:Clone(); bindTool(t); t.Parent = bp
    end
end
giveTool()
keep(lp.CharacterAdded:Connect(function()
    closeAll()
    task.wait(1); giveTool()
end))

keep(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.G then
        local ch = lp.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then
            local t = ch:FindFirstChild("GD_Tool") or lp.Backpack:FindFirstChild("GD_Tool")
            if t then
                if t.Parent == ch then hum:UnequipTools() else hum:EquipTool(t) end
            end
        end
    elseif gameGui.Enabled then
        if k == Enum.KeyCode.R and (S.state == "play" or S.state == "dead") then
            S.attempts += 1; startLevel(S.idx, true)
        elseif k == Enum.KeyCode.Q then
            leaveToMenu()
        end
    elseif menuGui.Enabled then
        if k == Enum.KeyCode.Left or k == Enum.KeyCode.A then selectLevel(-1)
        elseif k == Enum.KeyCode.Right or k == Enum.KeyCode.D then selectLevel(1)
        elseif k == Enum.KeyCode.Return then startLevel(S.sel, false) end
    end
end))

print("[GD] Geometry Dash v2 loaded. Take GD_Tool (or press G) to play.")
