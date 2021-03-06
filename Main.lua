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
local _textWarning = addon:CreateWarningText()

-- ----------------------------------------------------
-- Event Handler

local events = CreateFrame( "Frame" );
events:RegisterEvent( "ADDON_LOADED" )
events:SetScript( "OnEvent", function( self, event, ... )
	self[event]( self, ... )
end )

local function OnSlashCmd( ... )
	addon:Log( "Slash Command: " .. table.concat( { ... }, ", " ) )

	local arg1, arg2, arg3 = ...
	if ( arg1 == '' ) then
		addon:Print( "/ckick auto" )
		addon:Print( "/ckick rotation <RotationID> players <UnitID 1> ..." )
		addon:Print( "/ckick rotation <RotationID> target [<UnitID>]" )
		addon:Print( "/ckick rotation <RotationID> restart" )
		addon:Print( "/ckick rotation <RotationID> remove" )
		addon:Print( "/ckick sync [<RotationID>]" )
		addon:Print( "/ckick sync <RotationID> target" )
		addon:Print( "/ckick reset" )
		addon:Print( "/ckick log <enable|disable>" )
		return
	elseif ( arg1 == "auto" ) then
		addon:AutoRotations( 1, 0 )
	elseif ( arg1 == "rotation" ) then
		if ( arg3 == "players" ) then
			addon:SetPlayersByUnitID( arg2, select( 4, ... ) ) return
		elseif ( arg3 == "target" ) then
			addon:SetTargetByUnitID( arg2, select( 4, ... ) ) return
		elseif ( arg3 == "restart" ) then
			addon:RestartRotation( arg2 ) return
		elseif ( arg3 == "remove" ) then
			addon:RemoveRotation( arg2 ) return
		else
			addon:Print( "Unknown command for %q: %q", arg1, arg3 )
		end
	elseif ( arg1 == "sync" ) then
		if ( arg2 ) then
			if ( arg3 == "target" ) then
				addon:SyncTarget( arg2 )
			else
				addon:SyncRotation( arg2 )
			end
		else
			addon:SyncRotations()
		end
	elseif ( arg1 == "reset" ) then

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
	events:RegisterEvent( "PLAYER_REGEN_DISABLED" )

	events:UnregisterEvent( "PLAYER_LOGIN" )
end

function events:PLAYER_SPECIALIZATION_CHANGED( unitID )
	addon:Log( "PLAYER_SPECIALIZATION_CHANGED for %q", unitID )

	_players:StartPlayerInfoUpdate( unitID, true )
end

function events:INSPECT_READY( guid )
	addon:Log( "INSPECT_READY for %q", guid )

	if ( _players:UpdatePlayerInfo( guid ) ) then
		for _, rotation in next, _rotations do
			rotation:AdvanceRotation()
		end
	end

	_players:RequestNextPending()
end

function events:CHAT_MSG_ADDON( prefix, msg, channel, sender )
	if ( prefix ~= ADDON_NAME ) then
		return end

	addon:Log( "CHAT_MSG_ADDON from " .. sender .. " via " .. channel )
	addon:Log( " -> " .. msg )

	local args = { strsplit( ";", msg ) }
	if ( args[1] == "ROTATION" ) then
		addon:Log( "Received ROTATION sync message" )
		addon:SetPlayersByGUID( args[2], unpack( args, 3 ) )
	elseif ( args[1] == "TARGET" ) then
		addon:Log( "Received TARGET sync message" )
		addon:SetTargetByGUID( args[2], args[3] )
	else
		addon:Log( "Received unknown addon message: " .. args[1] )
	end
end

function events:PLAYER_REGEN_DISABLED( ... )
	for _, rotation in next, _rotations do
		rotation:AdvanceRotation()
	end
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

	addon:Log( "%q casted %s:%s", sourceName, spellID, spellName )

	for _, rotation in next, _rotations do
		rotation:StartCooldown( sourceGUID, spellInfo )
	end
end

function events:SPELL_INTERRUPT( timestamp, event, hideCaster,
								 sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
								 destGUID, destName, destFlags, destRaidFlags,
								 spellID, spellName, spellSchool,
								 extraSpellID, extraSpellName, extraSchool )

	addon:Log( "%q interrupted %q with %s:%s", sourceGUID, destGUID, spellID, spellName )

	local spellInfo = addon.Spells:GetSpellByID( spellID );
	if ( not spellInfo ) then
		addon:Log( "No spell info for %s:%s", spellID, spellName )
		return end

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
		--addon:Log( "%q is unconscious", destGUID )
	else
		--addon:Log( "%q died", destGUID )

		for _, rotation in next, _rotations do
			if ( rotation:GetTarget() == destGUID ) then
				rotation:SetTarget( nil )
			end
		end
	end
end

-- ----------------------------------------------------

local function GetRotation( rotationID, create )
	local rotation = _rotations[rotationID]
	if ( not rotation and create ) then
		rotation = addon:CreateRotation( rotationID )
		rotation:GetGUI():SetLabel( "Rotation " .. rotationID )
		_rotations[rotationID] = rotation
	end

	return rotation
end

function addon:SetTargetByUnitID( rotationID, unitID )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: rotation set target <RotationID>" ) return end

	local rotation = GetRotation( rotationID )
	if ( not rotation ) then
		return end

	rotation:SetTarget( UnitGUID( unitID or "target" ) )
end

function addon:SetTargetByGUID( rotationID, guid )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Log( "Failed to sync target: Invalid rotation ID: %q", rotationID ) return end

	local rotation = GetRotation( rotationID )
	if ( not rotation ) then
		return end

	if ( guid == "nil" ) then
		guid = nil
	end

	rotation:SetTarget( guid )
end

function addon:SetPlayersByUnitID( rotationID, ... )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: rotation set players <RotationID> <UnitID 1> ..." ) return end

	local playerInfos = {}
	for n = 1, select( '#', ... ) do
		local unitID = select( n, ... )
		local info = _players:GetPlayerInfo( unitID )

		if ( not info ) then
			addon:Print( "Failed to create rotation: Unable to add unit ID %q to rotation", unitID )
			return end

		table.insert( playerInfos, info )
	end

	if ( #playerInfos < 1 ) then
		addon:Print( "Failed to create rotation: Must specify at least one unit ID", unitID )
		addon:Print( "Usage: rotation set players <RotationID> <Player1> ..." ) return end

	for _, info in next, playerInfos do
		_players:StartPlayerInfoUpdate( info.Name )
	end

	_players:RegisterCallback( function()
		addon:FinishSetPlayers( rotationID, playerInfos )
	end )
end

function addon:SetPlayersByGUID( rotationID, ... )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Log( "Failed to sync rotation: Invalid rotation ID: %q", rotationID ) return end

	local playerInfos = {}
	for n = 1, select( '#', ... ) do
		local guid = select( n, ... )
		local info = _players:GetPlayerInfoByGUID( guid )

		if ( not info ) then
			addon:Log( "Failed to sync rotation: Unable to add GUID %q to rotation", guid )
			return end

		table.insert( playerInfos, info )
	end

	for _, info in next, playerInfos do
		_players:StartPlayerInfoUpdate( info.Name )
	end

	_players:RegisterCallback( function()
		addon:FinishSetPlayers( rotationID, playerInfos )
	end )
end

function addon:FinishSetPlayers( rotationID, playerInfos )
	addon:Log( "Finish set players" )

	addon:SortPlayers( playerInfos )

	local rotation = GetRotation( rotationID, true )
	rotation:Reset()
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

function addon:AutoRotations( nRotations, maxPlayers )
	addon:ResetRotations()

	addon:Log( "Setting up %s auto rotations", nRotations )

	local nPlayers = GetNumGroupMembers()
	local playerInfos = {}

	table.insert( playerInfos, _players:GetPlayerInfo( "player" ) )

	if ( nPlayers > 0 ) then
		if ( IsInRaid() ) then
			for i = 1, 40 do
				local info = _players:GetPlayerInfo( "raid" .. i )
				if ( info ) then
					table.insert( playerInfos, info )
				end
			end
		elseif ( IsInGroup() ) then
			for i = 1, 5 do
				local info = _players:GetPlayerInfo( "party" .. i )
				if ( info ) then
					table.insert( playerInfos, info )
				end
			end
		end
	end

	for _, info in next, playerInfos do
		_players:StartPlayerInfoUpdate( info.Name )
	end

	_players:RegisterCallback( function()
		addon:FinishAutoRotations( nRotations, playerInfos, maxPlayers )
	end )
end

function addon:FinishAutoRotations( nRotations, playerInfos, maxPlayers )
	addon:Log( "Finish auto rotation" )

	local valid = {}
	for _, info in next, playerInfos do
		if ( info.PrimarySpell ) then
			addon:Log( "Adding player %q to auto rotations", info.Name )
			table.insert( valid, info )
		else
			addon:Log( "%q has no primary spell", info.Name )
		end
	end

	if ( #valid == 0 ) then
		addon:Print( "No valid players found for auto rotation!" )
		return end

	addon:SortPlayers( valid )

	local rotation = GetRotation( 1, true )
	rotation:Reset()
	rotation:SetPlayers( valid )
	rotation:GetGUI():Show()
end

function addon:ResetRotations()
	addon:Log( "Clearing rotations" )

	for _, rotation in next, _rotations do
		rotation:Reset()
	end
end

-- ----------------------------------------------------

function addon:ShowTextAlert( msg, holdTime, fadeTime )
	_textWarning:ShowText( msg, holdTime, fadeTime )
end

-- ----------------------------------------------------

function addon:SyncRotations()
	for id, _ in next, _rotations do
		addon:SyncRotation( id )
		addon:SyncTarget( id )
	end
end

function addon:SyncRotation( rotationID )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: sync <RotationID>" ) return end

	local rotation = GetRotation( rotationID )
	if ( not rotation ) then
		return end

	local msg = "ROTATION;" .. tostring( rotationID ) .. ";" .. table.concat( rotation:GetPlayerGUIDs(), ";" )
	SendAddonMessage( ADDON_NAME, msg, "RAID" )
end

function addon:SyncTarget( rotationID )
	rotationID = tonumber( rotationID )
	if ( type( rotationID ) ~= "number" ) then
		addon:Print( "Usage: sync <RotationID> target" ) return end

	local rotation = GetRotation( rotationID )
	if ( not rotation ) then
		return end

	local msg = "TARGET;" .. tostring( rotationID ) .. ";" .. tostring( rotation:GetTarget() )
	SendAddonMessage( ADDON_NAME, msg, "RAID" )
end

-- ----------------------------------------------------

_G[ADDON_NAME] = addon