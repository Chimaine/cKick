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

	local function RetrievePlayerInfo( guid )
		local _, classID, _, _, _, name, realm = GetPlayerInfoByGUID( guid )

		if ( realm and ( string.len( realm ) > 0 ) ) then
			name = name .. "-" .. realm
		end

		local primarySpell = addon.Spells:GetPrimarySpell( classID );
		return {
			["GUID"] = guid,
			["Name"] = name,
			["Class"] = classID,
			["PrimarySpell"] = primarySpell,
			["PrimaryCooldown"] = primarySpell.DefaultCooldown,
		}
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
				
		return info
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