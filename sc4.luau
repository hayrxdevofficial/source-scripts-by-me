-- // REANIMATE FLY / HIDE LEGS //
-- Вставьте этот код в ваш executor.
-- ВНИМАНИЕ: Техника реанимации может не работать на очень новых играх с защитой.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- ================== НАСТРОЙКИ ==================
local FLY_SPEED = 60          -- Скорость полёта
local HIDE_LEGS = true       -- Скрыть ноги (спрятать в торс)
local FLY_ENABLED = false
local LEG_OFFSET = Vector3.new(0, 0, 0) -- Смещение ног внутрь торса
-- ================================================

-- Удаляем старые версии меню, чтобы не было дублей
local oldGui = game.CoreGui:FindFirstChild("ReanimateFlyGui")
if oldGui then oldGui:Destroy() end

-- ================== UI ==================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ReanimateFlyGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Кнопка в правом нижнем углу
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(1, -60, 1, -60)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
toggleBtn.Text = "🜁"
toggleBtn.TextColor3 = Color3.fromRGB(150, 220, 255)
toggleBtn.TextSize = 28
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

-- Основное меню
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 220)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -110)
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
titleBar.Text = "NO-LEGS FLY"
titleBar.TextColor3 = Color3.fromRGB(150, 220, 255)
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
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(0.85, 0, 0, 42)
flyBtn.Position = UDim2.new(0.075, 0, 0.25, 0)
flyBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 110)
flyBtn.Text = "FLY: OFF"
flyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyBtn.TextSize = 16
flyBtn.Font = Enum.Font.GothamBold
flyBtn.Parent = mainFrame
Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 8)

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

-- ================== ЛОГИКА РЕАНИМАЦИИ И ПОЛЁТА ==================
local flyVelocity = nil
local bodyGyro = nil
local legHiddenConnection = nil

-- Функция для скрытия ног (перемещение внутрь торса)
local function hideLegs(enable)
    local character = LocalPlayer.Character
    if not character then return end
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not torso then return end

    local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftUpperLeg")
    local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightUpperLeg")
    if not leftLeg or not rightLeg then return end

    -- Находим суставы (Motor6D) для ног
    local leftHip = torso:FindFirstChild("Left Hip") or torso:FindFirstChild("LeftUpperLeg")
    local rightHip = torso:FindFirstChild("Right Hip") or torso:FindFirstChild("RightUpperLeg")

    if enable then
        -- Сохраняем оригинальные C0 и C1, если ещё не сохранили
        if not leftLeg:GetAttribute("OrigC0") then
            if leftHip then
                leftLeg:SetAttribute("OrigC0", leftHip.C0)
                leftLeg:SetAttribute("OrigC1", leftHip.C1)
            end
            if rightHip then
                rightLeg:SetAttribute("OrigC0", rightHip.C0)
                rightLeg:SetAttribute("OrigC1", rightHip.C1)
            end
        end
        -- Смещаем суставы так, чтобы ноги ушли внутрь торса
        if leftHip then
            leftHip.C0 = CFrame.new(LEG_OFFSET) * leftHip.C0
        end
        if rightHip then
            rightHip.C0 = CFrame.new(LEG_OFFSET) * rightHip.C0
        end
        -- Делаем ноги невидимыми и отключаем коллизию
        leftLeg.Transparency = 1
        rightLeg.Transparency = 1
        leftLeg.CanCollide = false
        rightLeg.CanCollide = false
    else
        -- Восстанавливаем всё обратно
        if leftHip and leftLeg:GetAttribute("OrigC0") then
            leftHip.C0 = leftLeg:GetAttribute("OrigC0")
            leftHip.C1 = leftLeg:GetAttribute("OrigC1")
        end
        if rightHip and rightLeg:GetAttribute("OrigC0") then
            rightHip.C0 = rightLeg:GetAttribute("OrigC0")
            rightHip.C1 = rightLeg:GetAttribute("OrigC1")
        end
        leftLeg.Transparency = 0
        rightLeg.Transparency = 0
        leftLeg.CanCollide = true
        rightLeg.CanCollide = true
    end
end

-- Функция для включения/выключения полёта (парения)
local function setFly(enable)
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    if enable then
        -- Отключаем гравитацию и включаем "парение"
        humanoid.PlatformStand = true -- Позволяет парить и управлять движением
        humanoid.AutoRotate = false

        -- Создаём BodyGyro для стабилизации ориентации (чтобы не кувыркался)
        if not bodyGyro then
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.Name = "FlyGyro"
            bodyGyro.P = 10000
            bodyGyro.D = 500
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.CFrame = hrp.CFrame
            bodyGyro.Parent = hrp
        end

        -- Создаём BodyVelocity для управления движением
        if not flyVelocity then
            flyVelocity = Instance.new("BodyVelocity")
            flyVelocity.Name = "FlyVelocity"
            flyVelocity.Velocity = Vector3.new(0, 0, 0)
            flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flyVelocity.P = 1250
            flyVelocity.Parent = hrp
        end

        -- Скрываем ноги, если включено
        if HIDE_LEGS then
            hideLegs(true)
            -- Следим за респавном, чтобы снова спрятать ноги
            if legHiddenConnection then legHiddenConnection:Disconnect() end
            legHiddenConnection = LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                if FLY_ENABLED and HIDE_LEGS then hideLegs(true) end
            end)
        end
    else
        -- Отключаем полёт
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
        if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
        if legHiddenConnection then legHiddenConnection:Disconnect(); legHiddenConnection = nil end
        -- Возвращаем ноги на место
        hideLegs(false)
    end
end

-- Обработчик кнопки
flyBtn.MouseButton1Click:Connect(function()
    FLY_ENABLED = not FLY_ENABLED
    if FLY_ENABLED then
        flyBtn.Text = "FLY: ON"
        flyBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 220)
    else
        flyBtn.Text = "FLY: OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 110)
    end
    setFly(FLY_ENABLED)
end)

-- Управление полётом (WASD + камера)
RunService.RenderStepped:Connect(function()
    if not FLY_ENABLED or not flyVelocity then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    -- Получаем направление от камеры
    local camera = workspace.CurrentCamera
    local moveDirection = humanoid.MoveDirection
    local cameraDirection = camera.CFrame.LookVector

    -- Комбинируем движение вперёд/назад и влево/вправо с направлением камеры
    local flyDirection = (cameraDirection * moveDirection.Z + camera.CFrame.RightVector * moveDirection.X).Unit
    if moveDirection.Magnitude < 0.1 then
        flyDirection = Vector3.new(0, 0, 0)
    end

    -- Добавляем вертикальное управление (Space = вверх, Shift = вниз)
    local vertical = 0
    if UIS:IsKeyDown(Enum.KeyCode.Space) then vertical = 1 end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vertical = -1 end

    local finalVelocity = flyDirection * FLY_SPEED + Vector3.new(0, vertical * FLY_SPEED, 0)
    flyVelocity.Velocity = finalVelocity

    -- Стабилизируем гироскоп по направлению камеры
    if bodyGyro then
        bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + cameraDirection)
    end
end)

-- Автоматическое выключение при смерти (чтобы не зависнуть в полёте)
LocalPlayer.CharacterAdded:Connect(function()
    if FLY_ENABLED then
        FLY_ENABLED = false
        flyBtn.Text = "FLY: OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 110)
        -- Очистка
        if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    end
end)
