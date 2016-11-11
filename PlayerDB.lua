--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
]]

local ADDON_NAME, addon = ...

-- ----------------------------------------------------

function addon:CreatePlayerDB()
	local instance = {}
	local _players = {}
	local _pendingUpdates = {}

	-- ----------------------------------------------------

	local function SetPrimarySpellInfo( info )
		local primarySpell = addon.Spells:GetPrimarySpell( info.Class, info.Spec )
		if ( primarySpell ) then
			info["PrimarySpell"] = primarySpell
			info["PrimaryCooldown"] = primarySpell.DefaultCooldown
		end
	end

	local function RetrievePlayerInfo( guid )
		local _, classID, _, _, _, name, realm = GetPlayerInfoByGUID( guid )

		if ( realm and ( string.len( realm ) > 0 ) ) then
			name = name .. "-" .. realm
		end

		local info = {
			["GUID"] = guid,
			["Name"] = name,
			["Class"] = classID,
		}

		SetPrimarySpellInfo( info )

		return info
	end

	local function RequestInspect( unitID )
		local guid = UnitGUID( unitID )
		if ( not guid ) then
			return end

		addon:Log( "DEBUG", "Requesting inspect for %q, %q", unitID, guid )

		_pendingUpdates[guid] = unitID

		NotifyInspect( unitID )
	end

	function instance:GetPlayerInfo( unitID )
		local guid = UnitGUID( unitID )
		if ( not guid )	then
			return end
		
		local info = _players[guid]
		if ( not info ) then
			info = RetrievePlayerInfo( guid )
			_players[guid] = info
		end

		RequestInspect( unitID )
				
		return info
	end

	function instance:StartPlayerInfoUpdate( unitID )
		local guid = UnitGUID( unitID )
		if ( not guid )	then
			return end
		if ( not _players[guid] ) then
			return end

		RequestInspect( unitID )
	end

	function instance:UpdatePlayerInfo( guid )
		local unitID = _pendingUpdates[guid]
		if ( not unitID ) then
			return end
			
		local info = _players[guid]
		if ( not info ) then
			return end

		local specID = GetInspectSpecialization( unitID )
		addon:Log( "DEBUG", "%q:%q spec: %s", guid, unitID, specID )

		if ( specID == 0 ) then
			addon:Log( "WARN", "GetInspectSpecialization failed for %q:%q", guid, unitID )
			return end
		
		SetPrimarySpellInfo( info )
	end

	function instance:RemovePlayer( guid )
		_players[guid] = nil
	end

	function instance:Clear()
		_players = {}
	end

	function instance:GetPlayerInfos()
		return _players
	end

	return instance
end