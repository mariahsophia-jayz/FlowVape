--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.

local vape = shared.vape
local nativeLoadstring = loadstring
local GAME_PLACE_ID = 6872274481
local GAME_SCRIPT_PATH = ('FlowVape/games/%d.lua'):format(GAME_PLACE_ID)
local CACHE_WATERMARK =
	'--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'

local function notify(message, notificationType)
	if not vape then
		return
	end

	pcall(function()
		vape:CreateNotification('FlowVape', tostring(message), 8, notificationType or 'alert')
	end)
end

local function readTextFile(path)
	if type(readfile) ~= 'function' then
		return nil
	end

	local success, contents = pcall(readfile, path)
	if success and type(contents) == 'string' and contents ~= '' then
		return contents
	end
	return nil
end

local function resolveCommit()
	local commit = readTextFile('FlowVape/profiles/commit.txt')
	commit = commit and commit:match('^%s*(.-)%s*$')
	if commit and commit:match('^[%w._%-]+$') then
		return commit
	end
	return 'main'
end

local function loadGameSource(path)
	local cachedSource = readTextFile(path)
	if cachedSource then
		return cachedSource
	end

	if shared.VapeDeveloper then
		return nil, 'The local BedWars script is missing while developer mode is enabled.'
	end

	local relativePath = path:gsub('^FlowVape/', '')
	local url = ('https://raw.githubusercontent.com/mariahsophia-jayz/FlowVape/%s/%s'):format(
		resolveCommit(),
		relativePath
	)
	local success, source = pcall(function()
		return game:HttpGet(url, true)
	end)

	if not success then
		return nil, tostring(source)
	end
	if type(source) ~= 'string' or source == '' or source:find('404: Not Found', 1, true) then
		return nil, 'The BedWars game script could not be found at the configured revision.'
	end

	if path:match('%.lua$') and not source:match('^%-%-This watermark') then
		source = CACHE_WATERMARK .. source
	end

	if type(writefile) == 'function' then
		pcall(writefile, path, source)
	end
	return source
end

local function executeGameSource(source)
	if type(nativeLoadstring) ~= 'function' then
		notify('This executor does not provide loadstring.')
		return false
	end

	local compileSuccess, chunk, compileError = pcall(nativeLoadstring, source, 'bedwars')
	if not compileSuccess or type(chunk) ~= 'function' then
		notify('BedWars script compilation failed: ' .. tostring(compileError or chunk))
		return false
	end

	local success, runtimeError = pcall(chunk)
	if not success then
		notify('BedWars script startup failed: ' .. tostring(runtimeError))
		return false
	end
	return true
end

vape.Place = GAME_PLACE_ID

local gameSource, loadError = loadGameSource(GAME_SCRIPT_PATH)
if gameSource then
	executeGameSource(gameSource)
else
	notify('Unable to load BedWars support: ' .. tostring(loadError))
end
