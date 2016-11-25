--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
]]

local ADDON_NAME, addon = ...

-- ----------------------------------------------------

local _spells = {
	ByID = {},
	ByClass = {},
}

for k, v in pairs( RAID_CLASS_COLORS ) do
	_spells.ByClass[k] = {}
end

-- ----------------------------------------------------

local function RegisterSpell( classID, spellID, counterDuration, defaultCooldown, ignore, specIDs )
	local spellInfo = {
		["Class"] = classID,
		["ID"] = spellID,
		["CounterDuration"] = counterDuration,
		["DefaultCooldown"] = defaultCooldown,
		["Ignore"] = ignore or false,
		["SpecIDs"] = specIDs or false,
	}

	_spells.ByID[spellID] = spellInfo
	_spells.ByClass[classID][spellID] = spellInfo
end

RegisterSpell( "DEATHKNIGHT",  47528, 4,  15, false ) -- Mindfreeze
RegisterSpell( "DEATHKNIGHT",  47476, 3, 120,  true, { 250 } ) -- Strangulate (Blood/Honor)

RegisterSpell( "DEMONHUNTER", 183752, 3,  15, false ) -- Consume Magic

RegisterSpell(       "DRUID", 106839, 4,  15, false, { 103, 104 } ) -- Skull Bash (Feral/Guardian)
RegisterSpell(       "DRUID",  78675, 5,  60,  true, { 102 } ) -- Solar Beam (Balance)
RegisterSpell(       "DRUID",  93985, 4,  15,  true, {} ) -- Skull Bash (Effect ID?)
RegisterSpell(       "DRUID", 221514, 4,  15,  true, {} ) -- Skull Bash (Effect ID?)

RegisterSpell(      "HUNTER", 147362, 3,  24, false ) -- Counter Shot

RegisterSpell(        "MAGE",   2139, 6,  24, false ) -- Counterspell

RegisterSpell(       "ROGUE",   1766, 5,  15, false ) -- Kick

RegisterSpell(     "PALADIN",  96231, 4,  15, false, { 66, 70 } ) -- Rebuke (Protection/Retribution)
RegisterSpell(     "PALADIN",  31935, 3,  15, false, { 65 } ) -- Avenger's Shield (Protection)

RegisterSpell(      "PRIEST",  15487, 3,  45,  true, { 258 } ) -- Silence (Shadow)

RegisterSpell(        "MONK", 116705, 4,  15, false ) -- Spear Hand Strike

RegisterSpell(      "SHAMAN",  57994, 3,  12, false ) -- Wind Shear

RegisterSpell(     "WARLOCK",  19647, 6,  24,  true ) -- Spell Lock (Felhunter)
RegisterSpell(     "WARLOCK", 115781, 6,  24,  true ) -- Optical Blast (Observer)

RegisterSpell(     "WARRIOR",   6552, 4,  15, false ) -- Pummel

-- ----------------------------------------------------

addon.Spells = {}

function addon.Spells:GetSpellByID( spellID )
	return _spells.ByID[spellID]
end

function addon.Spells:GetSpellsForClass( classID )
	return _spells.ByClass[classID]
end

local function contains( t, value )
	if ( value == nil ) then
		return false end

	for _, v in next, t do
		if ( v == value ) then
			return true end
	end

	return false
end

function addon.Spells:GetPrimarySpell( classID, specID )
	for k, spell in pairs( _spells.ByClass[classID] ) do
		if ( not spell.Ignore ) then
			if ( specID and spell.SpecIDs ) then
				if ( contains( spell.SpecIDs, specID ) ) then
					return spell end
			elseif ( not spell.SpecIDs ) then
				return spell
			end
		end
	end
end

function addon.Spells:GetSpells()
	return _spells
end