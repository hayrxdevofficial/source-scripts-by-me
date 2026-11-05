-- // NO-LEGS WALK — прячет ноги в торс, ходьба остаётся обычной //
-- R6 + R15. Меню перетаскиваемое. Старое меню удаляется.
-- Вставьте в executor.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

-- ================== УДАЛЯЕМ СТАРОЕ МЕНЮ ==================
local old = game.CoreGui:FindFirstChild("NoLegsWalkGui")
if old then old:Destroy() end
local old2 = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("NoLegsWalkGui")
if old2 then old2:Destroy() end
-- =========================================================

-- ================== НАСТРОЙКИ ==================
local LEG_PULL = 1.2   -- насколько глубоко задвигать ноги (studs).
                        -- 1.0 = стандарт. Если торчат — увеличь до 1.5–2.
                        -- Если «проваливаются» в грудь — уменьши до 0.6.
local HIDE_ENABLED = false
-- ================================================

-- ================== UI ==================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoLegsWalkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Кнопка в правом нижнем углу
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(1, -60, 1, -60)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
toggleBtn.Text = "🦵"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
toggleBtn.TextSize = 26
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

-- Основное меню
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 170)
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -85)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Заголовок (перетаскивание)
local titleBar = Instance.new("TextButton")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Text = "NO-LEGS WALK"
titleBar.TextColor3 = Color3.fromRGB(200, 200, 255)
titleBar.TextSize = 18
titleBar.Font = Enum.Font.GothamBold
titleBar.Parent = mainFrame

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

-- Кнопка включения/выключения
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0.85, 0, 0, 42)
hideBtn.Position = UDim2.new(0.075, 0, 0.3, 0)
hideBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
hideBtn.Text = "HIDE LEGS: OFF"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.TextSize = 15
hideBtn.Font = Enum.Font.GothamBold
hideBtn.Parent = mainFrame
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 8)

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.85, 0, 0, 32)
closeBtn.Position = UDim2.new(0.075, 0, 0.7, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
closeBtn.Text = "CLOSE"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.Gotham
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

toggleBtn.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)
closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

-- ================== ЛОГИКА ПРЯТАНИЯ НОГ ==================
local function hideLegs(enable)
    local character = LocalPlayer.Character
    if not character then return end

    local isR6 = character:FindFirstChild("Torso") ~= nil

    if isR6 then
        -- ============ R6 ============
        local torso    = character:FindFirstChild("Torso")
        local leftLeg  = character:FindFirstChild("Left Leg")
        local rightLeg = character:FindFirstChild("Right Leg")
        local leftHip  = torso and torso:FindFirstChild("Left Hip")
        local rightHip = torso and torso:FindFirstChild("Right Hip")

        if enable then
            if leftLeg and leftHip then
                if not leftHip:GetAttribute("OrigC0") then
                    leftHip:SetAttribute("OrigC0", leftHip.C0)
                    leftHip:SetAttribute("OrigC1", leftHip.C1)
                end
                leftHip.C0 = leftHip.C0 + Vector3.new(0, LEG_PULL, 0)
                leftLeg.Transparency = 1
                leftLeg.CanCollide = false
            end
            if rightLeg and rightHip then
                if not rightHip:GetAttribute("OrigC0") then
                    rightHip:SetAttribute("OrigC0", rightHip.C0)
                    rightHip:SetAttribute("OrigC1", rightHip.C1)
                end
                rightHip.C0 = rightHip.C0 + Vector3.new(0, LEG_PULL, 0)
                rightLeg.Transparency = 1
                rightLeg.CanCollide = false
            end
        else
            if leftLeg and leftHip and leftHip:GetAttribute("OrigC0") then
                leftHip.C0 = leftHip:GetAttribute("OrigC0")
                leftHip.C1 = leftHip:GetAttribute("OrigC1")
                leftLeg.Transparency = 0
                leftLeg.CanCollide = true
            end
            if rightLeg and rightHip and rightHip:GetAttribute("OrigC0") then
                rightHip.C0 = rightHip:GetAttribute("OrigC0")
                rightHip.C1 = rightHip:GetAttribute("OrigC1")
                rightLeg.Transparency = 0
                rightLeg.CanCollide = true
            end
        end
    else
        -- ============ R15 ============
        local lowerTorso = character:FindFirstChild("LowerTorso")
        local legParts = {
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot"
        }
        local leftHip  = lowerTorso and lowerTorso:FindFirstChild("LeftHip")
        local rightHip = lowerTorso and lowerTorso:FindFirstChild("RightHip")

        if enable then
            -- Прячем все сегменты ног
            for _, name in ipairs(legParts) do
                local p = character:FindFirstChild(name)
                if p then
                    p.Transparency = 1
                    p.CanCollide = false
                end
            end
            -- Задвигаем всю цепочку в торс через Hip.C0
            if leftHip then
                if not leftHip:GetAttribute("OrigC0") then
                    leftHip:SetAttribute("OrigC0", leftHip.C0)
                    leftHip:SetAttribute("OrigC1", leftHip.C1)
                end
                leftHip.C0 = leftHip.C0 + Vector3.new(0, LEG_PULL, 0)
            end
            if rightHip then
                if not rightHip:GetAttribute("OrigC0") then
                    rightHip:SetAttribute("OrigC0", rightHip.C0)
                    rightHip:SetAttribute("OrigC1", rightHip.C1)
                end
                rightHip.C0 = rightHip.C0 + Vector3.new(0, LEG_PULL, 0)
            end
        else
            -- Восстанавливаем
            for _, name in ipairs(legParts) do
                local p = character:FindFirstChild(name)
                if p then
                    p.Transparency = 0
                    p.CanCollide = true
                end
            end
            if leftHip and leftHip:GetAttribute("OrigC0") then
                leftHip.C0 = leftHip:GetAttribute("OrigC0")
                leftHip.C1 = leftHip:GetAttribute("OrigC1")
            end
            if rightHip and rightHip:GetAttribute("OrigC0") then
                rightHip.C0 = rightHip:GetAttribute("OrigC0")
                rightHip.C1 = rightHip:GetAttribute("OrigC1")
            end
        end
    end
end

-- Обработчик кнопки
hideBtn.MouseButton1Click:Connect(function()
    HIDE_ENABLED = not HIDE_ENABLED
    if HIDE_ENABLED then
        hideBtn.Text = "HIDE LEGS: ON"
        hideBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 200)
    else
        hideBtn.Text = "HIDE LEGS: OFF"
        hideBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    end
    hideLegs(HIDE_ENABLED)
end)

-- Автоприменение после респавна (если было включено)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if HIDE_ENABLED then
        hideLegs(true)
    end
end)
