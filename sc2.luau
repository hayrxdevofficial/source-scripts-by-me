-- // FLAPPY BIRD GUI — fix "pipes connected"
if type(_G.__FlappyBirdCleanup) == "function" then pcall(_G.__FlappyBirdCleanup) end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Константы
local FRAME_W, FRAME_H = 400, 600
local GROUND_H = 60
local PLAY_H = FRAME_H - GROUND_H
local BIRD_X = 100
local BIRD_SIZE = 30
local PIPE_W = 50
local CAP_H = 14
local PIPE_GAP = 160          -- больше = легче и зазор заметнее
local GRAVITY = 0.55
local FLAP = -7.5
local PIPE_SPEED = 3          -- px за игровой кадр (60 к/с → 180 px/s)
local PIPE_INTERVAL = 2.0     -- ИГРОВЫЕ секунды → 360 px зазора между трубами

local connections = {}
local function track(c) table.insert(connections, c); return c end

-- ============ GUI ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlappyBirdGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false
screenGui.Parent = playerGui

local gameFrame = Instance.new("Frame")
gameFrame.Size = UDim2.fromOffset(FRAME_W, FRAME_H)
gameFrame.Position = UDim2.new(0.5, -FRAME_W/2, 0.5, -FRAME_H/2)
gameFrame.BackgroundColor3 = Color3.fromRGB(113, 197, 207)
gameFrame.BorderSizePixel = 0
gameFrame.ClipsDescendants = true
gameFrame.Parent = screenGui

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 10
closeBtn.Parent = gameFrame
track(closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false; isPlaying = false
end))

local ground = Instance.new("Frame")
ground.Size = UDim2.new(1, 0, 0, GROUND_H)
ground.Position = UDim2.new(0, 0, 1, -GROUND_H)
ground.BackgroundColor3 = Color3.fromRGB(222, 184, 135)
ground.BorderSizePixel = 0
ground.ZIndex = 2
ground.Parent = gameFrame

local bird = Instance.new("Frame")
bird.Size = UDim2.fromOffset(BIRD_SIZE, BIRD_SIZE)
bird.Position = UDim2.fromOffset(BIRD_X, 200)
bird.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
bird.BorderSizePixel = 0
bird.ZIndex = 3
bird.Parent = gameFrame

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.fromOffset(120, 50)
scoreLabel.Position = UDim2.new(0.5, -60, 0, 10)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = "0"
scoreLabel.TextColor3 = Color3.new(1, 1, 1)
scoreLabel.TextStrokeTransparency = 0
scoreLabel.TextScaled = true
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.ZIndex = 5
scoreLabel.Parent = gameFrame

local gameOverLabel = Instance.new("TextLabel")
gameOverLabel.Size = UDim2.new(1, 0, 0, 80)
gameOverLabel.Position = UDim2.new(0, 0, 0.4, 0)
gameOverLabel.BackgroundTransparency = 1
gameOverLabel.Text = "GAME OVER\n(клик — заново)"
gameOverLabel.TextColor3 = Color3.fromRGB(255, 40, 40)
gameOverLabel.TextStrokeTransparency = 0
gameOverLabel.TextScaled = true
gameOverLabel.Font = Enum.Font.GothamBold
gameOverLabel.Visible = false
gameOverLabel.ZIndex = 6
gameOverLabel.Parent = gameFrame

-- ============ Состояние ============
local isPlaying = false
local birdVelocity = 0
local score = 0
local pipes = {}
local spawnAccum = 0
local gameGen = 0

local function clearPipes()
    for _, p in ipairs(pipes) do
        if p.top then p.top:Destroy() end
        if p.bottom then p.bottom:Destroy() end
    end
    pipes = {}
end

-- Создаёт ОДНУ пару труб с гарантированным зазором PIPE_GAP
local function createPipe()
    local minGapY = 60
    local maxGapY = PLAY_H - PIPE_GAP - 60   -- 540-160-60 = 320
    local gapY = math.random(minGapY, maxGapY)
    local bottomHeight = PLAY_H - gapY - PIPE_GAP

    if bottomHeight < 40 then return end -- страховка

    -- ВЕРХНЯЯ труба (тело)
    local top = Instance.new("Frame")
    top.Size = UDim2.fromOffset(PIPE_W, gapY)
    top.Position = UDim2.fromOffset(FRAME_W, 0)
    top.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    top.BorderSizePixel = 0
    top.ZIndex = 1
    top.Parent = gameFrame

    -- ВЕРХНЯЯ «шапка» (светлый наконечник снизу)
    local topCap = Instance.new("Frame")
    topCap.Size = UDim2.fromOffset(PIPE_W + 8, CAP_H)
    topCap.Position = UDim2.fromOffset(-4, gapY - CAP_H)
    topCap.BackgroundColor3 = Color3.fromRGB(40, 220, 40)
    topCap.BorderSizePixel = 0
    topCap.ZIndex = 2
    topCap.Parent = top

    -- НИЖНЯЯ труба (тело)
    local bottom = Instance.new("Frame")
    bottom.Size = UDim2.fromOffset(PIPE_W, bottomHeight)
    bottom.Position = UDim2.fromOffset(FRAME_W, gapY + PIPE_GAP)
    bottom.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    bottom.BorderSizePixel = 0
    bottom.ZIndex = 1
    bottom.Parent = gameFrame

    -- НИЖНЯЯ «шапка» (светлый наконечник сверху)
    local bottomCap = Instance.new("Frame")
    bottomCap.Size = UDim2.fromOffset(PIPE_W + 8, CAP_H)
    bottomCap.Position = UDim2.fromOffset(-4, 0)
    bottomCap.BackgroundColor3 = Color3.fromRGB(40, 220, 40)
    bottomCap.BorderSizePixel = 0
    bottomCap.ZIndex = 2
    bottomCap.Parent = bottom

    table.insert(pipes, { top = top, bottom = bottom, passed = false })
end

local function resetGame()
    gameGen = gameGen + 1
    clearPipes()
    bird.Position = UDim2.fromOffset(BIRD_X, 200)
    birdVelocity = 0
    score = 0
    scoreLabel.Text = "0"
    gameOverLabel.Visible = false
    isPlaying = true
    spawnAccum = PIPE_INTERVAL       -- спавним первую трубу на первом же кадре
end

local function flap()
    if not isPlaying then
        resetGame()
        birdVelocity = FLAP
        return
    end
    birdVelocity = FLAP
end

local function endGame()
    if not isPlaying then return end
    isPlaying = false
    gameOverLabel.Visible = true
end

-- ============ ГЛАВНЫЙ ЦИКЛ: спавн + движение труб + физика ============
track(RS.RenderStepped:Connect(function(dt)
    if not isPlaying then return end

    -- gameDt: сколько "игровых" секунд прошло (1.0 = 60 кадров по 1 step)
    local step = math.clamp(dt * 60, 0, 3)
    local gameDt = step / 60
    local pipeDx = PIPE_SPEED * step

    -- СПАВН (теперь в игровом времени — зазор гарантирован!)
    spawnAccum = spawnAccum + gameDt
    while spawnAccum >= PIPE_INTERVAL do
        spawnAccum = spawnAccum - PIPE_INTERVAL
        createPipe()
    end

    -- ДВИЖЕНИЕ всех труб одним циклом
    for i = #pipes, 1, -1 do
        local p = pipes[i]
        if not p.top.Parent then
            table.remove(pipes, i)
        else
            p.top.Position = UDim2.fromOffset(p.top.Position.X.Offset - pipeDx, 0)
            p.bottom.Position = UDim2.fromOffset(p.bottom.Position.X.Offset - pipeDx, p.bottom.Position.Y.Offset)
            if p.top.Position.X.Offset < -PIPE_W - 20 then
                p.top:Destroy(); p.bottom:Destroy()
                table.remove(pipes, i)
            end
        end
    end

    -- ФИЗИКА ПТИЦЫ
    birdVelocity = birdVelocity + GRAVITY * step
    local newY = bird.Position.Y.Offset + birdVelocity * step
    if newY < 0 then newY = 0; birdVelocity = 0 end
    if newY + BIRD_SIZE >= PLAY_H then
        bird.Position = UDim2.fromOffset(BIRD_X, PLAY_H - BIRD_SIZE)
        endGame(); return
    end
    bird.Position = UDim2.fromOffset(BIRD_X, newY)

    -- СТОЛКНОВЕНИЯ + СЧЁТ
    local bx, by = BIRD_X, newY
    local bx2, by2 = bx + BIRD_SIZE, by + BIRD_SIZE
    for _, p in ipairs(pipes) do
        if p.top.Parent then
            local px = p.top.Position.X.Offset
            local px2 = px + PIPE_W
            if bx2 > px and bx < px2 then
                local topH = p.top.Size.Y.Offset
                local botY = p.bottom.Position.Y.Offset
                if by < topH or by2 > botY then endGame(); return end
            end
            if not p.passed and px2 < bx then
                p.passed = true
                score = score + 1
                scoreLabel.Text = tostring(score)
            end
        end
    end
end))

-- ============ Ввод ============
track(UIS.InputBegan:Connect(function(input, gp)
    if gp or not screenGui.Enabled then return end
    if input.KeyCode == Enum.KeyCode.Space
        or input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        flap()
    end
end))

-- ============ Инструмент ============
local function makeTool()
    local bp = player:FindFirstChildOfClass("Backpack")
    if not bp then return end
    local old = bp:FindFirstChild("FlappyBirdOpener")
    if old then old:Destroy() end

    local t = Instance.new("Tool")
    t.Name = "FlappyBirdOpener"
    t.RequiresHandle = false
    t.CanBeDropped = false
    t.ToolTip = "Flappy Bird (клик — открыть/закрыть)"
    t.Activated:Connect(function()
        screenGui.Enabled = not screenGui.Enabled
        if screenGui.Enabled then resetGame() else isPlaying = false end
    end)
    t.Parent = bp
end

makeTool()
track(player.CharacterAdded:Connect(function() task.wait(0.5); makeTool() end))

-- ============ Cleanup ============
local function cleanup()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    if screenGui then pcall(function() screenGui:Destroy() end) end
    local bp = player:FindFirstChildOfClass("Backpack")
    if bp then
        local t = bp:FindFirstChild("FlappyBirdOpener")
        if t then pcall(function() t:Destroy() end) end
    end
end
_G.__FlappyBirdCleanup = cleanup

print("[FlappyBird] ok. Зазор между трубами гарантирован при любом FPS.")
