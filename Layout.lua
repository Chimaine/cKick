--[[
	cKick
	Copyright(c) 2016, Tobias 'Chimaine' Rummelt, kontakt(at)rummelt-software.de
	All rights reserved
]]

local ADDON_NAME, addon = ...

-- ----------------------------------------------------

local LSM = LibStub( "LibSharedMedia-3.0" )
LSM:Register( "statusbar", "darkborder", "Interface\\Addons\\cKick\\media\\darkborder.tga" )

-- ----------------------------------------------------

local function SecondsToTimeDetail( t )
	if ( t >= 60 ) then -- 1 minute to 1 hour
		local m = floor( t / 60 )
		local s = t - ( m * 60 )
		return "%d:%02d", m, s
	elseif ( t < 10 ) then -- 0 to 10 seconds
		return "%1.1f", t
	else -- 10 seconds to one minute
		return "%.0f", floor( t + .5 )
	end
end

local function GetGroupPosition( id )
	local point = addon.DB.Points[id] or { "CENTER", UIParent, "CENTER", 0, 0 }
	return point[1], UIParent, point[3], point[4], point[5], point[6]
end

local function SaveGroupPosition( id, point )
	addon.DB.Points[id] = point
end

local function CreateAnchor( id )
	if ( not id ) then
		error( "id is nil" ) end

	local _id = id

	local anchor = CreateFrame( "Frame", "cKickGroupAnchor" .. id, UIParent )
	anchor:SetWidth( 200 )
	anchor:SetHeight( 18 )
	anchor:SetScale( 1 )
	anchor:SetAlpha( 1 )

	anchor:SetMovable( 1 )
	anchor:EnableMouse( 1 )
	anchor:SetUserPlaced( 0 )
	anchor:SetClampedToScreen( 1 )

	anchor:SetPoint( GetGroupPosition( _id ) )

	anchor:SetScript( "OnMouseDown", function()
		anchor:StartMoving()
	end )
	anchor:SetScript( "OnMouseUp", function()
		anchor:StopMovingOrSizing()
		SaveGroupPosition( _id, { anchor:GetPoint() } )
	end )

	local label = anchor:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmallOutline" )
	label:SetPoint( "CENTER", anchor, 0, 0 )
	label:SetFont( LSM:Fetch( "font", "Friz Quadrata TT" ), 11, select( 3, label:GetFont() ) )

	function anchor:SetLabel( text )
		label:SetText( text )
	end

	return anchor
end

local function CreateBar( width, height )
	local instance = {}

	local _enabled = true
	local _duration = 0
	local _remaining = 0
	local _expires = 0
	local _isRunning = false
	local _hideOnStop = false

	local _bar = CreateFrame( "Frame", nil, UIParent )
	_bar:SetWidth( width )
	_bar:SetHeight( height )
	_bar:SetScale( 1 )
	_bar:SetAlpha( 1 )

	local _statusbar = CreateFrame( "StatusBar", nil, _bar )
	_statusbar:SetAllPoints()
	_statusbar:SetStatusBarTexture( LSM:Fetch( "statusbar", "darkborder" ) )

	local _bg = _statusbar:CreateTexture( nil, "BACKGROUND" )
	_bg:SetAllPoints()
	_bg:SetTexture( LSM:Fetch( "statusbar", "darkborder" ) )
	_bg:SetVertexColor( 0.5, 0.5, 0.5, 0.5 )

	local _timer = _statusbar:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmallOutline" )
	_timer:SetPoint( "RIGHT", _statusbar, -2, 0 )

	local _label = _statusbar:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmallOutline" )
	_label:SetPoint( "LEFT", _statusbar, 2, 0 )
	_label:SetPoint( "RIGHT", _statusbar, -2, 0 )
	_label:SetTextColor( 1, 1, 1, 1 )
	_label:SetJustifyH( "CENTER" )
	_label:SetJustifyV( "MIDDLE" )

	local _arrowLeft = _statusbar:CreateTexture( nil, "OVERLAY" )
	_arrowLeft:SetPoint( "RIGHT", _statusbar, "LEFT", 0, 0 )
	_arrowLeft:SetTexture( "Interface\\Addons\\cKick\\media\\arrowLeft.tga" )
	_arrowLeft:SetVertexColor( 1, .1, .1 )
	_arrowLeft:SetWidth( height )
	_arrowLeft:SetHeight( height )
	_arrowLeft:Hide()

	local _arrowRight = _statusbar:CreateTexture( nil, "OVERLAY" )
	_arrowRight:SetPoint( "LEFT", _statusbar, "RIGHT", 0, 0 )
	_arrowRight:SetTexture( "Interface\\Addons\\cKick\\media\\arrowRight.tga" )
	_arrowRight:SetVertexColor( 1, .1, .1 )
	_arrowRight:SetWidth( height )
	_arrowRight:SetHeight( height )
	_arrowRight:Hide()

	-- ----------------------------------------------------

	local function OnUpdate()
		local t = GetTime()
		if ( t >= _expires ) then
			_statusbar:SetValue( 0 )
			instance:Stop()
		else
			_remaining = _expires - t
			_statusbar:SetValue( _remaining )
			_timer:SetFormattedText( SecondsToTimeDetail( _remaining ) )
		end
	end

	local function OnUpdateInverted()
		local t = GetTime()
		if ( t >= _expires ) then
			_statusbar:SetValue( _duration )
			instance:Stop()
		else
			_remaining = _expires - t
			_statusbar:SetValue( _duration - _remaining )
			_timer:SetFormattedText( SecondsToTimeDetail( _remaining ) )
		end
	end

	-- ----------------------------------------------------

	function instance:GetFrame()
		return _bar
	end

	function instance:IsRunning()
		return _isRunning
	end

	function instance:IsEnabled()
		return _enabled
	end

	function instance:Remaining()
		return _remaining
	end

	function instance:Start( duration, invert, hideOnStop )
		if ( not _enabled ) then
			error( "Bar is not enabled" ) end

		_duration = duration
		_remaining = duration
		_expires = GetTime() + duration
		_hideOnStop = hideOnStop or false

		_statusbar:SetMinMaxValues( 0, duration )

		if ( invert ) then
			_statusbar:SetValue( 0 )
		end

		_bar:SetScript( "OnUpdate", ( invert and OnUpdateInverted ) or OnUpdate )
		_bar:Show()

		_timer:Show()

		_isRunning = true
	end

	function instance:Stop( hide )
		if ( not _enabled ) then
			error( "Bar is not enabled" ) end

		if ( hide or _hideOnStop ) then
			bar:Hide()
		end

		_duration = 0
		_remaining = 0
		_expires = 0
		_hideOnStop = false

		_bar:SetScript( "OnUpdate", nil )
		_timer:Hide()

		_isRunning = false
	end

	function instance:SetEnabled( flag )
		_enabled = flag
		if ( _enabled ) then
			_bar:Show()
		else
			_bar:Hide()
			instance:HideArrows()
		end
	end

	function instance:SetLabel( text )
		_label:SetText( text )
	end

	function instance:SetMinMaxValues( min, max )
		_statusbar:SetMinMaxValues( min, max )
	end

	function instance:SetValue( value )
		_statusbar:SetValue( value )
	end

	function instance:SetTextStyle( font, size, flags )
		local curFont, curSize, curFlags = _label:GetFont()
		_label:SetFont( font or curFont, size or curSize, flags or curFlags )

		curFont, curSize, curFlags = _timer:GetFont()
		_timer:SetFont( font or curFont, size or curSize, flags or curFlags )
	end

	function instance:SetColor( r, g, b, a )
		_statusbar:SetStatusBarColor( r, g, b, a )
	end

	function instance:SetParent( parent )
		_bar:SetParent( parent )
	end

	function instance:SetPoint( from, relative, to, x, y )
		_bar:SetPoint( from, relative, to, x, y )
	end

	function instance:ShowArrows()
		_arrowLeft:Show()
		_arrowRight:Show()
	end

	function instance:HideArrows()
		_arrowLeft:Hide()
		_arrowRight:Hide()
	end

	function instance:SetHeight( height )
		_bar:SetHeight( height )
	end

	return instance
end

local function CreateLockoutBar( parent )
	local bar = CreateBar( 200, 18 )
	bar:SetParent( parent )
	bar:SetPoint( "TOP", parent, "BOTTOM", 0, 0 )
	bar:SetTextStyle( LSM:Fetch( "font", "Friz Quadrata TT" ), 11 )
	bar:SetColor( .31, .41, .53 )

	bar:SetMinMaxValues( 0, 1 )
	bar:SetValue( 0 )

	bar:SetLabel( "Lockout" )

	return bar
end

function addon:CreateGroup( id )
	local instance = {}

	local _anchor = CreateAnchor( id )
	local _lockoutBar = CreateLockoutBar( _anchor )
	local _bars = {}

	function instance:SetLabel( label )
		_anchor:SetLabel( label )
	end

	function instance:StartLockout( duration )
		_lockoutBar:Start( duration, false, false )
	end

	function instance:ShowLockoutBar( flag )
		_lockoutBar:SetEnabled( flag )
		instance:UpdateLayout()
	end

	function instance:GetBar( id, dontCreate )
		local bar = _bars[id]
		if ( bar or dontCreate ) then
			return bar end

		local spacing = ( ( 18 + 1 ) * ( id - 1 ) ) + 3
		if ( _lockoutBar:IsEnabled() ) then
			spacing = spacing + 18 + 1
		end

		bar = CreateBar( 200, 18 )
		bar:SetParent( _anchor )
		bar:SetPoint( "TOP", _anchor, "BOTTOM", 0, -spacing )
		bar:SetTextStyle( LSM:Fetch( "font", "Friz Quadrata TT" ), 11 )

		bar:SetMinMaxValues( 0, 1 )
		bar:SetValue( 1 )

		_bars[id] = bar
		return bar
	end

	function instance:UpdateLayout()
		for i, bar in next, _bars do
			local spacing = ( ( 18 + 1 ) * ( i - 1 ) ) + 3
			if ( _lockoutBar:IsEnabled() ) then
				spacing = spacing + 18 + 1
			end
			bar:SetPoint( "TOP", _anchor, "BOTTOM", 0, -spacing )
		end
	end

	function instance:HideAllBars()
		for i, bar in ipairs( _bars ) do
			bar:SetEnabled( false )
		end
	end

	function instance:Show()
		_anchor:Show()
	end

	function instance:Hide()
		_anchor:Hide()
	end

	instance:ShowLockoutBar( false )

	return instance
end

function addon:CreateWarningText()
	if ( cKickTextWarning ) then
		error() end

	local frame = CreateFrame( "Frame", "cKickTextWarning", UIParent )
	frame:Hide()
	frame:SetFrameStrata( "HIGH" )
	frame:SetToplevel( true )
	frame:SetWidth( 512 )
	frame:SetHeight( 35 )
	frame:SetPoint( "BOTTOM", "SpellActivationOverlayFrame", "TOP", 0, 100 )

	local fontStr = frame:CreateFontString( nil, "ARTWORK", "GameFontNormalHuge" )
	fontStr:SetPoint( "TOP" )
	fontStr:SetWidth( 800 )
	fontStr:SetJustifyH( "CENTER" )
	--text:SetJustifyV( "MIDDLE" )

	local fadeAnimGrp = frame:CreateAnimationGroup()
	local fadeAnim = fadeAnimGrp:CreateAnimation( "Alpha" )
	fadeAnim:SetDuration( 2 )
	fadeAnim:SetFromAlpha( 1 )
	fadeAnim:SetToAlpha( 0 )
	fadeAnim:SetScript( "OnFinished", function() frame:Hide() end )

	function frame:ShowText( text, holdTime, fadeTime )
		fontStr:SetText( text )
		fadeAnim:SetStartDelay( holdTime )
		fadeAnim:SetDuration( fadeTime )
		frame:Show()
		fadeAnimGrp:Play()
		PlaySound( "RaidWarning" )
	end

	return frame
end