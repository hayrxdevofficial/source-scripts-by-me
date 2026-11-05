-- ═══════════════════════════════════════════════════════════════
-- CROWN ORBIT EXPLOIT (v23 - Event sending + AlignPosition + Rescue)
-- ═══════════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

local player = Players.LocalPlayer
local char   = player.Character or player.CharacterAdded:Wait()

local CROWN_ID   = "5731050224"
local CLONE_NAME = "OrbitCrown"

local ORBIT_RADIUS = 30
local ORBIT_HEIGHT = 2.5
local ORBIT_SPEED  = 5
local MAX_CROWNS   = 195
local FALL_THRESHOLD = -2   -- если Y ниже этой — «спасаем»

-- ═══════════════ GUI ═══════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrownOrbitGUI"
screenGui.ResetOnSpawn = false
if not pcall(function() screenGui.Parent = CoreGui end) then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 320)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.Text = "🌀 Crown Orbit v23"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.95, 0, 0, 120)
statusLabel.Position = UDim2.new(0.025, 0, 0, 190)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.Text = "Статус: —"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

local function setStatus(t)
    statusLabel.Text = "Статус:\n" .. t
    print("[Crown] " .. t)
end

local function createButton(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 32)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.Parent = mainFrame
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        task.wait(0.15)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        callback()
    end)
end

-- ═══════════════ 1. ОТПРАВКА КОМАНД (как в твоём рабочем v14) ═══════════════
local function sendCommand(cmd)
    -- Основной канал — 01_server:FireServer("cmd", cmd) — работает в твоей игре
    local remote = ReplicatedStorage:FindFirstChild("01_server")
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer("cmd", cmd)
        return true, "01_server"
    end
    -- Резерв: рекурсивный поиск похожего RemoteEvent
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("server") or n:find("admin") or n:find("command") then
                obj:FireServer("cmd", cmd)
                return true, obj:GetFullName()
            end
        end
    end
    -- Последний шанс — старый чат (на случай гибридных игр)
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local sayRequest = chatEvents and chatEvents:FindFirstChild("SayMessageRequest")
    if sayRequest then
        sayRequest:FireServer(cmd, "All")
        return true, "chat"
    end
    return false, "no remote"
end

-- ═══════════════ 2. ДАННЫЕ ═══════════════
-- { crown, handle, rootAttach, handleAttach, alignPos, alignOri, lastGoodPos }
local crowns = {}
local orbitAngle = 0
local lastDebug = 0

-- ═══════════════ 3. СОЗДАНИЕ СВЯЗИ (настройки из рабочего HatOrbit) ═══════════════
local function createOrbitConstraint(handle, root)
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

    return handleAttach, rootAttach, alignPos, alignOri
end

-- Уничтожить любые чужие суставы (AccessoryWeld, Weld, Motor6D)
local function destroyForeignJoints(handle)
    local destroyed = 0
    for _, obj in ipairs(handle:GetChildren()) do
        if obj:IsA("JointInstance") or obj:IsA("Weld")
           or obj:IsA("WeldConstraint") or obj:IsA("Motor6D") then
            obj:Destroy()
            destroyed = destroyed + 1
        end
    end
    -- также проверим родителя-аксессуар
    local acc = handle.Parent
    if acc then
        for _, obj in ipairs(acc:GetChildren()) do
            if obj:IsA("Weld") or obj:IsA("Motor6D") or obj:IsA("WeldConstraint") then
                obj:Destroy()
                destroyed = destroyed + 1
            end
        end
    end
    return destroyed
end

-- ═══════════════ 4. ОБРАБОТКА КОРОНЫ ═══════════════
local function processCrown(crown)
    if not crown or not crown:FindFirstChild("Handle") then return end
    if crown.Name == CLONE_NAME then return end
    if #crowns >= MAX_CROWNS then crown:Destroy() return end

    task.wait(0.15)
    if crown.Parent ~= char then return end

    local handle = crown:FindFirstChild("Handle")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not handle or not root then return end

    -- Срезаем все суставы
    destroyForeignJoints(handle)

    -- Физика
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    pcall(function()
        handle.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
    end)

    -- Сетевой владелец (не критично, но пробуем)
    pcall(function() handle:SetNetworkOwner(player) end)

    -- Создаём AlignPosition + AlignOrientation
    local handleAttach, rootAttach, alignPos, alignOri = createOrbitConstraint(handle, root)

    -- Сразу ставим в стартовую точку (чтобы не летела с головы)
    local startAngle = #crowns * (math.pi * 2 / MAX_CROWNS)
    local startPos = root.Position + Vector3.new(
        math.cos(startAngle) * ORBIT_RADIUS,
        ORBIT_HEIGHT,
        math.sin(startAngle) * ORBIT_RADIUS
    )
    handle.CFrame = CFrame.new(startPos)

    crown.Name = CLONE_NAME
    table.insert(crowns, {
        crown = crown,
        handle = handle,
        handleAttach = handleAttach,
        rootAttach = rootAttach,
        alignPos = alignPos,
        alignOri = alignOri,
        lastGoodPos = startPos,
        fallCount = 0,
    })
    setStatus(("корона %d/%d в орбите"):format(#crowns, MAX_CROWNS))
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

-- ═══════════════ 5. ЦИКЛ ОРБИТЫ + RESCUE ═══════════════
RunService.Heartbeat:Connect(function(dt)
    if #crowns == 0 then return end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    orbitAngle = (orbitAngle + ORBIT_SPEED * dt) % (math.pi * 2)
    local count = #crowns

    local i = 1
    while i <= #crowns do
        local d = crowns[i]
        local alive = d.crown and d.crown.Parent
                   and d.handle and d.handle.Parent
                   and d.rootAttach and d.rootAttach.Parent
        if not alive then
            if d.alignPos then d.alignPos:Destroy() end
            if d.alignOri then d.alignOri:Destroy() end
            if d.rootAttach then d.rootAttach:Destroy() end
            if d.handleAttach then d.handleAttach:Destroy() end
            table.remove(crowns, i)
        else
            local angle = orbitAngle + (i - 1) * (math.pi * 2 / count)
            -- Двигаем ЦЕЛЬ на HumanoidRootPart
            d.rootAttach.Position = Vector3.new(
                math.cos(angle) * ORBIT_RADIUS,
                ORBIT_HEIGHT,
                math.sin(angle) * ORBIT_RADIUS
            )

            -- ─── RESCUE: если корона упала, принудительно вернуть ───
            local pos = d.handle.Position
            if pos.Y < FALL_THRESHOLD then
                d.fallCount = d.fallCount + 1
                -- «Спасаем»: якорим на кадр в правильной точке, потом снимаем
                d.handle.Anchored = true
                d.handle.CFrame = d.rootAttach.WorldCFrame
                d.handle.AssemblyLinearVelocity = Vector3.zero
                d.handle.AssemblyAngularVelocity = Vector3.zero
                -- после короткой паузы отдадим обратно AlignPosition
                task.delay(0.05, function()
                    if d.handle and d.handle.Parent then
                        d.handle.Anchored = false
                    end
                end)
            else
                d.lastGoodPos = pos
            end

            -- ─── Защита от повторной сварки ───
            -- раз в ~0.3 сек проверяем, не появился ли AccessoryWeld снова
            local hasWeld = false
            for _, obj in ipairs(d.handle:GetChildren()) do
                if obj:IsA("Weld") or obj:IsA("Motor6D") then
                    hasWeld = true
                    break
                end
            end
            if hasWeld then
                destroyForeignJoints(d.handle)
            end

            -- ─── Проверка ownership ───
            local owner = nil
            pcall(function() owner = d.handle:GetNetworkOwner() end)
            if owner ~= player then
                pcall(function() d.handle:SetNetworkOwner(player) end)
            end

            i = i + 1
        end
    end

    -- Debug каждые 2 сек
    if tick() - lastDebug > 2 then
        lastDebug = tick()
        local info = {}
        for idx, d in ipairs(crowns) do
            local dist = 0
            if d.handle and d.rootAttach then
                dist = (d.handle.Position - d.rootAttach.WorldPosition).Magnitude
            end
            local anch = d.handle and d.handle.Anchored and "A" or "f"
            table.insert(info, ("#%d y=%.1f d=%.1f %s F%d"):format(
                idx, d.handle and d.handle.Position.Y or -999, dist, anch, d.fallCount or 0
            ))
        end
        setStatus(("crowns=%d\n%s"):format(#crowns, table.concat(info, " | ")))
    end
end)

-- ═══════════════ 6. КНОПКИ ═══════════════
createButton("🧪 1 корона (тест)", 40, function()
    local ok, via = sendCommand("-gh " .. CROWN_ID)
    setStatus(ok and ("-gh via "..via) or "FAIL remote")
    task.wait(0.3)
    local okNet, viaNet = sendCommand("-net")
    setStatus(("-gh via %s\n-net via %s"):format(via or "nil", viaNet and "ok" or "fail"))
end)

createButton("👑 Создать 6 корон (орбита)", 76, function()
    -- Очистка
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
    orbitAngle = 0

    local lastVia = "?"
    for n = 1, MAX_CROWNS do
        local ok, via = sendCommand("-gh " .. CROWN_ID)
        lastVia = via or "?"
        setStatus(("отправка %d/%d via %s"):format(n, MAX_CROWNS, lastVia))
        task.wait(0.25)
        -- -net после каждой короны
        sendCommand("-net")
        task.wait(0.1)
    end
    setStatus(("все -gh отправлены via %s\nждём появления корон..."):format(lastVia))
end)

createButton("🧹 Удалить короны", 112, function()
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
    setStatus("удалено")
end)

createButton("🔍 Дамп состояния", 148, function()
    local lines = {}
    for i, d in ipairs(crowns) do
        local p = d.handle and d.handle.Position or Vector3.zero
        local a = d.handle and d.handle.Anchored
        local owner = nil
        pcall(function() owner = d.handle:GetNetworkOwner() end)
        local hasWeld = false
        if d.handle then
            for _, obj in ipairs(d.handle:GetChildren()) do
                if obj:IsA("Weld") then hasWeld = true end
            end
        end
        table.insert(lines, ("#%d y=%.0f anch=%s own=%s weld=%s F%d"):format(
            i, p.Y, tostring(a),
            owner and owner.Name or "nil",
            tostring(hasWeld),
            d.fallCount or 0
        ))
    end
    setStatus(table.concat(lines, "\n"))
end)

-- ═══════════════ 7. РЕСПАВН ═══════════════
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    crowns = {}
    orbitAngle = 0
    connectChar(newChar)
    setStatus("респавн")
end)

setStatus("v23 загружен — жми Создать")
