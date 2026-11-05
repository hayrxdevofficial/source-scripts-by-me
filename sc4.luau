-- // FLING SPIN SCRIPT + UI //
-- Вставьте этот код в ваш executor.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- ================== НАСТРОЙКИ ==================
local SPIN_SPEED = 999999  -- Огромная скорость вращения (можно менять)
local FLING_ENABLED = false
-- ================================================

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlingSpinGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Кнопка открытия/закрытия (в правом нижнем углу)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(1, -60, 1, -60) -- Правый нижний угол
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.Text = "⚙"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 30
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toggleBtn

-- Основное меню (скрыто изначально)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 180)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -90) -- По центру
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "FLING SPIN MENU"
title.TextColor3 = Color3.fromRGB(255, 80, 80)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Кнопка включения/выключения флинга
local flingBtn = Instance.new("TextButton")
flingBtn.Size = UDim2.new(0.8, 0, 0, 45)
flingBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
flingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
flingBtn.Text = "FLING: OFF"
flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flingBtn.TextSize = 16
flingBtn.Font = Enum.Font.GothamBold
flingBtn.Parent = mainFrame

local flingCorner = Instance.new("UICorner")
flingCorner.CornerRadius = UDim.new(0, 8)
flingCorner.Parent = flingBtn

-- Кнопка закрытия меню
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.8, 0, 0, 35)
closeBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
closeBtn.Text = "CLOSE"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.Gotham
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Функция переключения видимости меню
local function toggleMenu()
    mainFrame.Visible = not mainFrame.Visible
end

toggleBtn.MouseButton1Click:Connect(toggleMenu)
closeBtn.MouseButton1Click:Connect(toggleMenu)

-- ================== ЛОГИКА ФЛИНГА ==================
local function applyFling(enable)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if enable then
        -- Удаляем все части, кроме HumanoidRootPart, чтобы только он сталкивался
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part:Destroy()
            end
        end

        -- Отключаем коллизию у HRP? Нет, оставляем включенной, чтобы сталкиваться.
        hrp.CanCollide = true

        -- Добавляем огромную угловую скорость
        local angular = Instance.new("BodyAngularVelocity")
        angular.Name = "FlingAngular"
        angular.AngularVelocity = Vector3.new(0, SPIN_SPEED, 0) -- Вращение вокруг оси Y
        angular.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        angular.P = 100000
        angular.Parent = hrp

        -- (Опционально) Добавляем линейную скорость, чтобы было сложнее остановиться
        -- local linear = Instance.new("BodyVelocity")
        -- linear.Velocity = Vector3.new(0, 0, 0)
        -- linear.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        -- linear.Parent = hrp
    else
        -- Выключаем: удаляем BodyAngularVelocity и перезагружаем персонажа
        local angular = hrp:FindFirstChild("FlingAngular")
        if angular then angular:Destroy() end
        -- Перезагрузка персонажа для восстановления частей
        LocalPlayer:LoadCharacter()
    end
end

-- Обработчик кнопки флинга
flingBtn.MouseButton1Click:Connect(function()
    FLING_ENABLED = not FLING_ENABLED
    if FLING_ENABLED then
        flingBtn.Text = "FLING: ON (ОПАСНО)"
        flingBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        applyFling(true)
    else
        flingBtn.Text = "FLING: OFF"
        flingBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        applyFling(false)
    end
end)

-- Следим за респавном: если персонаж перезагрузился, а флинг был включён,
-- нужно применить его снова (опционально, можно убрать).
LocalPlayer.CharacterAdded:Connect(function(char)
    if FLING_ENABLED then
        task.wait(0.5)
        applyFling(true)
    end
end)
