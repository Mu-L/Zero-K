if gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name      = "Widget Events",
	desc      = "Tells widgets about events they can know about",
	author    = "Sprung, Klon",
	date      = "2015-05-27",
	license   = "PD",
	layer     = 0,
	enabled   = true,
} end

local spAreTeamsAllied     = Spring.AreTeamsAllied
local spGetMyAllyTeamID    = Spring.GetMyAllyTeamID
local spGetMyTeamID        = Spring.GetMyTeamID
local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitLosState    = Spring.GetUnitLosState

--[[ NB: these are C proxies, not the actual Lua functions currently linked LuaUI-side,
     so it is safe to cache them here even if the underlying func changes afterwards ]]
local scriptUnitDestroyed       = Script.LuaUI.UnitDestroyed
local scriptUnitDestroyedByTeam = Script.LuaUI.UnitDestroyedByTeam
local scriptUnitLeftRadar	= Script.LuaUI.UnitLeftRadar

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attUnitID, attUnitDefID, attTeamID)
	local myAllyTeamID = spGetMyAllyTeamID()
	local spec, specFullView = spGetSpectatingState()
	local isAllyUnit = spAreTeamsAllied(unitTeam, spGetMyTeamID())
	
	-- we need to check if any widget uses the callin, otherwise it is not bound and will produce error spam
	if Script.LuaUI('UnitDestroyedByTeam') then
		if spec then
			scriptUnitDestroyedByTeam(unitID, unitDefID, unitTeam, attTeamID)
			if not specFullView and not isAllyUnit then
				local losState = spGetUnitLosState(unitID, myAllyTeamID, true)
				if losState % 2 == 1 then
					scriptUnitDestroyed (unitID, unitDefID, unitTeam)
				elseif losState ~= 0 and Script.LuaUI('UnitLeftRadar') then
					scriptUnitLeftRadar(unitID, unitTeam)
				end
			end
		else
			local attackerInLos = attUnitID and (spGetUnitLosState(attUnitID, myAllyTeamID, true) % 2 == 1)
			if isAllyUnit then
				scriptUnitDestroyedByTeam(unitID, unitDefID, unitTeam, attackerInLos and attTeamID or nil)
			else
				local losState = spGetUnitLosState(unitID, myAllyTeamID, true)
				if losState % 2 == 1 then
					scriptUnitDestroyed (unitID, unitDefID, unitTeam)
					scriptUnitDestroyedByTeam (unitID, unitDefID, unitTeam, attackerInLos and attTeamID or nil)
				elseif losState ~= 0 and Script.LuaUI('UnitLeftRadar') then
					scriptUnitLeftRadar(unitID, unitTeam)
				end
			end
		end
	else
		if not isAllyUnit and not (spec and specFullView) then
			local losState = spGetUnitLosState(unitID, myAllyTeamID, true)
			if losState % 2 == 1 then
				scriptUnitDestroyed(unitID, unitDefID, unitTeam)
			elseif losState ~= 0 and Script.LuaUI('UnitLeftRadar') then
				scriptUnitLeftRadar(unitID, unitTeam)
			end
		end
	end
end
