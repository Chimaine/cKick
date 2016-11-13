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

	-- Returns the first player that is off cooldown
	-- or the player with the smallest remaining cooldown.
	function instance:GetNextPlayer()
		local result, cd = nil, math.huge;
		for i, player in ipairs( _players ) do
			if ( player.Info.PrimarySpell ) then
				local bar = player.Bar
				if ( not bar.IsRunning() ) then
					return player
				elseif ( bar.Remaining() < cd ) then
					result, cd = player, bar.Remaining()
				end
			end
		end

		return result
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

	function instance:StartLockout( duration )
		_gui:StartLockout( duration )
	end

	function instance:StartCooldown( guid, spellInfo )
		local player = GetPlayerByGUID( guid )
		if ( not player ) then
			return end
		if ( spellInfo ~= player.Info.PrimarySpell ) then
			addon:Log( "DEBUG", "%q used a secondary spell", player.Info.Name )
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

		_nextPlayer = instance:GetNextPlayer()
		if ( not _nextPlayer ) and ( not lastPlayer ) then
			return end

		_nextPlayer.Bar:ShowArrows()

		addon:Log( "DEBUG", "Advancing rotation from %q to %q",
			lastPlayer and lastPlayer.Info.Name or "None",
			_nextPlayer and _nextPlayer.Info.Name or "None" )
	end

	function instance:Reset()
		_players = nil
		_nextPlayer = nil
		instance:SetTarget( nil )
		_gui:HideAllBars()
		_gui:Hide()
	end

	return instance
end