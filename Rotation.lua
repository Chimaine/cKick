--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
]]

local ADDON_NAME, addon = ...

-- ----------------------------------------------------

function addon:CreateRotation( id )
	local instance = {}
	local _gui = addon:CreateGroup( id )
	local _target
	local _players
	local _nextPlayer

	-- ----------------------------------------------------

	-- Returns the first player that is off cooldown
	-- or the player with the smallest remaining cooldown.
	local function GetNextPlayer()
		local result, cd = 0, math.huge;
		for i, player in ipairs( _players ) do
			local bar = player.Bar
			if ( not bar.IsRunning() ) then
				return player
			elseif ( bar.Remaining() < cd ) then
				result, cd = player, bar.Remaining()
			end
		end

		return result;
	end

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

	function instance:GetNextPlayer()
		return _nextPlayer
	end

	function instance:GetPlayers() 
		return _players
	end

	function instance:SetTarget( guid )
		_target = guid
		_gui:ShowLockoutBar( guid or false )
	end

	function instance:SetPlayers( players )
		if ( #players < 1 ) then
			error( "Cannot create rotation without players" ) end

		_players = {}
		_nextPlayer = nil

		for i, player in ipairs( players ) do
			local bar = _gui:GetBar( i )
			bar:SetLabel( player.Name )
			bar:SetMinMaxValues( 0, player.PrimaryCooldown )
			bar:SetValue( player.PrimaryCooldown )
			bar:SetEnabled( true )

			_players[i] = {
				["Info"] = player,
				["Bar"] = bar,
			}
		end

		instance:AdvanceRotation()
	end

	function instance:StartLockout( duration )
		_gui:StartSilence( duration )
	end

	function instance:StartCooldown( guid )
		local player = GetPlayerByGUID( guid )
		if ( not player ) then
			return end
		
		addon:Log( "DEBUG", "Starting cooldown for %q: %s", player.Info.Name, player.Info.PrimaryCooldown )

		player.Bar:Start( player.Info.PrimaryCooldown, true )
		instance:AdvanceRotation()
	end

	function instance:AdvanceRotation()
		local lastPlayer = _nextPlayer
		if ( lastPlayer ) then
			lastPlayer.Bar:HideArrows()
		end

		_nextPlayer = GetNextPlayer()
		_nextPlayer.Bar:ShowArrows()

		addon:Log( "DEBUG", "Advancing rotation from %q to %q", 
			lastPlayer and lastPlayer.Info.Name or "None", 
			_nextPlayer and _nextPlayer.Info.Name or "None" )
	end

	function instance:Reset()
		_players = nil
		_nextPlayer = nil
		_gui:SetTarget( nil )
		_gui:HideAllBars()
		_gui:Hide()
	end

	return instance
end