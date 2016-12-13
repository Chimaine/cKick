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

addon.EnableLog = false

function addon:Log( msg, ... )
	if ( not addon.EnableLog ) then
		return end

	addon:Print( msg, ... )
end

function addon:Print( msg, ... )
	local args = {}
	for n = 1, select( '#', ... ) do
		args[n] = tostring( select( n, ... ) )
	end

	DEFAULT_CHAT_FRAME:AddMessage( "[" .. self.Title .. "] " .. string.format( msg, unpack( args ) ) )
end