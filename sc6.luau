-- ═══════════════════════════════════════════════════════════════
-- R6 HANDS (v33 - XYZ Rotation)
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local HAND_ID = "81845947659416"
local CLONE_NAME = "R6Hand"
local MAX_HANDS = 2

-- ═══════════════ НАСТРОЙКИ ═══════════════
local settings = {
    forward = 1,       -- насколько вытянуть вперёд
    height = 3.5,      -- высота рук над головой
    width = 2.5,       -- расстояние между руками по бокам
    bobSpeed = 2,      -- скорость покачивания
    bobAmp = 0.3,      -- амплитуда покачивания
    doWave = false,    -- махать руками?
    
    -- Повороты в градусах (0 = стандартный вид)
    rotX = 0,          -- наклон вперед/назад (Pitch)
    rotY = 0,          -- поворот влево/вправо (Yaw)
    rotZ = 0,          -- крен вбок (Roll)
}

-- ═══════════════ СОСТОЯНИЕ ═══════════════
local hands = {}
local scriptActive = true
local spawning = false
local nextSlot = 1
local heartbeatConn
local waveTime = 0

-- ═══════════════ ОТПРАВКА КОМАНД ═══════════════
local function sendCommand(cmd)
    local remote = ReplicatedStorage:FindFirstChild("01_server")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer("cmd", cmd); return true
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("server") or n:find("admin") or n:find("command") then
                obj:FireServer("cmd", cmd); return true
            end
        end
    end
    return false
end

-- ═══════════════ GUI ═══════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HandsGUI"
screenGui.ResetOnSpawn = false
if not pcall(function() screenGui.Parent = CoreGui end) then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 48, 0, 48)
toggleBtn.Position = UDim2.new(1, -58, 1, -58)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.BorderSizePixel = 2
toggleBtn.BorderColor3 = Color3.fromRGB(255, 150, 100)
toggleBtn.Text = "🤲"
toggleBtn.TextColor3 = Color3.fromRGB(255, 150, 100)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 24
toggleBtn.Visible = false
toggleBtn.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 450)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 150, 100)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 25, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🤲 R6 Hands v33 (XYZ)"
titleLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
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

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -80)
contentFrame.Position = UDim2.new(0, 10, 0, 44)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 4
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollingFrame.Parent = contentFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 1, -34)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.Text = "Готов"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

local function setStatus(t)
    statusLabel.Text = t
    print("[Hands] " .. t)
end

-- ═══════════════ ЛОГИКА РУК ═══════════════
local function destroyForeignJoints(handle)
    for _, obj in ipairs(handle:GetChildren()) do
        if obj:IsA("JointInstance") or obj:IsA("Weld")
           or obj:IsA("WeldConstraint") or obj:IsA("Motor6D") then
            obj:Destroy()
        end
    end
end

local function setupHand(handModel, isLeft)
    local handle = handModel:FindFirstChild("Handle")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not handle or not root then handModel:Destroy() return end

    destroyForeignJoints(handle)

    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    pcall(function()
        handle.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
    end)
    pcall(function() handle:SetNetworkOwner(player) end)

    local handleAttach = Instance.new("Attachment")
    handleAttach.Name = "HandAttach"
    handleAttach.Parent = handle

    local rootAttach = Instance.new("Attachment")
    rootAttach.Name = "HandTarget"
    rootAttach.Parent = root

    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
    alignPos.Attachment0 = handleAttach
    alignPos.Attachment1 = rootAttach
    alignPos.ApplyAtCenterOfMass = true
    alignPos.MaxForce = 999999999
    alignPos.MaxVelocity = math.huge
    alignPos.ReactionForceEnabled = false
    alignPos.Responsiveness = 200
    alignPos.RigidityEnabled = true
    alignPos.Parent = handle

    local alignOri = Instance.new("AlignOrientation")
    alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
    alignOri.Attachment0 = handleAttach
    alignOri.Attachment1 = rootAttach
    alignOri.MaxAngularVelocity = math.huge
    alignOri.MaxTorque = 999999999
    alignOri.PrimaryAxisOnly = false
    alignOri.ReactionTorqueEnabled = false
    alignOri.Responsiveness = 200
    alignOri.RigidityEnabled = true
    alignOri.Parent = handle

    handModel.Name = CLONE_NAME
    return {
        handle = handle, model = handModel,
        handleAttach = handleAttach, rootAttach = rootAttach,
        alignPos = alignPos, alignOri = alignOri,
        isLeft = isLeft,
    }
end

local function processHand(handModel)
    if not spawning then return end
    if handModel.Name == CLONE_NAME then return end
    if not handModel:IsA("Accessory") and not handModel:IsA("Tool") then return end
    if not handModel:FindFirstChild("Handle") then return end

    local mySlot = nextSlot
    nextSlot = nextSlot + 1
    if mySlot > MAX_HANDS then handModel:Destroy() return end

    local isLeft = (mySlot == 1)

    task.spawn(function()
        local t = 0
        while handModel.Parent ~= char and handModel.Parent and t < 3 do
            task.wait(0.1); t = t + 0.1
        end
        if handModel.Parent ~= char then handModel:Destroy() return end

        local data = setupHand(handModel, isLeft)
        if not data then return end
        table.insert(hands, data)
        setStatus(("рука %d/%d (%s)"):format(#hands, MAX_HANDS, isLeft and "левая" or "правая"))
    end)
end

local function connectChar(c)
    c.ChildAdded:Connect(function(child)
        processHand(child)
    end)
end
connectChar(char)

-- ═══════════════ ЦИКЛ ОБНОВЛЕНИЯ ═══════════════
heartbeatConn = RunService.Heartbeat:Connect(function(dt)
    if not scriptActive then return end
    if #hands == 0 then return end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    waveTime = waveTime + dt

    local i = 1
    while i <= #hands do
        local d = hands[i]
        local alive = d.handle and d.handle.Parent and d.rootAttach and d.rootAttach.Parent
        if not alive then
            if d.alignPos then d.alignPos:Destroy() end
            if d.alignOri then d.alignOri:Destroy() end
            if d.rootAttach then d.rootAttach:Destroy() end
            if d.handleAttach then d.handleAttach:Destroy() end
            table.remove(hands, i)
        else
            if d.handle.Massless ~= true then d.handle.Massless = true end
            if d.handle.CanCollide then d.handle.CanCollide = false end
            if d.handle.Anchored then d.handle.Anchored = false end

            local sign = d.isLeft and -1 or 1
            local offsetX = sign * settings.width
            local offsetY = settings.height
            local offsetZ = -settings.forward

            if settings.doWave then
                local waveOffset = math.sin(waveTime * 4 + (d.isLeft and 0 or math.pi)) * 1.5
                offsetY = offsetY + math.max(0, waveOffset)
            else
                offsetY = offsetY + math.sin(waveTime * settings.bobSpeed) * settings.bobAmp
            end

            -- Поворот по X, Y, Z (переводим градусы в радианы)
            local rotOffset = CFrame.Angles(
                math.rad(settings.rotX),
                math.rad(settings.rotY),
                math.rad(settings.rotZ)
            )

            local targetCF = root.CFrame * CFrame.new(offsetX, offsetY, offsetZ) * rotOffset
            d.rootAttach.CFrame = root.CFrame:Inverse() * targetCF

            local dist = (d.handle.Position - d.rootAttach.WorldPosition).Magnitude
            if dist > 5 then
                d.handle.CFrame = d.rootAttach.WorldCFrame
                d.handle.AssemblyLinearVelocity = Vector3.zero
                d.handle.AssemblyAngularVelocity = Vector3.zero
            end

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

-- ═══════════════ ХЕЛПЕРЫ GUI ═══════════════
local function makeButton(text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = scrollingFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createSlider(label, yPos, minVal, maxVal, step, getVal, setVal, format)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.Position = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = scrollingFrame

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
    valLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
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
local function clearAllHands()
    for _, obj in ipairs(char:GetChildren()) do
        if obj.Name == CLONE_NAME then obj:Destroy() end
    end
    for _, d in ipairs(hands) do
        if d.alignPos then d.alignPos:Destroy() end
        if d.alignOri then d.alignOri:Destroy() end
        if d.rootAttach then d.rootAttach:Destroy() end
        if d.handleAttach then d.handleAttach:Destroy() end
    end
    hands = {}
    nextSlot = 1
    spawning = false
end

-- ═══════════════ СБОРКА ИНТЕРФЕЙСА ═══════════════
local y = 0
makeButton("🤲 Создать 2 руки", y, Color3.fromRGB(50, 120, 80), function()
    if spawning then setStatus("уже спавнится..."); return end
    clearAllHands()
    spawning = true
    nextSlot = 1

    task.spawn(function()
        for n = 1, MAX_HANDS do
            sendCommand("-gh " .. HAND_ID)
            setStatus(("спавн %d/%d"):format(n, MAX_HANDS))
            task.wait(0.3)
            sendCommand("-net")
            task.wait(0.1)
        end
        task.wait(3)
        spawning = false
        setStatus(("готово: %d/%d рук"):format(#hands, MAX_HANDS))
    end)
end); y = y + 42

makeButton("🧹 Удалить руки", y, Color3.fromRGB(100, 50, 50), function()
    clearAllHands()
    setStatus("руки удалены")
end); y = y + 46

local waveBtn = makeButton("👋 Махать (ВЫКЛ)", y, Color3.fromRGB(60, 60, 60), function() end)
y = y + 42
waveBtn.MouseButton1Click:Connect(function()
    settings.doWave = not settings.doWave
    waveBtn.Text = settings.doWave and "👋 Махать (ВКЛ)" or "👋 Махать (ВЫКЛ)"
    waveBtn.BackgroundColor3 = settings.doWave and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(60, 60, 60)
end)

local lblPos = Instance.new("TextLabel")
lblPos.Size = UDim2.new(1, 0, 0, 20)
lblPos.Position = UDim2.new(0, 0, 0, y)
lblPos.BackgroundTransparency = 1
lblPos.Text = "ПОЗИЦИЯ:"
lblPos.TextColor3 = Color3.fromRGB(200, 150, 150)
lblPos.Font = Enum.Font.SourceSansBold
lblPos.TextSize = 12
lblPos.TextXAlignment = Enum.TextXAlignment.Left
lblPos.Parent = scrollingFrame
y = y + 24

createSlider("Высота", y, -5, 10, 0.5,
    function() return settings.height end,
    function(v) settings.height = v end,
    function(v) return ("%.1f"):format(v) end)
y = y + 36

createSlider("Ширина", y, 0, 10, 0.5,
    function() return settings.width end,
    function(v) settings.width = v end,
    function(v) return ("%.1f"):format(v) end)
y = y + 36

createSlider("Вперёд", y, -2, 10, 0.5,
    function() return settings.forward end,
    function(v) settings.forward = v end,
    function(v) return ("%.1f"):format(v) end)
y = y + 36

local lblRot = Instance.new("TextLabel")
lblRot.Size = UDim2.new(1, 0, 0, 20)
lblRot.Position = UDim2.new(0, 0, 0, y)
lblRot.BackgroundTransparency = 1
lblRot.Text = "ПОВОРОТ (градусы):"
lblRot.TextColor3 = Color3.fromRGB(200, 150, 150)
lblRot.Font = Enum.Font.SourceSansBold
lblRot.TextSize = 12
lblRot.TextXAlignment = Enum.TextXAlignment.Left
lblRot.Parent = scrollingFrame
y = y + 24

createSlider("Поворот X", y, -180, 180, 5,
    function() return settings.rotX end,
    function(v) settings.rotX = v end,
    function(v) return ("%d°"):format(v) end)
y = y + 36

createSlider("Поворот Y", y, -180, 180, 5,
    function() return settings.rotY end,
    function(v) settings.rotY = v end,
    function(v) return ("%d°"):format(v) end)
y = y + 36

createSlider("Поворот Z", y, -180, 180, 5,
    function() return settings.rotZ end,
    function(v) settings.rotZ = v end,
    function(v) return ("%d°"):format(v) end)
y = y + 36

-- Обработчики
toggleBtn.MouseButton1Click:Connect(function()
    toggleBtn.Visible = false; mainFrame.Visible = true
end)
btnMin.MouseButton1Click:Connect(function()
    mainFrame.Visible = false; toggleBtn.Visible = true
end)
btnClose.MouseButton1Click:Connect(function()
    scriptActive = false; spawning = false
    clearAllHands()
    if heartbeatConn then heartbeatConn:Disconnect() end
    screenGui:Destroy()
end)

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    hands = {}
    nextSlot = 1
    spawning = false
    connectChar(newChar)
    setStatus("респавн — создай руки заново")
end)

setStatus("v33 загружен — нажми «Создать 2 руки»")
