--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
return {
	name      = "Self destruct blocker",
	desc      = "ctrl+A+D becomes a resign",
	author    = "lurker",
	date      = "April, 2009",
	license   = "public domain",
	layer     = 0,
	enabled   = not (Spring.Utilities.Gametype.is1v1() or Spring.Utilities.Gametype.isFFA()),
	}
end

local spGetTeamUnits         = Spring.GetTeamUnits
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitSelfDTime     = Spring.GetUnitSelfDTime
local spGiveOrderToUnitArray = Spring.GiveOrderToUnitArray
local sputGetUnitCost        = Spring.Utilities.GetUnitCost

local CMD_SELFD = CMD.SELFD

local teamList = Spring.GetTeamList()
local teamCount = #teamList

local deathTeams = {}
local needsCheck = false

local onlyCountList = {}
for unitDefID, unitDef in pairs(UnitDefs) do
	if not unitDef.customParams.dontcount and not unitDef.canKamikaze then
		onlyCountList[unitDefID] = true
	end
end

function gadget:Initialize()
	local max = math.max
	for i = 1, teamCount do
		local teamID = teamList[i]
		deathTeams[teamID] = false
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_SELFD] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return onlyCountList
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions)
	needsCheck = true
	deathTeams[unitTeam] = true
	return true
end

local function CheckDeathTeam(teamID)
	local  realUnitCount = 0
	local selfDUnitCount = 0
	local selfDUnitIDs = {}
	local teamUnits = spGetTeamUnits(teamID)
	for i = 1, #teamUnits do
		local unitID = teamUnits[i]
		local unitDefID = spGetUnitDefID(unitID)
		if onlyCountList[unitDefID] then
			realUnitCount = realUnitCount + 1

			local selfDtime = spGetUnitSelfDTime(unitID)
			if selfDtime > 0 then
				selfDUnitCount = selfDUnitCount + 1
				selfDUnitIDs[selfDUnitCount] = unitID
			end
		end
	end

	--[[ The threshold is not 100% because between hitting Ctrl+A
	     and the self-D order reaching the server some more units
	     could have been created (keypress delay, network lag). ]]
	if selfDUnitCount < 0.85 * realUnitCount then
		return
	end

	--[[ Don't apply when self-destructing singular units, up
	     to 4k cost. The intent is to allow self-ding things
	     like your fac in a high density teamgame (apparently
	     a common case) and this value is supposed to let such
	     units through, while still not being enough to let a
	     commander self-d. ]]
	if selfDUnitCount < 10 then
		local value = 0
		for i = 1, selfDUnitCount do
			value = value + sputGetUnitCost(selfDUnitIDs[i])
		end
		if value < 4000 then
			return
		end
	end

	--[[ Resign the team because using Ctrl+AD to quit is a habit
	     that people have already developed (originating all the
	     way back in OTA). Perhaps it would be good to just block
	     the self-D command but not resign (forcing veterans to
	     learn the new methods, which would ultimately allow us to
	     remove the block as well). ]]
	gadgetHandler.RemoveCallIn(gadgetHandler, 'AllowCommand')
	spGiveOrderToUnitArray(selfDUnitIDs, CMD_SELFD, 0, 0)
	gadgetHandler.UpdateCallIn(gadgetHandler, 'AllowCommand')
	if #Spring.GetPlayerList(teamID) < 2 then -- do not kill commshare teams!
		local _, leader = Spring.GetTeamInfo(teamID)
		local playerName = (leader and Spring.GetPlayerInfo(leader)) or "Unknown"
		Spring.Echo("Someone attempted to self-destruct most of their stuff!")
		Spring.Echo("TeamID: ", teamID, "Player: ", playerName)
		--GG.ResignTeam(teamID)
	end
end

function gadget:GameFrame(n)
	if not needsCheck then
		return
	end
	for i = 1, teamCount do
		local teamID = teamList[i]
		if deathTeams[teamID] then
			CheckDeathTeam(teamID)
			deathTeams[teamID] = false
		end
	end
end
