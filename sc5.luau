-- ═══════════════════════════════════════════════════════════════
-- WINDOWS SCREEN (v27 - Face Player + Circle + Separate Spacing)
-- ═══════════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

local player = Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()

local WINDOW_ID  = "110547096233249"
local CLONE_NAME = "ScreenWindow"
local GRID_W     = 5
local GRID_H     = 6
local TOTAL      = GRID_W * GRID_H -- 30

-- ═══════════════ НАСТРОЙКИ ═══════════════
local settings = {
    shape       = "screen",  -- "screen" | "circle"
    cellSize    = 5,         -- горизонтальный шаг (screen) / ширина пикселя (circle)
    rowSpacing  = 5,         -- вертикальный шаг (только screen)
    height      = 6,         -- высота над root
    distance    = 20,        -- дистанция вперёд (screen)
    radius      = 14,        -- радиус круга (circle)
    followPlayer = false,    -- false = экран зафиксирован в мире
    facingOffset = 0,        -- 0 или math.pi — поворот «лицом»
}

-- ═══════════════ СОСТОЯНИЕ ═══════════════
local pixels         = {}
local screenCFrame   = nil
local scriptActive   = true
local spawning       = false
local nextSlot       = 1
local heartbeatConn

-- ═══════════════ ОТПРАВКА ═══════════════
local function sendCommand(cmd)
    local remote = ReplicatedStorage:FindFirstChild("01_server")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer("cmd", cmd); return true, "01_server"
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("server") or n:find("admin") or n:find("command") then
                obj:FireServer("cmd", cmd); return true, obj:GetFullName()
            end
        end
    end
    return false, "no remote"
end

-- ═══════════════ GUI ═══════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScreenGUI"
screenGui.ResetOnSpawn = false
if not pcall(function() screenGui.Parent = CoreGui end) then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 48, 0, 48)
toggleBtn.Position = UDim2.new(1, -58, 1, -58)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.BorderSizePixel = 2
toggleBtn.BorderColor3 = Color3.fromRGB(100, 200, 255)
toggleBtn.Text = "📺"
toggleBtn.TextColor3 = Color3.fromRGB(100, 200, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 24
toggleBtn.Visible = false
toggleBtn.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 480)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(100, 200, 255)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 32, 42)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "📺 Windows Screen v27"
titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Parent = titleBar

local btnMin = Instance.new("TextButton")
btnMin.Size = UDim2.new(0, 30, 0, 30)
btnMin.Position = UDim2.new(1, -65, 0, 2)
btnMin.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
btnMin.Text = "—"
btnMin.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMin.Font = Enum.Font.SourceSansBold
btnMin.TextSize = 18
btnMin.Parent = titleBar

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 30, 0, 30)
btnClose.Position = UDim2.new(1, -33, 0, 2)
btnClose.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
btnClose.Text = "X"
btnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
btnClose.Font = Enum.Font.SourceSansBold
btnClose.TextSize = 16
btnClose.Parent = titleBar

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 28)
tabBar.Position = UDim2.new(0, 10, 0, 40)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -120)
contentFrame.Position = UDim2.new(0, 10, 0, 74)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local function createScrollingTab()
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 4
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible = false
    sf.Parent = contentFrame
    return sf
end

local tabMain    = createScrollingTab()
local tabSettings = createScrollingTab()
tabMain.Visible = true

local function createTab(text, xPos, width, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 1, 0)
    btn.Position = UDim2.new(0, xPos, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.Parent = tabBar
    btn.MouseButton1Click:Connect(function()
        for _, c in ipairs(tabBar:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                c.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        onClick()
    end)
end

createTab("Управление", 0,   170, function() tabMain.Visible=true; tabSettings.Visible=false end)
createTab("Настройки",   175, 170, function() tabMain.Visible=false; tabSettings.Visible=true end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 1, -46)
statusLabel.BackgroundColor3 = Color3.fromRGB(25, 32, 42)
statusLabel.Text = "Готов"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

local function setStatus(t)
    statusLabel.Text = t
    print("[Screen] " .. t)
end

-- ═══════════════ ПОЗИЦИЯ + ВРАЩЕНИЕ ПИКСЕЛЯ ═══════════════
-- Возвращает мировой CFrame: где окно и как оно повёрнуто (лицом к игроку)
local function computePixelCFrame(d, root)
    local worldPos
    if settings.shape == "circle" then
        local angle = (d.index - 1) / TOTAL * math.pi * 2
        worldPos = root.Position + Vector3.new(
            math.cos(angle) * settings.radius,
            settings.height,
            math.sin(angle) * settings.radius
        )
    else
        -- screen: плоская сетка перед игроком
        local screenCF = screenCFrame or (root.CFrame * CFrame.new(0, settings.height, -settings.distance))
        local cx = (GRID_W - 1) / 2
        local cy = (GRID_H - 1) / 2
        local offX = (d.col - cx) * settings.cellSize
        local offY = (cy - d.row) * settings.rowSpacing
        worldPos = (screenCF * CFrame.new(offX, offY, 0)).Position
    end

    -- Смотрим на игрока
    local targetPos = root.Position + Vector3.new(0, settings.height * 0.5, 0)
    local lookCF = CFrame.lookAt(worldPos, targetPos)
    if settings.facingOffset ~= 0 then
        lookCF = lookCF * CFrame.Angles(0, settings.facingOffset, 0)
    end
    return lookCF
end

-- ═══════════════ ОБРАБОТКА ОКНА ═══════════════
local function destroyForeignJoints(handle)
    for _, obj in ipairs(handle:GetChildren()) do
        if obj:IsA("JointInstance") or obj:IsA("Weld")
           or obj:IsA("WeldConstraint") or obj:IsA("Motor6D") then
            obj:Destroy()
        end
    end
end

local function setupWindow(window, col, row, index)
    local handle = window:FindFirstChild("Handle")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not handle or not root then window:Destroy() return end

    destroyForeignJoints(handle)
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    pcall(function()
        handle.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
    end)
    pcall(function() handle:SetNetworkOwner(player) end)

    local handleAttach = Instance.new("Attachment")
    handleAttach.Name = "ScreenPixel"
    handleAttach.Parent = handle

    local rootAttach = Instance.new("Attachment")
    rootAttach.Name = "ScreenTarget"
    rootAttach.Parent = root

    -- AlignPosition — позиция
    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachments
    alignPos.Attachment0 = handleAttach
    alignPos.Attachment1 = rootAttach
    alignPos.ApplyAtCenterOfMass = true
    alignPos.MaxForce = 5772000
    alignPos.MaxVelocity = math.huge / 9e110
    alignPos.ReactionForceEnabled = false
    alignPos.Responsiveness = 200
    alignPos.RigidityEnabled = false
    alignPos.Parent = handle

    -- AlignOrientation — поворот к игроку
    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachments
    alignOri.Attachment0 = handleAttach
    alignOri.Attachment1 = rootAttach
    alignOri.MaxAngularVelocity = math.huge / 9e110
    alignOri.MaxTorque = 5772000
    alignOri.PrimaryAxisOnly = false
    alignOri.ReactionTorqueEnabled = false
    alignOri.Responsiveness = 200
    alignOri.RigidityEnabled = false
    alignOri.Parent = handle

    window.Name = CLONE_NAME
    return {
        handle = handle, window = window,
        handleAttach = handleAttach, rootAttach = rootAttach,
        alignPos = alignPos, alignOri = alignOri,
        col = col, row = row, index = index,
    }
end

local function processWindow(window)
    if not spawning then return end
    if window.Name == CLONE_NAME then return end
    if not window:IsA("Accessory") then return end
    if not window:FindFirstChild("Handle") then return end

    local mySlot = nextSlot
    nextSlot = nextSlot + 1
    if mySlot > TOTAL then window:Destroy() return end

    local col = (mySlot - 1) % GRID_W
    local row = math.floor((mySlot - 1) / GRID_W)

    task.spawn(function()
        local t = 0
        while window.Parent ~= char and window.Parent and t < 3 do
            task.wait(0.1); t = t + 0.1
        end
        if window.Parent ~= char then window:Destroy() return end

        local data = setupWindow(window, col, row, mySlot)
        if not data then return end
        table.insert(pixels, data)
        setStatus(("окно %d/%d (col=%d row=%d)"):format(#pixels, TOTAL, col, row))
    end)
end

local function connectChar(c)
    c.ChildAdded:Connect(function(child)
        processWindow(child)
    end)
end
connectChar(char)

-- ═══════════════ HEARTBEAT ═══════════════
heartbeatConn = RunService.Heartbeat:Connect(function()
    if not scriptActive then return end
    if #pixels == 0 then return end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if settings.followPlayer and settings.shape == "screen" then
        screenCFrame = root.CFrame * CFrame.new(0, settings.height, -settings.distance)
    end

    local i = 1
    while i <= #pixels do
        local d = pixels[i]
        local alive = d.handle and d.handle.Parent
                   and d.rootAttach and d.rootAttach.Parent
        if not alive then
            if d.alignPos then d.alignPos:Destroy() end
            if d.alignOri then d.alignOri:Destroy() end
            if d.rootAttach then d.rootAttach:Destroy() end
            if d.handleAttach then d.handleAttach:Destroy() end
            table.remove(pixels, i)
        else
            -- Считаем желаемый мировой CFrame и переводим в локальный для root
            local targetWorldCF = computePixelCFrame(d, root)
            d.rootAttach.CFrame = root.CFrame:Inverse() * targetWorldCF

            -- Rescue
            local dist = (d.handle.Position - d.rootAttach.WorldPosition).Magnitude
            if dist > 30 then
                d.handle.Anchored = true
                d.handle.CFrame = d.rootAttach.WorldCFrame
                d.handle.AssemblyLinearVelocity = Vector3.zero
                d.handle.AssemblyAngularVelocity = Vector3.zero
                task.delay(0.05, function()
                    if d.handle and d.handle.Parent then
                        d.handle.Anchored = false
                    end
                end)
            end

            -- Anti-weld
            for _, obj in ipairs(d.handle:GetChildren()) do
                if obj:IsA("Weld") or obj:IsA("Motor6D") then
                    destroyForeignJoints(d.handle); break
                end
            end

            -- Ownership
            local owner = nil
            pcall(function() owner = d.handle:GetNetworkOwner() end)
            if owner ~= player then
                pcall(function() d.handle:SetNetworkOwner(player) end)
            end

            i = i + 1
        end
    end
end)

-- ═══════════════ ХЕЛПЕРЫ ═══════════════
local function makeButton(parent, text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createSlider(parent, label, yPos, minVal, maxVal, step, getVal, setVal, format)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.48, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.24, 0, 1, 0)
    valLabel.Position = UDim2.new(0.48, 0, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = format(getVal())
    valLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    valLabel.Font = Enum.Font.Code
    valLabel.TextSize = 12
    valLabel.Parent = frame

    local btnMinus = Instance.new("TextButton")
    btnMinus.Size = UDim2.new(0, 26, 0, 26)
    btnMinus.Position = UDim2.new(0.76, 0, 0, 3)
    btnMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btnMinus.Text = "−"
    btnMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnMinus.Font = Enum.Font.SourceSansBold
    btnMinus.TextSize = 16
    btnMinus.Parent = frame

    local btnPlus = Instance.new("TextButton")
    btnPlus.Size = UDim2.new(0, 26, 0, 26)
    btnPlus.Position = UDim2.new(1, -26, 0, 3)
    btnPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btnPlus.Text = "+"
    btnPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnPlus.Font = Enum.Font.SourceSansBold
    btnPlus.TextSize = 16
    btnPlus.Parent = frame

    local function update() valLabel.Text = format(getVal()) end
    btnMinus.MouseButton1Click:Connect(function()
        setVal(math.max(minVal, getVal() - step)); update()
    end)
    btnPlus.MouseButton1Click:Connect(function()
        setVal(math.min(maxVal, getVal() + step)); update()
    end)
end

-- ═══════════════ ОЧИСТКА ═══════════════
local function clearAllPixels()
    for _, obj in ipairs(char:GetChildren()) do
        if obj.Name == CLONE_NAME then obj:Destroy() end
    end
    for _, d in ipairs(pixels) do
        if d.alignPos then d.alignPos:Destroy() end
        if d.alignOri then d.alignOri:Destroy() end
        if d.rootAttach then d.rootAttach:Destroy() end
        if d.handleAttach then d.handleAttach:Destroy() end
    end
    pixels = {}
    nextSlot = 1
    spawning = false
end

-- ═══════════════ ВКЛАДКА УПРАВЛЕНИЕ ═══════════════
local spawnY = 0

local function refreshSpawnButtonColors()
    if shapeScreenBtn then
        shapeScreenBtn.BackgroundColor3 = (settings.shape == "screen")
            and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(45, 45, 45)
        shapeScreenBtn.TextColor3 = (settings.shape == "screen")
            and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    end
    if shapeCircleBtn then
        shapeCircleBtn.BackgroundColor3 = (settings.shape == "circle")
            and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(45, 45, 45)
        shapeCircleBtn.TextColor3 = (settings.shape == "circle")
            and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    end
end

makeButton(tabMain, "📺 Создать 30 окон", spawnY, Color3.fromRGB(50, 120, 160), function()
    if spawning then setStatus("уже спавнится..."); return end
    clearAllPixels()
    spawning = true
    nextSlot = 1

    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        screenCFrame = root.CFrame * CFrame.new(0, settings.height, -settings.distance)
    end

    task.spawn(function()
        for n = 1, TOTAL do
            sendCommand("-gh " .. WINDOW_ID)
            setStatus(("спавн %d/%d"):format(n, TOTAL))
            task.wait(0.22)
            sendCommand("-net")
            task.wait(0.08)
        end
        setStatus("все -gh отправлены, ждём...")
        task.wait(4)
        spawning = false
        setStatus(("готово: %d/%d окон"):format(#pixels, TOTAL))
    end)
end); spawnY = spawnY + 38

makeButton(tabMain, "🧹 Удалить все окна", spawnY, Color3.fromRGB(100, 50, 50), function()
    clearAllPixels()
    setStatus("удалено")
end); spawnY = spawnY + 42

-- Формы
local shapeLabel = Instance.new("TextLabel")
shapeLabel.Size = UDim2.new(1, 0, 0, 20)
shapeLabel.Position = UDim2.new(0, 0, 0, spawnY)
shapeLabel.BackgroundTransparency = 1
shapeLabel.Text = "ФОРМА:"
shapeLabel.TextColor3 = Color3.fromRGB(150, 180, 200)
shapeLabel.Font = Enum.Font.SourceSansBold
shapeLabel.TextSize = 12
shapeLabel.TextXAlignment = Enum.TextXAlignment.Left
shapeLabel.Parent = tabMain
spawnY = spawnY + 24

shapeScreenBtn = Instance.new("TextButton")
shapeScreenBtn.Size = UDim2.new(0.48, 0, 0, 36)
shapeScreenBtn.Position = UDim2.new(0, 0, 0, spawnY)
shapeScreenBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
shapeScreenBtn.Text = "▭ Плоский экран"
shapeScreenBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
shapeScreenBtn.Font = Enum.Font.SourceSans
shapeScreenBtn.TextSize = 13
shapeScreenBtn.Parent = tabMain
shapeScreenBtn.MouseButton1Click:Connect(function()
    settings.shape = "screen"
    refreshSpawnButtonColors()
    setStatus("форма: плоский экран")
end)

shapeCircleBtn = Instance.new("TextButton")
shapeCircleBtn.Size = UDim2.new(0.48, 0, 0, 36)
shapeCircleBtn.Position = UDim2.new(0.52, 0, 0, spawnY)
shapeCircleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
shapeCircleBtn.Text = "⭕ Круг вокруг"
shapeCircleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shapeCircleBtn.Font = Enum.Font.SourceSans
shapeCircleBtn.TextSize = 13
shapeCircleBtn.Parent = tabMain
shapeCircleBtn.MouseButton1Click:Connect(function()
    settings.shape = "circle"
    refreshSpawnButtonColors()
    setStatus("форма: круг")
end)
spawnY = spawnY + 42

makeButton(tabMain, "🔄 Повернуть на 180° (если задом)", spawnY, Color3.fromRGB(70, 70, 100), function()
    settings.facingOffset = (settings.facingOffset + math.pi) % (math.pi * 2)
    setStatus(settings.facingOffset == 0 and "лицом" or "развёрнуто на 180°")
end); spawnY = spawnY + 38

makeButton(tabMain, "📍 Перецентрировать экран", spawnY, Color3.fromRGB(70, 70, 100), function()
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        screenCFrame = root.CFrame * CFrame.new(0, settings.height, -settings.distance)
        setStatus("экран переставлен перед игроком")
    end
end); spawnY = spawnY + 38

makeButton(tabMain, "🔍 Дамп состояния", spawnY, Color3.fromRGB(50, 50, 80), function()
    local lines = {}
    for i, d in ipairs(pixels) do
        local p = d.handle and d.handle.Position or Vector3.zero
        local dist = (d.handle and d.rootAttach) and (d.handle.Position - d.rootAttach.WorldPosition).Magnitude or 0
        table.insert(lines, ("#%d c%d r%d y=%.0f d=%.0f"):format(i, d.col, d.row, p.Y, dist))
    end
    setStatus(("пикселей: %d | %s"):format(#pixels, table.concat(lines, " | ")))
end); spawnY = spawnY + 38

-- ═══════════════ ВКЛАДКА НАСТРОЙКИ ═══════════════
local sY = 0
createSlider(tabSettings, "Шаг по горизонтали", sY, 2, 12, 0.5,
    function() return settings.cellSize end,
    function(v) settings.cellSize = v end,
    function(v) return ("%.1f"):format(v) end)
sY = sY + 36

createSlider(tabSettings, "Шаг по вертикали", sY, 2, 20, 0.5,
    function() return settings.rowSpacing end,
    function(v) settings.rowSpacing = v end,
    function(v) return ("%.1f"):format(v) end)
sY = sY + 36

createSlider(tabSettings, "Расстояние вперёд", sY, 5, 60, 1,
    function() return settings.distance end,
    function(v)
        settings.distance = v
        if settings.shape == "screen" and not settings.followPlayer then
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then screenCFrame = root.CFrame * CFrame.new(0, settings.height, -v) end
        end
    end,
    function(v) return ("%.0f"):format(v) end)
sY = sY + 36

createSlider(tabSettings, "Радиус круга", sY, 5, 40, 1,
    function() return settings.radius end,
    function(v) settings.radius = v end,
    function(v) return ("%.0f"):format(v) end)
sY = sY + 36

createSlider(tabSettings, "Высота над игроком", sY, -5, 30, 1,
    function() return settings.height end,
    function(v)
        settings.height = v
        if settings.shape == "screen" and not settings.followPlayer then
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then screenCFrame = root.CFrame * CFrame.new(0, v, -settings.distance) end
        end
    end,
    function(v) return ("%.0f"):format(v) end)
sY = sY + 40

local followBtn = makeButton(tabSettings, "📌 Экран зафиксирован в мире", sY, Color3.fromRGB(50, 80, 100), function() end)
sY = sY + 38
followBtn.MouseButton1Click:Connect(function()
    settings.followPlayer = not settings.followPlayer
    if settings.followPlayer then
        followBtn.Text = "📌 Экран следует за игроком"
        followBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 50)
    else
        followBtn.Text = "📌 Экран зафиксирован в мире"
        followBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 100)
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then screenCFrame = root.CFrame * CFrame.new(0, settings.height, -settings.distance) end
    end
end)

-- ═══════════════ ОБРАБОТЧИКИ ОКНА ═══════════════
toggleBtn.MouseButton1Click:Connect(function()
    toggleBtn.Visible = false; mainFrame.Visible = true
end)
btnMin.MouseButton1Click:Connect(function()
    mainFrame.Visible = false; toggleBtn.Visible = true
end)
btnClose.MouseButton1Click:Connect(function()
    scriptActive = false; spawning = false
    clearAllPixels()
    if heartbeatConn then heartbeatConn:Disconnect() end
    screenGui:Destroy()
end)

-- ═══════════════ РЕСПАВН ═══════════════
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    pixels = {}
    nextSlot = 1
    spawning = false
    connectChar(newChar)
    setStatus("респавн — создай экран заново")
end)

setStatus("v27 загружен — жми «Создать 30 окон»")
