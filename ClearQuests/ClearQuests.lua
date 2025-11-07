-- Load AceConfig-3.0
ClearQuests = LibStub("AceAddon-3.0"):NewAddon("ClearQuests")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local CQ = ClearQuests
local function tableContains(tbl, val) for _, entry in pairs(tbl) do if entry == val then return true end end end

-- Helper function to determine if a quest is trivial
local function isQuestTrivial(playerLevel, questLevel) return playerLevel >= (questLevel or 0) + 10 end

-- Helper function to check if a quest should be kept based on type and settings
local function shouldKeepQuest(titleText, level, questTag, isComplete, isDaily, options, playerLevel)
	-- Always keep these special quests regardless of settings
	if titleText:match("Prestige") or titleText:match("Mentorship") then return true end

	-- Check if quest is trivial (more than 10 levels below player)
	local trivial = isQuestTrivial(playerLevel, level)

	-- Path to Ascension quests
	local isPathToAscension = titleText:match("Path to Ascension")
	if options.keepAscension and isPathToAscension then return true end

	-- Completed quests
	if options.keepComplete and isComplete == 1 then
		-- Keep if non-trivial OR if keeping trivial completed is enabled
		if not trivial or options.keepTrivialComplete then return true end
	end

	-- Daily quests
	if options.keepDaily and isDaily == 1 then return true end

	-- Dungeon quests
	if options.keepDungeon and questTag == "Dungeon" then
		-- Keep if non-trivial OR if keeping trivial dungeons is enabled
		if not trivial or options.keepTrivialDungeon then return true end
	end

	-- Whitelist check
	if tableContains(options.whitelist, titleText) then return true end

	return false
end

-- Clear the quest log
function CQ:ClearQuests()
	local options = self.db.global
	local playerLevel = UnitLevel("player")

	for i = 1, GetNumQuestLogEntries() do
		local titleText, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i)

		-- Skip headers and invalid entries
		if titleText and not isHeader then
			local keepQuest = shouldKeepQuest(titleText, level, questTag, isComplete, isDaily, options, playerLevel)

			if not keepQuest then
				SelectQuestLogEntry(i)
				SetAbandonQuest()
				AbandonQuest()
			end
		end
	end
end

-- Function to open the Whitelist management window
local function OpenWhitelistWindow()
	local AceGUI = LibStub("AceGUI-3.0")
	AceConfigDialog:Close("ClearQuests")
	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Manage Whitelist")
	frame:SetLayout("Flow")
	frame:SetWidth(400)
	frame:SetHeight(300)

	local dropdownlist = AceGUI:Create("Dropdown")
	dropdownlist:SetLabel("Select Quest")
	dropdownlist:SetWidth(300)
	frame:AddChild(dropdownlist)
	tablelist = {}
	for i = 1, GetNumQuestLogEntries() do
		local title, _, _, _, isHeader, _, _, questID = GetQuestLogTitle(i)
		if title and not isHeader then table.insert(tablelist, title) end
	end
	dropdownlist:SetList(tablelist)
	local addButton = AceGUI:Create("Button")
	local list = AceGUI:Create("MultiLineEditBox")

	addButton:SetText("Add")
	addButton:SetWidth(100)
	addButton:SetCallback("OnClick", function()
		local dropdownIndex = dropdownlist:GetValue()
		local newString = tablelist[dropdownIndex]
		if newString and newString ~= "" then
			table.insert(CQ.db.global.whitelist, newString)
			list:SetText(table.concat(CQ.db.global.whitelist, "\n"))
		end
	end)
	frame:AddChild(addButton)

	list:SetLabel("Whitelist")
	list:SetWidth(380)
	list:SetHeight(150)
	list:SetText(table.concat(CQ.db.global.whitelist, "\n"))
	list:SetFullHeight(true)
	list:SetCallback("OnEnterPressed", function(widget, event, text)
		-- Update the list when Enter is pressed
		CQ.db.global.whitelist = {}
		for line in text:gmatch("[^\r\n]+") do table.insert(CQ.db.global.whitelist, line) end
	end)
	frame:AddChild(list)

	frame:SetCallback("OnClose", function(widget)
		AceConfigDialog:Open("ClearQuests") -- Refresh the options when the window is closed
	end)

	frame:Show()
end

local defaults = {
	global = {
		keepComplete = true,
		keepDaily = true,
		keepDungeon = true,
		keepTrivialDungeon = false,
		keepTrivialComplete = false,
		keepAscension = true,
		whitelist = {}
	}
}

local OptionsTable = {
	type = "group",
	get = function(info) return CQ.db.global[info[#info]] end,
	set = function(info, val) CQ.db.global[info[#info]] = val end,
	args = {
		run = {
			name = "Clear Quests",
			type = "execute",
			func = function(msg) CQ:ClearQuests() end,
			desc = "Runs the script to clear your quest log. Respects the options set below",
			order = 1
		},
		description = {
			name = "Will always keep mentorship quest and prestige quest when clearing the quest log. Set the options below to include other types of quests which you would like to keep.",
			type = "description",
			width = "full",
			order = 2
		},
		optionheader = {
			name = "Options",
			type = "header",
			order = 3
		},
		keepComplete = {
			name = "Keep Complete",
			desc = "Keep non-trivial quests marked as complete.",
			type = "toggle",
			order = 11
		},
		keepDaily = {
			name = "Keep Daily",
			desc = "Keep quests marked as daily.",
			type = "toggle",
			order = 12
		},
		keepDungeon = {
			name = "Keep Dungeon",
			desc = "Keep non-trivial dungeon quests.",
			type = "toggle",
			order = 13
		},
		keepTrivialDungeon = {
			name = "Keep Trivial Dungeon",
			desc = "Keep dungeon quests more than 9 levels below your level.",
			type = "toggle",
			order = 14
		},
		keepTrivialComplete = {
			name = "Keep Trivial Completed",
			desc = "Keep completed quests more than 9 levels below your level.",
			type = "toggle",
			order = 15
		},
		keepAscension = {
			name = "Keep Path to Ascension",
			desc = "Keep quests related to the Path to Ascension.",
			type = "toggle",
			order = 16
		},
		manageCustomStrings = {
			name = "Manage Whitelist",
			type = "execute",
			width = "full",
			func = OpenWhitelistWindow,
			order = 17
		}
	}
}

AceConfig:RegisterOptionsTable("ClearQuests", OptionsTable)
AceConfigDialog:AddToBlizOptions("ClearQuests")

function CQ:OnInitialize() self.db = AceDB:New("CQOptions", defaults, true) end

SLASH_CLEARQUESTS1 = "/cq"
SLASH_CLEARQUESTS2 = "/clearquests"
SlashCmdList["CLEARQUESTS"] = function(msg)
	AceConfigDialog:SetDefaultSize("ClearQuests", 400, 310)
	AceConfigDialog:Open("ClearQuests")
end
