-- cKick Bar Module by Chimaine
-- Simple bar module, ripped and modified from LibCandyBar-3.0

local ADDON_NAME, internal = ...

-- ----------------------------------------------------

local LSM = LibStub( "LibSharedMedia-3.0" )

-- ----------------------------------------------------

-- Time formatting
local tformat1 = "%d:%02d"
local tformat2 = "%1.1f"
local tformat3 = "%.0f"

local function SecondsToTimeDetail( t )
	if ( t >= 60 ) then -- 1 minute to 1 hour
		local m = floor( t / 60 )
		local s = t - ( m * 60 )
		return tformat1, m, s
	elseif ( t < 10 ) then -- 0 to 10 seconds
		return tformat2, t
	else -- 10 seconds to one minute
		return tformat3, floor( t + .5 )
	end
end

local nextBarID = 1

function internal:CreateBar( width, height )
	local bar = CreateFrame( "Frame", nil, UIParent )
	
	bar:SetWidth( width )
	bar:SetHeight( height )
	
	bar.ID = nextBarID
	nextBarID = nextBarID + 1
	
	bar.duration = 0
	bar.remaining = 0
	bar.exp = 0
	bar.isRunning = false
	bar.hideOnStop = false
	
	bar:SetScale(1)
	bar:SetAlpha(1)

	local statusbar = CreateFrame( "StatusBar", nil, bar )
	statusbar:SetAllPoints()
	statusbar:SetStatusBarTexture( LSM:Fetch( "statusbar", "darkborder" ) )
	--bar.StatusBar = statusbar
	
	local bg = statusbar:CreateTexture( nil, "BACKGROUND" )
	bg:SetAllPoints()
	bg:SetTexture( LSM:Fetch( "statusbar", "darkborder" ) )
	bg:SetVertexColor( 0.5, 0.5, 0.5, 0.5 )
	--bar.Background = bg
	
	local timer = statusbar:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmallOutline" )
	timer:SetPoint( "RIGHT", statusbar, -2, 0 )
	--bar.Timer = timer
	
	local label = statusbar:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmallOutline" )
	label:SetPoint( "LEFT", statusbar, 2, 0 )
	label:SetPoint( "RIGHT", statusbar, -2, 0 )
	label:SetTextColor( 1,1,1,1 )
	label:SetJustifyH( "CENTER" )
	label:SetJustifyV( "MIDDLE" )
	--bar.Label = label
	
	local arrowLeft = statusbar:CreateTexture( nil, "OVERLAY" )
	arrowLeft:SetPoint( "RIGHT", statusbar, "LEFT", 0, 0 )
	arrowLeft:SetTexture( "Interface\\Addons\\cKick\\media\\arrowLeft.tga" )
	arrowLeft:SetVertexColor( 1, .1, .1 )
	arrowLeft:SetWidth( height )
	arrowLeft:SetHeight( height )
	arrowLeft:Hide()
	--bar.arrowLeft = arrowLeft
	
	local arrowRight = statusbar:CreateTexture( nil, "OVERLAY" )
	arrowRight:SetPoint( "LEFT", statusbar, "RIGHT", 0, 0 )
	arrowRight:SetTexture( "Interface\\Addons\\cKick\\media\\arrowRight.tga" )
	arrowRight:SetVertexColor( 1, .1, .1 )
	arrowRight:SetWidth( height )
	arrowRight:SetHeight( height )
	arrowRight:Hide()
	--bar.arrowRight = arrowRight
	
	function bar:BarOnUpdate()
		local t = GetTime()
		if ( t >= self.exp ) then
			statusbar:SetValue( 0 )
			self:Stop()
		else
			self.remaining = self.exp - t
			statusbar:SetValue( self.remaining )
			timer:SetFormattedText( SecondsToTimeDetail( self.remaining ) )
		end
	end
	
	function bar:BarOnUpdateInvert()
		local t = GetTime()
		if ( t >= self.exp ) then
			statusbar:SetValue( self.duration )
			self:Stop()
		else
			self.remaining = self.exp - t
			statusbar:SetValue( self.duration - self.remaining )
			timer:SetFormattedText( SecondsToTimeDetail( self.remaining ) )
		end
	end
	
	function bar:ShowArrows()
		arrowLeft:Show()
		arrowRight:Show()
	end
	
	function bar:HideArrows()
		arrowLeft:Hide()
		arrowRight:Hide()
	end
	
	function bar:IsArrowShown()
		if ( arrowLeft:IsShown() and arrowRight:IsShown() ) then
			return true
		end
	end

	function bar:SetLabel( text )
		label:SetText( text )
	end
	
	function bar:SetTextStyle( modFont, modSize, modFlags )
		local font, size, flags = label:GetFont()
		label:SetFont( modFont or font, modSize or size, modFlags or flags )
		
		font, size, flags = timer:GetFont()
		timer:SetFont( modFont or font, modSize or size, modFlags or flags )
	end
	
	function bar:SetColor( r, g, b, a )
		statusbar:SetStatusBarColor( r, g, b, a )
	end
	
	function bar:Start( duration, invert, hideOnStop)
		internal:Log( "DEBUG", "Starting bar: " .. self.ID )
		
		self.duration = duration
		self.remaining = duration
		self.exp = GetTime() + duration
		self.hideOnStop = hideOnStop
		
		statusbar:SetMinMaxValues( 0, duration )

		self:SetScript( "OnUpdate", invert and self.BarOnUpdateInvert or self.BarOnUpdate )
		timer:Show()
		
		self:Show()
		
		self.isRunning = true
	end
	
	function bar:Stop( hide )
		if ( hide or self.hideOnStop ) then
			self:Hide()
		end
		
		self.duration = 0
		self.remaining = 0
		self.exp = 0
		self.hideOnStop = false
		
		self:SetScript("OnUpdate", nil)
		timer:Hide()
		
		self.isRunning = false
	end
	
	function bar:SetMinMaxValues( min, max )
		statusbar:SetMinMaxValues( min, max )
	end
	
	function bar:SetValue( value )
		statusbar:SetValue( 0 )
	end
	
	return bar
end

