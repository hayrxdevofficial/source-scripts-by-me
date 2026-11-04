-- // СКРИПТ FLAPPY BIRD GUI + TOOL ДЛЯ ОТКРЫТИЯ/ЗАКРЫТИЯ
-- // Вставь этот код в LocalScript (StarterGui) или в исполнитель

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local backpack = player:WaitForChild("Backpack")

------------------------------------------------------------
-- 1. СОЗДАНИЕ GUI FLAPPY BIRD
------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlappyBirdGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.Enabled = false -- по умолчанию скрыт

-- Основной фрейм (игровое поле)
local gameFrame = Instance.new("Frame")
gameFrame.Name = "GameFrame"
gameFrame.Size = UDim2.new(0, 400, 0, 600)
gameFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
gameFrame.BackgroundColor3 = Color3.fromRGB(113, 197, 207) -- небо
gameFrame.BorderSizePixel = 0
gameFrame.ClipsDescendants = true
gameFrame.Parent = screenGui

-- Земля
local ground = Instance.new("Frame")
ground.Name = "Ground"
ground.Size = UDim2.new(1, 0, 0, 60)
ground.Position = UDim2.new(0, 0, 1, -60)
ground.BackgroundColor3 = Color3.fromRGB(222, 184, 135)
ground.BorderSizePixel = 0
ground.Parent = gameFrame

-- Птица (жёлтый квадрат)
local bird = Instance.new("Frame")
bird.Name = "Bird"
bird.Size = UDim2.new(0, 30, 0, 30)
bird.Position = UDim2.new(0, 100, 0.5, -15)
bird.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
bird.BorderSizePixel = 0
bird.Parent = gameFrame

-- Счёт
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "Score"
scoreLabel.Size = UDim2.new(0, 100, 0, 40)
scoreLabel.Position = UDim2.new(0.5, -50, 0, 10)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = "0"
scoreLabel.TextColor3 = Color3.new(1, 1, 1)
scoreLabel.TextScaled = true
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.Parent = gameFrame

-- Текст Game Over
local gameOverLabel = Instance.new("TextLabel")
gameOverLabel.Name = "GameOver"
gameOverLabel.Size = UDim2.new(1, 0, 0, 80)
gameOverLabel.Position = UDim2.new(0, 0, 0.4, 0)
gameOverLabel.BackgroundTransparency = 1
gameOverLabel.Text = "GAME OVER"
gameOverLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
gameOverLabel.TextScaled = true
gameOverLabel.Font = Enum.Font.GothamBold
gameOverLabel.Visible = false
gameOverLabel.Parent = gameFrame

------------------------------------------------------------
-- 2. ЛОГИКА ИГРЫ
------------------------------------------------------------
local gravity = 0.5
local flapPower = -7
local birdVelocity = 0
local score = 0
local isPlaying = false
local pipes = {}

-- Функция создания трубы
local function createPipe()
    local gap = 120
    local pipeWidth = 50
    local minHeight = 60
    local maxHeight = 380
    local gapY = math.random(minHeight, maxHeight)

    local topPipe = Instance.new("Frame")
    topPipe.Name = "TopPipe"
    topPipe.Size = UDim2.new(0, pipeWidth, 0, gapY)
    topPipe.Position = UDim2.new(1, 0, 0, 0)
    topPipe.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    topPipe.BorderSizePixel = 0
    topPipe.Parent = gameFrame

    local bottomPipe = Instance.new("Frame")
    bottomPipe.Name = "BottomPipe"
    bottomPipe.Size = UDim2.new(0, pipeWidth, 0, 600 - gapY - gap)
    bottomPipe.Position = UDim2.new(1, 0, 0, gapY + gap)
    bottomPipe.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    bottomPipe.BorderSizePixel = 0
    bottomPipe.Parent = gameFrame

    table.insert(pipes, {top = topPipe, bottom = bottomPipe, passed = false})

    -- Движение трубы
    local speed = 3
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not isPlaying or not topPipe.Parent then
            connection:Disconnect()
            return
        end
        topPipe.Position = topPipe.Position - UDim2.new(0, speed, 0, 0)
        bottomPipe.Position = bottomPipe.Position - UDim2.new(0, speed, 0, 0)

        -- Удаление, когда труба ушла за экран
        if topPipe.Position.X.Offset < -100 then
            topPipe:Destroy()
            bottomPipe:Destroy()
            connection:Disconnect()
        end
    end)
end

-- Сброс игры
local function resetGame()
    -- Очистка труб
    for _, pipePair in pairs(pipes) do
        if pipePair.top then pipePair.top:Destroy() end
        if pipePair.bottom then pipePair.bottom:Destroy() end
    end
    pipes = {}

    bird.Position = UDim2.new(0, 100, 0.5, -15)
    birdVelocity = 0
    score = 0
    scoreLabel.Text = "0"
    gameOverLabel.Visible = false
    isPlaying = true

    -- Спавн труб
    task.spawn(function()
        while isPlaying do
            createPipe()
            task.wait(2.5)
        end
    end)
end

-- Прыжок
local function flap()
    if not isPlaying then
        resetGame()
        return
    end
    birdVelocity = flapPower
end

-- Обновление физики
RunService.RenderStepped:Connect(function()
    if not isPlaying then return end

    -- Гравитация
    birdVelocity = birdVelocity + gravity
    bird.Position = bird.Position + UDim2.new(0, 0, 0, birdVelocity)

    -- Ограничение по верхней границе
    if bird.Position.Y.Offset < 0 then
        bird.Position = UDim2.new(0, 100, 0, 0)
        birdVelocity = 0
    end

    -- Столкновение с землёй
    if bird.Position.Y.Offset + bird.Size.Y.Offset >= gameFrame.Size.Y.Offset - ground.Size.Y.Offset then
        isPlaying = false
        gameOverLabel.Visible = true
        return
    end

    -- Проверка столкновений с трубами и подсчёт очков
    for _, pipePair in pairs(pipes) do
        if pipePair.top and pipePair.top.Parent then
            local top = pipePair.top
            local bottom = pipePair.bottom
            local birdX = bird.Position.X.Offset
            local birdY = bird.Position.Y.Offset
            local birdW = bird.Size.X.Offset
            local birdH = bird.Size.Y.Offset

            local pipeX = top.Position.X.Offset
            local pipeW = top.Size.X.Offset

            -- Столкновение (AABB)
            if birdX + birdW > pipeX and birdX < pipeX + pipeW then
                local topH = top.Size.Y.Offset
                local bottomY = bottom.Position.Y.Offset
                if birdY < topH or birdY + birdH > bottomY then
                    isPlaying = false
                    gameOverLabel.Visible = true
                    return
                end
            end

            -- Очко за прохождение трубы
            if not pipePair.passed and pipeX + pipeW < birdX then
                pipePair.passed = true
                score = score + 1
                scoreLabel.Text = tostring(score)
            end
        end
    end
end)

------------------------------------------------------------
-- 3. ИНСТРУМЕНТ ДЛЯ ОТКРЫТИЯ/ЗАКРЫТИЯ GUI
------------------------------------------------------------
local tool = Instance.new("Tool")
tool.Name = "FlappyBirdOpener"
tool.RequiresHandle = false
tool.CanBeDropped = false
tool.Parent = backpack

tool.Activated:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
    if screenGui.Enabled then
        -- При открытии запускаем игру (или сбрасываем)
        isPlaying = false
        resetGame()
    else
        -- При закрытии останавливаем
        isPlaying = false
    end
end)

------------------------------------------------------------
-- 4. УПРАВЛЕНИЕ (ПРОБЕЛ / КЛИК ПО ЭКРАНУ)
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not screenGui.Enabled then return end

    if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
        flap()
    end
end)

print("[FlappyBird] Скрипт загружен. Возьми инструмент 'FlappyBirdOpener' в рюкзаке и активируй его (клик), чтобы открыть/закрыть игру. Пробел или клик по экрану — прыжок.")
