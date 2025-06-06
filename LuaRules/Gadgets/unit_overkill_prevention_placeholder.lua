--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Overkill Prevention Placeholder",
    desc      = "Prevents Placeholders from overlapping too much.",
    author    = "Google Frog",
    date      = "8 August 2016",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
 }
end

include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spValidUnitID           = Spring.ValidUnitID
local spFindUnitCmdDesc       = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc       = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc     = Spring.InsertUnitCmdDesc
local spSetUnitTarget         = Spring.SetUnitTarget
local spGetUnitCommandCount   = Spring.GetUnitCommandCount
local spGiveOrderToUnit       = Spring.GiveOrderToUnit

local FEATURE = 102
local UNIT = 117

local OVERLAP_DISTANCE = 70
local PERSIST_TIME = 260

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local preventOverkillCmdDesc = {
	id      = CMD_PREVENT_OVERKILL,
	type    = CMDTYPE.ICON_MODE,
	name    = "Prevent Overkill.",
	action  = 'preventoverkill',
	tooltip	= 'Enable to prevent units shooting at units which are already going to die.',
	params 	= {0, "Fire at anything", "On automatic commands", "On fire at will", "Single target with Hold Fire", "Prevent Overkill"}
}

local shotRequirement = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local shots = 1
	if ud.canFly then
		shots = shots + 1
	end
	if ud.mass > 400 then
		shots = shots + 1
	end
	if ud.mass > 800 then
		shots = shots + 1
	end
	shotRequirement[i] = shots
end

local _, handledUnitDefIDs, handledWeaponDefIDs, _, OVERKILL_STATES = include("LuaRules/Configs/overkill_prevention_defs.lua")

local canHandleUnit = {}
local units = {}
local projectiles = IterableMap.New()

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local overlappingAreas = 0
local function SumOverlappingAreas(_, data, _, tx, ty, tz, allyTeamID, areaLimit)
	if not overlappingAreas then
		return
	end
	
	if data.allyTeamID and (data.allyTeamID ~= allyTeamID) then
		return
	end
	
	if data.posUpdateFrame or data.removeFrame then
		local gameFrame = Spring.GetGameFrame()
		if data.removeFrame and data.removeFrame < gameFrame then
			return true -- Remove
		end
		if data.posUpdateFrame and data.posUpdateFrame > gameFrame then
			if data.targetID and spValidUnitID(data.targetID) then
				local _,_,_,_,_,_, x, y, z = Spring.GetUnitPosition(data.targetID, true, true)
				data.x = x
				data.y = y
				data.z = z
				data.posUpdateFrame = gameFrame + 10
			else
				data.targetID = nil
				data.posUpdateFrame = nil
			end
		end
	end

	local xDiff = tx - data.x
	local zDiff = tz - data.z
	local yDiff = ty - data.y
	
	if xDiff <= OVERLAP_DISTANCE and zDiff <= OVERLAP_DISTANCE and (xDiff*xDiff + yDiff*yDiff + zDiff*zDiff) < OVERLAP_DISTANCE*OVERLAP_DISTANCE then
		overlappingAreas = overlappingAreas + 1
		if overlappingAreas >= areaLimit then
			overlappingAreas = false
		end
	end
end

function GG.OverkillPreventionPlaceholder_CheckBlock(unitID, targetID, allyTeamID)
	if not (unitID and targetID and units[unitID]) then
		return false
	end
	if not GG.OverkillPrevention_IsWanted(unitID, targetID, units) then
		return false
	end
	
	local _,_,_,_,_,_, x, y, z = Spring.GetUnitPosition(targetID, true, true)
	
	local targetVisiblityState = Spring.GetUnitLosState(targetID, allyTeamID, true)
	local targetIdentified = (targetVisiblityState == 15) or (math.floor(targetVisiblityState / 4) % 4 == 3)
	local shotsRequired
	if targetIdentified then
		local targetDefID = Spring.GetUnitDefID(targetID)
		shotsRequired = shotRequirement[targetDefID] or 2
	else
		shotsRequired = 2
	end
	
	overlappingAreas = 0
	IterableMap.Apply(projectiles, SumOverlappingAreas, x, y, z, allyTeamID, shotsRequired)
	local block = not overlappingAreas
	
	if not block then
		local gameFrame = Spring.GetGameFrame()
		local data = {
			x = x,
			y = y,
			z = z,
			targetID = targetID,
			posUpdateFrame = gameFrame + 10,
			allyTeamID = allyTeamID,
		}
		
		IterableMap.Add(projectiles, -unitID, data)
		return false
	else
		local queueSize = spGetUnitCommandCount(unitID)
		if queueSize == 1 then
			local cmdID, cmdOpts, cmdTag, cp_1, cp_2 = Spring.GetUnitCurrentCommand(unitID)
			if cmdID == CMD.ATTACK and Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts, CMD.OPT_INTERNAL) and cp_1 and (not cp_2) and cp_1 == targetID then
				--Spring.Echo("Removing auto-attack command")
				spGiveOrderToUnit(unitID, CMD.REMOVE, cmdTag, 0 )
			end
		else
			spSetUnitTarget(unitID, 0)
		end
	end
	
	return true
end

function gadget:ProjectileCreated(proID, proOwnerID, weaponDefID)
	if not handledWeaponDefIDs[weaponDefID] then
		return
	end
	
	local data
	
	local targetType, targetData = Spring.GetProjectileTarget(proID)
	if targetType == UNIT then
		-- aim position
		if proOwnerID and IterableMap.InMap(projectiles, -proOwnerID) then
			data = IterableMap.Get(projectiles, -proOwnerID)
			IterableMap.Remove(projectiles, -proOwnerID)
		else
			local _,_,_,_,_,_, x, y, z = Spring.GetUnitPosition(targetData, true, true)
			local gameFrame = Spring.GetGameFrame()
			if z then
				data = {
					x = x,
					y = y,
					z = z,
					targetID = targetData,
					posUpdateFrame = gameFrame + 10,
				}
			end
		end
	elseif targetType == FEATURE then
		local x, y, z = Spring.GetFeaturePosition(targetData)
		data = {
			x = x,
			y = y,
			z = z,
		}
	else
		data = {
			x = targetData[1],
			y = targetData[2],
			z = targetData[3],
		}
	end
	
	if not data then
		return
	end
	
	local teamID = Spring.GetProjectileTeamID(proID)
	if teamID then
		local allyTeamID = select(6, Spring.GetTeamInfo(teamID, false))
		data.allyTeamID = allyTeamID
	end
	
	IterableMap.Add(projectiles, proID, data)
end

function gadget:ProjectileDestroyed(proID)
	if not IterableMap.InMap(projectiles, proID) then
		return
	end
	
	local x, y, z = Spring.GetProjectilePosition(proID)
	local gameFrame = Spring.GetGameFrame()
	
	local data = IterableMap.Get(projectiles, proID)
	data.x = x
	data.y = y
	data.z = z
	data.removeFrame = gameFrame + PERSIST_TIME
	data.allyTeamID = nil
	data.targetID = nil
	data.targetType = nil
	data.posUpdateFrame = nil
	
	IterableMap.Add(projectiles, IterableMap.GetUnusedKey(projectiles), data)
	IterableMap.Remove(projectiles, proID)
end

--local function Echo(key, data, index)
--	Spring.MarkerAddPoint(data.x, data.y, data.z, "")
--end
--
--function gadget:GameFrame(n)
--	if n%15 == 0 then
--		IterableMap.Apply(projectiles, Echo)
--	end
--end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Command Handling

local function PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)
	if canHandleUnit[unitID] then
		local state = cmdParams[1]
		if cmdOptions and cmdOptions.right then
			state = (state - 2)%(OVERKILL_STATES + 1)
		end
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PREVENT_OVERKILL)
		
		if (cmdDescID) then
			preventOverkillCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, {params = preventOverkillCmdDesc.params})
		end
		if state >= 1 then
			units[unitID] = state
		else
			if units[unitID] then
				units[unitID] = nil
			end
		end
		return false
	end
	return true
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_PREVENT_OVERKILL] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_PREVENT_OVERKILL) then
		return true  -- command was not used
	end
	return PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if handledUnitDefIDs[unitDefID] then
		spInsertUnitCmdDesc(unitID, preventOverkillCmdDesc)
		canHandleUnit[unitID] = true
		PreventOverkillToggleCommand(unitID, {handledUnitDefIDs[unitDefID]})
	end
end

function gadget:UnitDestroyed(unitID)
	if canHandleUnit[unitID] then
		if units[unitID] then
			units[unitID] = nil
		end
		canHandleUnit[unitID] = nil
	end
end

function gadget:Initialize()
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
	for w,_ in pairs(handledWeaponDefIDs) do
		Script.SetWatchProjectile(w, true)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
