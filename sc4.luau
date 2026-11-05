-- // FLING SPIN v2 — целое тело + перетаскиваемое меню + удаление старого //
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ================== УДАЛЯЕМ СТАРОЕ МЕНЮ ==================
local old = game.CoreGui:FindFirstChild("FlingSpinGui")
if old then old:Destroy() end
local old2 = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("FlingSpinGui")
if old2 then old2:Destroy() end
-- =========================================================

local DEFAULT_SPEED = 400   -- рад/с. Подбирай: 200–1500. Больше = опаснее.
local FLING_ENABLED = false
local currentAngular = nil

-- ================== UI ==================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlingSpinGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Кнопка открытия/закрытия
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(1, -60, 1, -60)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Text = "⚙"
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.TextSize = 30
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,10)

-- Основное меню
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 240)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -120)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Заголовок (за него тянем)
local titleBar = Instance.new("TextButton")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Text = "FLING SPIN MENU"
titleBar.TextColor3 = Color3.fromRGB(255, 80, 80)
titleBar.TextSize = 18
titleBar.Font = Enum.Font.GothamBold
titleBar.Parent = mainFrame

-- Перетаскивание
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Кнопка флинга
local flingBtn = Instance.new("TextButton")
flingBtn.Size = UDim2.new(0.85, 0, 0, 42)
flingBtn.Position = UDim2.new(0.075, 0, 0.22, 0)
flingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
flingBtn.Text = "FLING: OFF"
flingBtn.TextColor3 = Color3.fromRGB(255,255,255)
flingBtn.TextSize = 16
flingBtn.Font = Enum.Font.GothamBold
flingBtn.Parent = mainFrame
Instance.new("UICorner", flingBtn).CornerRadius = UDim.new(0, 8)

-- Ползунок скорости
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 0, 0.48, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Скорость: " .. DEFAULT_SPEED
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 13
speedLabel.Font = Enum.Font.Gotham
speedLabel.Parent = mainFrame

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(0.85, 0, 0, 8)
sliderBg.Position = UDim2.new(0.075, 0, 0.62, 0)
sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = mainFrame
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.25, 0, 1, 0) -- начальное положение = 400 из 1500
sliderFill.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local function updateSpeedFromX(x)
    local rel = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
    local speed = math.floor(100 + rel * 1400) -- 100..1500
    speedLabel.Text = "Скорость: " .. speed
    if currentAngular then
        currentAngular.AngularVelocity = Vector3.new(0, speed, 0)
    end
end

sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        updateSpeedFromX(input.Position.X)
        local conn
        conn = UIS.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                updateSpeedFromX(i.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                if conn then conn:Disconnect() end
            end
        end)
    end
end)

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.85, 0, 0, 32)
closeBtn.Position = UDim2.new(0.075, 0, 0.78, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
closeBtn.Text = "CLOSE"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.Gotham
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

toggleBtn.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

-- ================== ЛОГИКА СПИНА ==================
-- ВАЖНО: ничего не удаляем. Только отключаем коллизию у всех частей, кроме HRP.
-- Крутится вся сборка (все Motor6D-части вращаются вместе с HRP).
-- AutoRotate = false, чтобы Humanoid не боролся с вращением — ходьба работает
-- через MoveDirection от камеры.

local function applyFling(enable)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if enable then
        if hum then
            hum.AutoRotate = false
            -- чтобы физика не «убивала» при жёстком спине
            hum.PlatformStand = false
        end
        -- Отключаем коллизии у всех частей кроме HRP → тело не разрывает,
        -- но столкновение всё равно передаёт огромный момент.
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.CanCollide = false
            end
        end
        if hrp and not hrp:FindFirstChild("FlingAngular") then
            local ang = Instance.new("BodyAngularVelocity")
            ang.Name = "FlingAngular"
            ang.AngularVelocity = Vector3.new(0, DEFAULT_SPEED, 0)
            ang.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            ang.P = 100000
            ang.Parent = hrp
            currentAngular = ang
        end
    else
        if hrp then
            local ang = hrp:FindFirstChild("FlingAngular")
            if ang then ang:Destroy() end
        end
        currentAngular = nil
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
        if hum then hum.AutoRotate = true end
    end
end

flingBtn.MouseButton1Click:Connect(function()
    FLING_ENABLED = not FLING_ENABLED
    if FLING_ENABLED then
        flingBtn.Text = "FLING: ON"
        flingBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        flingBtn.Text = "FLING: OFF"
        flingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end
    applyFling(FLING_ENABLED)
end)

-- Авто-применение после респавна
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if FLING_ENABLED then applyFling(true) end
end)
