if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name = "Impact Swap",
		desc = "Swaps one projectile for another upon destruction",
		author = "GoogleFrog",
		date = "11 November 2023",
		license  = "GNU GPL, v2 or later",
		layer = -1,
		enabled = true
	}
end

local chainDefs = {}
for i = 1,#WeaponDefs do
	local wcp = WeaponDefs[i].customParams
	if wcp and wcp.child_chain_projectile then
		chainDefs[i] = {
			childDefID = WeaponDefNames[wcp.child_chain_projectile].id,
			setSpeed = tonumber(wcp.child_chain_speed) or false,
			maxVerticalFactor = tonumber(wcp.child_max_vertical) or false,
		}
	end
end

function gadget:ProjectileDestroyed(proID, proOwnerID)
	if not proID then
		return
	end
	local weaponDefID = Spring.GetProjectileDefID(proID)
	if not (weaponDefID and chainDefs[weaponDefID]) then
		return
	end
	local chainDef = chainDefs[weaponDefID]
	local projectileParams = {}
	
	local x, y, z = Spring.GetProjectilePosition(proID)
	projectileParams.pos = {x, y, z}
	
	local vx, vy, vz = Spring.GetProjectileVelocity(proID)
	local proSpeed = math.sqrt(vx*vx + vy*vy + vz*vz)
	if chainDef.setSpeed then
		local factor = chainDef.setSpeed/proSpeed
		vx, vy, vz = vx * factor, vy * factor, vz * factor
		
		if vx == 0 and vz == 0 then
			vx = 0.0000001 + (math.floor(math.random()*2)*2 - 1) * math.random()*0.0000001
			vz = 0.0000001 + (math.floor(math.random()*2)*2 - 1) * math.random()*0.0000001
		end
		if chainDef.maxVerticalFactor then
			local vertfactor = math.abs(vy) / (chainDef.maxVerticalFactor * math.sqrt(vx*vx + vz*vz))
			if vertfactor > 1 then
				vx, vz = vx * vertfactor, vz * vertfactor
				proSpeed = math.sqrt(vx*vx + vy*vy + vz*vz)
				factor = chainDef.setSpeed/proSpeed
				vx, vy, vz = vx * factor, vy * factor, vz * factor
			end
		end
		proSpeed = chainDef.setSpeed
	end
	projectileParams["end"] = {x + vx, y + vy, z + vz}
	projectileParams.speed = proSpeed
	
	projectileParams.spread = {0, 0, 0}
	projectileParams.error = projectileParams.spread
	
	local ownerID = Spring.GetProjectileOwnerID(proID)
	if Spring.ValidUnitID(ownerID) then
		projectileParams.owner = ownerID
	end
	projectileParams.team = Spring.GetProjectileTeamID(proID)
	
	local newProID = Spring.SpawnProjectile(chainDef.childDefID, projectileParams)
	Spring.SetProjectileVelocity(newProID, vx, vy, vz)
end

function gadget:Initialize()
	for weaponDefID, _ in pairs(chainDefs) do
		Script.SetWatchWeapon(weaponDefID, true)
	end
end
