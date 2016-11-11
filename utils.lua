--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
]]

local ADDON_NAME, addon = ...

-- ----------------------------------------------------

addon.Title = GetAddOnMetadata( ADDON_NAME, "Title" )
addon.Version = GetAddOnMetadata( ADDON_NAME, "Version" )

-- ----------------------------------------------------

local logLevels = { ["ALL"] = 1, ["TRACE"] = 2, ["DEBUG"] = 3, ["INFO"] = 4, ["WARN"] = 5, ["ERROR"] = 6, ["NONE"] = 7 }

addon.LogLevel = "ALL"

function addon:Log( level, msg, ... )
	local intLevel = logLevels[level]
	local maxLevel = logLevels[addon.LogLevel]
	
	if ( intLevel < maxLevel ) then
		return end

	DEFAULT_CHAT_FRAME:AddMessage( "[" .. self.Title .. "][" .. level .. "] " .. string.format( msg, ... ) )
end

function addon:Print( msg, ... )
	DEFAULT_CHAT_FRAME:AddMessage( "[" .. self.Title .. "] " .. string.format( msg, ... ) )
end