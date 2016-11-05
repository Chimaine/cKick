local ADDON_NAME, internal = ...
local DB_NAME = "cKick_Settings"

-- ----------------------------------------------------

internal.DBVersion = 1

function internal:GetDefaultSettings() 
	return {	
		DBVersion = 1,
		
		scale = 1,
		point = { "CENTER", UIParent, "CENTER", 0, 0 },
		
		barWidth = 150,
		barHeight = 15,
		barSpacing = 1,
		barTexture = "darkborder",
		
		barColor = { .31, .41, .53 },
		classColor = false,
		
		fontSize = 10,
		fontFace = "Friz Quadrata TT",	
	}
end

function internal:ReadSettings()
	local db = _G[DB_NAME]
	if ( not db ) then
		self:Log( "DEBUG", "Creating new DB" )
		db = self:GetDefaultSettings()
		_G[DB_NAME] = db
	end
	
	if ( ( not db.DBVersion ) or ( self.DBVersion > db.DBVersion ) ) then
		-- TODO
		self:Log( "DEBUG", "Upgrading DB from version", db.DBVersion, "to", self.DBVersion )
		db = self:GetDefaultSettings()
		_G[DB_NAME] = db
	end
	
	self.DB = db
end