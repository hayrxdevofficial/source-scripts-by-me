-- LocalScript: Создает инструмент для телепортации по клику
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Создаем сам инструмент
local tool = Instance.new("Tool")
tool.Name = "Click Teleport"
tool.RequiresHandle = false -- Инструменту не нужна ручка
tool.CanBeDropped = false
tool.Parent = player:WaitForChild("Backpack")

-- Функция телепортации при активации инструмента
tool.Activated:Connect(function()
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Телепортируем чуть выше поверхности, чтобы избежать застревания в полу
    local targetPosition = mouse.Hit.Position + Vector3.new(0, 3, 0)
    hrp.CFrame = CFrame.new(targetPosition)
end)
