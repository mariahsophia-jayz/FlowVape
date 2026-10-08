local hasReportedModuleError = false
local function run(callback)
	local success, err = pcall(callback)
	if not success then
		warn(('[FlowVape] Failed to initialize a BedWars lobby module: %s'):format(tostring(err)))
		local currentVape = shared and shared.vape
		if currentVape and not hasReportedModuleError then
			hasReportedModuleError = true
			pcall(function()
				currentVape:CreateNotification(
					'FlowVape',
					'A BedWars lobby module failed to initialize. Check the console for details.',
					8,
					'alert'
				)
			end)
		end
	end
	return success
end

local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return vape:CreateNotification(...)
end

local bedwarsInitialized = false
run(function()
	local function waitForValue(description, timeout, callback)
		local deadline = tick() + timeout
		repeat
			local success, value = pcall(callback)
			if success and value then
				return value
			end
			task.wait(0.1)
		until tick() >= deadline

		error(('Timed out waiting for %s.'):format(description))
	end

	local Knit = waitForValue('the BedWars Knit controller registry', 45, function()
		return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
	end)
	waitForValue('Knit.Start to finish initializing', 45, function()
		return debug.getupvalue(Knit.Start, 1)
	end)

	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client
	local crateController =
		Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController')
	local crateItemMeta = debug.getupvalue(crateController.onStart, 3)

	bedwars = setmetatable({
		Client = Client,
		CrateItemMeta = crateItemMeta,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
	}, {
		__index = function(self, index)
			local controller = Knit.Controllers[index]
			rawset(self, index, controller)
			return controller
		end,
	})

	sessioninfo:AddItem('Kills')
	sessioninfo:AddItem('Beds')
	sessioninfo:AddItem('Wins')
	sessioninfo:AddItem('Games')

	vape:Clean(function()
		table.clear(bedwars)
	end)
	bedwarsInitialized = true
end)

if not bedwarsInitialized then
	return
end

-- Collect first, then remove: mutating vape.Modules while iterating it skips entries.
local toRemove = {}
for name, v in vape.Modules do
	if v.Category == 'Combat' or v.Category == 'Minigames' then
		table.insert(toRemove, name)
	end
end
for _, name in toRemove do
	vape:Remove(name)
end

run(function()
	local Sprint
	local old

	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function()
						lplr.PlayerGui.MobileUI['2'].Visible = false
					end)
				end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function()
					bedwars.SprintController:stopSprinting()
				end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then
					pcall(function()
						lplr.PlayerGui.MobileUI['2'].Visible = true
					end)
				end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.',
	})
end)

run(function()
	local AutoGamble

	AutoGamble = vape.Categories.Minigames:CreateModule({
		Name = 'AutoGamble',
		Function = function(callback)
			if callback then
				AutoGamble:Clean(bedwars.Client:GetNamespace('RewardCrate'):Get('CrateOpened'):Connect(function(data)
					if data.openingPlayer == lplr then
						local tab = bedwars.CrateItemMeta[data.reward.itemType] or { displayName = data.reward.itemType or 'unknown' }
						notif('AutoGamble', 'Won ' .. tab.displayName, 5)
					end
				end))

				repeat
					if not bedwars.CrateAltarController.activeCrates[1] then
						for _, v in bedwars.Store:getState().Consumable.inventory do
							if v.consumable:find('crate') then
								bedwars.CrateAltarController:pickCrate(v.consumable, 1)
								task.wait(1.2)
								if bedwars.CrateAltarController.activeCrates[1] and bedwars.CrateAltarController.activeCrates[1][2] then
									bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
										crateId = bedwars.CrateAltarController.activeCrates[1][2].attributes.crateId,
									})
								end
								break
							end
						end
					end
					task.wait(1)
				until not AutoGamble.Enabled
			end
		end,
		Tooltip = 'Automatically opens lucky crates, piston inspired!',
	})
end)
