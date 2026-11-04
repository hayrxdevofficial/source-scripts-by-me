--[[ ⚡ GEOMETRY DASH — CLIENT-SIDE CHEAT ⚡ ]]
-- Всё создаётся локально. Сервер ничего не знает.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local lp  = Players.LocalPlayer
local pg  = lp:WaitForChild("PlayerGui")

-- == CLEANUP (если запускаем повторно) ==
for _, o in ipairs({
    pg:FindFirstChild("GD_Menu"),
    workspace:FindFirstChild("GD_Template"),
    workspace:FindFirstChild("GD_Levels"),
}) do if o then o:Destroy() end end
for _, c in ipairs({lp:FindFirstChild("Backpack"), lp.Character}) do
    if c and c:FindFirstChild("GD_Tool") then c.GD_Tool:Destroy() end
end

-- Уровни строятся высоко в небе, чтобы не мешать игре
local BASE = Vector3.new(10000, 500, 10000)

-- == ДАННЫЕ УРОВНЕЙ ==
-- Start / позиции платформ / шипов заданы относительно BASE
local LEVELS = {
    {
        Name = "Stereo Madness",
        Start = Vector3.new(0, 6, -100),
        Platforms = {
            {Vector3.new(20, 2, 250), Vector3.new(0, 0,   0)},
            {Vector3.new(20, 2,  80), Vector3.new(0, 5, 200)},
            {Vector3.new(20, 2,  60), Vector3.new(0,10, 280)},
            {Vector3.new(20, 2, 150), Vector3.new(0, 5, 400)},
        },
        Spikes = {
            Vector3.new(0, 2,  30), Vector3.new(0, 2,  60),
            Vector3.new(0, 7, 220), Vector3.new(0,12, 300),
            Vector3.new(0, 7, 450),
        },
        Finish = Vector3.new(0, 8, 480),
    },
    {
        Name = "Back On Track",
        Start = Vector3.new(0, 6, 600),
        Platforms = {
            {Vector3.new(20, 2, 180), Vector3.new(0, 0,  680)},
            {Vector3.new(20, 2, 100), Vector3.new(0, 6,  820)},
            {Vector3.new(20, 2, 160), Vector3.new(0, 3,  960)},
            {Vector3.new(20, 2, 100), Vector3.new(0, 9, 1100)},
        },
        Spikes = {
            Vector3.new(0, 2,  730), Vector3.new(0, 2,  770),
            Vector3.new(0, 8,  860), Vector3.new(0, 5, 1000),
            Vector3.new(0,11, 1150),
        },
        Finish = Vector3.new(0,11, 1180),
    },
    {
        Name = "Polargeist",
        Start = Vector3.new(0, 6, 1300),
        Platforms = {
            {Vector3.new(20, 2, 140), Vector3.new(0, 0, 1360)},
            {Vector3.new(20, 2,  60), Vector3.new(0, 5, 1460)},
            {Vector3.new(20, 2,  60), Vector3.new(0,10, 1530)},
            {Vector3.new(20, 2,  60), Vector3.new(0, 5, 1600)},
            {Vector3.new(20, 2, 140), Vector3.new(0, 0, 1690)},
        },
        Spikes = {
            Vector3.new(0, 2, 1400), Vector3.new(0, 7, 1480),
            Vector3.new(0,12, 1550), Vector3.new(0, 7, 1620),
            Vector3.new(0, 2, 1720),
        },
        Finish = Vector3.new(0, 2, 1760),
    },
}

-- == GUI ==
local gui = Instance.new("ScreenGui")
gui.Name = "GD_Menu"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.IgnoreGuiInset = true
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 500)
frame.Position = UDim2.new(0.5, -190, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 45)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 70)
title.BackgroundColor3 = Color3.fromRGB(90, 60, 220)
title.BorderSizePixel = 0
title.Text = "⚡ GEOMETRY DASH"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBlack
title.TextSize = 26
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 14)

local list = Instance.new("ScrollingFrame")
list.Name = "LevelList"
list.Size = UDim2.new(1, -20, 1, -160)
list.Position = UDim2.new(0, 10, 0, 80)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local help = Instance.new("TextLabel")
help.Size = UDim2.new(1, -20, 0, 60)
help.Position = UDim2.new(0, 10, 1, -70)
help.BackgroundColor3 = Color3.fromRGB(35, 35, 65)
help.BorderSizePixel = 0
help.TextColor3 = Color3.fromRGB(200, 200, 255)
help.Font = Enum.Font.Gotham
help.TextSize = 13
help.Text = "WASD / Space — управление\nR — рестарт уровня\nG — вкл/выкл Tool"
help.Parent = frame
Instance.new("UICorner", help).CornerRadius = UDim.new(0, 10)

-- == ЛОГИКА УРОВНЕЙ ==
local levelsFolder = Instance.new("Folder")
levelsFolder.Name = "GD_Levels"
levelsFolder.Parent = workspace

local currentLevel  = nil
local dying         = false
local exitPoint     = nil
local origWalkSpeed = 16

local function teleport(pos)
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

local function clearLevel()
    for _, c in ipairs(levelsFolder:GetChildren()) do c:Destroy() end
    currentLevel = nil
end

-- == ФУНКЦИЯ СТАРТА (объявлена заранее, чтобы кнопки её видели) ==
local startLevel

for i, lvl in ipairs(LEVELS) do
    local btn = Instance.new("TextButton")
    btn.Name = "Level_" .. i
    btn.Size = UDim2.new(1, -10, 0, 62)
    btn.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 20
    btn.Text = "▶  " .. lvl.Name
    btn.Parent = list
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function()
        startLevel(lvl)
    end)
end

startLevel = function(lvl)
    clearLevel()
    currentLevel = lvl

    -- сохраняем точку "выхода" (где игрок был до входа)
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") and not exitPoint then
        exitPoint = char.HumanoidRootPart.CFrame
    end

    -- платформы
    for _, spec in ipairs(lvl.Platforms) do
        local size, pos = spec[1], spec[2]
        local p = Instance.new("Part")
        p.Anchored = true
        p.Size = size
        p.Position = BASE + pos
        p.Color = Color3.fromRGB(60, 60, 220)
        p.Material = Enum.Material.Neon
        p.Name = "Platform"
        p.Parent = levelsFolder
    end

    -- шипы
    for _, pos in ipairs(lvl.Spikes) do
        local s = Instance.new("Part")
        s.Anchored = true
        s.Size = Vector3.new(3, 4, 3)
        s.Position = BASE + pos
        s.Color = Color3.fromRGB(255, 60, 60)
        s.Material = Enum.Material.Neon
        s.CanCollide = false
        s.Name = "Spike"
        s.Parent = levelsFolder
        s.Touched:Connect(function(hit)
            if dying or not currentLevel then return end
            local ch = lp.Character
            if ch and hit:IsDescendantOf(ch) then
                dying = true
                teleport(BASE + currentLevel.Start)
                task.wait(0.4)
                dying = false
            end
        end)
    end

    -- финиш
    local f = Instance.new("Part")
    f.Anchored = true
    f.Size = Vector3.new(20, 10, 3)
    f.Position = BASE + lvl.Finish
    f.Color = Color3.fromRGB(60, 255, 60)
    f.Material = Enum.Material.Neon
    f.CanCollide = false
    f.Name = "Finish"
    f.Parent = levelsFolder
    f.Touched:Connect(function(hit)
        if dying or not currentLevel then return end
        local ch = lp.Character
        if ch and hit:IsDescendantOf(ch) then
            dying = true
            -- телепорт на исходную
            if exitPoint then
                ch.HumanoidRootPart.CFrame = exitPoint
                exitPoint = nil
            end
            clearLevel()
            gui.Enabled = true
            task.wait(0.4)
            dying = false
        end
    end)

    -- ускорение персонажа для GD-ощущения
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        origWalkSpeed = hum.WalkSpeed
        hum.WalkSpeed  = 40
        hum.JumpPower  = 70
        hum.UseJumpPower = true
    end

    -- телепорт на старт
    teleport(BASE + lvl.Start)
    gui.Enabled = false
end

-- == TOOL (создаётся локально) ==
local templateFolder = Instance.new("Folder")
templateFolder.Name = "GD_Template"
templateFolder.Parent = workspace

local toolTemplate = Instance.new("Tool")
toolTemplate.Name = "GD_Tool"
toolTemplate.RequiresHandle = false
toolTemplate.CanBeDropped = false
toolTemplate.ToolTip = "Geometry Dash"
toolTemplate.Parent = templateFolder

local function bindTool(t)
    t.Equipped:Connect(function()
        gui.Enabled = true
    end)
    t.Unequipped:Connect(function()
        gui.Enabled = false
    end)
end

local function giveTool()
    if not lp:FindFirstChild("Backpack") then return end
    if lp.Backpack:FindFirstChild("GD_Tool") then return end
    if lp.Character and lp.Character:FindFirstChild("GD_Tool") then return end
    local t = toolTemplate:Clone()
    bindTool(t)
    t.Parent = lp.Backpack
end

giveTool()

-- == ОБРАБОТКА РЕСПАВНА ==
lp.CharacterAdded:Connect(function()
    gui.Enabled = false
    clearLevel()
    task.wait(1)
    giveTool()
end)

-- == КЛАВИШИ ==
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    -- R — рестарт текущего уровня
    if input.KeyCode == Enum.KeyCode.R and currentLevel then
        teleport(BASE + currentLevel.Start)
    end
    -- G — вручную экипировать/снять Tool (если хотбар не сработал)
    if input.KeyCode == Enum.KeyCode.G then
        local char = lp.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            local t = char:FindFirstChild("GD_Tool") or lp.Backpack:FindFirstChild("GD_Tool")
            if t then
                if t.Parent == char then
                    hum:UnequipTools()
                else
                    hum:EquipTool(t)
                end
            end
        end
    end
end)

print("[GD] Чит загружен! Tool 'GD_Tool' добавлен в Backpack.")
