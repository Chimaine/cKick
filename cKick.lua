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
end)

-- ----------------------------------------------------

local LSM = LibStub( "LibSharedMedia-3.0" )
LSM:Register( "statusbar", "darkborder", "Interface\\Addons\\cKick\\media\\darkborder.tga" ) 

-- ----------------------------------------------------

local bars = {};

-- ----------------------------------------------------
-- Event Handler

function internal:OnSlashCmd( cmd )
	self:Log( "INFO", "SlashCMD: " .. cmd )
	
	local arg1, arg2, arg3 = strsplit( " ", cmd )	
	if ( arg1 == "target" ) then
		if ( arg2 == "set" ) then
			self:SetTarget( "target" )
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
	
	--self:RAID_ROSTER_UPDATE()
	--events:RegisterEvent("CHAT_MSG_ADDON")
	--events:RegisterEvent("RAID_ROSTER_UPDATE")
	events:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" )
	
	bars.Silenced:Start( 10, false )
		
	events:UnregisterEvent( "PLAYER_LOGIN" )
end

function internal:COMBAT_LOG_EVENT_UNFILTERED( ... )
	local event = select( 2, ... );
	if ( event == "SPELL_CAST_SUCCESS" ) then 
		self:SPELL_CAST_SUCCESS( ... ) end
	if ( event == "SPELL_INTERRUPT" ) then 
		self:SPELL_INTERRUPT( ... ) end
end

function internal:SPELL_CAST_SUCCESS( timestamp, event, hideCaster, 
									  sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
									  destGUID, destName, destFlags, destRaidFlags, 
									  spellID, spellName, spellSchool )
	self:Log( "DEBUG", sourceGUID .. " casted " .. spellID .. ":" .. spellName )
	
	if ( bit.band( sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER ) > 0 ) then
		return end
	
	
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
	
	bars.Silenced:Start( spellInfo.CounterDuration, false )
end

-- ----------------------------------------------------
-- Player management

internal.Players = {
	Count = 0,
}

function internal:AddPlayer( unitID )
	local guid = UnitGUID( unitID )
	local className, classID, raceName, raceID, gender, name, realm = GetPlayerInfoByGUID( guid )
	
	self.Players[guid] = {
		["Name"] = name,
		["Realm"] = realm,
		["Class"] = classID,
		["Race"] = raceID,
		["Cooldown"] = 0,
	}
	self.Players.Count = self.Players.Count + 1;
end

function internal:RemovePlayer( unitID )
	local guid = UnitGUID( unitID )
	self.Players[guid] = nil
end

-- ----------------------------------------------------
-- Target management

internal.Target = nil;

function internal:SetTarget( unitID )
	local guid, name = UnitGUID( unitID ), UnitName( unitID )
	
	self:Log( "DEBUG", "Adding target: " .. unitID )
	
	self.Target = {
		["Name"] = name,
		["GUID"] = guid,
		["Rotation"] = {},
	}
end

-- ----------------------------------------------------
-- Layout


function internal:SetupAnchor()
	-- Anchor
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
	
	-- Buttons
	
	self.Anchor = anchor
end

function internal:CreateSilenceBar()
	local bar = self:CreateBar( 200, 18 )
	bar:SetParent( self.Anchor )
	bar:SetPoint( "TOP", self.Anchor, "BOTTOM" )
	bar:SetLabel( "Silence" )
	bar:SetTextStyle( LSM:Fetch( "font", "Friz Quadrata TT" ), 11 )
	bar:SetColor( .31, .41, .53 )
	bar:SetMinMaxValues( 0, 1 )
	bar:SetValue( 0 )
	
	bars.Silenced = bar;
end

_G[ADDON_NAME] = internal