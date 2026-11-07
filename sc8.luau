-- LocalScript: StarterPlayer > StarterPlayerScripts
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- === 1. ИНТЕРФЕЙС ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerSelectMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 210)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -105)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Выберите игрока"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(0.9, 0, 0, 90)
playerListFrame.Position = UDim2.new(0.05, 0, 0, 45)
playerListFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 6
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.Parent = mainFrame

Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, 4)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = playerListFrame

local selectedPlayerName = nil

local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
            btn.Text = player.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextScaled = true
            btn.Parent = playerListFrame
            btn.MouseButton1Click:Connect(function()
                selectedPlayerName = player.Name
                titleLabel.Text = "Выбран: " .. player.Name
            end)
        end
    end
    playerListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    refreshPlayerList()
end)
refreshPlayerList()

local actionButton = Instance.new("TextButton")
actionButton.Size = UDim2.new(0.9, 0, 0, 40)
actionButton.Position = UDim2.new(0.05, 0, 0, 150)
actionButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
actionButton.Text = "Плавный влёт"
actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
actionButton.Font = Enum.Font.SourceSansBold
actionButton.TextScaled = true
actionButton.Parent = mainFrame

Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 6)

-- === 2. НАСТРОЙКИ ПЛАВНОСТИ ===
local OFFSET_STUDS = 2      -- на сколько студов отлетать
local CYCLE_TIME   = 0.2    -- секунд на полный цикл "влёт -> отлёт -> влёт"
-- (увеличь до 2–3 для ещё более медленного, уменьши до 0.8 для более быстрого)

-- === 3. ЛОГИКА ===
local isActive = false
local connection = nil
local elapsed = 0

local function getMyHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getTargetHRP()
    if not selectedPlayerName then return nil end
    local tgt = Players:FindFirstChild(selectedPlayerName)
    return tgt and tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
end

local function stopLoop()
    isActive = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
    actionButton.Text = "Плавный влёт"
end

local function startLoop()
    if isActive then
        stopLoop()
        return
    end
    if not selectedPlayerName then
        warn("Сначала выберите игрока!")
        return
    end

    isActive = true
    elapsed = 0
    actionButton.Text = "Остановить"

    connection = RunService.Heartbeat:Connect(function(dt)
        if not isActive then return end

        local myHRP = getMyHRP()
        local tgtHRP = getTargetHRP()
        if not myHRP or not tgtHRP then return end

        elapsed += dt

        -- Синусоида от 0 до 1:
        --   k = 0  -> влетаем В игрока (offset = 0)
        --   k = 1  -> отлетаем на OFFSET_STUDS назад
        local phase = (elapsed / CYCLE_TIME) * math.pi * 2 - math.pi / 2
        local k = (math.sin(phase) + 1) / 2
        local offset = k * OFFSET_STUDS

        -- Плавно ставим персонажа относительно цели
        myHRP.CFrame = tgtHRP.CFrame * CFrame.new(0, 0, offset)

        -- Гасим физику, чтобы персонаж не "дёргался" от собственных импульсов
        myHRP.AssemblyLinearVelocity = Vector3.zero
        myHRP.AssemblyAngularVelocity = Vector3.zero
    end)
end

actionButton.MouseButton1Click:Connect(startLoop)

-- === 4. СБРОС ПРИ РЕСПАВНЕ ===
LocalPlayer.CharacterAdded:Connect(function()
    stopLoop()
end)
