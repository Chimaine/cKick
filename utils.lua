local ADDON_NAME, internal = ...

internal.Title = GetAddOnMetadata( ADDON_NAME, "Title" )
internal.Version = GetAddOnMetadata( ADDON_NAME, "Version" )

-- ----------------------------------------------------

local logLevels = { ["ALL"] = 1, ["TRACE"] = 2, ["DEBUG"] = 3, ["INFO"] = 4, ["WARN"] = 5, ["ERROR"] = 6, ["NONE"] = 7 }

internal.LogLevel = "ALL"

function internal:Log( level, ... )
	local intLevel = logLevels[level];
	local maxLevel = logLevels[internal.LogLevel];
	
	if ( intLevel < maxLevel ) then
		return end

	local output = "[" .. self.Title .. "][" .. level .. "]";

	for i = 1, select( "#", ... ) do
		output = output .. " " .. tostring( select( i, ... ) );
	end

	DEFAULT_CHAT_FRAME:AddMessage( output );
end