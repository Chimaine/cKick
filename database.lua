--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
]]

local ADDON_NAME, addon = ...
local DB_NAME = "cKick_Settings"

-- ----------------------------------------------------

local _version = 2

local function GetDefaultSettings()
	return {
		Version = _version,

		Scale = 1,
		Points = {},

		BarWidth = 150,
		BarHeight = 15,
		BarSpacing = 1,
		BarTexture = "darkborder",

		BarColor = { .31, .41, .53 },
		ClassColor = false,

		FontSize = 10,
		FontFace = "Friz Quadrata TT",
	}
end

function addon:ReadSettings()
	local db = _G[DB_NAME]
	if ( not db ) then
		addon:Log( "Creating new DB" )
		db = GetDefaultSettings()
		_G[DB_NAME] = db
	end

	if ( ( not db.Version ) or ( _version > db.Version ) ) then
		-- TODO
		addon:Log( "Upgrading DB from version", db.Version, "to", _version )
		db = GetDefaultSettings()
		_G[DB_NAME] = db
	end

	return db
end