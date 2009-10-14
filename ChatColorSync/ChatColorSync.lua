
-- Copyright (c) 2009, Sven Kirmess

local Version = 5
local Loaded = false

local function log(msg)

	if ( msg == nil ) then
		return
	end

	DEFAULT_CHAT_FRAME:AddMessage("ChatColorSync: "..msg)
end

--
-- Remove the zone suffix from a channel, if present, and return
-- its geenric name.
--
-- Input: "General - Ironforge"
-- Output: "General"
--
local function GetChannelGenericName(name)

	local i, j = string.find(name, " ")

	if ( i == nil ) then
		-- No whitespace in channel name found
		return name
	end

	local genericName = string.sub(name, 1, i - 1)

	return genericName
end

local function GetChannelNameByTypeName(chatType)

	local channelNumber, count = string.gsub(chatType, "CHANNEL", "")

	if ( count == 0 ) then
		-- The chatType is not a CHANNEL<nr> channel
		return chatType
	end

	if ( count > 1 ) then
		-- should never happen
		log("Could not understand chatType '"..chatType.."'.")
		return
	end

	-- CHANNEL1 -> 1
	local cid = tonumber(channelNumber)

	if ( cid == nil ) then
		log("Could not get channel id from chatType '"..chatType.."'.")
		return
	end

	local id, name = GetChannelName(cid)
	if ( not name ) then
		log("GetChannelName() failed for chatType '"..chatType.."'.")
		return
	end

	name = GetChannelGenericName(name)

	return name
end

local function SaveChannelColorToDB(index, r, g, b)

	if ( ChatColorSync[index] == nil ) then
		ChatColorSync[index] = { }
	end

	ChatColorSync[index].r = r
	ChatColorSync[index].g = g
	ChatColorSync[index].b = b
end

local function GetChatTypeInfo(chatType)

	if ( ( ChatTypeInfo[chatType] == nil ) or
	     ( not ChatTypeInfo[chatType].r ) or
	     ( not ChatTypeInfo[chatType].g ) or
	     ( not ChatTypeInfo[chatType].b ) ) then
		log("Retrieving information for chat channel '"..chatType.."' failed.")

		return
	end

	local r = math.floor(ChatTypeInfo[chatType].r * 255)
	local g = math.floor(ChatTypeInfo[chatType].g * 255)
	local b = math.floor(ChatTypeInfo[chatType].b * 255)

	return r, g, b
end

local function SynchronizeChannelColorWithDB(chatType, name)

	local r, g, b = GetChatTypeInfo(chatType)

	if ( not r or not g or not b ) then
		return
	end

	if ( ( not ChatColorSync[name] ) or
	     ( not ChatColorSync[name].r) or
	     ( not ChatColorSync[name].g) or
	     ( not ChatColorSync[name].b) ) then

		if ( ChatColorSync[name] ) then
			log("Broken entry in SavedVariables.lua detected for channel '"..name.."'. Removing the broken entry.")

			ChatColorSync[name] = nil
		end

		-- There is no entry in the DB yet.
		SaveChannelColorToDB(name, r, g, b)

		return
	end

	if ( ( r and ( r ~= ChatColorSync[name].r ) ) or
	     ( g and ( g ~= ChatColorSync[name].g ) ) or
	     ( b and ( b ~= ChatColorSync[name].b ) ) ) then

		log(string.format("Setting color for channel '%s' to %i/%i/%i",
			name,
			ChatColorSync[name].r,
			ChatColorSync[name].g,
			ChatColorSync[name].b)
		)

		ChangeChatColor(
			chatType,
			ChatColorSync[name].r / 255,
			ChatColorSync[name].g / 255,
			ChatColorSync[name].b / 255
		)

		return
	end

	-- Channel color is already in sync with database
end

local function SyncAllChannels()

	-- Sync the 10 custom channels
	local i
	for i=1,10 do
		local id, name = GetChannelName(i)
		if ( ( id > 0 ) and ( name ~= nil ) ) then
			name = GetChannelGenericName(name)

			SynchronizeChannelColorWithDB("CHANNEL"..id, name)
		end
	end

	-- Sunc all other channels
	local channelsToSync = {

		-- Player Messages
		"SAY",
		"EMOTE",
		"TEXT_EMOTE",
		"YELL",
		"GUILD",
		"OFFICER",
		"WHISPER",
		"WHISPER_INFORM",
		"PARTY",
		"MONSTER_PARTY",
		"RAID",
		"RAID_LEADER",
		"RAID_WARNING",
		"BATTLEGROUND",
		"BATTLEGROUND_LEADER",

		-- Creature Messages
		"MONSTER_SAY",
		"MONSTER_EMOTE",
		"MONSTER_YELL",
		"MONSTER_WHISPER",
		"RAID_BOSS_EMOTE",
		"RAID_BOSS_WHISPER",

		-- Combat
		"COMBAT_XP_GAIN",
		"COMBAT_HONOR_GAIN",
		"COMBAT_FACTION_CHANGE",
		"SKILL",
		"LOOT",
		"MONEY",
		"TRADESKILLS",
		"OPENING",
		"PET_INFO",
		"COMBAT_MISC_INFO",

		-- PvP
		"BG_SYSTEM_HORDE",
		"BG_SYSTEM_ALLIANCE",
		"BG_SYSTEM_NEUTRAL",

		-- Other
		"SYSTEM",
		"RESTRICTED",
		"FILTERED",
		"AFK",
		"DND",
		"IGNORED"
	}

	local x, chatType
	for x, chatType in pairs(channelsToSync)
	do
		SynchronizeChannelColorWithDB(chatType, chatType)
	end
end

local function CHAT_MSG_CHANNEL_NOTICE(eventType, channelType, channelNumber, channelName)

	if ( not eventType or not channelType or not channelNumber or not channelName ) then
		log("Ignoring malformed CHAT_MSG_CHANNEL_NOTICE event.")
		return
	end

	if ( eventType == "YOU_JOINED" ) then
		local name = GetChannelGenericName(channelName)

		SynchronizeChannelColorWithDB("CHANNEL"..channelNumber, name)
	end
end

local function UPDATE_CHAT_COLOR(chatType, r, g, b)

	if ( not chatType or not r or not g or not b ) then
		log("Ignoring malformed UPDATE_CHAT_COLOR event.")
		return
	end

	local index = GetChannelNameByTypeName(chatType)

	if ( index == nil ) then
		return
	end

	-- local r, g, b = GetChatTypeInfo(chatType)
	local r = math.floor(r * 255)
	local g = math.floor(g * 255)
	local b = math.floor(b * 255)

	SaveChannelColorToDB(index, r, g, b)
end

local function EventHandler(self, event, ...)

	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 = ...

	if ( event == "PLAYER_ENTERING_WORLD" ) then

		if ( ( not Loaded ) and
		     ( ChatColorSync == nil ) ) then
			ChatColorSync = { }
		end

		self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
		self:RegisterEvent("UPDATE_CHAT_COLOR")

		if ( not Loaded ) then
			SyncAllChannels()

			log(string.format("Version %i loaded.", Version))
			Loaded = true
		end

	elseif ( event == "PLAYER_LEAVING_WORLD" ) then

		self:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")
		self:UnregisterEvent("UPDATE_CHAT_COLOR")

	elseif ( event == "CHAT_MSG_CHANNEL_NOTICE" ) then

		-- Fired when you enter or leave a chat channel (or a channel was
		-- recently throttled)
		--
		-- arg1		type
		--		"YOU_JOINED" if you joined a channel
		--		"YOU_LEFT" if you left
		--		"THROTTLED" if channel was throttled
		--
		-- arg4		Channel name with number (e.g. "6. TestChannel")
		--
		-- arg7		Channel Type (e.g. 0 for any user channel,
		--		1 for system-channel "General", 2 for "Trade")
		--
		-- arg8		Channel Number
		--
		-- arg9		Channel name without number

		CHAT_MSG_CHANNEL_NOTICE(arg1, arg7, arg8, arg9)

	elseif ( event == "UPDATE_CHAT_COLOR" ) then

		-- Fired when the chat colour needs to be updated. Refer to the
		-- ChangeChatColor API call for details on the parameters.
		--
		-- arg1		Chat type
		--
		-- arg2		red
		--
		-- arg3		green
		--
		-- arg4		blue

		UPDATE_CHAT_COLOR(arg1, arg2, arg3, arg4)
	end
end

-- main
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", EventHandler)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")

