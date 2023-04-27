local meta = FindMetaTable("Player")

local util_SharedRandom = util.SharedRandom
local PLAYERANIMEVENT_FLINCH_HEAD = PLAYERANIMEVENT_FLINCH_HEAD
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local GESTURE_SLOT_FLINCH = GESTURE_SLOT_FLINCH
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local HITGROUP_HEAD = HITGROUP_HEAD
local HITGROUP_CHEST = HITGROUP_CHEST
local HITGROUP_STOMACH = HITGROUP_STOMACH
local HITGROUP_LEFTLEG = HITGROUP_LEFTLEG
local HITGROUP_RIGHTLEG = HITGROUP_RIGHTLEG
local HITGROUP_LEFTARM = HITGROUP_LEFTARM
local HITGROUP_RIGHTARM = HITGROUP_RIGHTARM
local TEAM_UNDEAD = TEAM_UNDEAD
local TEAM_SPECTATOR = TEAM_SPECTATOR
local TEAM_HUMAN = TEAM_HUMAN
local IN_ZOOM = IN_ZOOM
local MASK_SOLID = MASK_SOLID
local MASK_SOLID_BRUSHONLY = MASK_SOLID_BRUSHONLY
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull

local getmetatable = getmetatable

local M_Entity = FindMetaTable("Entity")

local P_Team = meta.Team

local E_IsValid = M_Entity.IsValid
local E_GetDTBool = M_Entity.GetDTBool
local E_GetTable = M_Entity.GetTable

---Grabs players steam ID and user name
function meta:LogID()
	return "<"..self:SteamID().."> "..self:Name()
end

---Grabs max zombie health or max health, use over GetMaxHealth
function meta:GetMaxHealthEx()
	if P_Team(self) == TEAM_UNDEAD then
		return self:GetMaxZombieHealth()
	end

	return self:GetMaxHealth()
end

---Dismember a body part
---@param dismembermenttype number
function meta:Dismember(dismembermenttype)
	local effectdata = EffectData()
		effectdata:SetOrigin(self:EyePos())
		effectdata:SetEntity(self)
		effectdata:SetScale(dismembermenttype)
	util.Effect("dismemberment", effectdata, true, true)
end

---Random custom anim event
---@param event
---@param maxrandom_s1 number
function meta:DoRandomEvent(event, maxrandom_s1)
	self:DoCustomAnimEvent(event, math.ceil(util_SharedRandom("anim", 0, maxrandom_s1, self:EntIndex())))
end

---Attack event for zombies
function meta:DoZombieEvent()
	self:DoRandomEvent(PLAYERANIMEVENT_ATTACK_PRIMARY, 7)
end

---Flinch event
---@param hitgroup number
function meta:DoFlinchEvent(hitgroup)
	local base = util_SharedRandom("flinch", 1, self:EntIndex())
	if hitgroup == HITGROUP_HEAD then
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base * 2 + 4)
	elseif hitgroup == HITGROUP_CHEST  then
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base * 2 + 1)
	elseif hitgroup == HITGROUP_STOMACH then
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base * 2 + 10)
	elseif hitgroup == HITGROUP_LEFTARM then
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base + 8)
	elseif hitgroup == HITGROUP_RIGHTARM then
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base + 9)
	elseif hitgroup == HITGROUP_LEFTLEG then
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base + 6)
	elseif hitgroup == HITGROUP_RIGHTLEG then
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base + 7)
	elseif hitgroup == HITGROUP_BELT then
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base + 3)
	else
		self:DoCustomAnimEvent(PLAYERANIMEVENT_FLINCH_HEAD, base * 2)
	end
end

---Random flinch event
function meta:DoRandomFlinchEvent()
	self:DoRandomEvent(PLAYERANIMEVENT_FLINCH_HEAD, 12)
end

local FlinchSequences = {
	"flinch_01",
	"flinch_02",
	"flinch_back_01",
	"flinch_head_01",
	"flinch_head_02",
	"flinch_phys_01",
	"flinch_phys_02",
	"flinch_shoulder_l",
	"flinch_shoulder_r",
	"flinch_stomach_01",
	"flinch_stomach_02",
}

---Flinch anim
---@param data number
function meta:DoFlinchAnim(data)
	local seq = FlinchSequences[data] or FlinchSequences[1]
	if seq then
		local seqid = self:LookupSequence(seq)
		if seqid > 0 then
			self:AddVCDSequenceToGestureSlot(GESTURE_SLOT_FLINCH, seqid, 0, true)
		end
	end
end

local ZombieAttackSequences = {
	"zombie_attack_01",
	"zombie_attack_02",
	"zombie_attack_03",
	"zombie_attack_04",
	"zombie_attack_05",
	"zombie_attack_06"
}

---Zombie attack anim
---@param data number
function meta:DoZombieAttackAnim(data)
	local seq = ZombieAttackSequences[data] or ZombieAttackSequences[1]
	if seq then
		local seqid = self:LookupSequence(seq)
		if seqid > 0 then
			self:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, seqid, 0, true)
		end
	end
end

---Player is Spectator
function meta:IsSpectator()
	return E_IsValid(self) and P_Team(self) == TEAM_SPECTATOR
end

---Zombie aura range
function meta:GetAuraRange()
	if GAMEMODE.ZombieEscape then
		return 8192
	end

	local wep = self:GetWeapon()
	return wep.GetAuraRange and wep:GetAuraRange() or 2048
end

---Zombie aura range squared
function meta:GetAuraRangeSqr()
	local r = self:GetAuraRange()
	return r * r
end

---Get poison damage
function meta:GetPoisonDamage()
	return self.Poison and self.Poison:IsValid() and self.Poison:GetDamage() or 0
end

---Get bleed damage
function meta:GetBleedDamage()
	return self.Bleed and self.Bleed:IsValid() and self.Bleed:GetDamage() or 0
end

---Weapon function (reload etc)
function meta:CallWeaponFunction(funcname, ...)
	local wep = self:GetActiveWeapon()
	if wep:IsValid() and wep[funcname] then
		return wep[funcname](wep, self, ...)
	end
end

---Capped name size
function meta:ClippedName()
	local name = self:Name()
	if #name > 16 then
		name = string.sub(name, 1, 14)..".."
	end

	return name
end

---Get teleport destination
---@param not_from_sigil boolean
---@param corrupted boolean
function meta:SigilTeleportDestination(not_from_sigil, corrupted)
	local sigils = corrupted and GAMEMODE:GetCorruptedSigils() or GAMEMODE:GetUncorruptedSigils()

	local s_len = #sigils
	if s_len <= 1 then return end

	local mypos = self:GetPos()
	local eyevector = self:GetAimVector()

	local dist = 999999999999
	local spos, d, icurrent, target, itarget

	local sigil
	if not not_from_sigil then
		for i=1, s_len do
			sigil = sigils[i]
			d = sigil:GetPos():DistToSqr(mypos)
			if d < dist then
				dist = d
				icurrent = i
			end
		end
	end

	dist = -1
	for i=1, s_len do
		if i == icurrent then continue end

		sigil = sigils[i]
		spos = sigil:GetPos() - mypos
		spos:Normalize()
		d = spos:Dot(eyevector)
		if d > dist then
			dist = d
			target = sigil
			itarget = i
		end
	end

	return target, itarget
end

---Alternate use
function meta:DispatchAltUse()
	local tpexist = self:GetStatus("sigilteleport")
	if tpexist and tpexist:IsValid() then
		self:RemoveStatus("sigilteleport", false, true)
		return
	end

	local tr = self:CompensatedMeleeTrace(64, 4, nil, nil, nil, true)
	local ent = tr.Entity
	if ent and ent:IsValid() and ent.AltUse then
		return ent:AltUse(self, tr)
	end
end

---View punch based on damage dealt
---@param damage number
function meta:MeleeViewPunch(damage)
	local maxpunch = (damage + 25) * 0.5
	local minpunch = -maxpunch
	self:ViewPunch(Angle(math.Rand(minpunch, maxpunch), math.Rand(minpunch, maxpunch), math.Rand(minpunch, maxpunch)))
end

---Range check for arsenal crate
function meta:NearArsenalCrate()
	local pos = self:EyePos()

	if self.ArsenalZone and self.ArsenalZone:IsValid() then return true end

	local arseents = {}
	table.Add(arseents, ents.FindByClass("prop_arsenalcrate"))
	table.Add(arseents, ents.FindByClass("status_arsenalpack"))
	local a_len = #arseents
	local ent
	for i=1, a_len do
		ent = arseents[i]
		local nearest = ent:NearestPoint(pos)
		if pos:DistToSqr(nearest) <= 10000 and (WorldVisible(pos, nearest) or self:TraceLine(100).Entity == ent) then -- 80^2
			return true
		end
	end

	return false
end
meta.IsNearArsenalCrate = meta.NearArsenalCrate

---Range check for remantler
function meta:NearRemantler()
	local pos = self:EyePos()

	local remantlers = ents.FindByClass("prop_remantler")
	local r_len = #remantlers
	local ent
	for i=1, r_len do
		ent = remantlers[i]
		local nearest = ent:NearestPoint(pos)
		if pos:DistToSqr(nearest) <= 10000 and (WorldVisible(pos, nearest) or self:TraceLine(100).Entity == ent) then -- 80^2
			return true
		end
	end

	return false
end

---Get resupply ammo type based on weapon held
function meta:GetResupplyAmmoType()
	local ammotype
	if not self.ResupplyChoice then
		local wep = self:GetWeapon()
		ammotype = wep.GetResupplyAmmoType and wep:GetResupplyAmmoType() or wep.ResupplyAmmoType or wep:GetPrimaryAmmoTypeString()
	end

	ammotype = ammotype and ammotype:lower() or self.ResupplyChoice

	if not ammotype or not GAMEMODE.AmmoResupply[ammotype] then
		return "scrap"
	end

	return ammotype
end

---Force zombie class to this
function meta:SetZombieClassName(classname)
	if GAMEMODE.ZombieClasses[classname] then
		self:SetZombieClass(GAMEMODE.ZombieClasses[classname].Index)
	end
end

---Get points
function meta:GetPoints()
	return self:GetDTInt(1)
end

---Get blood armor
function meta:GetBloodArmor()
	return self:GetDTInt(DT_PLAYER_INT_BLOODARMOR)
end

---Add leg slow
---@param damage number
function meta:AddLegDamage(damage)
	if self.SpawnProtection then return end

	local legdmg = self:GetLegDamage() + damage

	if self:GetFlatLegDamage() - damage * 0.25 > damage then
		legdmg = self:GetFlatLegDamage()
	end

	self:SetLegDamage(legdmg)
end

---Advanced leg slow function, generally preferable to AddLegDamage
---@param damage number
---@param attacker entity
---@param inflictor entity
---@param type number
function meta:AddLegDamageExt(damage, attacker, inflictor, type)
	inflictor = inflictor or attacker

	if type == SLOWTYPE_PULSE then
		local legdmg = damage * (attacker.PulseWeaponSlowMul or 1)
		local startleg = self:GetFlatLegDamage()

		self:AddLegDamage(legdmg)
		if attacker.PulseImpedance then
			self:AddArmDamage(legdmg)
		end

		if SERVER and attacker:HasTrinket("resonance") then
			attacker.AccuPulse = (attacker.AccuPulse or 0) + (self:GetFlatLegDamage() - startleg)

			if attacker.AccuPulse > 80 then
				self:PulseResonance(attacker, inflictor)
			end
		end
	elseif type == SLOWTYPE_COLD then
		if self:IsValidLivingZombie() and self:GetZombieClassTable().ResistFrost then return end

		self:AddLegDamage(damage)
		self:AddArmDamage(damage)

		if SERVER and attacker:HasTrinket("cryoindu") then
			self:CryogenicInduction(attacker, inflictor, damage)
		end
	end
end

---Force set leg damage
---@param damage number
function meta:SetLegDamage(damage)
	self.LegDamage = CurTime() + math.min(GAMEMODE.MaxLegDamage, damage * 0.125)
	if SERVER then
		self:UpdateLegDamage()
	end
end

---Force set leg damage based on time
---@param time number
function meta:RawSetLegDamage(time)
	self.LegDamage = math.min(CurTime() + GAMEMODE.MaxLegDamage, time)
	if SERVER then
		self:UpdateLegDamage()
	end
end

---Cap leg damage based on time
---@param time number
function meta:RawCapLegDamage(time)
	self:RawSetLegDamage(math.max(self.LegDamage or 0, time))
end

---Get leg damage
function meta:GetLegDamage()
	return math.max(0, (self.LegDamage or 0) - CurTime())
end

---Get flat leg damage value
function meta:GetFlatLegDamage()
	return math.max(0, ((self.LegDamage or 0) - CurTime()) * 8)
end

---Add arm damage
---@param damage number
function meta:AddArmDamage(damage)
	if self.SpawnProtection then return end

	local armdmg = self:GetArmDamage() + damage

	if self:GetFlatArmDamage() - damage * 0.25 > damage  then
		armdmg = self:GetFlatArmDamage()
	end

	self:SetArmDamage(armdmg)
end

---Set arm damage
---@param damage number
function meta:SetArmDamage(damage)
	self.ArmDamage = CurTime() + math.min(GAMEMODE.MaxArmDamage, damage * 0.125)
	if SERVER then
		self:UpdateArmDamage()
	end
end

---Set arm damage based on time
---@param time number
function meta:RawSetArmDamage(time)
	self.ArmDamage = math.min(CurTime() + GAMEMODE.MaxArmDamage, time)
	if SERVER then
		self:UpdateArmDamage()
	end
end

---Cap arm damage
---@param time number
function meta:RawCapArmDamage(time)
	self:RawSetArmDamage(math.max(self.ArmDamage or 0, time))
end

---Get arm damage
function meta:GetArmDamage()
	return math.max(0, (self.ArmDamage or 0) - CurTime())
end

---Get flat arm damage
function meta:GetFlatArmDamage()
	return math.max(0, ((self.ArmDamage or 0) - CurTime()) * 8)
end

---Flinch
function meta:Flinch()
	if CurTime() >= (self.NextFlinch or 0) then
		self.NextFlinch = CurTime() + 0.75

		if P_Team(self) == TEAM_UNDEAD then
			self:DoFlinchEvent(self:LastHitGroup())
		else
			self:DoRandomFlinchEvent()
		end
	end
end

---Get player zombie class
function meta:GetZombieClass()
	return self.Class or GAMEMODE.DefaultZombieClass
end

local ZombieClasses = {}
if GAMEMODE then
	ZombieClasses = GAMEMODE.ZombieClasses
end
hook.Add("Initialize", "LocalizeZombieClasses", function() ZombieClasses = GAMEMODE.ZombieClasses end)

---Get player zombie class table
function meta:GetZombieClassTable()
	return ZombieClasses[self:GetZombieClass()]
end


local zctab
local zcfunc
---Calls zombie class functions (like OnKilled or ProcessDamage)
---@param func_name string
function meta:CallZombieFunction(func_name, ...)
	if self:IsZombie() then
		zctab = ZombieClasses[E_GetTable(self).Class or GAMEMODE.DefaultZombieClass]
		zcfunc = zctab[func_name]
		if zcfunc then
			return zcfunc(zctab, self, ...)
		end
	end
end

---Fires a traceline from the defined starting position or players firing position
---@param distance number
---@param mask number
---@param filter function
---@param start vector
function meta:TraceLine(distance, mask, filter, start)
	start = start or self:GetShootPos()
	return util_TraceLine({start = start, endpos = start + self:GetAimVector() * distance, filter = filter or self, mask = mask})
end

---Fires a tracehull from the defined starting position or players firing position
---@param distance number
---@param mask number
---@param size number
---@param filter function
---@param start vector
function meta:TraceHull(distance, mask, size, filter, start)
	start = start or self:GetShootPos()
	return util_TraceHull({start = start, endpos = start + self:GetAimVector() * distance, filter = filter or self, mask = mask, mins = Vector(-size, -size, -size), maxs = Vector(size, size, size)})
end

--- Adjusts player speed statically
---@param speed number
function meta:SetSpeed(speed)
	if not speed then speed = 200 end

	local run_speed = self:GetBloodArmor() > 0 and self:IsSkillActive(SKILL_CARDIOTONIC) and speed + 40 or speed

	self:SetWalkSpeed(speed)
	self:SetRunSpeed(run_speed)
	self:SetMaxSpeed(run_speed)
end

--- Adjusts individual human speed statically
---@param speed number
function meta:SetHumanSpeed(speed)
	if P_Team(self) == TEAM_HUMAN then self:SetSpeed(speed) end
end

--- Gets a valid player weapon, use over GetActiveWeapon
function meta:GetWeapon()
	local wep = self:GetActiveWeapon()
	return E_IsValid(wep) and wep or NULL
end

--- Is a valid human
function meta:IsHuman()
	return E_IsValid(self) and P_Team(self) == TEAM_HUMAN
end

--- Is a valid living human
function meta:IsLivingHuman()
	return self:IsHuman() and self:Alive()
end

--- Is a valid zombie
function meta:IsZombie()
	return E_IsValid(self) and P_Team(self) == TEAM_UNDEAD
end

---Is a valid living zombie
function meta:IsLivingZombie()
	return self:IsZombie() and self:Alive()
end

--- Resets player speed to default
---@param noset boolean
---@param health number
function meta:ResetSpeed(noset, health)
	if not E_IsValid(self) then return end

	if self:IsZombie() then
		local speed = math.max(140, self:GetZombieClassTable().Speed * GAMEMODE.ZombieSpeedMultiplier - (GAMEMODE.ObjectiveMap and 20 or 0))

		self:SetSpeed(speed)
		return speed
	end

	local wep = self:GetWeapon()
	local speed

	if wep.GetWalkSpeed then
		speed = wep:GetWalkSpeed()
	end

	if not speed then
		speed = wep.WalkSpeed or SPEED_NORMAL
	end

	if speed < SPEED_NORMAL then
		speed = SPEED_NORMAL - (SPEED_NORMAL - speed) * (self.WeaponWeightSlowMul or 1)
	end

	if self.SkillSpeedAdd and P_Team(self) == TEAM_HUMAN then
		speed = speed + self.SkillSpeedAdd
	end

	if self:IsSkillActive(SKILL_LIGHTWEIGHT) and wep.IsMelee then
		speed = speed + 6
	end

	speed = math.max(1, speed)

	if 32 < speed and not GAMEMODE.ZombieEscape then
		health = health or self:Health()
		local maxhealth = self:GetMaxHealth() * 0.6666
		if health < maxhealth then
			speed = math.max(88, speed - speed * 0.4 * (1 - health / maxhealth) * (self.LowHealthSlowMul or 1))
		end
	end

	if not noset then
		self:SetSpeed(speed)
	end

	return speed
end

--- Resets a players jump power
---@param noset boolean
function meta:ResetJumpPower(noset)
	local power = DEFAULT_JUMP_POWER

	if self:IsZombie() then
		power = self:CallZombieFunction("GetJumpPower") or power

		local classtab = self:GetZombieClassTable()
		if classtab and classtab.JumpPower then
			power = classtab.JumpPower
		end
	else
		power = power * (self.JumpPowerMul or 1)

		if self:GetBarricadeGhosting() then
			power = power * 0.25
			if not noset then
				self:SetJumpPower(power)
			end

			return power
		end
	end

	local wep = self:GetWeapon()
	if wep.ResetJumpPower then
		power = wep:ResetJumpPower(power) or power
	end

	if not noset then
		self:SetJumpPower(power)
	end

	return power
end

---Set barricade ghosting
---@param b boolean
---@param fullspeed boolean
function meta:SetBarricadeGhosting(b, fullspeed)
	if self == NULL then return end --???

	if b and self.NoGhosting and not self:GetBarricadeGhosting() then
		self:SetDTFloat(DT_PLAYER_FLOAT_WIDELOAD, CurTime() + 6)
	end

	if fullspeed == nil then fullspeed = false end

	self:SetDTBool(0, b)
	self:SetDTBool(1, b and fullspeed)
	--self:SetCustomCollisionCheck(b)
	self:CollisionRulesChanged()

	self:ResetJumpPower()
end

---Get barricade ghosting
function meta:GetBarricadeGhosting()
	return E_GetDTBool(self, 0)
end
meta.IsBarricadeGhosting = meta.GetBarricadeGhosting

---Check if you can ghost with it
---@param ent entity
function meta:ShouldBarricadeGhostWith(ent)
	return ent:IsBarricadeProp()
end

---Barricade ghost think
function meta:BarricadeGhostingThink()
	if E_GetDTBool(self, 1) then
		if not self:ActiveBarricadeGhosting() then
			self:SetBarricadeGhosting(false)
		end
	else
		if self:KeyDown(IN_ZOOM) or self:ActiveBarricadeGhosting() then
			if self.FirstGhostThink then
				self:SetLocalVelocity(vector_origin)
				self.FirstGhostThink = false
			end

			return
		end

		self.FirstGhostThink = true
		self:SetBarricadeGhosting(false)
	end
end

-- Needs to be as optimized as possible.

---Check collisions
---@param ent entity
function meta:ShouldNotCollide(ent)
	if E_IsValid(ent) then
		if getmetatable(ent) == meta then
			if P_Team(self) == P_Team(ent) or E_GetTable(self).NoCollideAll or E_GetTable(ent).NoCollideAll then
				return true
			end

			return false
		end

		return E_GetDTBool(self, 0) and ent:IsBarricadeProp()
	end

	return false
end

meta.OldSetHealth = FindMetaTable("Entity").SetHealth
---Set player health to this value
---@param health number
function meta:SetHealth(health)
	self:OldSetHealth(health)
	if P_Team(self) == TEAM_HUMAN and 1 <= health then
		self:ResetSpeed(nil, health)
	end
end

---Is player headcrab
function meta:IsHeadcrab()
	return self:IsZombie() and GAMEMODE.ZombieClasses[self:GetZombieClass()].IsHeadcrab
end

---Is player crawler
function meta:IsTorso()
	return self:IsZombie() and GAMEMODE.ZombieClasses[self:GetZombieClass()].IsTorso
end

---Stop velocity effectively
function meta:AirBrake()
	local vel = self:GetVelocity()

	vel.x = vel.x * 0.15
	vel.y = vel.y * 0.15
	if vel.z > 0 then
		vel.z = vel.z * 0.15
	end

	self:SetLocalVelocity(vel)
end

local temp_attacker = NULL
local temp_attacker_team = -1
local temp_pen_ents = {}
local temp_override_team

local function MeleeTraceFilter(ent)
	if ent == temp_attacker
	or E_GetTable(ent).IgnoreMelee
	or getmetatable(ent) == meta and P_Team(ent) == temp_attacker_team
	or not temp_override_team and ent.IgnoreMeleeTeam and ent.IgnoreMeleeTeam == temp_attacker_team
	or temp_pen_ents[ent] then
		return false
	end

	return true
end

local function DynamicTraceFilter(ent)
	if ent.IgnoreTraces or ent:IsPlayer() then
		return false
	end

	return true
end

local function MeleeTraceFilterFFA(ent)
	if temp_pen_ents[ent] then
		return false
	end

	return ent ~= temp_attacker
end

local melee_trace = {filter = MeleeTraceFilter, mask = MASK_SOLID, mins = Vector(), maxs = Vector()}

function meta:GetDynamicTraceFilter()
	return DynamicTraceFilter
end

---Fake hitbox
local function CheckFHB(tr)
	if E_IsValid(tr.Entity) and tr.Entity.FHB then
		tr.Entity = tr.Entity:GetParent()
	end
end

---Melee trace
function meta:MeleeTrace(distance, size, start, dir, hit_team_members, override_team, override_mask)
	start = start or self:GetShootPos()
	dir = dir or self:GetAimVector()
	hit_team_members = hit_team_members or GAMEMODE.RoundEnded

	local tr

	temp_attacker = self
	temp_attacker_team = P_Team(self)
	temp_override_team = override_team
	melee_trace.start = start
	melee_trace.endpos = start + dir * distance
	melee_trace.mask = override_mask or MASK_SOLID
	melee_trace.mins.x = -size
	melee_trace.mins.y = -size
	melee_trace.mins.z = -size
	melee_trace.maxs.x = size
	melee_trace.maxs.y = size
	melee_trace.maxs.z = size
	melee_trace.filter = hit_team_members and MeleeTraceFilterFFA or MeleeTraceFilter

	tr = util_TraceLine(melee_trace)

	CheckFHB(tr)

	if tr.Hit then
		return tr
	end

	return util_TraceHull(melee_trace)
end

---Anti lag
local function InvalidateCompensatedTrace(tr, start, distance)
	-- Need to do this or people with 300 ping will be hitting people across rooms
	if tr.Entity:IsValid() and tr.Entity:IsPlayer() and tr.HitPos:DistToSqr(start) > distance * distance + 144 then -- Give just a little bit of leeway
		tr.Hit = false
		tr.HitNonWorld = false
		tr.Entity = NULL
	end
end

---Compensated hit trace
function meta:CompensatedMeleeTrace(distance, size, start, dir, hit_team_members, override_team)
	start = start or self:GetShootPos()
	dir = dir or self:GetAimVector()

	self:LagCompensation(true)
	local tr = self:MeleeTrace(distance, size, start, dir, hit_team_members, override_team)
	CheckFHB(tr)
	self:LagCompensation(false)

	InvalidateCompensatedTrace(tr, start, distance)

	return tr
end

---Compensated penetrating hit trace
function meta:CompensatedPenetratingMeleeTrace(distance, size, start, dir, hit_team_members, num_traces)
	start = start or self:GetShootPos()
	dir = dir or self:GetAimVector()

	self:LagCompensation(true)
	local t = self:PenetratingMeleeTrace(distance, size, start, dir, hit_team_members, num_traces)
	self:LagCompensation(false)

	local tr
	local tlen = #t
	for i=1, tlen do
		tr = t[i]
		InvalidateCompensatedTrace(tr, start, distance)
	end

	return t
end

---Zombie melee trace
function meta:CompensatedZombieMeleeTrace(distance, size, start, dir, hit_team_members, num_traces)
	start = start or self:GetShootPos()
	dir = dir or self:GetAimVector()

	self:LagCompensation(true)
	local hit_entities = {}

	local t, hitprop = self:PenetratingMeleeTrace(distance, size, start, dir, hit_team_members, num_traces)
	local t_legs = self:PenetratingMeleeTrace(distance, size, self:WorldSpaceCenter(), dir, hit_team_members, num_traces)
	local tr
	local tlen = #t

	for i=1, tlen do
		tr = t[i]
		hit_entities[tr.Entity] = true
	end

	if not hitprop then
		tlen = #t_legs
		for i=1, tlen do
			tr = t_legs[i]
			if not hit_entities[tr.Entity] then
				t[#t + 1] = tr
			end
		end
	end
	self:LagCompensation(false)

	tlen = #t
	for i=1, tlen do
		tr = t[i]
		InvalidateCompensatedTrace(tr, tr.StartPos, distance)
	end

	return t
end

---Penetrating melee trace
function meta:PenetratingMeleeTrace(distance, size, start, dir, hit_team_members, num_traces)
	start = start or self:GetShootPos()
	dir = dir or self:GetAimVector()
	hit_team_members = hit_team_members or GAMEMODE.RoundEnded
	num_traces = num_traces or 16

	local tr, ent

	temp_attacker = self
	temp_attacker_team = P_Team(self)
	temp_pen_ents = {}
	melee_trace.start = start
	melee_trace.endpos = start + dir * distance
	melee_trace.mask = MASK_SOLID
	melee_trace.mins.x = -size
	melee_trace.mins.y = -size
	melee_trace.mins.z = -size
	melee_trace.maxs.x = size
	melee_trace.maxs.y = size
	melee_trace.maxs.z = size
	melee_trace.filter = hit_team_members and MeleeTraceFilterFFA or MeleeTraceFilter

	local t = {}
	local onlyhitworld
	local trace_num
	for i=1, num_traces do
		tr = util_TraceLine(melee_trace)

		if not tr.Hit then tr = util_TraceHull(melee_trace) end
		if not tr.Hit then break end

		trace_num = #t + 1
		if tr.HitWorld then
			t[trace_num] = tr
			onlyhitworld = true
			break
		end

		CheckFHB(tr)

		ent = tr.Entity
		if not ent:IsValid() then continue end
		if not ent:IsPlayer() then
			melee_trace.mask = MASK_SOLID_BRUSHONLY
			onlyhitworld = true
			break
		end

		t[trace_num] = tr
		temp_pen_ents[ent] = true
	end

	temp_pen_ents = {}

	return t, onlyhitworld
end

---Should I be ghosted?
function meta:ActiveBarricadeGhosting(override)
	if P_Team(self) ~= TEAM_HUMAN and not override or not self:GetBarricadeGhosting() then return false end

	local min, max = self:WorldSpaceAABB()
	min.x = min.x + 1
	min.y = min.y + 1

	max.x = max.x - 1
	max.y = max.y - 1

	local ent
	local find_func = ents.FindInBox(min, max)
	local len = #find_func
	for i=1, len do
		ent = find_func[i]
		if E_IsValid(ent) and self:ShouldBarricadeGhostWith(ent) then return true end
	end

	return false
end

function meta:IsHolding()
	return self:GetHolding():IsValid()
end
meta.IsCarrying = meta.IsHolding

function meta:GetHolding()
	local status = self.status_human_holding
	if status and status:IsValid() then
		local obj = status:GetObject()
		if obj:IsValid() then return obj end
	end

	return NULL
end

function meta:NearestRemantler()
	local pos = self:EyePos()

	local remantlers = ents.FindByClass("prop_remantler")
	local min, remantler = 99999

	local r_len = #remantlers
	local ent
	for i=1, r_len do
		ent = remantlers[i]
		local nearpoint = ent:NearestPoint(pos)
		local trmatch = self:TraceLine(100).Entity == ent
		local dist = trmatch and 0 or pos:DistToSqr(nearpoint)
		if pos:DistToSqr(nearpoint) <= 10000 and dist < min then
			remantler = ent
			break
		end
	end

	return remantler
end

function meta:GetMaxZombieHealth()
	return self:GetZombieClassTable().Health
end

local oldmaxhealth = FindMetaTable("Entity").GetMaxHealth
function meta:GetMaxHealth()
	if P_Team(self) == TEAM_UNDEAD then
		return self:GetMaxZombieHealth()
	end

	return oldmaxhealth(self)
end

if not meta.OldAlive then
	meta.OldAlive = meta.Alive
	function meta:Alive()
		return self:GetObserverMode() == OBS_MODE_NONE and not self.NeverAlive and self:OldAlive()
	end
end

-- Override these because they're different in 1st person and on the server.
function meta:SyncAngles()
	local ang = self:EyeAngles()
	ang.pitch = 0
	ang.roll = 0
	return ang
end
meta.GetAngles = meta.SyncAngles

function meta:GetForward()
	return self:SyncAngles():Forward()
end

function meta:GetUp()
	return self:SyncAngles():Up()
end

function meta:GetRight()
	return self:SyncAngles():Right()
end

function meta:GetZombieMeleeSpeedMul()
	return 1 * (1 + math.Clamp(self:GetArmDamage() / GAMEMODE.MaxArmDamage, 0, 1)) / (self:GetStatus("zombie_battlecry") and 1.2 or 1)
end

function meta:GetMeleeSpeedMul()
	if P_Team(self) == TEAM_UNDEAD then
		return self:GetZombieMeleeSpeedMul()
	end

	return 1 * (1 + math.Clamp(self:GetArmDamage() / GAMEMODE.MaxArmDamage, 0, 1)) / (self:GetStatus("frost") and 0.7 or 1)
end

function meta:GetPhantomHealth()
	return self:GetDTFloat(DT_PLAYER_FLOAT_PHANTOMHEALTH)
end
