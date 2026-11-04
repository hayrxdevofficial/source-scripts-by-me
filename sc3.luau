--[[ ⚡ GEOMETRY DASH — GUI EDITION (client-side cheat) ⚡ ]]
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- === CLEANUP ===
for _, n in ipairs({"GD_Menu","GD_Game"}) do
    local o = pg:FindFirstChild(n); if o then o:Destroy() end
end
for _, c in ipairs({lp:FindFirstChild("Backpack"), lp.Character}) do
    if c and c:FindFirstChild("GD_Tool") then c.GD_Tool:Destroy() end
end

-- === LEVELS ===
local LEVELS = {
    {Name="Stereo Madness", Speed=420, Length=3200, Color=Color3.fromRGB(80,130,255),
     Spikes={700,950,1200,1550,1600,2100,2400,2700}},
    {Name="Back On Track", Speed=480, Length=3800, Color=Color3.fromRGB(120,220,120),
     Spikes={600,700,800,1300,1350,1400,1900,2200,2250,2900,3000}},
    {Name="Polargeist", Speed=540, Length=4200, Color=Color3.fromRGB(255,180,60),
     Spikes={500,650,800,950,1400,1500,1600,2100,2300,2400,2600,3100,3200,3300,3700}},
}

-- === CONSTANTS ===
local GAME_W, GAME_H = 900, 500
local GROUND_H = 100
local GROUND_Y = GAME_H - GROUND_H
local PLAYER_SIZE = 40
local PLAYER_CENTER_X = 250
local PLAYER_LEFT = PLAYER_CENTER_X - PLAYER_SIZE/2
local GRAVITY = 2800
local JUMP_V  = -1000

-- ===================== MENU =====================
local menu = Instance.new("ScreenGui")
menu.Name = "GD_Menu"; menu.ResetOnSpawn = false
menu.IgnoreGuiInset = true; menu.Enabled = false; menu.Parent = pg

local mframe = Instance.new("Frame")
mframe.Size = UDim2.new(0,420,0,540)
mframe.Position = UDim2.new(0.5,-210,0.5,-270)
mframe.BackgroundColor3 = Color3.fromRGB(15,15,40)
mframe.BorderSizePixel = 0; mframe.Parent = menu
Instance.new("UICorner", mframe).CornerRadius = UDim.new(0,16)

local mtitle = Instance.new("TextLabel")
mtitle.Size = UDim2.new(1,0,0,80); mtitle.BorderSizePixel = 0
mtitle.BackgroundColor3 = Color3.fromRGB(90,60,220)
mtitle.Text = "⚡ GEOMETRY DASH"; mtitle.TextColor3 = Color3.new(1,1,1)
mtitle.Font = Enum.Font.GothamBlack; mtitle.TextSize = 28
mtitle.Parent = mframe
Instance.new("UICorner", mtitle).CornerRadius = UDim.new(0,16)

local mlist = Instance.new("ScrollingFrame")
mlist.Size = UDim2.new(1,-20,1,-110); mlist.Position = UDim2.new(0,10,0,90)
mlist.BackgroundTransparency = 1; mlist.BorderSizePixel = 0
mlist.ScrollBarThickness = 6; mlist.AutomaticCanvasSize = Enum.AutomaticSize.Y
mlist.CanvasSize = UDim2.new(0,0,0,0); mlist.Parent = mframe
Instance.new("UIListLayout", mlist).Padding = UDim.new(0,10)

-- ===================== GAME =====================
local game = Instance.new("ScreenGui")
game.Name = "GD_Game"; game.ResetOnSpawn = false
game.IgnoreGuiInset = true; game.Enabled = false; game.Parent = pg

local gf = Instance.new("Frame")
gf.Size = UDim2.new(0,GAME_W,0,GAME_H)
gf.Position = UDim2.new(0.5,-GAME_W/2,0.5,-GAME_H/2)
gf.BackgroundColor3 = Color3.fromRGB(10,10,30)
gf.BorderSizePixel = 0; gf.ClipsDescendants = true; gf.Parent = game
Instance.new("UICorner", gf).CornerRadius = UDim.new(0,12)

local ground = Instance.new("Frame")
ground.Size = UDim2.new(1,0,0,GROUND_H)
ground.Position = UDim2.new(0,0,1,-GROUND_H)
ground.BackgroundColor3 = Color3.fromRGB(40,40,100)
ground.BorderSizePixel = 0; ground.Parent = gf
Instance.new("UICorner", ground).CornerRadius = UDim.new(0,8)

local groundLine = Instance.new("Frame")
groundLine.Size = UDim2.new(1,0,0,3); groundLine.Position = UDim2.new(0,0,0,0)
groundLine.BackgroundColor3 = Color3.fromRGB(120,120,255)
groundLine.BorderSizePixel = 0; groundLine.Parent = ground

local obstacles = Instance.new("Folder")
obstacles.Name = "Obstacles"; obstacles.Parent = gf

local player = Instance.new("Frame")
player.Name = "Player"; player.AnchorPoint = Vector2.new(0.5, 0.5)
player.Size = UDim2.new(0,PLAYER_SIZE,0,PLAYER_SIZE)
player.BackgroundColor3 = Color3.fromRGB(255,220,60)
player.BorderSizePixel = 0; player.Parent = gf
Instance.new("UICorner", player).CornerRadius = UDim.new(0,6)

local inner = Instance.new("Frame")
inner.Size = UDim2.new(0.5,0,0.5,0); inner.Position = UDim2.new(0.25,0,0.25,0)
inner.BackgroundColor3 = Color3.fromRGB(255,255,200)
inner.BorderSizePixel = 0; inner.Parent = player
Instance.new("UICorner", inner).CornerRadius = UDim.new(0,3)

local attemptsLbl = Instance.new("TextLabel")
attemptsLbl.Size = UDim2.new(0,250,0,40); attemptsLbl.Position = UDim2.new(0,20,0,20)
attemptsLbl.BackgroundTransparency = 1; attemptsLbl.TextColor3 = Color3.new(1,1,1)
attemptsLbl.Font = Enum.Font.GothamBlack; attemptsLbl.TextSize = 22
attemptsLbl.TextXAlignment = Enum.TextXAlignment.Left
attemptsLbl.Text = "Attempt 1"; attemptsLbl.Parent = gf

local progBg = Instance.new("Frame")
progBg.Size = UDim2.new(0,300,0,16); progBg.Position = UDim2.new(0.5,-150,0,30)
progBg.BackgroundColor3 = Color3.fromRGB(50,50,80)
progBg.BorderSizePixel = 0; progBg.Parent = gf
Instance.new("UICorner", progBg).CornerRadius = UDim.new(0,8)

local progFill = Instance.new("Frame")
progFill.Size = UDim2.new(0,0,1,0)
progFill.BackgroundColor3 = Color3.fromRGB(100,200,255)
progFill.BorderSizePixel = 0; progFill.Parent = progBg
Instance.new("UICorner", progFill).CornerRadius = UDim.new(0,8)

local pctLbl = Instance.new("TextLabel")
pctLbl.Size = UDim2.new(0,100,0,20); pctLbl.Position = UDim2.new(0.5,-50,0,52)
pctLbl.BackgroundTransparency = 1; pctLbl.TextColor3 = Color3.new(1,1,1)
pctLbl.Font = Enum.Font.GothamBold; pctLbl.TextSize = 14
pctLbl.Text = "0%"; pctLbl.Parent = gf

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,40,0,40); closeBtn.Position = UDim2.new(1,-50,0,10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 22; closeBtn.Text = "✕"; closeBtn.BorderSizePixel = 0
closeBtn.Parent = gf
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)

local winOverlay = Instance.new("TextLabel")
winOverlay.Size = UDim2.new(1,0,0,100); winOverlay.Position = UDim2.new(0,0,0.5,-50)
winOverlay.BackgroundTransparency = 1
winOverlay.TextColor3 = Color3.fromRGB(100,255,100)
winOverlay.Font = Enum.Font.GothamBlack; winOverlay.TextSize = 56
winOverlay.Text = "LEVEL COMPLETE!"; winOverlay.Visible = false
winOverlay.Parent = gf

-- === STATE ===
local S = {running=false, camX=0, py=GROUND_Y-PLAYER_SIZE, vy=0,
           grounded=true, level=nil, attempts=1, dead=false, conn=nil}

local function rectOverlap(ax,ay,aw,ah,bx,by,bw,bh)
    return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by
end
local function stopLoop() if S.conn then S.conn:Disconnect(); S.conn = nil end end
local function jump()
    if S.running and S.grounded and not S.dead then S.vy = JUMP_V; S.grounded = false end
end

local startLevel -- forward decl

local function die()
    if S.dead then return end
    S.dead = true
    player.BackgroundColor3 = Color3.fromRGB(255,50,50)
    task.delay(0.35, function()
        if S.level and S.running then
            S.attempts += 1
            startLevel(S.level, true)
        end
    end)
end

local function winLevel()
    if S.dead then return end
    S.dead = true; S.running = false; stopLoop()
    winOverlay.Visible = true
    task.delay(1.5, function()
        winOverlay.Visible = false
        game.Enabled = false
        menu.Enabled = true
    end)
end

startLevel = function(lvl, isRestart)
    S.level = lvl; S.running = true; S.camX = 0
    S.py = GROUND_Y - PLAYER_SIZE; S.vy = 0
    S.grounded = true; S.dead = false
    if not isRestart then S.attempts = 1 end
    attemptsLbl.Text = "Attempt " .. S.attempts

    player.BackgroundColor3 = Color3.fromRGB(255,220,60)
    player.Rotation = 0
    progFill.Size = UDim2.new(0,0,1,0); pctLbl.Text = "0%"
    winOverlay.Visible = false
    gf.BackgroundColor3 = Color3.fromRGB(10,10,30)
    ground.BackgroundColor3 = Color3.fromRGB(40,40,100)
    groundLine.BackgroundColor3 = lvl.Color

    for _, c in ipairs(obstacles:GetChildren()) do c:Destroy() end
    for _, wx in ipairs(lvl.Spikes) do
        local spike = Instance.new("Frame")
        spike.Size = UDim2.new(0,30,0,30)
        spike.BackgroundColor3 = Color3.fromRGB(255,60,60)
        spike.BorderSizePixel = 0
        spike.Parent = obstacles
        spike:SetAttribute("WorldX", wx)
        local tri = Instance.new("Frame")
        tri.Size = UDim2.new(0,10,0,10)
        tri.Position = UDim2.new(0.5,-5,0,2)
        tri.BackgroundColor3 = Color3.fromRGB(255,150,150)
        tri.BorderSizePixel = 0; tri.Rotation = 45; tri.Parent = spike
    end

    menu.Enabled = false; game.Enabled = true
    stopLoop()
    S.conn = RunService.RenderStepped:Connect(function(dt) end)
    S.conn:Disconnect()
    S.conn = RunService.RenderStepped:Connect(function(dt)
        if not S.running then return end
        dt = math.min(dt, 0.05)
        local lvl2 = S.level

        S.vy += GRAVITY * dt
        S.py += S.vy * dt
        if S.py >= GROUND_Y - PLAYER_SIZE then
            S.py = GROUND_Y - PLAYER_SIZE; S.vy = 0; S.grounded = true
        end

        S.camX += lvl2.Speed * dt

        player.Position = UDim2.new(0, PLAYER_CENTER_X, 0, S.py + PLAYER_SIZE/2)
        player.Rotation = math.clamp(S.vy / 30, -25, 25)

        for _, obs in ipairs(obstacles:GetChildren()) do
            local wx = obs:GetAttribute("WorldX")
            local sx = wx - S.camX
            obs.Position = UDim2.new(0, sx, 0, GROUND_Y - 30)
            obs.Visible = sx > -60 and sx < GAME_W + 60
            if not S.dead then
                local hx, hy, hw, hh = sx+8, GROUND_Y-30+8, 14, 22
                if rectOverlap(PLAYER_LEFT+6, S.py+6, PLAYER_SIZE-12, PLAYER_SIZE-12,
                               hx, hy, hw, hh) then
                    die()
                end
            end
        end

        local pct = math.clamp(S.camX / lvl2.Length, 0, 1)
        progFill.Size = UDim2.new(pct, 0, 1, 0)
        pctLbl.Text = math.floor(pct * 100) .. "%"

        if S.camX >= lvl2.Length then winLevel() end
    end)
end

-- level buttons
for _, lvl in ipairs(LEVELS) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-10,0,70)
    btn.BackgroundColor3 = lvl.Color
    btn.BorderSizePixel = 0; btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBlack; btn.TextSize = 22
    btn.Text = "▶  " .. lvl.Name; btn.Parent = mlist
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    btn.MouseButton1Click:Connect(function() startLevel(lvl, false) end)
end

closeBtn.MouseButton1Click:Connect(function()
    S.running = false; stopLoop()
    game.Enabled = false; menu.Enabled = true
end)

-- input
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Space
       or input.KeyCode == Enum.KeyCode.Up
       or input.KeyCode == Enum.KeyCode.W then jump() end
    if input.KeyCode == Enum.KeyCode.R and S.running and not S.dead then
        S.attempts += 1
        startLevel(S.level, true)
    end
    if input.KeyCode == Enum.KeyCode.Escape and game.Enabled then
        S.running = false; stopLoop()
        game.Enabled = false; menu.Enabled = true
    end
end)

gf.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        jump()
    end
end)

-- === TOOL (в Backpack, полностью локальный) ===
local tool = Instance.new("Tool")
tool.Name = "GD_Tool"; tool.RequiresHandle = false
tool.CanBeDropped = false; tool.ToolTip = "Geometry Dash"

local function bindTool(t)
    t.Equipped:Connect(function()
        if not game.Enabled then menu.Enabled = true end
    end)
    t.Unequipped:Connect(function()
        menu.Enabled = false; game.Enabled = false
        S.running = false; stopLoop()
    end)
end

local function giveTool()
    local bp = lp:FindFirstChild("Backpack")
    if bp and not bp:FindFirstChild("GD_Tool") then
        local t = tool:Clone(); bindTool(t); t.Parent = bp
    end
end

giveTool()
lp.CharacterAdded:Connect(function()
    menu.Enabled = false; game.Enabled = false
    S.running = false; stopLoop()
    task.wait(1); giveTool()
end)

-- G — вкл/выкл Tool вручную (если хотбар не срабатывает)
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.G then
        local ch = lp.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then
            local t = ch:FindFirstChild("GD_Tool") or lp.Backpack:FindFirstChild("GD_Tool")
            if t then
                if t.Parent == ch then hum:UnequipTools() else hum:EquipTool(t) end
            end
        end
    end
end)

print("[GD] GUI Geometry Dash loaded. Take GD_Tool (or press G) to play.")
