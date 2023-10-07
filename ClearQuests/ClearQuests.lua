-- Load AceConfig-3.0
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local CQ = LibStub("AceAddon-3.0"):GetAddon("ClearQuests")

local function tableContains(tbl, val)
	for _, entry in pairs(tbl) do
		if entry == val then return true end
	end
end

function CQ:ClearQuests()
	-- Clear the quest log
	local options = self.db.global

	local keepComplete = options.keepComplete
	local keepDaily = options.keepDaily
	local keepDungeon = options.keepDungeon
	local keepTrivialDungeon = options.keepTrivialDungeon
	local keepTrivialComplete = options.keepTrivialComplete
	local whitelist = options.whitelist

	local playerLevel = UnitLevel("player")

	for i=1,GetNumQuestLogEntries() do
		local titleText,
		level,
		questTag,
		suggestedGroup,
		isHeader,
		isCollapsed,
		isComplete,
		isDaily,
		questID = GetQuestLogTitle(i) 

		local valid = titleText and not isHeader
		local trivial = playerLevel >= (level or 0) + 10
		local validComplete = (keepTrivialComplete and trivial) or (not trivial)
		local validDungeon = (keepTrivialDungeon and trivial) or (not trivial)
	
		local Keep = titleText:match("Prestige")
		or titleText:match("Mentorship")
		or (keepComplete and isComplete == 1 and validComplete)
		or (keepDaily and isDaily == 1)
		or (keepDungeon and questTag == "Dungeon" and validDungeon)
		or tableContains(whitelist, titleText)
		
		if valid
		and not Keep then
			SelectQuestLogEntry(i)
			SetAbandonQuest()
			AbandonQuest()      
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
		if title and not isHeader then
				table.insert(tablelist, title)
		end
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
			for line in text:gmatch("[^\r\n]+") do
					table.insert(CQ.db.global.whitelist, line)
			end
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
			whitelist = {}
	}
}

local OptionsTable = {
	type = "group",
	get =  function(info) return CQ.db.global[info[#info]] end,
	set =  function(info,val) CQ.db.global[info[#info]] = val end,
	args = {
		run = {
			name = "Clear Quests",
			type = "execute",
			func = function(msg) CQ:ClearQuests() end,
			desc = "Runs the script to clear your quest log. Respects the options set below",
			order = 1,
		},
		description = {
			name = "Will always keep mentorship quest and prestige quest when clearing the quest log. Set the options below to include other types of quests which you would like to keep.",
			type = "description",
			width = "full",
			order = 2,
		},
		optionheader = {
			name = "Options",
			type = "header",
			order = 3,
		},
		keepComplete = {
			name = "Keep Complete",
			desc = "Keep non-trivial quests marked as complete.",
			type = "toggle",
			order = 11,
		},
		keepDaily = {
			name = "Keep Daily",
			desc = "Keep quests marked as daily.",
			type = "toggle",
			order = 12,
		},
		keepDungeon = {
			name = "Keep Dungeon",
			desc = "Keep non-trivial dungeon quests.",
			type = "toggle",
			order = 13,
		},
		keepTrivialDungeon = {
			name = "Keep Trivial Dungeon",
			desc = "Keep dungeon quests more than 9 levels below your level.",
			type = "toggle",
			order = 14,
		},
		keepTrivialComplete = {
			name = "Keep Trivial Completed",
			desc = "Keep completed quests more than 9 levels below your level.",
			type = "toggle",
			order = 14,
		},
		manageCustomStrings = {
			name = "Manage Whitelist",
			type = "execute",
			width = 2,
			func = OpenWhitelistWindow,
			order = 15,
		},
	},
}

AceConfig:RegisterOptionsTable("ClearQuests", OptionsTable)
AceConfigDialog:AddToBlizOptions("ClearQuests")

function CQ:OnInitialize()
  self.db = AceDB:New("CQOptions", defaults, true)
end

SLASH_CLEARQUESTS1 = "/cq"
SLASH_CLEARQUESTS2 = "/clearquests"
SlashCmdList["CLEARQUESTS"] = function(msg)
	AceConfigDialog:SetDefaultSize("ClearQuests", 400, 310)
	AceConfigDialog:Open("ClearQuests")
end
