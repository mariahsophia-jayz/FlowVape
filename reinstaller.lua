-- Gui to Lua
-- Version: 3.2

-- Instances:

local flowvape = Instance.new("ScreenGui")
local notifframe = Instance.new("Frame")
local uicorner = Instance.new("UICorner")
local uistroke = Instance.new("UIStroke")
local notiflabel = Instance.new("TextLabel")

-- Properties:

flowvape.Name = "flowvape"
flowvape.ResetOnSpawn = false
flowvape.IgnoreGuiInset = true
flowvape.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
flowvape.DisplayOrder = 99999

pcall(function()
    flowvape.Parent = game:GetService("CoreGui")
end)
if not flowvape.Parent then
    flowvape.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

notifframe.Name = "notifframe"
notifframe.Parent = flowvape
notifframe.BackgroundColor3 = Color3.fromRGB(18, 17, 19)
notifframe.BackgroundTransparency = 0.100
notifframe.BorderSizePixel = 0
notifframe.Position = UDim2.new(1, -280, 1, -90)
notifframe.Size = UDim2.new(0, 260, 0, 70)

uicorner.CornerRadius = UDim.new(0, 8)
uicorner.Name = "uicorner"
uicorner.Parent = notifframe

uistroke.Color = Color3.fromRGB(96, 165, 250)
uistroke.Thickness = 1.500
uistroke.Name = "uistroke"
uistroke.Parent = notifframe

notiflabel.Name = "notiflabel"
notiflabel.Parent = notifframe
notiflabel.BackgroundTransparency = 1.000
notiflabel.Position = UDim2.new(0, 10, 0, 5)
notiflabel.Size = UDim2.new(1, -20, 1, -10)
notiflabel.Font = Enum.Font.GothamSemibold
notiflabel.Text = "flowvape\ndeleting old files..."
notiflabel.TextColor3 = Color3.fromRGB(220, 220, 220)
notiflabel.TextSize = 14.000
notiflabel.TextWrapped = true

-- Scripts:

local function custlog(str, ui)
    if ui then
        notiflabel.Text = str
    end
    print("[flowvape] " .. str)
end

if shared.vape then
    pcall(function()
        shared.vape:Uninject()
    end)
    shared.vape = nil
end

local function del(dir)
    if not isfolder(dir) then return end
    
    if delfolder then
        pcall(delfolder, dir)
        return
    end

    if listfiles then
        for _, v in pairs(listfiles(dir)) do
            pcall(function()
                if isfile(v) then
                    if delfile then 
                        delfile(v) 
                    else 
                        writefile(v, "") 
                    end
                elseif isfolder(v) then
                    del(v)
                end
            end)
        end
    end
end

custlog("cleaning flowvape folder...", false)
del("FlowVape")

task.wait(1.5)

custlog("done, downloading main script...", true)
task.wait(0.5)

flowvape:Destroy()

loadstring(game:HttpGet("https://raw.githubusercontent.com/mariahsophia-jayz/FlowVape/main/NewMainScript.lua", true))()
