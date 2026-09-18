local isfile = isfile or function(path)
    local s, res = pcall(readfile, path)
    return s and res ~= nil and res ~= ''
end

local delfile = delfile or function(path)
    pcall(writefile, path, '')
end

local repo = 'https://raw.githubusercontent.com/mariahsophia-jayz/FlowVape/main/'

local function wipeFolder(dir)
    if not isfolder(dir) then return end
    for _, v in pairs(listfiles(dir)) do
        if not v:find('loader') and isfile(v) then
            local content = readfile(v)
            if content and content:find('^--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.') then
                delfile(v)
            end
        end
    end
end

local folders = {'FlowVape', 'FlowVape/games', 'FlowVape/profiles', 'FlowVape/assets', 'FlowVape/libraries', 'FlowVape/profilesmobile', 'FlowVape/guis'}
for i = 1, #folders do
    if not isfolder(folders[i]) then
        pcall(makefolder, folders[i])
    end
end

task.wait(0.1)

local function fetchCommit()
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

if not shared.VapeDeveloper then
    local commit = fetchCommit()
    local cur = isfile('FlowVape/profiles/commit.txt') and readfile('FlowVape/profiles/commit.txt') or ''
    
    if commit == 'main' or cur ~= commit then
        wipeFolder('FlowVape')
        wipeFolder('FlowVape/games')
        wipeFolder('FlowVape/guis')
        wipeFolder('FlowVape/libraries')
    end
    pcall(writefile, 'FlowVape/profiles/commit.txt', commit)
end

local function downloadFile(path, func)
    if not isfile(path) then
        local s, res = pcall(function()
            return game:HttpGet(repo .. (path:gsub('FlowVape/', '')), true)
        end)
        if not s or res == '404: Not Found' then
            error(res)
        end
        if path:find('%.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
        end
        pcall(writefile, path, res)
        if func then return func(path) end
        return res 
    end
    return (func or readfile)(path)
end

local function forceDownloadProfile(urlPath, localPath)
    local s, res = pcall(function()
        return game:HttpGet(repo .. urlPath, true)
    end)
    if s and res ~= '404: Not Found' then
        pcall(writefile, 'FlowVape/' .. localPath, res)
    end
end

local isMobile = shared.FlowVapeIsMobile == true

if isMobile then
    local mobile = {
        {remote = 'profilesmobile/legitMob6872274481.txt', saveAs = 'profiles/Legit6872274481.txt'},
        {remote = 'profilesmobile/blatantMob6872274481.txt', saveAs = 'profiles/Blatant6872274481.txt'},
        {remote = 'profilesmobile/legitMob6872265039.txt', saveAs = 'profiles/Legit6872265039.txt'},
        {remote = 'profilesmobile/blatantMob6872265039.txt', saveAs = 'profiles/Blatant6872265039.txt'}
    }
    for i = 1, #mobile do
        forceDownloadProfile(mobile[i].remote, mobile[i].saveAs)
    end
else
    local pc = {
        {remote = 'profiles/Legit6872274481.txt', saveAs = 'profiles/Legit6872274481.txt'},
        {remote = 'profiles/Blatant6872274481.txt', saveAs = 'profiles/Blatant6872274481.txt'},
        {remote = 'profiles/Legit6872265039.txt', saveAs = 'profiles/Legit6872265039.txt'},
        {remote = 'profiles/Blatant6872265039.txt', saveAs = 'profiles/Blatant6872265039.txt'}
    }
    for i = 1, #pc do
        forceDownloadProfile(pc[i].remote, pc[i].saveAs)
    end
end

return loadstring(downloadFile('FlowVape/main.lua'), 'main')()
