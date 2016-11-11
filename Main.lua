--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
	
	Thanks to Sakuri, Raymakur, Chalya and Manidin of EU-Destromath for early alpha testing
	and my guild Karma for beta testing :)

	Also thanks to Cerridwen for commissioning me for an update after 8 years.
]]


local ADDON_NAME, addon = ...

_G[ADDON_NAME] = addon

-- ----------------------------------------------------

local _players = addon:CreatePlayerDB()
local _rotations = {}

-- ----------------------------------------------------
-- Event Handler

local events = CreateFrame( "Frame" );
events:RegisterEvent( "ADDON_LOADED" )
events:SetScript( "OnEvent", function( self, event, ... )
	self[event]( self, ... )
end )

local function OnSlashCmd( ... )	
	addon:Log( "DEBUG", "Slash Command: " .. table.concat( { ... }, ", " ) )

	local arg1, arg2, arg3 = ...
	if ( arg1 == "rotation" ) then
		if ( arg2 == "set" ) then
			if ( arg3 == "players" ) then
				addon:SetPlayers( select( 4, ... ) ) return
			elseif ( arg3 == "target" ) then
				addon:SetTarget( select( 4, ... ) ) return
			end
		elseif ( arg2 == "restart" ) then
			addon:RestartRotation( arg3 ) return
		elseif ( arg2 == "remove" ) then
			addon:RemoveRotation( arg3 ) return
		end
	end

	addon:Print( "Unknown command" )
end

function events:ADDON_LOADED( arg )
	if ( tostring( arg ) ~= ADDON_NAME ) then return end
	
	events:UnregisterEvent( "ADDON_LOADED" )
		
	_G["SLASH_" .. ADDON_NAME .. "1"] = "/ckick"
	_G["hash_SlashCmdList"][ADDON_NAME] = nil
	_G["SlashCmdList"][ADDON_NAME] = function( cmd ) OnSlashCmd( strsplit( " ", cmd ) ) end
	
	events:RegisterEvent( "PLAYER_LOGIN" )
end

function events:PLAYER_LOGIN()
	addon.DB = addon:ReadSettings()
	
	if ( not RegisterAddonMessagePrefix( ADDON_NAME ) ) then
		addon:Log( "ERROR", "Unable to register AddonMessagePrefix, sync unavailable!" ) 
	end

	events:RegisterEvent( "CHAT_MSG_ADDON" )
	events:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" )
		
	events:UnregisterEvent( "PLAYER_LOGIN" )
end

function events:COMBAT_LOG_EVENT_UNFILTERED( ... )
	local event = select( 2, ... )
	local handler = events[event]
	
	if ( handler ) then
		handler( event, ... )
	end
end

function events:SPELL_CAST_SUCCESS( timestamp, event, hideCaster, 
									sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
									destGUID, destName, destFlags, destRaidFlags, 
									spellID, spellName, spellSchool )	
	if ( bit.band( sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER ) > 0 ) then
		return end

	addon:Log( "DEBUG", "%q casted %s:%s", sourceName, spellID, spellName )
	
	local spellInfo = addon.Spells:GetSpellByID( spellID );
	if ( not spellInfo ) then
		addon:Log( "DEBUG", "Ignoring spell %i", spellID )
		return end

	for _, rotation in pairs( _rotations ) do
		rotation:StartCooldown( sourceGUID )
	end
end

function events:SPELL_INTERRUPT( timestamp, event, hideCaster, 
								 sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
								 destGUID, destName, destFlags, destRaidFlags, 
								 spellID, spellName, spellSchool,
								 extraSpellID, extraSpellName, extraSchool )
	addon:Log( "DEBUG", sourceGUID .. " interrupted " .. destGUID )
	addon:Log( "DEBUG", "%i, %i, %i", spellID, spellName, spellSchool )
	addon:Log( "DEBUG", "%i, %i, %i", extraSpellID, extraSpellName, extraSchool )
		
	local spellInfo = addon.Spells:GetSpellByID( spellID );
	if ( not spellInfo ) then
		return end
	
	for _, rotation in next, _rotations do
		if ( rotation:GetTarget() == destGUID ) then
			rotation:StartLockout( spellInfo.CounterDuration )
		end
	end
end

function events:CHAT_MSG_ADDON( prefix, message, channel, sender )
	if ( prefix ~= ADDON_NAME ) then
		return end

	addon:Log( "DEBUG", "AddonMessageReceived from " .. sender .. " via " .. channel )
end

-- ----------------------------------------------------

function addon:SetTarget( rotationID )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: rotation set target <RotationID>" ) return end
	
	local rotation = _rotations[rotationID]
	if ( not rotation ) then
		return end

	rotation:SetTarget( UnitGUID( "target" ) )
end

function addon:SetPlayers( rotationID, ... )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: rotation set players <RotationID> <Player1> ..." ) return end
	
	local rotation = _rotations[rotationID]
	if ( not rotation ) then
		rotation = addon:CreateRotation( rotationID )
		rotation:GetGUI():SetLabel( "Rotation " .. rotationID )
		_rotations[rotationID] = rotation
	end

	local playerInfos = {}
	for n = 1, select( '#', ... ) do
		local player = select( n, ... )
		table.insert( playerInfos, _players:GetPlayerInfo( player ) )
	end

	if ( #playerInfos < 1 ) then
		addon:Print( "Usage: rotation set players <RotationID> <Player1> ..." ) return end

	rotation:SetPlayers( playerInfos )
	rotation:GetGUI():Show()

	rotation:StartCooldown( playerInfos[1].GUID )
end

function addon:RestartRotation( rotationID )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: rotation restart <RotationID>" ) return end
	
	local rotation = _rotations[rotationID]
	if ( not rotation ) then
		return end

	rotation:AdvanceRotation()
end

function addon:RemoveRotation( rotationID )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: rotation remove <RotationID>" ) return end
	
	local rotation = _rotations[rotationID]
	if ( not rotation ) then
		return end

	rotation:Reset()
end

-- ----------------------------------------------------

_G[ADDON_NAME] = addon