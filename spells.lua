local ADDON_NAME, internal = ...

-- ----------------------------------------------------

internal.SpellDB = {
	-- WARRIOR
	[6552] = { -- Pummel
		["Class"] = "WARRIOR", 
		["CounterDuration"] = 4, 
		["DefaultCooldown"] = 15, 
		["Talent"] = false, 
		["Pet"] = false,
	}, 
	-- PALADIN
	[96231] = { -- Rebuke (Protection/Retribution)
		["Class"] = "PALADIN", 
		["CounterDuration"] = 4, 
		["DefaultCooldown"] = 15, 
		["Talent"] = true, 
		["Pet"] = false,
	}, 
	[31935] = { -- Avenger's Shield (Protection)
		["Class"] = "PALADIN", 
		["CounterDuration"] = 3, 
		["DefaultCooldown"] = 15, 
		["Talent"] = true, 
		["Pet"] = false,
	}, 
	-- HUNTER
	[147362] = { -- Counter Shot
		["Class"] = "HUNTER", 
		["CounterDuration"] = 3, 
		["DefaultCooldown"] = 24, 
		["Talent"] = false, 
		["Pet"] = false,
	}, 
	-- ROGUE
	[1766] = { -- Kick
		["Class"] = "ROGUE", 
		["CounterDuration"] = 5, 
		["DefaultCooldown"] = 15, 
		["Talent"] = false, 
		["Pet"] = false,
	}, 
	-- PRIEST
	[15487] = { -- Silence (Shadow)
		["Class"] = "PRIEST", 
		["CounterDuration"] = 3, 
		["DefaultCooldown"] = 45, 
		["Talent"] = true, 
		["Pet"] = false,
		["Ignore"] = true, 
	}, 
	-- DEATHKNIGHT
	[47528] = { -- Mindfreeze
		["Class"] = "DEATHKNIGHT", 
		["CounterDuration"] = 4, 
		["DefaultCooldown"] = 15, 
		["Talent"] = false, 
		["Pet"] = false,
	}, 
	[47476] = { -- Strangulate (Blood/Honor)
		["Class"] = "DEATHKNIGHT", 
		["CounterDuration"] = 3, 
		["DefaultCooldown"] = 120, 
		["Talent"] = true, 
		["Pet"] = false,
		["Ignore"] = true, 
	}, 
	-- SHAMAN
	[57994] = { -- Wind Shear
		["Class"] = "SHAMAN", 
		["CounterDuration"] = 3, 
		["DefaultCooldown"] = 12, 
		["Talent"] = false, 
		["Pet"] = false,
	}, 
	-- MAGE
	[2139] = { -- Counterspell
		["Class"] = "MAGE", 
		["CounterDuration"] = 6, 
		["DefaultCooldown"] = 24, 
		["Talent"] = false, 
		["Pet"] = false,
	}, 
	-- WARLOCK
	[19647] = { -- Spell Lock (Felhunter)
		["Class"] = "WARLOCK", 
		["CounterDuration"] = 6, 
		["DefaultCooldown"] = 24, 
		["Talent"] = false, 
		["Pet"] = true,
	}, 
	[115781] = { -- Optical Blast (Observer)
		["Class"] = "WARLOCK", 
		["CounterDuration"] = 6, 
		["DefaultCooldown"] = 24, 
		["Talent"] = false, 
		["Pet"] = true,
	}, 
	-- MONK
	[116705] = { -- Spear Hand Strike
		["Class"] = "MONK", 
		["CounterDuration"] = 4, 
		["DefaultCooldown"] = 15, 
		["Talent"] = false, 
		["Pet"] = false 
	}, 
	-- DRUID
	[106839] = { -- Skull Bash (Feral/Guardian)
		["Class"] = "DRUID", 
		["CounterDuration"] = 4, 
		["DefaultCooldown"] = 15, 
		["Talent"] = true, 
		["Pet"] = false 
	}, 
	[78675] = { -- Solar Beam (Balance)
		["Class"] = "DRUID", 
		["CounterDuration"] = 5, 
		["DefaultCooldown"] = 60, 
		["Talent"] = true, 
		["Pet"] = false,
		["Ignore"] = true, 
	}, 
}
