--// Сервисы
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

--// Удаление старой версии меню
local oldGui = pg:FindFirstChild("Hay")
if oldGui then oldGui:Destroy() end

--// Настройки
local settings = { walkSpeed = 16, jumpPower = 50, flySpeed = 50, hipHeight = 2 }
local state = { fly = false, noclip = false, infJump = false }

--// Хелпер
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

--// ScreenGui
local gui = new("ScreenGui", {
	Name = "Hay",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, pg)

--// Кнопка открытия
local button = new("TextButton", {
	Size = UDim2.fromOffset(50, 50),
	Position = UDim2.new(0, 20, 0.5, -25),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Text = "",
	AutoButtonColor = false,
	Parent = gui,
})
new("UICorner", { CornerRadius = UDim.new(0, 10) }, button)
new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 3 }, button)
new("ImageLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Image = "rbxassetid://90354306501701",
	ScaleType = Enum.ScaleType.Fit,
	Parent = button,
})

--// Главное Меню
local menu = new("Frame", {
	Size = UDim2.fromOffset(435, 315),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	Visible = false,
	Active = true,
	Parent = gui,
})
new("UICorner", { CornerRadius = UDim.new(0, 15) }, menu)
new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 4 }, menu)

--// Заголовок меню
new("TextLabel", {
	Size = UDim2.fromOffset(200, 30),
	Position = UDim2.new(0.5, 0, 0, 8),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Text = "Hay",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	Font = Enum.Font.GothamBlack,
	TextSize = 24,
	ZIndex = 5,
	Parent = menu,
})

--// Кнопка закрытия
local closeBtn = new("TextButton", {
	Size = UDim2.fromOffset(30, 30),
	Position = UDim2.new(0, 10, 0, 10),
	BackgroundTransparency = 1,
	Text = "X",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	AutoButtonColor = false,
	ZIndex = 5,
	Parent = menu,
})

--// Правая панель (Tabs)
local tabsFrame = new("Frame", {
	Size = UDim2.new(0, 85, 1, -40),
	Position = UDim2.new(1, -90, 0, 20),
	BackgroundTransparency = 1,
	Parent = menu,
})
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, tabsFrame)

--// Левая панель (Контент)
local contentFrame = new("ScrollingFrame", {
	Size = UDim2.new(1, -130, 1, -40),
	Position = UDim2.new(0, 25, 0, 45),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = menu,
})
new("UIPadding", { PaddingRight = UDim.new(0, 10) }, contentFrame)

--// Вкладки
local tabMain = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = contentFrame })
local tabMisc = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = contentFrame })
local tabAnims = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = contentFrame })
local tabEmotes = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = contentFrame })
local tabScripts = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = contentFrame })

new("UIListLayout", { Padding = UDim.new(0, 10) }, tabMain)
new("UIListLayout", { Padding = UDim.new(0, 10) }, tabMisc)
new("UIListLayout", { Padding = UDim.new(0, 8) }, tabAnims)
new("UIListLayout", { Padding = UDim.new(0, 8) }, tabEmotes)
new("UIListLayout", { Padding = UDim.new(0, 8) }, tabScripts)

--// --- Генераторы UI ---
local function createInputRow(parent, labelText, defaultVal, callback)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent })

	local boxFrame = new("Frame", { Size = UDim2.fromOffset(80, 36), BackgroundColor3 = Color3.fromRGB(25, 25, 25), Parent = row })
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, boxFrame)
	new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2 }, boxFrame) 

	local box = new("TextBox", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(defaultVal),
		TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBlack, TextSize = 16, 
		TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, Parent = boxFrame,
	})

	local lbl = new("TextLabel", {
		Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 90, 0, 0), BackgroundTransparency = 1,
		Text = labelText, TextColor3 = Color3.fromRGB(0, 0, 0), Font = Enum.Font.GothamBold, 
		TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
	})

	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num then callback(num) else box.Text = tostring(defaultVal) end
	end)
end

local function createToggleRow(parent, labelText, initialState, callback)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = parent })

	local btnFrame = new("Frame", { Size = UDim2.fromOffset(80, 36), BackgroundColor3 = Color3.fromRGB(25, 25, 25), Parent = row })
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, btnFrame)
	new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2 }, btnFrame)

	local btn = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = initialState and "ON" or "OFF",
		TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBlack, TextSize = 16, 
		AutoButtonColor = false, Parent = btnFrame,
	})

	new("TextLabel", {
		Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 90, 0, 0), BackgroundTransparency = 1,
		Text = labelText, TextColor3 = Color3.fromRGB(0, 0, 0), Font = Enum.Font.GothamBold, 
		TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
	})

	local isOn = initialState
	btn.MouseButton1Click:Connect(function()
		isOn = not isOn
		btn.Text = isOn and "ON" or "OFF"
		callback(isOn)
	end)
end

--// --- Наполнение Main / Misc ---
createInputRow(tabMain, "speed", settings.walkSpeed, function(v) 
	settings.walkSpeed = v
	if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed = v end
end)

createInputRow(tabMain, "jump", settings.jumpPower, function(v) 
	settings.jumpPower = v
	if player.Character and player.Character:FindFirstChild("Humanoid") then 
		player.Character.Humanoid.UseJumpPower = true
		player.Character.Humanoid.JumpPower = v 
	end
end)

createInputRow(tabMain, "hip height", settings.hipHeight, function(v) 
	settings.hipHeight = v
	if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.HipHeight = v end
end)

createInputRow(tabMisc, "fly speed", settings.flySpeed, function(v) settings.flySpeed = v end)
createToggleRow(tabMisc, "fly", state.fly, function(on) state.fly = on; if on then startFly() else stopFly() end end)
createToggleRow(tabMisc, "noclip", state.noclip, function(on) state.noclip = on end)
createToggleRow(tabMisc, "inf jump", state.infJump, function(on) state.infJump = on end)

--// --- ЛОГИКА АНИМАЦИЙ ---
local ANIMATION_PACKS = {
	["Default (Reset)"] = {
		idle = {"rbxassetid://507766666", "rbxassetid://507766953"},
		walk = {"rbxassetid://507777826"},
		run = {"rbxassetid://507767714"},
		jump = {"rbxassetid://507765000"},
		fall = {"rbxassetid://507767968"},
		climb = {"rbxassetid://507765644"},
		swim = {"rbxassetid://507785072"},
		swimidle = {"rbxassetid://507785072"},
	},
	zombie = {
		idle = {"rbxassetid://616158929", "rbxassetid://616160636"},
		walk = {"rbxassetid://616168032"},
		run = {"rbxassetid://616163682"},
		jump = {"rbxassetid://616161997"},
		fall = {"rbxassetid://616157476"},
		climb = {"rbxassetid://616156119"},
		swim = {"rbxassetid://616165109"},
		swimidle = {"rbxassetid://616166655"},
	},
	robot = {
		idle = {"rbxassetid://616088211", "rbxassetid://616089559"},
		walk = {"rbxassetid://616095330"},
		run = {"rbxassetid://616091570"},
		jump = {"rbxassetid://616090535"},
		fall = {"rbxassetid://616087089"},
		climb = {"rbxassetid://616086039"},
		swim = {"rbxassetid://616092998"},
		swimidle = {"rbxassetid://616094091"},
	},
	ninja = {
		idle = {"rbxassetid://656117400", "rbxassetid://656118341"},
		walk = {"rbxassetid://656121766"},
		run = {"rbxassetid://656118852"},
		jump = {"rbxassetid://656117878"},
		fall = {"rbxassetid://656115606"},
		climb = {"rbxassetid://656114359"},
		swim = {"rbxassetid://656119721"},
		swimidle = {"rbxassetid://656121397"},
	},
	knight = {
		idle = {"rbxassetid://657595757", "rbxassetid://657568135"},
		walk = {"rbxassetid://657552124"},
		run = {"rbxassetid://657564596"},
		jump = {"rbxassetid://658409194"},
		fall = {"rbxassetid://657600338"},
		climb = {"rbxassetid://658360781"},
		swim = {"rbxassetid://657560551"},
		swimidle = {"rbxassetid://657557095"},
	},
	mage = {
		idle = {"rbxassetid://707742142", "rbxassetid://707855907"},
		walk = {"rbxassetid://707897309"},
		run = {"rbxassetid://707861613"},
		jump = {"rbxassetid://707853694"},
		fall = {"rbxassetid://707829716"},
		climb = {"rbxassetid://707826056"},
		swim = {"rbxassetid://707876443"},
		swimidle = {"rbxassetid://707894699"},
	},
	pirate = {
		idle = {"rbxassetid://750781874", "rbxassetid://750782770"},
		walk = {"rbxassetid://750785693"},
		run = {"rbxassetid://750783738"},
		jump = {"rbxassetid://750782230"},
		fall = {"rbxassetid://750780242"},
		climb = {"rbxassetid://750779899"},
		swim = {"rbxassetid://750784579"},
		swimidle = {"rbxassetid://750785176"},
	},
	cartoony = {
		idle = {"rbxassetid://742637544", "rbxassetid://742638445"},
		walk = {"rbxassetid://742640026"},
		run = {"rbxassetid://742638842"},
		jump = {"rbxassetid://742637942"},
		fall = {"rbxassetid://742637151"},
		climb = {"rbxassetid://742636889"},
		swim = {"rbxassetid://742639220"},
		swimidle = {"rbxassetid://742639812"},
	},
	elder = {
		idle = {"rbxassetid://845397899", "rbxassetid://845400520"},
		walk = {"rbxassetid://845403856"},
		run = {"rbxassetid://845386501"},
		jump = {"rbxassetid://845398858"},
		fall = {"rbxassetid://845396048"},
		climb = {"rbxassetid://845392038"},
		swim = {"rbxassetid://845401742"},
		swimidle = {"rbxassetid://845403127"},
	},
	toy = {
		idle = {"rbxassetid://782841498", "rbxassetid://782845736"},
		walk = {"rbxassetid://782843345"},
		run = {"rbxassetid://782842708"},
		jump = {"rbxassetid://782847020"},
		fall = {"rbxassetid://782846423"},
		climb = {"rbxassetid://782843869"},
		swim = {"rbxassetid://782844582"},
		swimidle = {"rbxassetid://782845186"},
	},
	bubbly = {
		idle = {"rbxassetid://910004836", "rbxassetid://910009958"},
		walk = {"rbxassetid://910034870"},
		run = {"rbxassetid://910025107"},
		jump = {"rbxassetid://910016857"},
		fall = {"rbxassetid://910001910"},
		climb = {"rbxassetid://909997997"},
		swim = {"rbxassetid://910028158"},
		swimidle = {"rbxassetid://910030921"},
	},
	astronaut = {
		idle = {"rbxassetid://891621366", "rbxassetid://891633237"},
		walk = {"rbxassetid://891636393"},
		run = {"rbxassetid://891636393"},
		jump = {"rbxassetid://891627522"},
		fall = {"rbxassetid://891617961"},
		climb = {"rbxassetid://891609353"},
		swim = {"rbxassetid://891639666"},
		swimidle = {"rbxassetid://891663592"},
	},
	vampire = {
		idle = {"rbxassetid://1083445855", "rbxassetid://1083450166"},
		walk = {"rbxassetid://1083473930"},
		run = {"rbxassetid://1083462077"},
		jump = {"rbxassetid://1083455352"},
		fall = {"rbxassetid://1083443587"},
		climb = {"rbxassetid://507765644"},
		swim = {"rbxassetid://1083464683"},
		swimidle = {"rbxassetid://1083467779"},
	},
	werewolf = {
		idle = {"rbxassetid://1083195517", "rbxassetid://1083214717"},
		walk = {"rbxassetid://1083178339"},
		run = {"rbxassetid://1083216690"},
		jump = {"rbxassetid://1083218792"},
		fall = {"rbxassetid://1083189019"},
		climb = {"rbxassetid://1083182000"},
		swim = {"rbxassetid://1083222527"},
		swimidle = {"rbxassetid://1083225406"},
	},
	levitation = {
		idle = {"rbxassetid://616006778", "rbxassetid://616008087"},
		walk = {"rbxassetid://616013216"},
		run = {"rbxassetid://616010382"},
		jump = {"rbxassetid://616008936"},
		fall = {"rbxassetid://616005863"},
		climb = {"rbxassetid://507765644"},
		swim = {"rbxassetid://616011509"},
		swimidle = {"rbxassetid://616012453"},
	},
	rthro = {
		idle = {"rbxassetid://2510196951"},
		walk = {"rbxassetid://2510202577"},
		run = {"rbxassetid://2510198475"},
		jump = {"rbxassetid://2510197830"},
		fall = {"rbxassetid://2510195892"},
		climb = {"rbxassetid://2510192778"},
		swim = {"rbxassetid://2510199791"},
		swimidle = {"rbxassetid://2510201162"},
	},
}

local function applyAnimationPack(packName)
	local pack = ANIMATION_PACKS[packName]
	if not pack then return end

	local char = player.Character
	local animate = char and char:FindFirstChild("Animate")
	if not animate then return end

	for groupName, ids in pairs(pack) do
		local group = animate:FindFirstChild(groupName)
		if group then
			local index = 1
			for _, child in ipairs(group:GetChildren()) do
				if child:IsA("Animation") and ids[index] then
					child.AnimationId = ids[index]
					index += 1
				end
			end
		end
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingTracks()) do
					track:Stop(0)
			end
		end
	end

	local animateClone = animate:Clone()
	animate:Destroy()
	animateClone.Disabled = false
	animateClone.Parent = char
end

--// --- Наполнение Anims ---
local animPacks = {
	"Default (Reset)", "zombie", "robot", "ninja", "knight", "mage", "pirate", 
	"cartoony", "elder", "toy", "bubbly", "astronaut", "vampire", "werewolf", "levitation", "rthro"
}

for _, packName in ipairs(animPacks) do
	local btnFrame = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(25, 25, 25), Parent = tabAnims })
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, btnFrame)
	new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2 }, btnFrame)

	local btn = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.upper(packName),
		TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 16, 
		AutoButtonColor = false, Parent = btnFrame,
	})

	btn.MouseButton1Click:Connect(function()
		applyAnimationPack(packName)
	end)
end

--// --- ЭМОЦИИ ---
local EMOTES = {
	{name = "Wave", id = 507770239}, {name = "Point", id = 507770453}, {name = "Cheer", id = 507770677},
	{name = "Laugh", id = 507770840}, {name = "Dance", id = 507771019}, {name = "Dance 2", id = 507771955},
	{name = "Dance 3", id = 507772104}, {name = "Hello", id = 3576686446}, {name = "Applaud", id = 5915693819},
	{name = "Point HD", id = 3576823880}, {name = "Stadium", id = 3360686498}, {name = "Tilt", id = 3360692915},
	{name = "Shrug", id = 3576968026}, {name = "Salute", id = 3360689775}, {name = "Agree", id = 4849487550},
	{name = "Disagree", id = 4849495710},
}

local emotesAppliedTo = nil

local function playEmote(emoteName)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	if emotesAppliedTo ~= hum then
		local hd = hum:FindFirstChildOfClass("HumanoidDescription")
		if not hd then
			pcall(function() hd = Players:GetHumanoidDescriptionFromUserId(player.UserId) end)
			if not hd then hd = Instance.new("HumanoidDescription") end
			hd.Parent = hum
		end
		local emoteTable = {}
		for _, e in ipairs(EMOTES) do emoteTable[e.name] = {e.id} end
		hd:SetEmotes(emoteTable)
		emotesAppliedTo = hum
	end

	hum:PlayEmote(emoteName)
end

for _, e in ipairs(EMOTES) do
	local btnFrame = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(25, 25, 25), Parent = tabEmotes })
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, btnFrame)
	new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2 }, btnFrame)

	local btn = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.upper(e.name),
		TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 16,
		AutoButtonColor = false, Parent = btnFrame,
	})

	btn.MouseButton1Click:Connect(function() playEmote(e.name) end)
end

--// --- ДИНАМИЧЕСКИЕ СКРИПТЫ ---
local SCRIPT_LIST_URL = "https://raw.githubusercontent.com/hayrxdevofficial/source-scripts-by-me/refs/heads/main/main.txt"
local scriptsContainer = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = tabScripts })
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scriptsContainer)

local function clearScripts()
	for _, child in ipairs(scriptsContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

-- Безопасный аналог string.trim для Luau
local function trim(s)
	return string.match(s, "^%s*(.-)%s*$")
end

-- Универсальная функция для HTTP-запросов (работает в разных эксплойтах)
local function doHttpGet(url)
	if game.HttpGet then
		return game:HttpGet(url, true)
	elseif request then
		return request({Url = url, Method = "GET"}).Body
	elseif syn and syn.request then
		return syn.request({Url = url, Method = "GET"}).Body
	elseif http and http.request then
		return http.request({Url = url, Method = "GET"}).Body
	else
		return nil
	end
end

local function loadScripts()
	clearScripts()
	
	local success, result = pcall(function()
		return doHttpGet(SCRIPT_LIST_URL)
	end)

	if not success or not result or result == "" then
		warn("[Hay] Не удалось загрузить список скриптов.")
		return
	end

	local lines = string.split(result, "\n")
	for _, line in ipairs(lines) do
		line = trim(line) -- Используем нашу безопасную функцию
		if line ~= "" then
			local parts = string.split(line, " ")
			local url = parts[1]
			table.remove(parts, 1)
			local name = table.concat(parts, " ")
			
			if name == "" then name = "Unnamed Script" end

			local btnFrame = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(25, 25, 25), Parent = scriptsContainer })
			new("UICorner", { CornerRadius = UDim.new(0, 5) }, btnFrame)
			new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2 }, btnFrame)

			local btn = new("TextButton", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = string.upper(name),
				TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 16,
				AutoButtonColor = false, Parent = btnFrame,
			})

			btn.MouseButton1Click:Connect(function()
				local s, e = pcall(function()
					local source = doHttpGet(url)
					if source and #source > 0 then
						local func, loadErr = loadstring(source)
						if func then
							func()
						else
							warn("Ошибка компиляции: " .. tostring(loadErr))
						end
					else
						warn("Не удалось загрузить скрипт: пустой ответ.")
					end
				end)
				if not s then warn("Ошибка выполнения: " .. tostring(e)) end
			end)
		end
	end
end

-- Кнопка "Обновить список"
local refreshFrame = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(40, 40, 40), Parent = tabScripts })
new("UICorner", { CornerRadius = UDim.new(0, 5) }, refreshFrame)
new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2 }, refreshFrame)

local refreshBtn = new("TextButton", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "ОБНОВИТЬ СПИСОК",
	TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.GothamBold, TextSize = 14,
	AutoButtonColor = false, Parent = refreshFrame,
})
refreshBtn.MouseButton1Click:Connect(loadScripts)

loadScripts()

--// --- Кнопки Tabs ---
local function createTabButton(text, tabId, order)
	local tabFrame = new("Frame", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		LayoutOrder = order, Parent = tabsFrame,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, tabFrame)
	new("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2 }, tabFrame)

	local btn = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text,
		TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 15, 
		AutoButtonColor = false, Parent = tabFrame,
	})

	btn.MouseButton1Click:Connect(function()
		tabMain.Visible = (tabId == 1)
		tabMisc.Visible = (tabId == 2)
		tabAnims.Visible = (tabId == 3)
		tabEmotes.Visible = (tabId == 4)
		tabScripts.Visible = (tabId == 5)
	end)
end

createTabButton("Main", 1, 1)
createTabButton("Misc", 2, 2)
createTabButton("Anims", 3, 3)
createTabButton("Emotes", 4, 4)
createTabButton("Scripts", 5, 5)

--// --- Логика полёта ---
local flyConn, flyVel, flyGyro
function stopFly()
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if flyVel then flyVel:Destroy() flyVel = nil end
	if flyGyro then flyGyro:Destroy() flyGyro = nil end
end

function startFly()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	flyVel = new("BodyVelocity", { MaxForce = Vector3.new(1e5, 1e5, 1e5), Velocity = Vector3.zero }, hrp)
	flyGyro = new("BodyGyro", { MaxTorque = Vector3.new(1e5, 1e5, 1e5), P = 2000, D = 50 }, hrp)

	flyConn = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local dir = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
		if dir.Magnitude > 0 then dir = dir.Unit end
		flyVel.Velocity = dir * settings.flySpeed
		flyGyro.CFrame = cam.CFrame
	end)
end

--// --- Inf Jump, Noclip и UI ---
UIS.JumpRequest:Connect(function()
	if state.infJump then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

RunService.Stepped:Connect(function()
	if not state.noclip then return end
	local char = player.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false end
	end
end)

button.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
closeBtn.MouseButton1Click:Connect(function() menu.Visible = false end)

local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

menu.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = menu.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

menu.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then update(input) end
end)

player.CharacterAdded:Connect(function(char)
	task.wait(1)
	local hum = char:WaitForChild("Humanoid")
	hum.WalkSpeed = settings.walkSpeed
	hum.UseJumpPower = true
	hum.JumpPower = settings.jumpPower
	hum.HipHeight = settings.hipHeight
end)
