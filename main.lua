repeat task.wait() until game:IsLoaded()

if shared.vape then
    pcall(function() shared.vape:Uninject() end)
end

if identifyexecutor then
    local exec = ({identifyexecutor()})[1] or ''
    if table.find({'Argon', 'Volt', 'Wave', 'Xeno', 'Solara'}, exec) then
        getgenv().setthreadidentity = nil
    end
end

local vape
local old_loadstring = loadstring

local loadstring = function(...)
    local res, err = old_loadstring(...)
    if err and vape then
        vape:CreateNotification('Vape', 'Failed to load: ' .. tostring(err), 30, 'alert')
    end
    return res, err
end

local queue_on_teleport = queue_on_teleport or queueonteleport or function() end

local isfile = isfile or function(path)
    local s, res = pcall(readfile, path)
    return s and res ~= nil and res ~= ''
end

local cloneref = cloneref or function(obj) return obj end
local plrs = cloneref(game:GetService('Players'))
local hs = game:GetService('HttpService')
local isMobile = shared.FlowVapeIsMobile == true
local repo = 'https://raw.githubusercontent.com/mariahsophia-jayz/FlowVape/main/'

local all_profiles = {
    ['6872274481'] = {
        {Name = 'Legit', File = 'Legit6872274481'},
        {Name = 'Blatant', File = 'Blatant6872274481'},
        {Name = 'LegitMob', File = 'legitMob6872274481'},
        {Name = 'BlatantMob', File = 'blatantMob6872274481'}
    },
    ['6872265039'] = {
        {Name = 'Legit', File = 'Legit6872265039'},
        {Name = 'Blatant', File = 'Blatant6872265039'},
        {Name = 'LegitMob', File = 'legitMob6872265039'},
        {Name = 'BlatantMob', File = 'blatantMob6872265039'}
    }
}

local function injectProfiles()
    local placeId = tostring(game.PlaceId)
    local profiles = all_profiles[placeId]
    if not profiles then return end

    local list = vape.Profiles or {}
    vape.Profiles = list

    for i = 1, #profiles do
        local entry = profiles[i]
        if entry and entry.Name then
            local is_mob = entry.Name:find('Mob') ~= nil
            if (isMobile and is_mob) or (not isMobile and not is_mob) then
                local exists = false
                for _, v in pairs(list) do
                    local name = type(v) == 'table' and v.Name or tostring(v)
                    if name == entry.Name then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(list, {Name = entry.Name, File = entry.File, Bind = {}})
                end
            end
        end
    end

    pcall(function()
        if vape.Categories and vape.Categories.Profiles then
            vape.Categories.Profiles:ChangeValue()
        end
    end)
end

local function downloadFile(path, func)
    if not isfile(path) then
        local s, res = pcall(function()
            return game:HttpGet(repo .. (path:gsub('FlowVape/', '')), true)
        end)
        if not s or not res or res == '' or res == '404: Not Found' then
            error('Failed to download: ' .. tostring(path))
        end
        if path:find('%.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
        end
        writefile(path, res)
    end
    return (func or readfile)(path)
end
shared.downloadFile = downloadFile

local function finishLoading()
    vape.Init = nil
    vape:Load()
    pcall(injectProfiles)

    local last_file = 'FlowVape/profiles/lastprofile.txt'
    local old_load = vape.LoadProfile
    if old_load then
        vape.LoadProfile = function(self, name, ...)
            pcall(writefile, last_file, tostring(name))
            return old_load(self, name, ...)
        end
    end

    local last = isfile(last_file) and readfile(last_file) or nil
    if last and last ~= '' then
        task.spawn(function()
            local start = tick()
            while not shared.FlowVapeGameReady and tick() - start < 15 do
                task.wait(0.1)
            end
            pcall(function()
                if vape.LoadProfile then
                    vape:LoadProfile(last)
                end
                local lobby = 'FlowVape/profiles/' .. last .. '6872274481.txt'
                local match = 'FlowVape/profiles/' .. last .. '6872265039.txt'
                if isfile(lobby) and isfile(match) then
                    local s1, lobby_data = pcall(function() return hs:JSONDecode(readfile(lobby)) end)
                    local s2, match_data = pcall(function() return hs:JSONDecode(readfile(match)) end)
                    if s1 and s2 and type(lobby_data) == 'table' and type(match_data) == 'table' then
                        for k, v in pairs(lobby_data) do
                            if match_data[k] == nil then
                                match_data[k] = v
                            end
                        end
                        pcall(writefile, match, hs:JSONEncode(match_data))
                    end
                end
            end)
        end)
    end

    task.spawn(function()
        repeat
            vape:Save()
            task.wait(10)
        until not vape.Loaded
    end)

    local teleported
    vape:Clean(plrs.LocalPlayer.OnTeleport:Connect(function()
        if not teleported and not shared.VapeIndependent then
            teleported = true
            local src = [[
shared.vapereload = true
if shared.VapeDeveloper then
    loadstring(readfile('FlowVape/loader.lua'), 'loader')()
else
    loadstring(game:HttpGet('https://raw.githubusercontent.com/mariahsophia-jayz/FlowVape/main/loader.lua', true), 'loader')()
end
]]
            if shared.VapeDeveloper then
                src = 'shared.VapeDeveloper = true\n' .. src
            end
            if shared.VapeCustomProfile then
                local escaped = shared.VapeCustomProfile:gsub('\\', '\\\\'):gsub('"', '\\"')
                src = 'shared.VapeCustomProfile = "' .. escaped .. '"\n' .. src
            end
            vape:Save()
            queue_on_teleport(src)
        end
    end))

    if not shared.vapereload then
        if not vape.Categories or not vape.Categories.Main or not vape.Categories.Main.Options then return end
        local opt = vape.Categories.Main.Options['GUI bind indicator']
        if opt and opt.Enabled then
            vape:CreateNotification(
                'Finished Loading',
                vape.VapeButton and 'Press the button in the top right to open GUI'
                    or 'Press ' .. table.concat(vape.Keybind, ' + '):upper() .. ' to open GUI',
                5
            )
        end
    end
end

if not isfile('FlowVape/profiles/gui.txt') then
    pcall(writefile, 'FlowVape/profiles/gui.txt', 'new')
end

local gui = isfile('FlowVape/profiles/gui.txt') and readfile('FlowVape/profiles/gui.txt') or 'new'
gui = gui:gsub('%s+', '')
if gui == '' then gui = 'new' end

if not isfolder('FlowVape/assets/' .. gui) then
    makefolder('FlowVape/assets/' .. gui)
end

local s_gui, gui_raw = pcall(function()
    return game:HttpGet(repo .. 'guis/' .. gui .. '.lua')
end)
if not s_gui or not gui_raw or gui_raw == '' or gui_raw == '404: Not Found' then
    error('Failed to fetch GUI: ' .. tostring(gui))
end

local gui_fn, gui_err = loadstring(gui_raw, 'gui')
if not gui_fn then
    warn('[FlowVape] GUI syntax error: ' .. tostring(gui_err))
    error('GUI syntax error: ' .. tostring(gui_err))
end

local ran, res = pcall(gui_fn)
if not ran or not res then
    error('GUI failed to run: ' .. tostring(res))
end

vape = res
shared.vape = vape

if not shared.VapeIndependent then
    local s_uni, uni_raw = pcall(function()
        return game:HttpGet(repo .. 'games/universal.lua')
    end)
    if not s_uni or not uni_raw or uni_raw == '' or uni_raw == '404: Not Found' then
        error('Failed to fetch universal.lua')
    end

    local uni_fn, uni_err = loadstring(uni_raw, 'universal')
    if not uni_fn then
        error('universal.lua syntax error: ' .. tostring(uni_err))
    end
    uni_fn()

    local path = 'FlowVape/games/' .. game.PlaceId .. '.lua'
    if isfile(path) then
        local s_game, cached = pcall(readfile, path)
        if s_game and cached and cached ~= '' then
            local game_fn, game_err = loadstring(cached, tostring(game.PlaceId))
            if game_fn then
                game_fn(...)
            else
                warn('[FlowVape] Cached game script error: ' .. tostring(game_err))
            end
        end
    else
        if not shared.VapeDeveloper then
            local s_net, net_code = pcall(function()
                return game:HttpGet(repo .. 'games/' .. game.PlaceId .. '.lua', true)
            end)
            if s_net and net_code and net_code ~= '' and net_code ~= '404: Not Found' then
                -- Watermark so the loader's wipe step refreshes this on the next update
                if not net_code:find('^%-%-This watermark') then
                    net_code = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. net_code
                end
                writefile(path, net_code)
                local game_fn, game_err = loadstring(net_code, tostring(game.PlaceId))
                if game_fn then
                    game_fn(...)
                else
                    warn('[FlowVape] Game script error: ' .. tostring(game_err))
                end
            end
        end
    end

    finishLoading()
else
    vape.Init = finishLoading
    return vape
end
