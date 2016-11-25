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

	-- ----------------------------------------------------

	local function SetPrimarySpellInfo( info )
		local primarySpell = addon.Spells:GetPrimarySpell( info.Class, info.Spec )
		if ( primarySpell ) then
			addon:Log( "Primary spell for %s,%s : %s", info.Class, info.Spec, primarySpell.ID )

			info["PrimarySpell"] = primarySpell
			info["PrimaryCooldown"] = primarySpell.DefaultCooldown
		else
			addon:Log( "No primary spell for %s,%s", info.Class, info.Spec )

			info["PrimarySpell"] = nil
			info["PrimaryCooldown"] = nil
		end
	end

	local function GetPlayerNameAndClass( guid )
		local _, classID, _, _, _, name, realm = GetPlayerInfoByGUID( guid )

		if ( realm and ( string.len( realm ) > 0 ) ) then
			name = name .. "-" .. realm
		end

		return name, classID
	end

	local function RetrievePlayerInfo( guid )
		local name, classID = GetPlayerNameAndClass( guid )
		local info = {
			["GUID"] = guid,
			["Name"] = name,
			["Class"] = classID,
			["Spec"] = 0,
			["Inspected"] = false,
		}

		SetPrimarySpellInfo( info )

		return info
	end

	local function RequestInspect( info, reset )
		if ( info.Inspected and ( not reset ) ) then
			return end

		addon:Log( "Requesting inspect for %q", info.GUID )

		info.Inspected = false

		NotifyInspect( info.Name )
	end

	function instance:GetPlayerInfo( unitID )
		if ( not UnitExists( unitID )
		  or not UnitIsPlayer( unitID )
		  or not UnitIsFriend( "player", unitID ) ) then
			return end

		local guid = UnitGUID( unitID )
		if ( not guid )	then
			return end

		local info = _players[guid]
		if ( not info ) then
			info = RetrievePlayerInfo( guid )
			_players[guid] = info

			RequestInspect( info )
		end

		return info
	end

	function instance:GetPlayerInfoByGUID( guid )
		local info = _players[guid]
		if ( info ) then
			return info end

		local name = GetPlayerNameAndClass( guid )
		return instance:GetPlayerInfo( name )
	end

	function instance:StartPlayerInfoUpdate( unitID, reset )
		local guid = UnitGUID( unitID )
		if ( not guid )	then
			return end

		local info = _players[guid]
		if ( not info ) then
			return end

		RequestInspect( info, reset )
	end

	function instance:StartMissingInfoUpdates()
		for _, info in next, _players do
			RequestInspect( info )
		end
	end

	function instance:UpdatePlayerInfo( guid )
		local info = _players[guid]
		if ( not info ) then
			return end
		if ( info.Inspected ) then
			return end

		local specID = GetInspectSpecialization( info.Name )
		addon:Log( "%q spec: %s", guid, specID )

		info.Spec = specID
		SetPrimarySpellInfo( info )

		if ( specID == 0 ) then
			addon:Log( "WARN", "GetInspectSpecialization failed for %q:%q", guid, info.Name )
			return end
		info.Inspected = true
		return true
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