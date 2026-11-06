-- ═══════════════════════════════════════════════════════════════
-- CROWN MAN (v59 - Fixed Crash (Motor6D names) + Smooth No Player)
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local backpack = player:WaitForChild("Backpack")

local CROWN_ID = "5731050224"
local CLONE_NAME = "CrownManPart"

local LAYOUT = {
    {bone="Head", offset=Vector3.new(0, 0.5, 0)},
    {bone="Torso", offset=Vector3.new(-0.5, 0.5, 0)}, {bone="Torso", offset=Vector3.new(0.5, 0.5, 0)},
    {bone="Torso", offset=Vector3.new(-0.5, -0.5, 0)}, {bone="Torso", offset=Vector3.new(0.5, -0.5, 0)},
    {bone="Left Arm", offset=Vector3.new(0, -0.5, 0)}, {bone="Left Arm", offset=Vector3.new(0, -1.5, 0)},
    {bone="Right Arm", offset=Vector3.new(0, -0.5, 0)}, {bone="Right Arm", offset=Vector3.new(0, -1.5, 0)},
    {bone="Left Leg", offset=Vector3.new(0, -0.5, 0)}, {bone="Left Leg", offset=Vector3.new(0, -1.5, 0)},
    {bone="Right Leg", offset=Vector3.new(0, -0.5, 0)}, {bone="Right Leg", offset=Vector3.new(0, -1.5, 0)},
}
local TOTAL_CROWNS = #LAYOUT

local settings = {
    sizeMultiplier = 1.5,
    sideOffset = -5,
    heightOffset = 2.5,
    forwardOffset = 3.0,
    armHeightOffset = 1.0,
    ghostSpeed = 16,
}

local activeParts = {}
local spawning = false
local heartbeatConn
local nextSlot = 1

local possessionMode = false
local isReturning = false
local dummyRig = nil
local dummyHum = nil
local dummyRoot = nil
local dummyAnimator = nil
local currentAnimTrack = nil

local dummyIdleTrack = nil
local dummyRunTrack = nil

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

local function getBone(name)
    local targetChar = (possessionMode and dummyRig) or char
    if not targetChar then return nil end
    if name == "Head" then return targetChar:FindFirstChild("Head") end
    if name == "Torso" then return targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso") end
    if name == "Left Arm" then return targetChar:FindFirstChild("Left Arm") or targetChar:FindFirstChild("LeftUpperArm") end
    if name == "Right Arm" then return targetChar:FindFirstChild("Right Arm") or targetChar:FindFirstChild("RightUpperArm") end
    if name == "Left Leg" then return targetChar:FindFirstChild("Left Leg") or targetChar:FindFirstChild("LeftUpperLeg") end
    if name == "Right Leg" then return targetChar:FindFirstChild("Right Leg") or targetChar:FindFirstChild("RightUpperLeg") end
end

local function stopAllAnimations()
    if currentAnimTrack then pcall(function() currentAnimTrack:Stop() end) end
    if dummyIdleTrack then pcall(function() dummyIdleTrack:Stop() end) end
    if dummyRunTrack then pcall(function() dummyRunTrack:Stop() end) end
    
    local hum = (possessionMode and dummyHum) or char:FindFirstChildOfClass("Humanoid")
    if hum then
        local anim = hum:FindFirstChildOfClass("Animator")
        if anim then
            for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                pcall(function() track:Stop() end)
            end
        end
    end
end

local function playCustomAnimation(animId)
    if not animId then return end
    local humanoid = (possessionMode and dummyHum) or char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then animator = Instance.new("Animator", humanoid) end

    stopAllAnimations()

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. animId
    
    pcall(function()
        local track = animator:LoadAnimation(anim)
        track.Looped = true
        track:Play()
        currentAnimTrack = track
    end)
end

local function getWASD()
    local cam = workspace.CurrentCamera
    local forward = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    forward = Vector3.new(forward.X, 0, forward.Z).Unit
    right = Vector3.new(right.X, 0, right.Z).Unit
    
    local move = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
    if move.Magnitude > 0 then move = move.Unit end
    return move
end

local function createDummyRig()
    local model = Instance.new("Model")
    model.Name = "InvisibleDummy"
    
    local hum = Instance.new("Humanoid")
    hum.RigType = Enum.HumanoidRigType.R6
    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    hum.Parent = model
    dummyAnimator = Instance.new("Animator", hum)
    
    local parts = {"HumanoidRootPart", "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
    local sizes = {Vector3.new(2,2,1), Vector3.new(2,2,1), Vector3.new(1,1,1), Vector3.new(1,2,1), Vector3.new(1,2,1), Vector3.new(1,2,1), Vector3.new(1,2,1)}
    
    for i, name in ipairs(parts) do
        local p = Instance.new("Part")
        p.Name = name
        p.Size = sizes[i]
        p.Transparency = 1
        p.CanCollide = false
        p.Anchored = true -- Оставляем Anchored, чтобы физика не крашила игру
        p.Parent = model
        if name == "HumanoidRootPart" then model.PrimaryPart = p end
    end
    
    -- СОЗДАЕМ СУСТАВЫ С ПРАВИЛЬНЫМИ ИМЕНАМИ (Чтобы анимации работали без крашей)
    local function makeJoint(p0, p1, c0, name)
        local w = Instance.new("Motor6D")
        w.Name = name
        w.Part0 = p0; w.Part1 = p1; w.C0 = c0; w.Parent = p0
    end
    makeJoint(model.HumanoidRootPart, model.Torso, CFrame.new(0,0,0), "RootJoint")
    makeJoint(model.Torso, model.Head, CFrame.new(0,1.5,0), "Neck")
    makeJoint(model.Torso, model["Left Arm"], CFrame.new(-1.5,0,0), "Left Shoulder")
    makeJoint(model.Torso, model["Right Arm"], CFrame.new(1.5,0,0), "Right Shoulder")
    makeJoint(model.Torso, model["Left Leg"], CFrame.new(-0.5,-2,0), "Left Hip")
    makeJoint(model.Torso, model["Right Leg"], CFrame.new(0.5,-2,0), "Right Hip")
    
    local idleAnim = Instance.new("Animation")
    idleAnim.AnimationId = "rbxassetid://180435571"
    pcall(function() dummyIdleTrack = dummyAnimator:LoadAnimation(idleAnim) end)
    if dummyIdleTrack then dummyIdleTrack.Looped = true; dummyIdleTrack:Play() end
    
    local runAnim = Instance.new("Animation")
    runAnim.AnimationId = "rbxassetid://180426354"
    pcall(function() dummyRunTrack = dummyAnimator:LoadAnimation(runAnim) end)
    if dummyRunTrack then dummyRunTrack.Looped = true end
    
    model.Parent = workspace
    return model
end

local function togglePossession()
    if isReturning then return end

    if possessionMode then
        isReturning = true
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        local targetPos = torso.Position + Vector3.new(settings.sideOffset, settings.heightOffset, settings.forwardOffset)
        
        task.spawn(function()
            local startTime = tick()
            while tick() - startTime < 1.5 do
                if not dummyRig or not dummyRig.Parent or not dummyRoot then break end
                local currentPos = dummyRoot.Position
                if (targetPos - currentPos).Magnitude < 2 then break end
                
                -- Плавное движение без крашей физики
                local newPos = currentPos:Lerp(targetPos, 0.1)
                dummyRig:PivotTo(CFrame.new(newPos, newPos + dummyRoot.CFrame.LookVector))
                task.wait(0.03)
            end
            
            possessionMode = false
            workspace.CurrentCamera.CameraSubject = char.Humanoid
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
            
            stopAllAnimations()
            if dummyRig then dummyRig:Destroy() end
            dummyRig = nil; dummyHum = nil; dummyRoot = nil; dummyAnimator = nil
            dummyIdleTrack = nil; dummyRunTrack = nil
            isReturning = false
        end)
    else
        if #activeParts == 0 then return end
        possessionMode = true
        char.Humanoid.WalkSpeed = 0
        char.Humanoid.JumpPower = 0
        
        local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        local spawnPos = torso.Position + Vector3.new(settings.sideOffset, settings.heightOffset - 3, settings.forwardOffset)
        
        dummyRig = createDummyRig()
        dummyRig:PivotTo(CFrame.new(spawnPos, spawnPos + torso.CFrame.LookVector))
        dummyHum = dummyRig.Humanoid
        dummyRoot = dummyRig.HumanoidRootPart
        
        workspace.CurrentCamera.CameraSubject = dummyHum
    end
end

local function processCrown(crown)
    if not spawning then return end
    if crown.Name == CLONE_NAME then return end
    if not crown:FindFirstChild("Handle") then return end
    
    if crown.Parent == backpack then crown.Parent = char end

    local mySlot = nextSlot
    nextSlot = nextSlot + 1
    if mySlot > TOTAL_CROWNS then crown:Destroy() return end

    local layoutData = LAYOUT[mySlot]

    task.spawn(function()
        task.wait(0.4)
        if crown.Parent ~= char or not crown:FindFirstChild("Handle") then return end

        local handle = crown:FindFirstChild("Handle")
        local targetBone = getBone(layoutData.bone)
        if not targetBone then return end

        for _, obj in ipairs(crown:GetDescendants()) do
            if obj:IsA("Weld") or obj:IsA("Motor6D") or obj:IsA("JointInstance") then
                obj:Destroy()
            end
        end

        handle.Anchored = false
        handle.CanCollide = false
        handle.Massless = true
        pcall(function() handle.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0) end)

        local handleAttach = Instance.new("Attachment", handle)
        local boneAttach = Instance.new("Attachment", targetBone)
        
        local alignPos = Instance.new("AlignPosition", handle)
        alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
        alignPos.Attachment0 = handleAttach; alignPos.Attachment1 = boneAttach
        alignPos.MaxForce = 100000 -- Снизили силу, чтобы физика не сходила с ума
        alignPos.MaxVelocity = 1000
        alignPos.RigidityEnabled = true

        local alignOri = Instance.new("AlignOrientation", handle)
        alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
        alignOri.Attachment0 = handleAttach; alignOri.Attachment1 = boneAttach
        alignOri.MaxTorque = 100000
        alignOri.MaxAngularVelocity = 1000
        alignOri.RigidityEnabled = true

        crown.Name = CLONE_NAME
        table.insert(activeParts, {
            handle = handle, boneAttach = boneAttach, alignPos = alignPos, alignOri = alignOri,
            slot = mySlot, layout = layoutData, isArm = layoutData.bone:find("Arm") ~= nil
        })
    end)
end

char.ChildAdded:Connect(processCrown)
backpack.ChildAdded:Connect(processCrown)

heartbeatConn = RunService.Heartbeat:Connect(function(dt)
    if possessionMode and dummyRig and dummyRoot then
        local currentCF = dummyRoot.CFrame
        local moveDir = getWASD()
        
        if moveDir.Magnitude > 0.1 then
            -- Плавное движение вперед
            local newPos = currentCF.Position + (moveDir * settings.ghostSpeed * dt)
            -- Плавный разворот
            local lookCF = CFrame.lookAt(newPos, newPos + moveDir)
            local lerpedRot = currentCF:Lerp(lookCF, 0.15)
            
            dummyRig:PivotTo(lerpedRot)
            
            if dummyIdleTrack then pcall(function() dummyIdleTrack:Stop() end) end
            if dummyRunTrack and not dummyRunTrack.IsPlaying then pcall(function() dummyRunTrack:Play() end) end
        else
            if dummyRunTrack then pcall(function() dummyRunTrack:Stop() end) end
            if dummyIdleTrack and not dummyIdleTrack.IsPlaying then pcall(function() dummyIdleTrack:Play() end) end
        end
    end

    local torso = getBone("Torso")
    if not torso then return end

    local offsetCF = CFrame.new(0, 0, 0)
    if not possessionMode then
        offsetCF = CFrame.new(settings.sideOffset, settings.heightOffset, settings.forwardOffset)
    end
    local worldShift = torso.CFrame * offsetCF * torso.CFrame:Inverse()

    for i, d in ipairs(activeParts) do
        local handle = d.handle
        if not handle or not handle.Parent or not d.boneAttach or not d.boneAttach.Parent then
            table.remove(activeParts, i)
            continue
        end

        for _, obj in ipairs(handle:GetChildren()) do
            if obj:IsA("Weld") or obj:IsA("Motor6D") then obj:Destroy() end
        end

        local bone = getBone(d.layout.bone)
        if bone then
            if d.boneAttach.Parent ~= bone then d.boneAttach.Parent = bone end

            local finalX = d.layout.offset.X * settings.sizeMultiplier
            local finalY = d.layout.offset.Y * settings.sizeMultiplier
            local finalZ = d.layout.offset.Z * settings.sizeMultiplier
            local localOffset = CFrame.new(finalX, finalY, finalZ)
            
            if d.isArm then 
                localOffset = localOffset * CFrame.new(0, settings.armHeightOffset, 0) 
            end

            local shiftedBoneCF = worldShift * bone.CFrame
            local targetWorldCF = shiftedBoneCF * localOffset * CFrame.Angles(0, math.rad(90), 0)
            d.boneAttach.CFrame = bone.CFrame:ToObjectSpace(targetWorldCF)
        end
    end
end)

-- GUI (Без изменений)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrownManGUI"
screenGui.ResetOnSpawn = false
if not pcall(function() screenGui.Parent = CoreGui end) then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 500)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundColor3 = Color3.fromRGB(35, 30, 20)
title.Text = "👑 Crown Man v59"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -50)
content.Position = UDim2.new(0, 10, 0, 44)
content.BackgroundTransparency = 1
content.Parent = mainFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, 0)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = content

local function clearAll()
    if possessionMode then togglePossession() end
    for _, obj in ipairs(char:GetChildren()) do if obj.Name == CLONE_NAME then obj:Destroy() end end
    for _, obj in ipairs(backpack:GetChildren()) do if obj.Name == CLONE_NAME then obj:Destroy() end end
    for _, d in ipairs(activeParts) do
        if d.alignPos then d.alignPos:Destroy() end
        if d.alignOri then d.alignOri:Destroy() end
        if d.boneAttach then d.boneAttach:Destroy() end
    end
    activeParts = {}
    spawning = false
    nextSlot = 1
    stopAllAnimations()
end

local y = 0
local function makeBtn(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = scroll
    btn.MouseButton1Click:Connect(callback)
    y = y + 42
    return btn
end

local function createSlider(label, minVal, maxVal, step, getVal, setVal, format)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.Position = UDim2.new(0, 0, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = scroll

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLabel = Instance.new("TextLabel", frame)
    valLabel.Size = UDim2.new(0.25, 0, 1, 0)
    valLabel.Position = UDim2.new(0.45, 0, 0, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = format(getVal())
    valLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    valLabel.Font = Enum.Font.Code
    valLabel.TextSize = 12

    local btnMinus = Instance.new("TextButton", frame)
    btnMinus.Size = UDim2.new(0, 26, 0, 26); btnMinus.Position = UDim2.new(0.75, 0, 0, 2)
    btnMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 60); btnMinus.Text = "−"; btnMinus.TextColor3 = Color3.new(1,1,1)
    btnMinus.Font = Enum.Font.SourceSansBold; btnMinus.Parent = frame

    local btnPlus = Instance.new("TextButton", frame)
    btnPlus.Size = UDim2.new(0, 26, 0, 26); btnPlus.Position = UDim2.new(1, -26, 0, 2)
    btnPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 60); btnPlus.Text = "+"; btnPlus.TextColor3 = Color3.new(1,1,1)
    btnPlus.Font = Enum.Font.SourceSansBold; btnPlus.Parent = frame

    local function update() valLabel.Text = format(getVal()) end
    btnMinus.MouseButton1Click:Connect(function() setVal(math.max(minVal, getVal() - step)); update() end)
    btnPlus.MouseButton1Click:Connect(function() setVal(math.min(maxVal, getVal() + step)); update() end)
    y = y + 34
end

makeBtn("👑 СОБРАТЬ БРАТАНА", Color3.fromRGB(180, 140, 0), function()
    clearAll()
    spawning = true
    task.spawn(function()
        for i = 1, TOTAL_CROWNS do
            sendCommand("-gh " .. CROWN_ID)
            task.wait(0.4)
            sendCommand("-net")
            task.wait(0.2)
        end
        task.wait(2)
        spawning = false
    end)
end)

local controlBtn = makeBtn("🎮 No Player (Управление)", Color3.fromRGB(50, 150, 150), function()
    togglePossession()
    if possessionMode then
        controlBtn.Text = "🛑 Вернуть управление"
        controlBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    else
        controlBtn.Text = "🎮 No Player (Управление)"
        controlBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
    end
end)

local lblAnim = Instance.new("TextLabel")
lblAnim.Size = UDim2.new(1, 0, 0, 20); lblAnim.Position = UDim2.new(0, 0, 0, y)
lblAnim.BackgroundTransparency = 1; lblAnim.Text = "АНИМАЦИИ:"; lblAnim.TextColor3 = Color3.fromRGB(200, 150, 255)
lblAnim.Font = Enum.Font.SourceSansBold; lblAnim.TextSize = 12; lblAnim.TextXAlignment = Enum.TextXAlignment.Left
lblAnim.Parent = scroll; y = y + 24

makeBtn("👋 Привет", Color3.fromRGB(50, 120, 200), function() playCustomAnimation("128777973") end)
makeBtn("💃 Танец 1", Color3.fromRGB(150, 50, 150), function() playCustomAnimation("180435571") end)
makeBtn("🕺 Танец 2", Color3.fromRGB(150, 50, 150), function() playCustomAnimation("180435792") end)
makeBtn("🕺 Танец 3", Color3.fromRGB(150, 50, 150), function() playCustomAnimation("182435998") end)
makeBtn("🛑 Остановить", Color3.fromRGB(100, 100, 100), function() stopAllAnimations() end)

local lblSettings = Instance.new("TextLabel")
lblSettings.Size = UDim2.new(1, 0, 0, 20); lblSettings.Position = UDim2.new(0, 0, 0, y)
lblSettings.BackgroundTransparency = 1; lblSettings.Text = "ПОЗИЦИЯ:"; lblSettings.TextColor3 = Color3.fromRGB(200, 150, 255)
lblSettings.Font = Enum.Font.SourceSansBold; lblSettings.TextSize = 12; lblSettings.TextXAlignment = Enum.TextXAlignment.Left
lblSettings.Parent = scroll; y = y + 24

createSlider("Вперёд/Назад", -10, 15, 0.5, function() return settings.forwardOffset end, function(v) settings.forwardOffset = v end, function(v) return ("%.1f"):format(v) end)
createSlider("Влево/Вправо", -15, 15, 0.5, function() return settings.sideOffset end, function(v) settings.sideOffset = v end, function(v) return ("%.1f"):format(v) end)
createSlider("Общая высота", -5, 20, 0.5, function() return settings.heightOffset end, function(v) settings.heightOffset = v end, function(v) return ("%.1f"):format(v) end)
createSlider("Высота рук", -2, 5, 0.5, function() return settings.armHeightOffset end, function(v) settings.armHeightOffset = v end, function(v) return ("%.1f"):format(v) end)
createSlider("Размер", 0.5, 3, 0.1, function() return settings.sizeMultiplier end, function(v) settings.sizeMultiplier = v end, function(v) return ("%.1f"):format(v) end)

makeBtn("🧹 УДАЛИТЬ", Color3.fromRGB(150, 50, 50), function()
    clearAll()
    if possessionMode then
        controlBtn.Text = "🎮 No Player (Управление)"
        controlBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
    end
end)

player.CharacterAdded:Connect(function(newChar)
    char = newChar
    activeParts = {}
    nextSlot = 1
    possessionMode = false
    char.ChildAdded:Connect(processCrown)
end)
