--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
]]
--[[
	Thanks to Sakuri, Raymakur, Chalya and Manidin of EU-Destromath for early alpha testing
	and my guild Karma for beta testing :)
]]


local ADDON_NAME, internal = ...

-- ----------------------------------------------------

local events = CreateFrame( "Frame", ADDON_NAME .. "_EventReceiver" );
events:RegisterEvent( "ADDON_LOADED" )
events:SetScript( "OnEvent", function( self, event, ... )
	internal[event]( internal, ... )
end )

-- ----------------------------------------------------

local LSM = LibStub( "LibSharedMedia-3.0" )
LSM:Register( "statusbar", "darkborder", "Interface\\Addons\\cKick\\media\\darkborder.tga" ) 

-- ----------------------------------------------------

internal.Players = {}
internal.Bars = {}

-- ----------------------------------------------------
-- Event Handler

function internal:OnSlashCmd( cmd )
	self:Log( "INFO", "SlashCMD: " .. cmd )
	
	local arg1, arg2, arg3 = strsplit( " ", cmd )	
	if ( arg1 == "target" ) then
		if ( arg2 == "set" ) then
			self:SetTarget( "target" )
		end
	elseif ( arg1 == "player" ) then
		if ( arg2 == "add" ) then
			self:AddPlayer( arg3 )
		elseif ( arg2 == "remove" ) then
			self:RemovePlayer( arg3 )
		end
	end
end

function internal:ADDON_LOADED( arg )
	if ( tostring( arg ) ~= ADDON_NAME ) then return end
	
	events:UnregisterEvent( "ADDON_LOADED" )
		
	_G["SLASH_" .. ADDON_NAME .. "1"] = "/ckick"
	_G["hash_SlashCmdList"][ADDON_NAME] = nil
	_G["SlashCmdList"][ADDON_NAME] = function( cmd ) self:OnSlashCmd( cmd ) end
	
	events:RegisterEvent( "PLAYER_LOGIN" )
end

function internal:PLAYER_LOGIN()
	self:ReadSettings()

	self:SetupAnchor()
	--self:SetupPopup()
	self:CreateSilenceBar()
	--self:Update()
	
	--self.Anchor:Hide()
	
	if ( not RegisterAddonMessagePrefix( ADDON_NAME ) ) then
		self:Log( "ERROR", "Unable to register AddonMessagePrefix, sync unavailable!" ) 
	end

	events:RegisterEvent( "CHAT_MSG_ADDON" )

	--self:RAID_ROSTER_UPDATE()
	--events:RegisterEvent("CHAT_MSG_ADDON")
	--events:RegisterEvent("RAID_ROSTER_UPDATE")
	events:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" )
	
	self.Bars.Silenced.Start( 10, false )
	self:AddPlayer( "player" )
	self:AddPlayer( "player" )
	self:AddPlayer( "player" )
	self:AddPlayer( "player" )
	self:AddPlayer( "player" )
		
	events:UnregisterEvent( "PLAYER_LOGIN" )
end

function internal:COMBAT_LOG_EVENT_UNFILTERED( ... )
	local event = select( 2, ... )
	if ( event == "SPELL_CAST_SUCCESS" ) then 
		self:SPELL_CAST_SUCCESS( ... )
	elseif ( event == "SPELL_INTERRUPT" ) then 
		self:SPELL_INTERRUPT( ... ) 
	end
end

function internal:SPELL_CAST_SUCCESS( timestamp, event, hideCaster, 
									  sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
									  destGUID, destName, destFlags, destRaidFlags, 
									  spellID, spellName, spellSchool )	
	if ( bit.band( sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER ) > 0 ) then
		return end
	
	local spellInfo = self.SpellDB[spellID];
	if ( not spellInfo ) then
		return end

	self:Log( "DEBUG", sourceName .. " casted " .. spellID .. ":" .. spellName )

	
	for i, v in ipairs( self.Players ) do
		if ( v.GUID == sourceGUID ) then
			v.Bar.Start( spellInfo["DefaultCooldown"], true )
		end
	end

	--[[
	local playerID = self:GetPlayerID( sourceGUID )
	if ( not playerID ) then
		return end
	
	local bar = self.Players[playerID].Bar
	bar.Start( spellInfo["DefaultCooldown"], true )
	]]
end

function internal:SPELL_INTERRUPT( timestamp, event, hideCaster, 
								   sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
								   destGUID, destName, destFlags, destRaidFlags, 
								   spellID, spellName, spellSchool,
								   extraSpellID, extraSpellName, extraSchool )
	self:Log( "DEBUG", sourceGUID .. " interrupted " .. destGUID )
	self:Log( "DEBUG", spellID, spellName, spellSchool )
	self:Log( "DEBUG", extraSpellID, extraSpellName, extraSchool )
	
	
	local spellInfo = self.SpellDB[spellID];
	if ( not spellInfo ) then
		return end
		
	if ( not self.Target ) and ( destGUID ~= UnitGUID( "target" ) ) then
		return end
	
	if ( self.Target and ( destGUID ~= self.Target.GUID ) ) then
		return end
	
	self.Bars.Silenced.Start( spellInfo.CounterDuration, false )
end

function internal:CHAT_MSG_ADDON( prefix, message, channel, sender )
	if ( prefix ~= ADDON_NAME ) then
		return end

	self:Log( "DEBUG", "AddonMessageReceived from " .. sender .. " via " .. channel )
end

-- ----------------------------------------------------
-- Rotation management

function internal:FindBestPlayerOrder()
	
end

-- ----------------------------------------------------
-- Player management

function internal:GetPlayerID( guid )
	for i, v in ipairs( self.Players ) do
		if ( v.GUID == guid ) then return i end
	end
end

function internal:AddPlayer( unitID )	
	local guid = UnitGUID( unitID )
	if ( not guid )	then
		return end
	
	--local id = self:GetPlayerID( guid )
	--if ( id ) then
	--	return self:Log( "ERROR", "Connot add player twice" ) end
	
	local _, classID, _, _, _, name, realm = GetPlayerInfoByGUID( guid )

	if ( realm and ( string.len( realm ) > 0 ) ) then
		name = name .. "-" .. realm
	end

	self:Log( "DEBUG", "Adding Player to rotation" )

	id = #self.Players + 1
	
	local bar = self:GetBar( id )
	bar.SetEnabled( true )
	bar.SetLabel( name )

	table.insert( self.Players, {
		["GUID"] = guid,
		["Name"] = name,
		["Class"] = classID,
		["Bar"] = bar
	} )
	
	return id
end

function internal:RemovePlayer( unitID )
	local guid = UnitGUID( unitID )
	if ( not guid )	then
		return end

	self:Log( "DEBUG", "Removing Player from rotation" )

	local id = self:GetPlayerID( guid )
	if ( not id ) then
		return end

	local reassign = ( id ~= #self.Players )
	local playerInfo = table.remove( self.Players, id )

	if ( reassign ) then
		self:ReassignBars()
	else
		playerInfo.Bar.SetEnabled( false )
	end
end

function internal:ReassignBars()
	for i, v in ipairs( self.Bars ) do
		v.SetEnabled( false )
	end
	for i, v in ipairs( self.Players ) do
		v.Bar = self:GetBar( i )
		v.Bar.SetEnabled( true )
	end 
end

-- ----------------------------------------------------
-- Target management

function internal:SetTarget( unitID )
	if ( unitID == "none" ) then
		internal.Target = nil
	else
		local guid, name = UnitGUID( unitID ), UnitName( unitID )
		
		self:Log( "DEBUG", "Adding target: " .. unitID )
		
		self.Target = {
			["GUID"] = guid,
			["Name"] = name,
		}
	end
end

-- ----------------------------------------------------
-- Layout

function internal:SetupAnchor()
	local anchor = CreateFrame( "Frame", "cKick_Anchor", UIParent )	
	anchor:SetWidth( 200 )
	anchor:SetHeight( 18 )	
	anchor:SetScale( 1 )
	anchor:SetAlpha( 1 )

	anchor:SetMovable( 1 )
	anchor:EnableMouse( 1 )
	anchor:SetUserPlaced( 0 )
	anchor:SetClampedToScreen( 1 )
	
	local point = self.DB.point
	anchor:SetPoint( point[1], UIParent, point[3], point[4], point[5] )

	anchor:SetScript( "OnMouseDown", function()
		anchor:StartMoving()
	end )
	anchor:SetScript( "OnMouseUp", function()
		anchor:StopMovingOrSizing()
		local point, parent, relativeTo, xPos, yPos = anchor:GetPoint()
		self.DB.point = { point, parent, relativeTo, xPos, yPos }
	end)
	
	anchor:SetScript( "OnShow", function() anchor.IsAnchorShown = true end )
	anchor:SetScript( "OnHide", function() anchor.IsAnchorShown = false end )

	local label = anchor:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmallOutline" )
	label:SetPoint( "CENTER", anchor, 0, 0 )
	label:SetFont( LSM:Fetch( "font", "Friz Quadrata TT" ), 11, select( 3, label:GetFont() ) )
	label:SetText( ADDON_NAME )
	anchor.Label = label
		
	self.Anchor = anchor
end

function internal:CreateSilenceBar()
	local bar = self.CreateBar( 200, 18 )
	bar.SetParent( self.Anchor )
	bar.SetPoint( "TOP", self.Anchor, "BOTTOM", 0, 0 )
	bar.SetTextStyle( LSM:Fetch( "font", "Friz Quadrata TT" ), 11 )
	bar.SetColor( .31, .41, .53 )

	bar.SetMinMaxValues( 0, 1 )
	bar.SetValue( 1 )

	bar.SetLabel( "Silence" )
	
	self.Bars.Silenced = bar;
end

function internal:GetBar( id )
	if ( self.Bars[id] ) then
		return self.Bars[id] end

	local space = ( ( 18 + 1 ) * ( id ) ) + 3

	self:Log("DEBUG", "Spacing: " .. space )

	local bar = self.CreateBar( 200, 18 )
	bar.SetParent( self.Anchor )
	bar.SetPoint( "TOP", self.Anchor, "BOTTOM", 0, -space )
	bar.SetTextStyle( LSM:Fetch( "font", "Friz Quadrata TT" ), 11 )
	bar.SetColor( .31, .41, .53 )
	
	bar.SetMinMaxValues( 0, 1 )
	bar.SetValue( 1 )

	self.Bars[id] = bar
	return bar
end

_G[ADDON_NAME] = internal