-- cKick Bar Module by Chimaine
-- Simple bar module, inspired by LibCandyBar-3.0

local ADDON_NAME, internal = ...

-- ----------------------------------------------------

local nextBarID = 1
local LSM = LibStub( "LibSharedMedia-3.0" )

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

function internal.CreateBar( width, height )
	local instance = {}
		
	local _id = nextBarID
	local _enabled = true
	local _duration = 0
	local _remaining = 0
	local _expires = 0
	local _isRunning = false
	local _hideOnStop = false

	nextBarID = nextBarID + 1

	local _bar = CreateFrame( "Frame", "cKick_Bar_" .. _id, UIParent )	
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
	
	local function OnUpdate()
		local t = GetTime()
		if ( t >= _expires ) then
			_statusbar:SetValue( 0 )
			instance.Stop()
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
			instance.Stop()
		else
			_remaining = _expires - t
			_statusbar:SetValue( _duration - _remaining )
			_timer:SetFormattedText( SecondsToTimeDetail( _remaining ) )
		end
	end

	function instance.GetID()
		return _id
	end

	function instance.IsRunning()
		return isRunning
	end

	function instance.IsEnabled()
		return _enabled
	end
	
	function instance.Start( duration, invert, hideOnStop )
		if ( not _enabled ) then
			error( "Bar is not enabled" ) end

		internal:Log( "DEBUG", "Starting bar: " .. _id )
		
		_duration = duration
		_remaining = duration
		_expires = GetTime() + duration
		_hideOnStop = hideOnStop or false
		
		_statusbar:SetMinMaxValues( 0, duration )

		_bar:SetScript( "OnUpdate", ( invert and OnUpdateInverted ) or OnUpdate )
		_bar:Show()

		_timer:Show()		
		
		_isRunning = true
	end
	
	function instance.Stop( hide )
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

	function instance.SetEnabled( flag )
		_enabled = flag
		if ( _enabled ) then 
			_bar:Show()
		else 
			_bar:Hide()
		end
	end

	function instance.SetLabel( text )
		_label:SetText( text )
	end
	
	function instance.SetMinMaxValues( min, max )
		_statusbar:SetMinMaxValues( min, max )
	end
	
	function instance.SetValue( value )
		_statusbar:SetValue( value )
	end
	
	function instance.SetTextStyle( font, size, flags )
		local curFont, curSize, curFlags = _label:GetFont()
		_label:SetFont( font or curFont, size or curSize, flags or curFlags )
		
		curFont, curSize, curFlags = _timer:GetFont()
		_timer:SetFont( font or curFont, size or curSize, flags or curFlags )
	end
	
	function instance.SetColor( r, g, b, a )
		_statusbar:SetStatusBarColor( r, g, b, a )
	end

	function instance.SetParent( parent )
		_bar:SetParent( parent )
	end

	function instance.SetPoint( from, relative, to, x, y )
		_bar:SetPoint( from, relative, to, x, y )
	end
	
	function instance.ShowArrows()
		_arrowLeft:Show()
		_arrowRight:Show()
	end
	
	function instance.HideArrows()
		_arrowLeft:Hide()
		_arrowRight:Hide()
	end
	
	return instance
end

