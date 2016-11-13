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

	local arg1, arg2 = ...
	if ( arg1 == '' ) then
		addon:Print( "/ckick rotation players <RotationID> <UnitID 1> ..." )
		addon:Print( "/ckick rotation target <RotationID> [<UnitID>]" )
		addon:Print( "/ckick rotation restart <RotationID>" )
		addon:Print( "/ckick rotation remove <RotationID>" )
		addon:Print( "/ckick log <enable|disable>" )
		return
	elseif ( arg1 == "rotation" ) then
		if ( arg2 == "players" ) then
			addon:SetPlayers( select( 3, ... ) ) return
		elseif ( arg2 == "target" ) then
			addon:SetTarget( select( 3, ... ) ) return
		elseif ( arg2 == "restart" ) then
			addon:RestartRotation( arg3 ) return
		elseif ( arg2 == "remove" ) then
			addon:RemoveRotation( arg3 ) return
		else
			addon:Print( "Unknown argument for %q: %q", arg1, arg2 )
		end
	elseif ( arg1 == "log" ) then
		if ( arg2 == "enable" ) then
			addon.EnableLog = true return
		elseif ( arg2 == "disable" ) then
			addon.EnableLog = false return
		else
			addon:Print( "Unknown argument for %q: %q", arg1, arg2 )
		end
	else
		addon:Print( "Unknown command: %q. Type /ckick to get a list of available commands", arg1 )
	end
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
	events:RegisterEvent( "PLAYER_SPECIALIZATION_CHANGED" )
	events:RegisterEvent( "INSPECT_READY" )

	events:UnregisterEvent( "PLAYER_LOGIN" )
end

function events:PLAYER_SPECIALIZATION_CHANGED( unitID )
	addon:Log( "DEBUG", "PLAYER_SPECIALIZATION_CHANGED for %q", unitID )

	_players:StartPlayerInfoUpdate( unitID, true )
end

function events:INSPECT_READY( guid )
	addon:Log( "DEBUG", "INSPECT_READY for %q", guid )

	_players:UpdatePlayerInfo( guid )
end

function events:CHAT_MSG_ADDON( prefix, message, channel, sender )
	if ( prefix ~= ADDON_NAME ) then
		return end

	addon:Log( "DEBUG", "AddonMessageReceived from " .. sender .. " via " .. channel )
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

	local spellInfo = addon.Spells:GetSpellByID( spellID );
	if ( not spellInfo ) then
		return end

	addon:Log( "DEBUG", "%q casted %s:%s", sourceName, spellID, spellName )

	for _, rotation in next, _rotations do
		rotation:StartCooldown( sourceGUID, spellInfo )
	end
end

function events:SPELL_INTERRUPT( timestamp, event, hideCaster,
								 sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
								 destGUID, destName, destFlags, destRaidFlags,
								 spellID, spellName, spellSchool,
								 extraSpellID, extraSpellName, extraSchool )
	local spellInfo = addon.Spells:GetSpellByID( spellID );
	if ( not spellInfo ) then
		return end

	addon:Log( "DEBUG", "%q interrupted %q with %s:%s", sourceGUID, destGUID, spellID, spellName )

	for _, rotation in next, _rotations do
		if ( rotation:GetTarget() == destGUID ) then
			rotation:StartLockout( spellInfo.CounterDuration )
		end
	end
end

function events:UNIT_DIED( timestamp, event, hideCaster,
						   sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
						   destGUID, destName, destFlags, destRaidFlags,
						   recapID, unconsciousOnDeath )
	if ( unconsciousOnDeath ) then
		addon:Log( "DEBUG", "%q is unconscious", destGUID )
	else
		addon:Log( "DEBUG", "%q died", destGUID )

		for _, rotation in next, _rotations do
			if ( rotation:GetTarget() == destGUID ) then
				rotation:SetTarget( nil )
			end
		end
	end
end

-- ----------------------------------------------------

function addon:SetTarget( rotationID, unitID )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: rotation set target <RotationID>" ) return end

	local rotation = _rotations[rotationID]
	if ( not rotation ) then
		return end

	rotation:SetTarget( UnitGUID( unitID or "target" ) )
end

function addon:SetPlayers( rotationID, ... )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: rotation set players <RotationID> <UnitID 1> ..." ) return end

	local rotation = _rotations[rotationID]
	if ( not rotation ) then
		rotation = addon:CreateRotation( rotationID )
		rotation:GetGUI():SetLabel( "Rotation " .. rotationID )
		_rotations[rotationID] = rotation
	end

	local playerInfos = {}
	for n = 1, select( '#', ... ) do
		local unitID = select( n, ... )
		local info = _players:GetPlayerInfo( unitID )

		if ( not info ) then
			addon:Print( "Unable to add unit ID %q to rotation", unitID )
			return end

		table.insert( playerInfos, info )
	end

	if ( #playerInfos < 1 ) then
		addon:Print( "Usage: rotation set players <RotationID> <Player1> ..." ) return end

	rotation:SetPlayers( playerInfos )
	rotation:GetGUI():Show()
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