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

local function RegisterSpell( classID, spellID, counterDuration, defaultCooldown, isTalent, isPet, ignore )
	local spellInfo = {
		["Class"] = classID, 
		["ID"] = spellID,
		["CounterDuration"] = counterDuration, 
		["DefaultCooldown"] = defaultCooldown, 
		["IsTalent"] = isTalent or false, 
		["Ignore"] = ignore or false,
	}

	_spells.ByID[spellID] = spellInfo
	_spells.ByClass[classID][spellID] = spellInfo
end

RegisterSpell( "DEATHKNIGHT",  47528, 4,  15, false ) -- Mindfreeze
RegisterSpell( "DEATHKNIGHT",  47476, 3, 120, false, true ) -- Strangulate (Blood/Honor)
RegisterSpell( "DEMONHUNTER", 183752, 3,  15, false ) -- Consume Magic
RegisterSpell(       "DRUID", 106839, 4,  15,  true ) -- Skull Bash (Feral/Guardian)
RegisterSpell(       "DRUID", 147362, 5,  60,  true, true ) -- Solar Beam (Balance)
RegisterSpell(      "HUNTER",  78675, 3,  24, false ) -- Counter Shot
RegisterSpell(        "MAGE",   2139, 6,  24, false ) -- Counterspell
RegisterSpell(       "ROGUE",   1766, 5,  15, false ) -- Kick
RegisterSpell(     "PALADIN",  96231, 4,  15,  true ) -- Rebuke (Protection/Retribution)
RegisterSpell(     "PALADIN",  31935, 3,  15,  true ) -- Avenger's Shield (Protection)
RegisterSpell(      "PRIEST",  15487, 3,  45,  true, true ) -- Silence (Shadow)
RegisterSpell(        "MONK", 116705, 4,  15, false ) -- Spear Hand Strike
RegisterSpell(      "SHAMAN",  57994, 3,  12, false ) -- Wind Shear
RegisterSpell(     "WARLOCK",  19647, 6,  24, false, true ) -- Spell Lock (Felhunter)
RegisterSpell(     "WARLOCK", 115781, 6,  24, false, true ) -- Optical Blast (Observer)
RegisterSpell(     "WARRIOR",   6552, 4,  15, false ) -- Pummel

-- ----------------------------------------------------

addon.Spells = {}

function addon.Spells:GetSpellByID( spellID )
	return _spells.ByID[spellID]
end

function addon.Spells:GetSpellsForClass( classID )
	return _spells.ByClass[classID]
end

function addon.Spells:GetPrimarySpell( classID )
	for k, spell in pairs( _spells.ByClass[classID] ) do
		if ( ( not spell.Ignore ) and ( not spell.IsTalent ) ) then
			return spell 
		end
	end
end

function addon.Spells:GetSpells()
	return _spells
end

function addon.Spells:GetPlayerPrimarySpell()
	local _, classID, _ = UnitClass( "player" ); 
	local spells = _spells.ByClass[classID]
	for k, v in pairs( spells ) do
		if ( ( not spell.Ignore ) and IsSpellKnown( spell.ID ) ) then
			local _, cooldown, _ = GetSpellCooldown( spellID )
			return spell, cooldown
		end
	end
end