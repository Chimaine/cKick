--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
]]

local ADDON_NAME, addon = ...

-- ----------------------------------------------------

local ROLE_KICKER_ORDER = {
	["TANK"] = 1,
	["DAMAGER"] = 2,
	["HEALER"] = 3,
	["NONE"] = 4,
}

local function ComparePlayers( a, b )
	if ( not a or not b ) then return end

	addon:Log( "Comparing %q and %q", a.Name, b.Name )

	local result = ROLE_KICKER_ORDER[a.Role] < ROLE_KICKER_ORDER[b.Role]
	addon:Log( "  Role: %s vs %s: %s", a.Role, b.Role, result )
	if ( result ~= 0 ) then
		return result end

	result = a.PrimaryCooldown < b.PrimaryCooldown
	addon:Log( "  CD: %s vs %s: %s", a.PrimaryCooldown, b.PrimaryCooldown, result )
	if ( result ~= 0 ) then
		return result end

	result = a.PrimarySpell.CounterDuration > b.PrimarySpell.CounterDuration
	addon:Log( "  Duration: %s vs %s: %s", a.PrimarySpell.CounterDuration, b.PrimarySpell.CounterDuration, result )
end

function addon:SortPlayers( players )
	table.sort( players, ComparePlayers )
end

function addon:CreateRotation( id )
	local instance = {}
	local _playerGUID = UnitGUID( "player" )
	local _gui = addon:CreateGroup( id )
	local _target
	local _players = {}
	local _nextPlayer

	-- ----------------------------------------------------

	local function GetPlayerByGUID( guid )
		if ( not _players ) then
			return end

		for i, player in ipairs( _players ) do
			if ( player.Info.GUID == guid ) then
				return player end
		end
	end

	-- ----------------------------------------------------

	function instance:GetGUI()
		return _gui
	end

	function instance:GetTarget()
		return _target
	end

	function instance:GetCurrentPlayer()
		return _nextPlayer
	end

	-- Returns the first player that is off cooldown
	-- or the player with the smallest remaining cooldown
	-- or the first player in the rotation
	function instance:GetNextPlayer()
		local result, cd = nil, math.huge;
		for i, player in next, _players do
			if ( player.Info.PrimarySpell ) then
				local bar = player.Bar
				if ( not bar.IsRunning() ) then
					return player
				elseif ( bar.Remaining() < cd ) then
					result, cd = player, bar.Remaining()
				end
			else
				addon:Log( "%q has no primary spell", player.Info.Name )
			end
		end

		return result or _players[1]
	end

	function instance:GetPlayerGUIDs()
		local result = {}
		for _, player in next, _players do
			table.insert( result, player.Info.GUID )
		end
		return result
	end

	function instance:SetTarget( guid )
		_target = guid
		_gui:ShowLockoutBar( guid or false )
	end

	function instance:SetPlayers( players )
		_players = {}
		_nextPlayer = nil

		for i, player in next, players do
			local bar = _gui:GetBar( i )
			bar:SetLabel( player.Name )
			bar:SetMinMaxValues( 0, 1 )
			bar:SetValue( 1 )
			bar:SetEnabled( true )

			--bar:SetColor( .31, .41, .53 )
			local color = RAID_CLASS_COLORS[player.Class]
			bar:SetColor( color.r, color.g, color.b )

			_players[i] = {
				["Info"] = player,
				["Bar"] = bar,
			}
		end

		instance:AdvanceRotation()
	end

	function instance:SortPlayers()
		local players = {}
		for _, entry in next, _players do
			table.insert( players, entry.Info )
		end

		addon:SortPlayers( players )

		instance:SetPlayers( players )
	end

	function instance:StartLockout( duration )
		addon:Log( "Starting lockout of " .. duration )
		_gui:StartLockout( duration )
	end

	function instance:StartCooldown( guid, spellInfo )
		local player = GetPlayerByGUID( guid )
		if ( not player ) then
			return end
		if ( player.Info.PrimarySpell ) and ( spellInfo ~= player.Info.PrimarySpell ) then
			addon:Log( "%q used a secondary spell", player.Info.Name )
			return end

		addon:Log( "Starting cooldown for %q: %s", player.Info.Name, player.Info.PrimaryCooldown )

		player.Bar:Start( spellInfo.DefaultCooldown, true )
		instance:AdvanceRotation()
	end

	function instance:AdvanceRotation()
		local lastPlayer = _nextPlayer
		--if ( lastPlayer ) then
		--	lastPlayer.Bar:HideArrows()
		--end
		_gui:HideAllArrows()

		if ( #_players < 1 ) then
			return end

		_nextPlayer = instance:GetNextPlayer()
		_nextPlayer.Bar:ShowArrows()

		addon:Log( "Advancing rotation from %q to %q",
			lastPlayer and lastPlayer.Info.Name or "None",
			_nextPlayer and _nextPlayer.Info.Name or "None" )

		if ( _nextPlayer.Info.GUID == _playerGUID ) and ( InCombatLockdown() ) then
			addon:ShowTextAlert( "You are next to interrupt!", 3, 1 )
		end
	end

	function instance:Reset()
		_players = nil
		_nextPlayer = nil
		instance:SetTarget( nil )
		_gui:HideAllBars()
		_gui:HideAllArrows()
		_gui:Hide()
	end

	return instance
end