local plrs = game:GetService('Players')
local uis = game:GetService('UserInputService')
local rs = game:GetService('RunService')
local ts = game:GetService('TweenService')
local hs = game:GetService('HttpService')

local lplr = plrs.LocalPlayer
local pgui = lplr:WaitForChild('PlayerGui')

local isfile = isfile or function(path)
	local s, res = pcall(readfile, path)
	return s and res ~= nil and res ~= ''
end

local delfile = delfile or function(path)
	writefile(path, '')
end

local repo = 'https://raw.githubusercontent.com/mariahsophia-jayz/FlowVape/main/'

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local scale = math.clamp(workspace.CurrentCamera.ViewportSize.Y / 800, 0.75, 1.8)

local function wipe(folder)
	if not isfolder(folder) then return end
	local s, list = pcall(listfiles, folder)
	if not s then return end

	for _, v in pairs(list) do
		if not v:find('loader') and isfile(v) then
			local content = readfile(v)
			if content and content:find('^--This watermark is used to delete the file') then
				delfile(v)
			end
		end
	end
end

local function init_dirs()
	local dirs = {
		'FlowVape',
		'FlowVape/games',
		'FlowVape/profiles',
		'FlowVape/profilesmobile',
		'FlowVape/assets',
		'FlowVape/assets/new',
		'FlowVape/libraries',
		'FlowVape/guis'
	}
	for i = 1, #dirs do
		if not isfolder(dirs[i]) then
			makefolder(dirs[i])
		end
	end
end

local function fetch_commit()
	-- Prefer the API (stable JSON), fall back to scraping the repo page.
	local s, res = pcall(game.HttpGet, game, 'https://api.github.com/repos/mariahsophia-jayz/FlowVape/commits/main')
	if s and type(res) == 'string' then
		local sha = res:match('"sha"%s*:%s*"(%x+)"')
		if sha and #sha == 40 then
			return sha
		end
	end
	local s2, raw = pcall(game.HttpGet, game, 'https://github.com/mariahsophia-jayz/FlowVape')
	if s2 and type(raw) == 'string' then
		local sha = raw:match('currentOid.-(%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)')
		if sha then return sha end
	end
	return 'main'
end

local function check_commit()
	if shared.VapeDeveloper then return end
	local commit = fetch_commit()
	local cur = isfile('FlowVape/profiles/commit.txt') and readfile('FlowVape/profiles/commit.txt') or ''
	
	if commit == 'main' or cur ~= commit then
		wipe('FlowVape')
		wipe('FlowVape/games')
		wipe('FlowVape/guis')
		wipe('FlowVape/libraries')
		wipe('FlowVape/profiles')
		wipe('FlowVape/profilesmobile')
		wipe('FlowVape/assets/new')
	end
	pcall(writefile, 'FlowVape/profiles/commit.txt', commit)
end

local shared_files = {
	'gui.txt',
	'commit.txt',
	'2619619496.gui.txt',
	'default6872274481.txt',
	'default6872265039.txt'
}

local pc = {
	'Legit6872274481.txt',
	'Blatant6872274481.txt',
	'Legit6872265039.txt',
	'Blatant6872265039.txt'
}

local mobile = {
	'legitMob6872274481.txt',
	'blatantMob6872265039.txt',
	'legitMob6872265039.txt',
	'blatantMob6872274481.txt'
}

local game_scripts = {
	'6872274481.lua',
	'6872265039.lua',
	'8560631822.lua',
	'8444591321.lua'
}

local function download(url, path)
	local s, body = pcall(game.HttpGet, game, url)
	if s and body and body ~= '404: Not Found' then
		pcall(writefile, path, body)
	end
end

local function clean_profiles(is_mobile)
	local whitelist = {}
	for _, v in pairs(shared_files) do whitelist[v] = true end
	
	local target = is_mobile and mobile or pc
	for _, v in pairs(target) do whitelist[v] = true end

	local s, files = pcall(listfiles, 'FlowVape/profiles')
	if not s then return end

	for _, path in pairs(files) do
		local name = path:match('([^/\\]+)$')
		if name and name:sub(-4) == '.txt' and not name:find('%.lua$') and not whitelist[name] then
			pcall(delfile, path)
		end
	end
end

local function get_profiles(is_mobile)
	clean_profiles(is_mobile)
	for i = 1, #shared_files do
		download(repo .. 'profiles/' .. shared_files[i], 'FlowVape/profiles/' .. shared_files[i])
	end
	
	local profs = is_mobile and mobile or pc
	local dir = is_mobile and 'profilesmobile/' or 'profiles/'
	for i = 1, #profs do
		download(repo .. dir .. profs[i], 'FlowVape/profiles/' .. profs[i])
	end
end

local function get_games()
	for i = 1, #game_scripts do
		download(repo .. 'games/' .. game_scripts[i], 'FlowVape/games/' .. game_scripts[i])
	end
end

local function get_assets()
	if not isfolder('FlowVape/assets/new') then
		makefolder('FlowVape/assets/new')
	end
	
	local s, res = pcall(game.HttpGet, game, 'https://api.github.com/repos/mariahsophia-jayz/FlowVape/contents/assets/new?ref=main')
	if not s or not res then return end
	
	local parsed
	pcall(function() parsed = hs:JSONDecode(res) end)
	
	if type(parsed) == 'table' then
		for _, item in pairs(parsed) do
			if item.type == 'file' and item.name and item.download_url then
				download(item.download_url, 'FlowVape/assets/new/' .. item.name)
			end
		end
	end
end

local function run_load(is_mobile, lbl)
	init_dirs()
	if lbl then lbl.Text = 'Checking for updates...' end
	task.wait(0.2)
	
	check_commit()
	if lbl then lbl.Text = 'Downloading profiles...' end
	task.wait(0.1)
	
	get_profiles(is_mobile)
	if lbl then lbl.Text = 'Downloading game scripts...' end
	task.wait(0.1)
	
	get_games()
	if lbl then lbl.Text = 'Downloading assets...' end
	task.wait(0.1)
	
	get_assets()
	if lbl then lbl.Text = 'Loading FlowVape...' end
	task.wait(0.2)
	
	shared.FlowVapeIsMobile = is_mobile
	
	local src = game:HttpGet(repo .. 'main.lua')
	pcall(writefile, 'FlowVape/main.lua', src)
	
	local fn, err = loadstring(src, 'main')
	if not fn then
		return false, 'Syntax error: ' .. tostring(err)
	end
	
	local run_ok, run_err = pcall(fn)
	if not run_ok then
		return false, tostring(run_err)
	end
	
	return true
end

init_dirs()

if isfile('FlowVape/device.txt') then
	local mode = readfile('FlowVape/device.txt')
	local s, err = run_load(mode == 'mobile', nil)
	if s then
		if shared.vape then
			shared.vape:CreateNotification('FlowVape', 'Loaded - thanks for using FlowVape!', 2)
		end
	else
		pcall(delfile, 'FlowVape/device.txt')
		warn('[FlowVape] Load error: ' .. tostring(err))
	end
	return
end

local sg = Instance.new('ScreenGui')
sg.Name = 'FlowVapeInstaller'
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.Parent = pgui

local card = Instance.new('Frame')
card.Name = 'Card'
card.Size = UDim2.fromOffset(280 * scale, 240 * scale)
card.Position = UDim2.fromScale(0.5, 0.5)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.BackgroundColor3 = Color3.fromRGB(18, 17, 19)
card.BorderSizePixel = 0
card.Parent = sg
Instance.new('UICorner', card).CornerRadius = UDim.new(0, 14 * scale)
local cardStroke = Instance.new('UIStroke', card)
cardStroke.Color = Color3.fromRGB(45, 43, 48)
cardStroke.Thickness = 1

local topbar = Instance.new('Frame')
topbar.Size = UDim2.new(1, 0, 0, 38 * scale)
topbar.BackgroundColor3 = Color3.fromRGB(13, 12, 14)
topbar.BorderSizePixel = 0
topbar.Parent = card
Instance.new('UICorner', topbar).CornerRadius = UDim.new(0, 14 * scale)
local tbFix = Instance.new('Frame')
tbFix.Size = UDim2.new(1, 0, 0.5, 0)
tbFix.Position = UDim2.fromScale(0, 0.5)
tbFix.BackgroundColor3 = Color3.fromRGB(13, 12, 14)
tbFix.BorderSizePixel = 0
tbFix.Parent = topbar

local titleLabel = Instance.new('TextLabel')
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = 'FlowVape'
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.TextSize = 13 * scale
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = topbar

local dot = Instance.new('Frame')
dot.Size = UDim2.fromOffset(10 * scale, 10 * scale)
dot.Position = UDim2.new(1, -14 * scale, 0.5, 0)
dot.AnchorPoint = Vector2.new(1, 0.5)
dot.BackgroundColor3 = Color3.fromRGB(55, 53, 58)
dot.BorderSizePixel = 0
dot.Parent = topbar
Instance.new('UICorner', dot).CornerRadius = UDim.new(1, 0)

local rainbow = Instance.new('Frame')
rainbow.Size = UDim2.new(1, 0, 0, 2 * scale)
rainbow.Position = UDim2.new(0, 0, 1, -2 * scale)
rainbow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
rainbow.BorderSizePixel = 0
rainbow.Parent = topbar
local grad = Instance.new('UIGradient', rainbow)

local body = Instance.new('Frame')
body.Size = UDim2.new(1, 0, 1, -38 * scale)
body.Position = UDim2.fromOffset(0, 38 * scale)
body.BackgroundTransparency = 1
body.Parent = card

local mainTitle = Instance.new('TextLabel')
mainTitle.Size = UDim2.new(1, 0, 0, 24 * scale)
mainTitle.Position = UDim2.fromOffset(0, 14 * scale)
mainTitle.BackgroundTransparency = 1
mainTitle.Text = 'Choose your device'
mainTitle.TextColor3 = Color3.fromRGB(210, 210, 210)
mainTitle.TextSize = 14 * scale
mainTitle.Font = Enum.Font.GothamSemibold
mainTitle.Parent = body

local subTitle = Instance.new('TextLabel')
subTitle.Size = UDim2.new(1, 0, 0, 18 * scale)
subTitle.Position = UDim2.fromOffset(0, 36 * scale)
subTitle.BackgroundTransparency = 1
subTitle.Text = 'Select the platform you are on'
subTitle.TextColor3 = Color3.fromRGB(100, 98, 105)
subTitle.TextSize = 11 * scale
subTitle.Font = Enum.Font.Gotham
subTitle.Parent = body

local function makeBtn(name, desc, icon, xOffset, accentColor)
	local btn = Instance.new('TextButton')
	btn.Size = UDim2.fromOffset(118 * scale, 90 * scale)
	btn.Position = UDim2.fromOffset(xOffset, 62 * scale)
	btn.BackgroundColor3 = Color3.fromRGB(23, 22, 25)
	btn.BorderSizePixel = 0
	btn.Text = ''
	btn.AutoButtonColor = false
	btn.Parent = body
	Instance.new('UICorner', btn).CornerRadius = UDim.new(0, 10 * scale)
	local s = Instance.new('UIStroke', btn)
	s.Color = Color3.fromRGB(40, 38, 44)
	s.Thickness = 1
	local accent = Instance.new('Frame')
	accent.Size = UDim2.new(1, 0, 0, 2 * scale)
	accent.Position = UDim2.new(0, 0, 1, -2 * scale)
	accent.BackgroundColor3 = accentColor
	accent.BorderSizePixel = 0
	accent.Parent = btn
	Instance.new('UICorner', accent).CornerRadius = UDim.new(0, 10 * scale)
	local ic = Instance.new('TextLabel')
	ic.Size = UDim2.new(1, 0, 0, 36 * scale)
	ic.Position = UDim2.fromOffset(0, 10 * scale)
	ic.BackgroundTransparency = 1
	ic.Text = icon
	ic.TextSize = 28 * scale
	ic.Font = Enum.Font.Gotham
	ic.Parent = btn
	local nl = Instance.new('TextLabel')
	nl.Size = UDim2.new(1, 0, 0, 18 * scale)
	nl.Position = UDim2.fromOffset(0, 50 * scale)
	nl.BackgroundTransparency = 1
	nl.Text = name
	nl.TextColor3 = Color3.fromRGB(200, 200, 200)
	nl.TextSize = 13 * scale
	nl.Font = Enum.Font.GothamSemibold
	nl.Parent = btn
	local dl = Instance.new('TextLabel')
	dl.Size = UDim2.new(1, 0, 0, 14 * scale)
	dl.Position = UDim2.fromOffset(0, 68 * scale)
	dl.BackgroundTransparency = 1
	dl.Text = desc
	dl.TextColor3 = Color3.fromRGB(90, 88, 95)
	dl.TextSize = 10 * scale
	dl.Font = Enum.Font.Gotham
	dl.Parent = btn
	btn.MouseEnter:Connect(function()
		ts:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(28, 27, 31)}):Play()
		ts:Create(s, TweenInfo.new(0.12), {Color = accentColor}):Play()
	end)
	btn.MouseLeave:Connect(function()
		ts:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(23, 22, 25)}):Play()
		ts:Create(s, TweenInfo.new(0.12), {Color = Color3.fromRGB(40, 38, 44)}):Play()
	end)
	return btn
end

local pcBtn = makeBtn('PC', 'Windows / Mac', 'PC', 14 * scale, Color3.fromRGB(96, 165, 250))
local mobBtn = makeBtn('Mobile', 'iOS / Android', 'MOB', 148 * scale, Color3.fromRGB(74, 222, 128))

local statusLabel = Instance.new('TextLabel')
statusLabel.Size = UDim2.new(1, -28 * scale, 0, 20 * scale)
statusLabel.Position = UDim2.fromOffset(14 * scale, 162 * scale)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ''
statusLabel.TextColor3 = Color3.fromRGB(120, 118, 125)
statusLabel.TextSize = 11 * scale
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.Parent = body

local hue = 0
local rainbowConn = rs.RenderStepped:Connect(function()
	hue = (hue + 0.005) % 1
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, 1, 1)),
		ColorSequenceKeypoint.new(0.2, Color3.fromHSV((hue + 0.2) % 1, 1, 1)),
		ColorSequenceKeypoint.new(0.4, Color3.fromHSV((hue + 0.4) % 1, 1, 1)),
		ColorSequenceKeypoint.new(0.6, Color3.fromHSV((hue + 0.6) % 1, 1, 1)),
		ColorSequenceKeypoint.new(0.8, Color3.fromHSV((hue + 0.8) % 1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 1, 1)),
	})
end)

local dragging = false
local dragStart, startPos
topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = card.Position
	end
end)
uis.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		card.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
	end
end)
uis.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local function start(is_mobile)
	pcBtn.Active = false
	mobBtn.Active = false
	statusLabel.Text = 'Setting up folders...'
	statusLabel.TextColor3 = Color3.fromRGB(120, 118, 125)
	task.wait(0.2)

	local s, err = run_load(is_mobile, statusLabel)

	if s then
		pcall(writefile, 'FlowVape/device.txt', is_mobile and 'mobile' or 'pc')
		rainbowConn:Disconnect()
		sg:Destroy()
		task.wait(0.3)
		if shared.vape then
			shared.vape:CreateNotification('FlowVape', 'Loaded - thanks for using FlowVape!', 2)
		end
	else
		pcall(delfile, 'FlowVape/device.txt')
		statusLabel.Text = 'Error: ' .. tostring(err):sub(1, 50)
		statusLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
		pcBtn.Active = true
		mobBtn.Active = true
	end
end

pcBtn.MouseButton1Click:Connect(function() start(false) end)
mobBtn.MouseButton1Click:Connect(function() start(true) end)
