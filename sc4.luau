-- ═══════════════════════════════════════════════════════════════
-- CROWN ORBIT EXPLOIT (v24 - GUI, Settings, Shapes, Dragon)
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local CROWN_ID = "5731050224"
local CLONE_NAME = "OrbitCrown"
local MAX_COUNT = 90
local DIST_THRESHOLD = 90

-- ═══════════════ НАСТРОЙКИ ═══════════════
local settings = {
    count = 6,
    radius = 4.5,
    height = 2.5,
    speed = 2.5,
    shape = "circle",
    waveAmp = 1.5,
    waveFreq = 3,
    dragonAmp = 2,
    dragonFreq = 2,
    dragonPhase = 0.6,
}

-- ═══════════════ СОСТОЯНИЕ ═══════════════
local crowns = {}
local orbitAngle = 0
local scriptActive = true
local heartbeatConn
local setCount  -- предобъявление для замыканий

-- ═══════════════ ОТПРАВКА КОМАНД ═══════════════
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

-- ═══════════════ ФОРМЫ ═══════════════
local function computeOffset(angle, i, total, s)
    if s.shape == "circle" then
        return Vector3.new(math.cos(angle)*s.radius, s.height, math.sin(angle)*s.radius)
    elseif s.shape == "triangle" then
        local t = angle / (2*math.pi)
        local verts = {
            Vector2.new(math.cos(math.pi/2), math.sin(math.pi/2)),
            Vector2.new(math.cos(math.pi/2 + 2*math.pi/3), math.sin(math.pi/2 + 2*math.pi/3)),
            Vector2.new(math.cos(math.pi/2 + 4*math.pi/3), math.sin(math.pi/2 + 4*math.pi/3)),
        }
        local seg = math.floor(t*3) % 3
        local localT = (t*3) % 1
        local a, b = verts[seg+1], verts[(seg+1)%3 + 1]
        return Vector3.new(
            (a.X + (b.X-a.X)*localT) * s.radius,
            s.height,
            (a.Y + (b.Y-a.Y)*localT) * s.radius
        )
    elseif s.shape == "sphere" then
        local phi = (total > 1) and ((i-1)*math.pi/(total-1)) or (math.pi/2)
        local theta = angle
        return Vector3.new(
            s.radius * math.sin(phi) * math.cos(theta),
            s.height + s.radius * math.cos(phi),
            s.radius * math.sin(phi) * math.sin(theta)
        )
    elseif s.shape == "wave" then
        return Vector3.new(
            math.cos(angle)*s.radius,
            s.height + math.sin(angle*s.waveFreq + i*0.5) * s.waveAmp,
            math.sin(angle)*s.radius
        )
    elseif s.shape == "cube" then
        local half = s.radius * 0.7
        local verts = {
            Vector3.new(-half,-half,-half), Vector3.new(half,-half,-half),
            Vector3.new(half,-half,half), Vector3.new(-half,-half,half),
            Vector3.new(-half,half,-half), Vector3.new(half,half,-half),
            Vector3.new(half,half,half), Vector3.new(-half,half,half),
        }
        local edges = {
            {1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}
        }
        local t = angle/(2*math.pi)
        local ec = #edges
        local eIdx = math.floor(t*ec) % ec + 1
        local lT = (t*ec) % 1
        local e = edges[eIdx]
        local p = verts[e[1]]:Lerp(verts[e[2]], lT)
        return Vector3.new(p.X, s.height + p.Y, p.Z)
    elseif s.shape == "dragon" then
        local a = angle - i * s.dragonPhase
        local r = s.radius + math.sin(a*0.8 + i*0.4) * s.dragonAmp * 0.3
        local y = s.height + math.sin(a*s.dragonFreq + i*0.7) * s.dragonAmp
        return Vector3.new(math.cos(a)*r, y, math.sin(a)*r)
    end
    return Vector3.new(0, s.height, 0)
end

-- ═══════════════ GUI ═══════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrownOrbitGUI"
screenGui.ResetOnSpawn = false
if not pcall(function() screenGui.Parent = CoreGui end) then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Toggle-кнопка в правом нижнем углу
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 48, 0, 48)
toggleBtn.Position = UDim2.new(1, -58, 1, -58)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.BorderSizePixel = 2
toggleBtn.BorderColor3 = Color3.fromRGB(255, 215, 0)
toggleBtn.Text = "🌀"
toggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 24
toggleBtn.Visible = false
toggleBtn.Parent = screenGui

-- Главное окно
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 450)
mainFrame.Position = UDim2.new(0.5, -180, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🌀 Crown Orbit v24"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
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

-- Вкладки
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
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible = false
    sf.Parent = contentFrame
    return sf
end

local tabControl  = createScrollingTab()
local tabSettings = createScrollingTab()
local tabShapes   = createScrollingTab()
tabControl.Visible = true

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
        btn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        onClick()
    end)
end

createTab("Управление", 0,   110, function() tabControl.Visible=true;  tabSettings.Visible=false; tabShapes.Visible=false end)
createTab("Настройки",  115, 110, function() tabControl.Visible=false; tabSettings.Visible=true;  tabShapes.Visible=false end)
createTab("Формы",      230, 100, function() tabControl.Visible=false; tabSettings.Visible=false; tabShapes.Visible=true  end)

-- Статус
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 1, -46)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
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
    print("[Crown] " .. t)
end

-- Обработчики кнопок заголовка
toggleBtn.MouseButton1Click:Connect(function()
    toggleBtn.Visible = false
    mainFrame.Visible = true
end)
btnMin.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    toggleBtn.Visible = true
end)
btnClose.MouseButton1Click:Connect(function()
    scriptActive = false
    for _, obj in ipairs(char:GetChildren()) do
        if obj.Name == CLONE_NAME then obj:Destroy() end
    end
    for _, d in ipairs(crowns) do
        if d.alignPos then d.alignPos:Destroy() end
        if d.alignOri then d.alignOri:Destroy() end
        if d.rootAttach then d.rootAttach:Destroy() end
        if d.handleAttach then d.handleAttach:Destroy() end
    end
    crowns = {}
    if heartbeatConn then heartbeatConn:Disconnect() end
    screenGui:Destroy()
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

local function clearCrowns()
    for _, obj in ipairs(char:GetChildren()) do
        if obj.Name == CLONE_NAME then obj:Destroy() end
    end
    for _, d in ipairs(crowns) do
        if d.alignPos then d.alignPos:Destroy() end
        if d.alignOri then d.alignOri:Destroy() end
        if d.rootAttach then d.rootAttach:Destroy() end
        if d.handleAttach then d.handleAttach:Destroy() end
    end
    crowns = {}
end

-- ═══════════════ ФУНКЦИЯ ИЗМЕНЕНИЯ КОЛИЧЕСТВА ═══════════════
setCount = function(newCount)
    newCount = math.max(1, math.min(MAX_COUNT, math.floor(newCount)))
    local old = settings.count
    settings.count = newCount
    if newCount > old then
        task.spawn(function()
            for _ = old+1, newCount do
                sendCommand("-gh " .. CROWN_ID)
                task.wait(0.22)
                sendCommand("-net")
                task.wait(0.08)
            end
            setStatus(("доспавнено до %d"):format(newCount))
        end)
    elseif newCount < old then
        for _ = 1, (old - newCount) do
            if #crowns > 0 then
                local d = table.remove(crowns)
                if d.crown then d.crown:Destroy() end
                if d.alignPos then d.alignPos:Destroy() end
                if d.alignOri then d.alignOri:Destroy() end
                if d.rootAttach then d.rootAttach:Destroy() end
                if d.handleAttach then d.handleAttach:Destroy() end
            end
        end
        setStatus(("уменьшено до %d"):format(newCount))
    end
end

-- ═══════════════ ВКЛАДКА УПРАВЛЕНИЕ ═══════════════
local yPos = 0
makeButton(tabControl, "👑 Создать короны (по настройкам)", yPos, Color3.fromRGB(60, 100, 60), function()
    clearCrowns()
    orbitAngle = 0
    task.spawn(function()
        for n = 1, settings.count do
            sendCommand("-gh " .. CROWN_ID)
            setStatus(("отправка %d/%d"):format(n, settings.count))
            task.wait(0.22)
            sendCommand("-net")
            task.wait(0.08)
        end
        setStatus(("спавн %d корон завершён"):format(settings.count))
    end)
end); yPos = yPos + 38

makeButton(tabControl, "🧹 Удалить все короны", yPos, Color3.fromRGB(100, 50, 50), function()
    clearCrowns()
    setStatus("все короны удалены")
end); yPos = yPos + 38

local upBtn = Instance.new("TextButton")
upBtn.Size = UDim2.new(0.48, 0, 0, 34)
upBtn.Position = UDim2.new(0, 0, 0, yPos)
upBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 50)
upBtn.Text = "↑ Вверх +2"
upBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
upBtn.Font = Enum.Font.SourceSans
upBtn.TextSize = 14
upBtn.Parent = tabControl

local downBtn = Instance.new("TextButton")
downBtn.Size = UDim2.new(0.48, 0, 0, 34)
downBtn.Position = UDim2.new(0.52, 0, 0, yPos)
downBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 50)
downBtn.Text = "↓ Вниз -2"
downBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
downBtn.Font = Enum.Font.SourceSans
downBtn.TextSize = 14
downBtn.Parent = tabControl

upBtn.MouseButton1Click:Connect(function()
    settings.height = math.min(40, settings.height + 2)
    setStatus(("высота: %.1f"):format(settings.height))
end)
downBtn.MouseButton1Click:Connect(function()
    settings.height = math.max(-5, settings.height - 2)
    setStatus(("высота: %.1f"):format(settings.height))
end)
yPos = yPos + 38

makeButton(tabControl, "🔍 Дамп состояния", yPos, Color3.fromRGB(50, 50, 80), function()
    local lines = {}
    for i, d in ipairs(crowns) do
        local p = d.handle and d.handle.Position or Vector3.zero
        local dist = (d.handle and d.rootAttach) and (d.handle.Position - d.rootAttach.WorldPosition).Magnitude or 0
        table.insert(lines, ("#%d y=%.0f d=%.1f"):format(i, p.Y, dist))
    end
    setStatus(table.concat(lines, " | "))
end); yPos = yPos + 38

-- ═══════════════ ВКЛАДКА НАСТРОЙКИ ═══════════════
local function createSlider(parent, label, yPos, minVal, maxVal, step, getVal, setVal, format)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.25, 0, 1, 0)
    valLabel.Position = UDim2.new(0.45, 0, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = format(getVal())
    valLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    valLabel.Font = Enum.Font.Code
    valLabel.TextSize = 13
    valLabel.Parent = frame

    local btnMinus = Instance.new("TextButton")
    btnMinus.Size = UDim2.new(0, 28, 0, 26)
    btnMinus.Position = UDim2.new(0.75, 0, 0, 3)
    btnMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btnMinus.Text = "−"
    btnMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnMinus.Font = Enum.Font.SourceSansBold
    btnMinus.TextSize = 16
    btnMinus.Parent = frame

    local btnPlus = Instance.new("TextButton")
    btnPlus.Size = UDim2.new(0, 28, 0, 26)
    btnPlus.Position = UDim2.new(1, -28, 0, 3)
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

local sY = 0
createSlider(tabSettings, "Корон (макс 22)", sY, 1, MAX_COUNT, 1,
    function() return settings.count end,
    function(v) setCount(v) end,
    function(v) return tostring(math.floor(v)) end)
sY = sY + 36

createSlider(tabSettings, "Дистанция", sY, 1, 20, 0.5,
    function() return settings.radius end,
    function(v) settings.radius = v end,
    function(v) return ("%.1f"):format(v) end)
sY = sY + 36

createSlider(tabSettings, "Высота", sY, -5, 40, 0.5,
    function() return settings.height end,
    function(v) settings.height = v end,
    function(v) return ("%.1f"):format(v) end)
sY = sY + 36

createSlider(tabSettings, "Скорость", sY, 0.1, 10, 0.1,
    function() return settings.speed end,
    function(v) settings.speed = v end,
    function(v) return ("%.1f"):format(v) end)
sY = sY + 36

createSlider(tabSettings, "Амплитуда (волна/дракон)", sY, 0, 10, 0.5,
    function() return settings.waveAmp end,
    function(v) settings.waveAmp = v; settings.dragonAmp = v end,
    function(v) return ("%.1f"):format(v) end)
sY = sY + 36

-- ═══════════════ ВКЛАДКА ФОРМЫ ═══════════════
local shapeButtons = {}
local function makeShapeButton(text, yPos, shapeId)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = tabShapes
    shapeButtons[shapeId] = btn
    btn.MouseButton1Click:Connect(function()
        settings.shape = shapeId
        for k, b in pairs(shapeButtons) do
            local active = (k == shapeId)
            b.BackgroundColor3 = active and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(45, 45, 45)
            b.TextColor3 = active and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        end
        setStatus("форма: " .. shapeId)
    end)
end

local shapeY = 0
makeShapeButton("⭕ Круг",            shapeY, "circle");   shapeY = shapeY + 40
makeShapeButton("🔺 Треугольник",    shapeY, "triangle"); shapeY = shapeY + 40
makeShapeButton("🌐 Сфера (3D)",     shapeY, "sphere");   shapeY = shapeY + 40
makeShapeButton("🌊 Волна (верх-вниз)", shapeY, "wave");  shapeY = shapeY + 40
makeShapeButton("🧊 Куб (3D)",       shapeY, "cube");     shapeY = shapeY + 40
makeShapeButton("🐉 Небесный дракон", shapeY, "dragon");  shapeY = shapeY + 40

if shapeButtons["circle"] then
    shapeButtons["circle"].BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    shapeButtons["circle"].TextColor3 = Color3.fromRGB(0, 0, 0)
end

-- ═══════════════ ОБРАБОТКА КОРОНЫ ═══════════════
local function destroyForeignJoints(handle)
    local n = 0
    for _, obj in ipairs(handle:GetChildren()) do
        if obj:IsA("JointInstance") or obj:IsA("Weld")
           or obj:IsA("WeldConstraint") or obj:IsA("Motor6D") then
            obj:Destroy(); n = n + 1
        end
    end
    return n
end

local function processCrown(crown)
    if not crown or not crown:FindFirstChild("Handle") then return end
    if crown.Name == CLONE_NAME then return end
    if #crowns >= MAX_COUNT then crown:Destroy() return end
    task.wait(0.15)
    if crown.Parent ~= char then return end

    local handle = crown:FindFirstChild("Handle")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not handle or not root then return end

    destroyForeignJoints(handle)
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    pcall(function()
        handle.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
    end)
    pcall(function() handle:SetNetworkOwner(player) end)

    local handleAttach = Instance.new("Attachment")
    handleAttach.Name = "OrbitHandleAttach"
    handleAttach.Parent = handle

    local rootAttach = Instance.new("Attachment")
    rootAttach.Name = "OrbitRootTarget"
    rootAttach.Parent = root

    local alignPos = Instance.new("AlignPosition")
    alignPos.Attachment0 = handleAttach
    alignPos.Attachment1 = rootAttach
    alignPos.ApplyAtCenterOfMass = true
    alignPos.MaxForce = 5772000
    alignPos.MaxVelocity = math.huge / 9e110
    alignPos.ReactionForceEnabled = false
    alignPos.Responsiveness = 200
    alignPos.RigidityEnabled = false
    alignPos.Parent = handle

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Attachment0 = handleAttach
    alignOri.MaxAngularVelocity = math.huge / 9e110
    alignOri.MaxTorque = 5772000
    alignOri.PrimaryAxisOnly = false
    alignOri.ReactionTorqueEnabled = false
    alignOri.Responsiveness = 200
    alignOri.RigidityEnabled = false
    alignOri.Parent = handle

    local startAngle = #crowns * (math.pi * 2 / math.max(1, settings.count))
    local startOffset = computeOffset(startAngle, #crowns + 1, settings.count, settings)
    handle.CFrame = root.CFrame * CFrame.new(startOffset)

    crown.Name = CLONE_NAME
    table.insert(crowns, {
        crown = crown, handle = handle,
        handleAttach = handleAttach, rootAttach = rootAttach,
        alignPos = alignPos, alignOri = alignOri,
    })
    setStatus(("корона %d/%d"):format(#crowns, settings.count))
end

local function connectChar(c)
    c.ChildAdded:Connect(function(child)
        if child.Name == CLONE_NAME then return end
        if child.Name:find("Crown") or child.Name:find("Gold") then
            processCrown(child)
        end
    end)
end
connectChar(char)

-- ═══════════════ HEARTBEAT ═══════════════
heartbeatConn = RunService.Heartbeat:Connect(function(dt)
    if not scriptActive then return end
    if #crowns == 0 then return end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    orbitAngle = (orbitAngle + settings.speed * dt) % (math.pi * 2)
    local total = #crowns

    local i = 1
    while i <= #crowns do
        local d = crowns[i]
        local alive = d.crown and d.crown.Parent and d.handle and d.handle.Parent
                   and d.rootAttach and d.rootAttach.Parent
        if not alive then
            if d.alignPos then d.alignPos:Destroy() end
            if d.alignOri then d.alignOri:Destroy() end
            if d.rootAttach then d.rootAttach:Destroy() end
            if d.handleAttach then d.handleAttach:Destroy() end
            table.remove(crowns, i)
        else
            local angle = orbitAngle + (i - 1) * (math.pi * 2 / total)
            local offset = computeOffset(angle, i, total, settings)
            d.rootAttach.Position = offset

            -- Rescue: если улетела далеко от цели
            local dist = (d.handle.Position - d.rootAttach.WorldPosition).Magnitude
            if dist > DIST_THRESHOLD then
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

            -- Анти-пересварка
            for _, obj in ipairs(d.handle:GetChildren()) do
                if obj:IsA("Weld") or obj:IsA("Motor6D") then
                    destroyForeignJoints(d.handle); break
                end
            end

            local owner = nil
            pcall(function() owner = d.handle:GetNetworkOwner() end)
            if owner ~= player then
                pcall(function() d.handle:SetNetworkOwner(player) end)
            end
            i = i + 1
        end
    end
end)

-- ═══════════════ РЕСПАВН ═══════════════
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    crowns = {}
    orbitAngle = 0
    connectChar(newChar)
    setStatus("респавн")
end)

setStatus("v24 загружен — настрой и создавай")
