-- // FLAPPY BIRD GUI — исправленная версия
-- Вставь в LocalScript (StarterGui) или в исполнитель

-- Очистка от предыдущего запуска
if type(_G.__FlappyBirdCleanup) == "function" then
    pcall(_G.__FlappyBirdCleanup)
end

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
local PIPE_GAP = 140
local GRAVITY = 0.55
local FLAP = -7.5
local PIPE_SPEED = 3
local PIPE_INTERVAL = 2.5

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
gameFrame.Size = UDim2.new(0, FRAME_W, 0, FRAME_H)
gameFrame.Position = UDim2.new(0.5, -FRAME_W/2, 0.5, -FRAME_H/2)
gameFrame.BackgroundColor3 = Color3.fromRGB(113, 197, 207)
gameFrame.BorderSizePixel = 0
gameFrame.ClipsDescendants = true
gameFrame.Parent = screenGui

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
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
    screenGui.Enabled = false
    isPlaying = false
end))

local ground = Instance.new("Frame")
ground.Size = UDim2.new(1, 0, 0, GROUND_H)
ground.Position = UDim2.new(0, 0, 1, -GROUND_H)
ground.BackgroundColor3 = Color3.fromRGB(222, 184, 135)
ground.BorderSizePixel = 0
ground.ZIndex = 2
ground.Parent = gameFrame

local bird = Instance.new("Frame")
bird.Size = UDim2.new(0, BIRD_SIZE, 0, BIRD_SIZE)
bird.Position = UDim2.new(0, BIRD_X, 0, 200)
bird.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
bird.BorderSizePixel = 0
bird.ZIndex = 3
bird.Parent = gameFrame

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(0, 120, 0, 50)
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

-- ============ Состояние игры ============
local isPlaying = false
local birdVelocity = 0
local score = 0
local pipes = {}
local gameGen = 0

local function clearPipes()
    for _, p in ipairs(pipes) do
        if p.top and p.top.Parent then p.top:Destroy() end
        if p.bottom and p.bottom.Parent then p.bottom:Destroy() end
    end
    pipes = {}
end

local function createPipe()
    local minGapY = 60
    local maxGapY = PLAY_H - PIPE_GAP - 60
    local gapY = math.random(minGapY, maxGapY)

    -- ВАЖНО: ТОЛЬКО Offset (Scale = 0), чтобы координаты читались однозначно
    local top = Instance.new("Frame")
    top.Size = UDim2.new(0, PIPE_W, 0, gapY)
    top.Position = UDim2.new(0, FRAME_W, 0, 0)
    top.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    top.BorderSizePixel = 0
    top.ZIndex = 1
    top.Parent = gameFrame

    local bottomHeight = PLAY_H - gapY - PIPE_GAP
    local bottom = Instance.new("Frame")
    bottom.Size = UDim2.new(0, PIPE_W, 0, bottomHeight)
    bottom.Position = UDim2.new(0, FRAME_W, 0, gapY + PIPE_GAP)
    bottom.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    bottom.BorderSizePixel = 0
    bottom.ZIndex = 1
    bottom.Parent = gameFrame

    table.insert(pipes, { top = top, bottom = bottom, passed = false })

    local myGen = gameGen
    local conn
    conn = RS.RenderStepped:Connect(function(dt)
        if not isPlaying or gameGen ~= myGen or not top.Parent then
            conn:Disconnect(); return
        end
        local step = math.clamp(dt * 60, 0, 3)
        local dx = PIPE_SPEED * step
        top.Position = top.Position - UDim2.new(0, dx, 0, 0)
        bottom.Position = bottom.Position - UDim2.new(0, dx, 0, 0)
        if top.Position.X.Offset < -PIPE_W - 20 then
            top:Destroy(); bottom:Destroy(); conn:Disconnect()
        end
    end)
end

local function resetGame()
    gameGen = gameGen + 1
    local myGen = gameGen

    clearPipes()
    bird.Position = UDim2.new(0, BIRD_X, 0, 200)
    birdVelocity = 0
    score = 0
    scoreLabel.Text = "0"
    gameOverLabel.Visible = false
    isPlaying = true

    task.spawn(function()
        while isPlaying and gameGen == myGen do
            createPipe()
            task.wait(PIPE_INTERVAL)
        end
    end)
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

-- ============ Физика (FPS-independent) ============
track(RS.RenderStepped:Connect(function(dt)
    if not isPlaying then return end
    local step = math.clamp(dt * 60, 0, 3)

    birdVelocity = birdVelocity + GRAVITY * step
    local newY = bird.Position.Y.Offset + birdVelocity * step

    if newY < 0 then newY = 0; birdVelocity = 0 end
    if newY + BIRD_SIZE >= PLAY_H then
        bird.Position = UDim2.new(0, BIRD_X, 0, PLAY_H - BIRD_SIZE)
        endGame(); return
    end
    bird.Position = UDim2.new(0, BIRD_X, 0, newY)

    local bx, by = BIRD_X, newY
    local bx2, by2 = bx + BIRD_SIZE, by + BIRD_SIZE

    for i = #pipes, 1, -1 do
        local p = pipes[i]
        if not p.top.Parent then
            table.remove(pipes, i)
        else
            local px = p.top.Position.X.Offset
            local px2 = px + PIPE_W
            if bx2 > px and bx < px2 then
                local topH = p.top.Size.Y.Offset
                local botY = p.bottom.Position.Y.Offset
                if by < topH or by2 > botY then
                    endGame(); return
                end
            end
            if not p.passed and px2 < bx then
                p.passed = true
                score = score + 1
                scoreLabel.Text = tostring(score)
            end
        end
    end
end))

-- ============ Управление ============
track(UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not screenGui.Enabled then return end
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
        if screenGui.Enabled then
            resetGame()
        else
            isPlaying = false
        end
    end)

    t.Parent = bp
end

makeTool()

track(player.CharacterAdded:Connect(function()
    task.wait(0.5)
    makeTool()
end))

-- ============ Cleanup ============
local function cleanup()
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    if screenGui then pcall(function() screenGui:Destroy() end) end

    local bp = player:FindFirstChildOfClass("Backpack")
    if bp then
        local t = bp:FindFirstChild("FlappyBirdOpener")
        if t then pcall(function() t:Destroy() end) end
    end
    local char = player.Character
    if char then
        local t = char:FindFirstChild("FlappyBirdOpener")
        if t then pcall(function() t:Destroy() end) end
    end
end
_G.__FlappyBirdCleanup = cleanup

print("[FlappyBird] Готово. Возьми инструмент 'FlappyBirdOpener' → клик = вкл/выкл. Пробел/клик = флап.")
