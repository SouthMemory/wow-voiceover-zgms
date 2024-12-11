setfenv(1, VoiceOver)

if not select then
    function select(index, ...)
        if index == "#" then
            return arg.n
        else
            local result = {}
            for i = index, arg.n do
                table.insert(result, arg[i])
            end
            return unpack(result)
        end
    end
end

if not print or Version.IsLegacyVanilla or Version.IsLegacyBurningCrusade then
    local argn, argi
    if Version.IsLegacyVanilla then
        argn, argi = "arg.n", "arg[i]"
    else
        argn, argi = [[select("#", ...)]], [[(select(i, ...))]]
    end
    print = loadstring(format([[return function(...)
        local text = ""
        for i = 1, %s do
            text = text .. (i > 1 and " " or "") .. tostring(%s)
        end
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end]], argn, argi))()
end

if not strsplit then
    function strsplit(delimiter, text)
        local result = {}
        local from = 1
        local delim_from, delim_to = string.find(text, delimiter, from)
        while delim_from do
            table.insert(result, string.sub(text, from, delim_from - 1))
            from = delim_to + 1
            delim_from, delim_to = string.find(text, delimiter, from)
        end
        table.insert(result, string.sub(text, from))
        return unpack(result)
    end
end

if not string.gmatch then
    string.gmatch = string.gfind
end

if not string.match then
    local function getargs(s, e, ...)
        return unpack(arg)
    end
    function string.match(str, pattern)
        return getargs(string.find(str, pattern))
    end
end

if not string.trim then
    function string.trim(str)
        return (string.match(str, "^%s*(.-)%s*$"))
    end
end

if not table.wipe then
    function table.wipe(tbl)
        for key in next, tbl do
            tbl[key] = nil
        end
    end
end
if not wipe then
    wipe = table.wipe
end

if not hooksecurefunc then
    ---@overload fun(name, hook)
    function hooksecurefunc(table, name, hook)
        if not hook then
            name, hook = table, name
            table = _G
        end

        local old = table[name]
        assert(type(old) == "function")
        table[name] = function(...)
            local result = { old(unpack(arg)) }
            hook(unpack(arg))
            return unpack(result)
        end
    end
end

if not GetAddOnEnableState then
    ---@overload fun(addon)
    function GetAddOnEnableState(character, addon)
        addon = addon or character
        local name, _, _, _, loadable, reason = _G.GetAddOnInfo(addon)
        if not name or not loadable and reason == "DISABLED" then
            return 0
        end
        return 2
    end

    function GetAddOnInfo(indexOrName)
        local name, title, notes, enabled, loadable, reason, security, newVersion = _G.GetAddOnInfo(indexOrName)
        return name, title, notes, loadable, reason, security, newVersion
    end
end

if not GetQuestID then
    local source, text
    local old_QUEST_DETAIL = Addon.QUEST_DETAIL
    local old_QUEST_PROGRESS = Addon.QUEST_PROGRESS
    local old_QUEST_COMPLETE = Addon.QUEST_COMPLETE
    local GetTitleText = GetTitleText -- Store original function before EQL3 (Extended Quest Log 3) overrides it and starts prepending quest level
    function Addon:QUEST_DETAIL()   source = "accept"   text = GetQuestText()    old_QUEST_DETAIL(self) end
    function Addon:QUEST_PROGRESS() source = "progress" text = GetProgressText() old_QUEST_PROGRESS(self) end
    function Addon:QUEST_COMPLETE() source = "complete" text = GetRewardText()   old_QUEST_COMPLETE(self) end
    function GetQuestID()
        local npcName = Utils:GetNPCName()
        if Utils:IsNPCPlayer() then
            -- Can't do anything about quest sharing currently, because we need the original questgiver's name to obtain quest ID, and we need quest ID to obtain the questgiver's name
            return 0
        end

        return DataModules:GetQuestID(source, GetTitleText(), npcName, text) or 0
    end
end

if not QUESTS_DISPLAYED then
    if QuestLogScrollFrame then
        QUESTS_DISPLAYED = getn(QuestLogScrollFrame.buttons)
    end
end

-- Patch 7.3.0: New global table: SOUNDKIT - Keys are named similar to the old string names, and they hold the soundkit ID for the sound
if not SOUNDKIT or Version:IsBelowLegacyVersion(70300) then
    SOUNDKIT =
    {
        U_CHAT_SCROLL_BUTTON = "uChatScrollButton",
        IG_MAINMENU_OPEN = "igMainMenuOpen",
        IG_MAINMENU_CLOSE = "igMainMenuClose",
    }
end

-- Not sure when exactly were UI-Cursor-Move and UI-Cursor-SizeRight added, but the former was present in 6.0.1
if Version:IsBelowLegacyVersion(60000) then
    function SetCursor() end
end

-- Patch 2.4.0 (2008-03-25): Added.
if Version.IsAnyLegacy and not UnitGUID then
    -- 1.0.0 - 2.3.0
    Utils.GetGUIDType = nil
    Utils.GetIDFromGUID = nil
    Utils.MakeGUID = function() end
-- Patch 4.0.1 (2010-10-12): Bits shifted. NPCID is now characters 5-8, not 7-10 (counting from 1).
elseif Version:IsBelowLegacyVersion(40000) then
    -- 2.4.0 - 3.3.5
    Enums.GUID.Player     = tonumber("0000", 16)
    Enums.GUID.Item       = tonumber("4000", 16)
    Enums.GUID.Creature   = tonumber("F130", 16)
    Enums.GUID.Vehicle    = tonumber("F150", 16)
    Enums.GUID.GameObject = tonumber("F110", 16)

    function Utils:GetGUIDType(guid)
        return guid and tonumber(guid:sub(3, 3 + 4 - 1), 16)
    end

    function Utils:GetIDFromGUID(guid)
        local type = assert(self:GetGUIDType(guid), format([[Failed to determine the type of GUID "%s"]], guid))
        assert(Enums.GUID:GetName(type), format([[Unknown GUID type %d]], type))
        assert(Enums.GUID:CanHaveID(type), format([[GUID "%s" does not contain ID]], guid))
        return tonumber(guid:sub(7, 7 + 6 - 1), 16)
    end

    function Utils:MakeGUID(type, id)
        assert(Enums.GUID:CanHaveID(type), format("GUID of type %d (%s) cannot contain ID", type, Enums.GUID:GetName(type) or "Unknown"))
        return format("0x%04X%06X%06X", type, id, 0)
    end
-- Patch 6.0.2 (2014-10-14): Changed to a new format, e.g. for players: Player-[serverID]-[playerUID]
elseif Version:IsBelowLegacyVersion(60000) then
    -- 4.0.1 - 5.4.8
    Enums.GUID.Player     = tonumber("000", 16)
    Enums.GUID.Item       = tonumber("400", 16)
    Enums.GUID.Creature   = tonumber("F13", 16)
    Enums.GUID.Vehicle    = tonumber("F15", 16)
    Enums.GUID.GameObject = tonumber("F11", 16)

    function Utils:GetGUIDType(guid)
        return guid and tonumber(guid:sub(3, 3 + 3 - 1), 16)
    end

    function Utils:GetIDFromGUID(guid)
        if not guid then
            return
        end
        local type = assert(self:GetGUIDType(guid), format([[Failed to determine the type of GUID "%s"]], guid))
        assert(Enums.GUID:GetName(type), format("Unknown GUID type %d", type))
        assert(Enums.GUID:CanHaveID(type), format([[GUID "%s" does not contain ID]], guid))
        return tonumber(guid:sub(6, 6 + 5 - 1), 16)
    end

    function Utils:MakeGUID(type, id)
        assert(Enums.GUID:CanHaveID(type), format("GUID of type %d (%s) cannot contain ID", type, Enums.GUID:GetName(type) or "Unknown"))
        return format("0x%03X%05X%08X", type, id, 0)
    end
end

-- Patch 6.0.2 (2014-10-14): Removed returns 'questTag' and 'isDaily'. Added returns 'frequency', 'isOnMap', 'hasLocalPOI', 'isTask', and 'isStory'.
if Version:IsBelowLegacyVersion(60000) then
    local dummyQuestIDMap = { NEXT = -1 }
    local oldGetQuestLogTitle = GetQuestLogTitle -- Store original function before BEQL (Bayi's Extended Questlog) overrides it and starts prepending quest level
    function GetQuestLogTitle(questIndex)
        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID, displayQuestID
        -- Patch 2.0.3 (2007-01-09): Added the 'suggestedGroup' return.
        if Version:IsBelowLegacyVersion(20000) then
            title, level, questTag, isHeader, isCollapsed, isComplete = oldGetQuestLogTitle(questIndex)
        else
            title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID, displayQuestID = oldGetQuestLogTitle(questIndex)
        end
        -- Patch 3.3.0 (2009-12-08): Added the 'questID' return.
        if Version:IsBelowLegacyVersion(30300) then
            questID = DataModules:GetQuestID("accept", title, "", "")
            if not questID then
                -- Try assuming that the last quest with the same title that the player has accepted is the quest that's currently in the quest log
                questID = Addon.db.char.RecentQuestTitleToID[title]
            end
            if not questID then
                -- Return a dummy quest ID unique per quest title, just to support having multiple quest log buttons in their current implementation (i.e. keyed by quest ID instead of button index)
                questID = dummyQuestIDMap[title]
                if not questID then
                    questID = dummyQuestIDMap.NEXT
                    dummyQuestIDMap.NEXT = dummyQuestIDMap.NEXT - 1
                    dummyQuestIDMap[title] = questID
                end
            end
        end
        local frequency = isDaily and 2 or 1
        return title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID
    end
end

local RegionMixins = {}
local RegionOverrides = {}
local FrameMixins = {}
local FrameOverrides = {}
local FontStringMixins = {}
local ModelMixins = {}
local function ApplyMixinsAndOverrides(self, mixins, overrides)
    if mixins then
        for k, v in pairs(mixins) do
            if not self[k] then
                self[k] = v
            end
        end
    end
    if overrides then
        for k, v in pairs(overrides) do
            if self[k] then
                self["_" .. k], self[k] = self[k], v
            end
        end
    end
end
local hookFrame
local hookModel
function CreateFrame(frameType, name, parent, template)
    if UIParent.SetBackdrop and template == "BackdropTemplate" then
        template = nil
    end

    local frame = _G.CreateFrame(frameType, name, parent, template)
    ApplyMixinsAndOverrides(frame, RegionMixins, RegionOverrides)
    ApplyMixinsAndOverrides(frame, FrameMixins, FrameOverrides)
    if hookFrame then
        hookFrame(frame)
    end
    if frameType == "Model" or frameType == "PlayerModel" or frameType == "DressUpModel" then
        ApplyMixinsAndOverrides(frame, ModelMixins)
        if hookModel then
            hookModel(frame)
        end
    end
    return frame
end

function RegionMixins:SetShown(shown)
    if shown then
        self:Show()
    else
        self:Hide()
    end
end
function RegionMixins:SetSize(width, height)
    self:SetWidth(width)
    self:SetHeight(height)
end
function FrameMixins:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
    self:SetMinResize(minWidth, minHeight)
    if maxWidth and maxHeight then
        self:SetMaxResize(maxWidth, maxHeight)
    end
end
function ModelMixins:SetAnimation(animation)
    self:SetSequence(animation)
end
function ModelMixins:SetCustomCamera(camera)
    self:SetCamera(camera)
end
-- Patch 7.0.3 (2016-07-19): Added.
if Version:IsBelowLegacyVersion(70000) then
    local modelToFileID = {
        ["Original"] = {
            ["interface/buttons/talktomequestion_white"]                = 130737,

            ["character/bloodelf/female/bloodelffemale"]                = 116921,
            ["character/bloodelf/male/bloodelfmale"]                    = 117170,
            ["character/broken/female/brokenfemale"]                    = 117400,
            ["character/broken/male/brokenmale"]                        = 117412,
            ["character/draenei/female/draeneifemale"]                  = 117437,
            ["character/draenei/male/draeneimale"]                      = 117721,
            ["character/dwarf/female/dwarffemale"]                      = 118135,
            ["character/dwarf/female/dwarffemale_hd"]                   = 950080,
            ["character/dwarf/female/dwarffemale_npc"]                  = 950080,
            ["character/dwarf/male/dwarfmale"]                          = 118355,
            ["character/dwarf/male/dwarfmale_hd"]                       = 878772,
            ["character/dwarf/male/dwarfmale_npc"]                      = 878772,
            ["character/felorc/female/felorcfemale"]                    = 118652,
            ["character/felorc/male/felorcmale"]                        = 118653,
            ["character/felorc/male/felorcmaleaxe"]                     = 118654,
            ["character/felorc/male/felorcmalesword"]                   = 118667,
            ["character/foresttroll/male/foresttrollmale"]              = 118798,
            ["character/gnome/female/gnomefemale"]                      = 119063,
            ["character/gnome/female/gnomefemale_hd"]                   = 940356,
            ["character/gnome/female/gnomefemale_npc"]                  = 940356,
            ["character/gnome/male/gnomemale"]                          = 119159,
            ["character/gnome/male/gnomemale_hd"]                       = 900914,
            ["character/gnome/male/gnomemale_npc"]                      = 900914,
            ["character/goblin/female/goblinfemale"]                    = 119369,
            ["character/goblin/male/goblinmale"]                        = 119376,
            ["character/goblinold/male/goblinoldmale"]                  = 119376,
            ["character/human/female/humanfemale"]                      = 119563,
            ["character/human/female/humanfemale_hd"]                   = 1000764,
            ["character/human/female/humanfemale_npc"]                  = 1000764,
            ["character/human/male/humanmale"]                          = 119940,
            ["character/human/male/humanmale_cata"]                     = 119940,
            ["character/human/male/humanmale_hd"]                       = 1011653,
            ["character/human/male/humanmale_npc"]                      = 1011653,
            ["character/icetroll/male/icetrollmale"]                    = 232863,
            ["character/naga_/female/naga_female"]                      = 120263,
            ["character/naga_/male/naga_male"]                          = 120294,
            ["character/nightelf/female/nightelffemale"]                = 120590,
            ["character/nightelf/female/nightelffemale_hd"]             = 921844,
            ["character/nightelf/female/nightelffemale_npc"]            = 921844,
            ["character/nightelf/male/nightelfmale"]                    = 120791,
            ["character/nightelf/male/nightelfmale_hd"]                 = 974343,
            ["character/nightelf/male/nightelfmale_npc"]                = 974343,
            ["character/northrendskeleton/male/northrendskeletonmale"]  = 233367,
            ["character/orc/female/orcfemale"]                          = 121087,
            ["character/orc/female/orcfemale_npc"]                      = 121087,
            ["character/orc/male/orcmale"]                              = 121287,
            ["character/orc/male/orcmale_hd"]                           = 917116,
            ["character/orc/male/orcmale_npc"]                          = 917116,
            ["character/scourge/female/scourgefemale"]                  = 121608,
            ["character/scourge/female/scourgefemale_hd"]               = 997378,
            ["character/scourge/female/scourgefemale_npc"]              = 997378,
            ["character/scourge/male/scourgemale"]                      = 121768,
            ["character/scourge/male/scourgemale_hd"]                   = 959310,
            ["character/scourge/male/scourgemale_npc"]                  = 959310,
            ["character/skeleton/male/skeletonmale"]                    = 121942,
            ["character/taunka/male/taunkamale"]                        = 233878,
            ["character/tauren/female/taurenfemale"]                    = 121961,
            ["character/tauren/female/taurenfemale_hd"]                 = 986648,
            ["character/tauren/female/taurenfemale_npc"]                = 986648,
            ["character/tauren/male/taurenmale"]                        = 122055,
            ["character/tauren/male/taurenmale_hd"]                     = 968705,
            ["character/tauren/male/taurenmale_npc"]                    = 968705,
            ["character/troll/female/trollfemale"]                      = 122414,
            ["character/troll/female/trollfemale_hd"]                   = 1018060,
            ["character/troll/female/trollfemale_npc"]                  = 1018060,
            ["character/troll/male/trollmale"]                          = 122560,
            ["character/troll/male/trollmale_hd"]                       = 1022938,
            ["character/troll/male/trollmale_npc"]                      = 1022938,
            ["character/tuskarr/male/tuskarrmale"]                      = 122738,
            ["character/vrykul/male/vrykulmale"]                        = 122815,
        },
        ["HD"] = {
            ["character/scourge/female/scourgefemale"]                  = 997378,
        },
    }
    local function CleanupModelName(model)
        model = string.lower(model)
        model = string.gsub(model, "\\", "/")
        model = string.gsub(model, "%.m2", "")
        model = string.gsub(model, "%.mdx", "")
        return model
    end
    function ModelMixins:GetModelFileID()
        local model = self:GetModel()
        if model and type(model) == "string" then
            model = CleanupModelName(model)
            local models = modelToFileID[Utils:GetCurrentModelSet()] or modelToFileID["Original"]
            return models[model] or modelToFileID["Original"][model]
        end
    end
end

if Version.IsLegacyVanilla then

    LibStub("AceConfig-3.0"):Embed(Addon)

    local function getargn(...)
        return arg.n
    end
    function GetNumGossipActiveQuests()
        return getargn(GetGossipActiveQuests())
    end
    function GetNumGossipAvailableQuests()
        return getargn(GetGossipAvailableQuests())
    end

    function Utils:GetNPCName()
        return UnitName("npc")
    end

    function Utils:GetNPCGUID()
        return nil
    end

    function Utils:IsNPCObjectOrItem()
        return not UnitExists("npc")
    end

    function Utils:IsNPCPlayer()
        return UnitIsPlayer("npc")
    end

    function Utils:IsSoundEnabled()
        return tonumber(GetCVar("MasterSoundEffects")) == 1
    end

    function Utils:TestSound(soundData)
        return true
    end

    function Utils:PlaySound(soundData)
        -- Interrupt NPC greeting voiceline
        if Addon.db.profile.Audio.AutoToggleDialog then
            SetCVar("MasterSoundEffects", 0)
            SetCVar("MasterSoundEffects", 1)
        end

        PlaySoundFile(soundData.filePath)
        soundData.handle = 1 -- Just put something here to flag the sound as stoppable
    end

    function Utils:StopSound(soundData)
        SetCVar("MasterSoundEffects", 0)
        SetCVar("MasterSoundEffects", 1)
        soundData.handle = nil
    end

    function RegionOverrides:SetPoint(point, region, relativeFrame, offsetX, offsetY)
        if region == nil and relativeFrame == nil and offsetX == nil and offsetY == nil then
            self:_SetPoint(point, 0, 0)
        else
            self:_SetPoint(point, region, relativeFrame, offsetX, offsetY)
        end
    end
    function FrameOverrides:SetScript(script, handler)
        self:_SetScript(script, script == "OnEvent"
            and function() handler(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) end
            or  function() handler(this,        arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) end)
    end
    function FrameMixins:HookScript(script, handler)
        local old = self:GetScript(script)
        self:_SetScript(script, script == "OnEvent"
            and function() if old then old() end handler(this, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) end
            or  function() if old then old() end handler(this,        arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) end)
    end

    hooksecurefunc(GameTooltip, "SetOwner", function(self, owner, anchor)
        self._owner = owner
    end)
    function GameTooltip:GetOwner()
        return self._owner
    end

    function Addon.OnAddonLoad.EQL3() -- Extended Quest Log 3
        QUESTS_DISPLAYED = EQL3_QUESTS_DISPLAYED

        QuestLogFrame = EQL3_QuestLogFrame
        QuestLogListScrollFrame = EQL3_QuestLogListScrollFrame

        function Utils:GetQuestLogTitleFrame(index)
            return _G["EQL3_QuestLogTitle" .. index]
        end

        function Utils:GetQuestLogTitleNormalText(index)
            return _G["EQL3_QuestLogTitle" .. index .. "NormalText"]
        end

        function Utils:GetQuestLogTitleCheck(index)
            return _G["EQL3_QuestLogTitle" .. index .. "Check"]
        end

        -- Hook the new function created by EQL3
        hooksecurefunc("QuestLog_Update", function()
            QuestOverlayUI:Update()
        end)
    end

end
if Version.IsLegacyVanilla or Version.IsLegacyBurningCrusade then

    local modelFramePool = {}
    function Utils:CreateNPCModelFrame(soundData)
        if soundData.modelFrame then
            return
        end

        local frame
        for _, pooled in ipairs(modelFramePool) do
            if not pooled._inUse then
                frame = pooled
                break
            end
        end

        if not frame then
            frame = CreateFrame("PlayerModel", nil, SoundQueueUI.frame.portrait)
            table.insert(modelFramePool, frame)
        end

        frame._inUse = true
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT")
        frame:SetSize(1, 1)
        frame:Show()
        frame:SetUnit("npc")

        soundData.modelFrame = frame
    end
    function Utils:FreeNPCModelFrame(soundData)
        local frame = soundData.modelFrame
        if not frame then
            return
        end
        soundData.modelFrame = nil

        if SoundQueueUI.frame.portrait.model == frame then
            SoundQueueUI.frame.portrait.model = SoundQueueUI.frame.portrait.defaultModel
        end

        frame:Hide()
        frame:ClearModel()
        frame._inUse = false
    end

    function hookModel(self)
        self._sequence = 0
        hooksecurefunc(self, "ClearModel", function(self)
            self._sequence = 0
            self._sequenceStart = nil
        end)
        hooksecurefunc(self, "SetSequence", function(self, sequence)
            self._sequence = sequence
            self._sequenceStart = GetTime()
        end)
        self:HookScript("OnUpdate", function(self, elapsed)
            if self._sequence ~= 0 then
                self:SetSequenceTime(self._sequence, (GetTime() - self._sequenceStart) * 1000)
            end
        end)
    end

    function FrameOverrides:HookScript(script, handler)
        if self:GetScript(script) then
            self:_HookScript(script, handler)
        else
            self:SetScript(script, handler)
        end
    end
    function FrameOverrides:CreateTexture(name, layer)
        local region = self:_CreateTexture(name, layer)
        ApplyMixinsAndOverrides(region, RegionMixins, RegionOverrides)
        return region
    end
    function FrameOverrides:CreateFontString(name, layer, template)
        local region = self:_CreateFontString(name, layer, template)
        ApplyMixinsAndOverrides(region, RegionMixins, RegionOverrides)
        ApplyMixinsAndOverrides(region, FontStringMixins)
        return region
    end
    function FrameOverrides:SetNormalTexture(file)
        local texture = self:CreateTexture(nil, "ARTWORK")
        local success = texture:SetTexture(file)
        texture:SetAllPoints()
        self._normalTexture = texture
        self:_SetNormalTexture(texture)
        return success
    end
    function FrameMixins:GetNormalTexture()
        return self._normalTexture
    end
    function FrameOverrides:SetPushedTexture(file)
        local texture = self:CreateTexture(nil, "ARTWORK")
        local success = texture:SetTexture(file)
        texture:SetAllPoints()
        self._pushedTexture = texture
        self:_SetPushedTexture(texture)
        return success
    end
    function FrameMixins:GetPushedTexture()
        return self._pushedTexture
    end
    function FrameOverrides:SetDisabledTexture(file)
        local texture = self:CreateTexture(nil, "ARTWORK")
        local success = texture:SetTexture(file)
        texture:SetAllPoints()
        self._disabledTexture = texture
        self:_SetDisabledTexture(texture)
        return success
    end
    function FrameMixins:GetDisabledTexture()
        return self._disabledTexture
    end
    function FrameOverrides:SetHighlightTexture(file)
        local texture = self:CreateTexture(nil, "HIGHLIGHT")
        local success = texture:SetTexture(file)
        texture:SetAllPoints()
        self._highlightTexture = texture
        self:_SetHighlightTexture(texture)
        return success
    end
    function FrameMixins:GetHighlightTexture()
        return self._highlightTexture
    end
    function FontStringMixins:SetWordWrap(wrap)
        if not wrap then
            self:SetHeight((select(2, self:GetFont())))
        end
    end
    function ModelMixins:SetCreature()
    end

    function GameTooltip_Hide()
        -- Used for XML OnLeave handlers
        GameTooltip:Hide()
    end

end
if Version.IsLegacyBurningCrusade then
end
if Version.IsLegacyBurningCrusade or Version.IsLegacyWrath then

    function Utils:IsSoundEnabled()
        -- 检查所有声音是否启用
        if tonumber(GetCVar("Sound_EnableAllSound")) ~= 1 then
            return false -- 如果所有声音未启用，返回false
        end
        -- 返回是否在音乐通道上启用播放或特效声音是否启用
        return Addon.db.profile.LegacyWrath.PlayOnMusicChannel.Enabled or tonumber(GetCVar("Sound_EnableSFX")) == 1
    end

    function Utils:TestSound(soundData)
        return true -- 测试声音的占位符功能，始终返回true
    end

    function Utils:GetCurrentModelSet()
        -- 根据用户设置返回当前模型集（高清或原版）
        return Addon.db.profile.LegacyWrath.HDModels and "HD" or "Original"
    end

    --[[
            下面开始播放语音（VO）通过音乐通道的代码，以支持暂停/停止语音的功能。
            在2.4.3和3.3.5版本中，PlaySound/PlaySoundFile无法通过任何方式停止，除非重新启动整个声音系统（这会导致客户端冻结几秒）。
            而PlayMusic可以通过StopMusic停止。但是，这会导致当前正在播放的脚本音乐淡出而不直接停止，
                这会造成一个问题，因为这样会导致我们听到语音循环直到完全淡出。这个问题可以通过播放另一个音频文件（甚至是不存在的文件）来解决，
                因为这样可以立即中断脚本音乐。
            切换Sound_EnableMusic的cvar的开关状态也允许我们中断当前游戏中的背景音乐。
            整个过程如下：
            1. 声音队列通过调用Utils:PlaySound请求开始播放语音
            2. 音乐音量在config.FadeOutMusic的持续时间内平滑降低到0
            3. 通过切换Sound_EnableMusic的cvar的开关状态，立即停止游戏中的背景音乐
            4. 音乐音量立即改变为config.Volume的水平
            5. 语音音频文件在音乐通道播放
            6. 一旦语音的持续时间结束（soundData.stopSoundTimer），silence.wav将作为音乐播放，以立即停止语音并防止其循环播放
            7. 声音队列请求停止播放语音，通过调用Utils:StopSound（无论是由于暂停还是soundData被从队列移除）- silence.wav再次播放，以中断语音，以防它尚未自然停止播放
            8. 音乐音量立即变为0
            9. 音乐音量平滑地提高回到语音播放前的水平，持续时间为config.FadeOutMusic
            10. 通过调用StopMusic()停止游戏中的背景音乐

            在2.4.3版本中，步骤2和3的顺序是互换的，因为3.3.5中的通过切换cvars立即停止音乐的技巧导致在2.4.3中反而出现短暂淡出（约0.4-0.5秒）。因此我们将config.FadeOutMusic锁定为0.5秒，使客户端在这0.5秒内自然淡出音乐，之后我们再提高音量并按正常流程进行。
    ]]
    local function GetCurrentVolume()
        -- 获取当前音乐音量，默认值为1
        return tonumber(GetCVar("Sound_MusicVolume")) or 1
    end

    local function PlaySilence()
        -- 播放静音音效，阻止其他VO声音的循环播放
        PlayMusic([[Interface\AddOns\AI_VoiceOver\Sounds\silence.wav]])
    end

    -- Functions that deal with temporarily changing player's sound settings to utilize the music channel for VO playback
    local prev_Sound_EnableMusic -- 保存之前的音乐启用状态
    local prev_Sound_MusicVolume -- 保存之前的音乐音量

    local function ReplaceCVars()
        -- 替换当前音频设置以启用音乐通道
        if prev_Sound_EnableMusic == nil then
            prev_Sound_EnableMusic = GetCVar("Sound_EnableMusic") -- 获取并保存当前音频设置
            prev_Sound_MusicVolume = GetCVar("Sound_MusicVolume")
            SetCVar("Sound_EnableMusic", 1) -- 启用音乐
        end
    end

    local function RestoreCVars()
        -- 恢复之前的音频设置
        if prev_Sound_EnableMusic ~= nil then
            SetCVar("Sound_EnableMusic", prev_Sound_EnableMusic) -- 恢复音乐启用状态
            SetCVar("Sound_MusicVolume", prev_Sound_MusicVolume) -- 恢复音乐音量
            prev_Sound_EnableMusic = nil -- 清空保存的状态
            prev_Sound_MusicVolume = nil
        end
    end

    -- Functions that deal with smoothly changing the music channel's volume to avoid abrupt changes
    local slideVolumeTarget -- 目标音量
    local slideVolumeRate -- 音量变化速率
    local slideVolumeCallback -- 音量变化完成后的回调函数
    local EPS_VOLUME = 0.01 -- 允许的音量精度误差

    local function GetMusicFadeOutDuration()
        -- 获取音乐淡出持续时间，如果音乐已关闭或音量为0，则返回0
        if tonumber(prev_Sound_EnableMusic) == 0 or tonumber(prev_Sound_MusicVolume) == 0 then
            return 0
        end
        return Addon.db.profile.LegacyWrath.PlayOnMusicChannel.FadeOutMusic or 0 -- 获取用户设置的淡出时间
    end

    local function StopSlideVolume()
        -- 停止音量滑动并重置参数
        slideVolumeTarget = nil
        slideVolumeRate = nil
        slideVolumeCallback = nil
    end

    local function SlideVolume(target, callback)
        -- 滑动音量至目标值
        local duration = GetMusicFadeOutDuration() -- 获取淡出时间
        if duration <= 0 then
            -- 如果持续时间为0，则迅速改变音量
            return false
        end
        local current = GetCurrentVolume() -- 获取当前音量
        if math.abs(target - current) <= EPS_VOLUME then
            -- 如果当前音量接近目标音量，则立即更改并取消滑动
            StopSlideVolume()
            return false
        end
        -- 在设定的持续时间内，从当前音量渐变到目标音量
        slideVolumeTarget = target -- 设置目标音量
        slideVolumeRate = (target - current) / duration -- 计算音量变化速率
        slideVolumeCallback = callback -- 设置回调函数
        return true
    end

    -- 创建音量滑动控制框架
    local volumeFrame = CreateFrame("Frame", "VoiceOverSlideVolumeFrame", UIParent)
    volumeFrame:RegisterEvent("PLAYER_LOGOUT") -- 注册玩家登出事件
    volumeFrame:HookScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGOUT" then
            StopSlideVolume() -- 停止音量滑动
            RestoreCVars() -- 恢复之前的音频设置
        end
    end)

    volumeFrame:HookScript("OnUpdate", function(self, elapsed)
        -- 在每次更新时，检查并调节音量
        if slideVolumeRate then
            local current = GetCurrentVolume() -- 获取当前音量
            local target = slideVolumeTarget -- 获取目标音量
            local next = current + slideVolumeRate * elapsed -- 计算下一个音量
            local finished = false
            -- 检查是否达到目标音量
            if math.abs(target - current) <= EPS_VOLUME or (current < target and next >= target) or (current > target and next <= target) then
                next = target -- 设置为目标音量
                finished = true
            end
            SetCVar("Sound_MusicVolume", next) -- 更新音乐音量
            if finished then -- 如果达到目标音量
                if slideVolumeCallback then
                    slideVolumeCallback() -- 调用完成回调
                end
                StopSlideVolume() -- 停止音量滑动
            end
        end
    end)

    function Utils:PlaySound(soundData)
        soundData.delay = nil -- 清除延迟标记
        -- 如果未启用音乐通道，则以普通声音播放
        if not Addon.db.profile.LegacyWrath.PlayOnMusicChannel.Enabled then
            -- Play VO as a sound, but have no ability to stop it
            _G.PlaySoundFile(soundData.filePath) -- 播放音效文件
            return
        end

        soundData.handle = 1 -- 设置标志以表示声音可停止

        ReplaceCVars() -- 替换变量以使用音乐通道
        local function Play()
            -- Hack to instantly interrupt the music
            SetCVar("Sound_EnableMusic", 0) -- 关闭音乐以中断当前音乐
            SetCVar("Sound_EnableMusic", 1) -- 重新启用音乐

            -- 设置所需的音乐音量并播放文件
            SetCVar("Sound_MusicVolume", Addon.db.profile.LegacyWrath.PlayOnMusicChannel.Volume)
            PlayMusic(soundData.filePath) -- 在音乐通道播放VO文件

            -- 设置定时器，播放静音音效以防止循环
            soundData.stopSoundTimer = Addon:ScheduleTimer(function()
                PlaySilence() -- 播放静音以中断VO音效
            end, soundData.length) -- 使用VO文件的长度作为延迟
        end

        if SlideVolume(0, Play) then
            soundData.delay = GetMusicFadeOutDuration() -- 获取淡出时间

            if Version.IsLegacyBurningCrusade then
                -- 2.4.3版本中请求客户端中断音乐并自然淡出
                SetCVar("Sound_EnableMusic", 0)
                SetCVar("Sound_EnableMusic", 1)
                PlaySilence() -- 播放静音文件
            end
        else
            Play() -- 直接播放音效
        end
    end

    function Utils:StopSound(soundData)
        if not soundData.handle then
            -- 如果当作普通音效播放，则无法停止
            return
        end

        Addon:CancelTimer(soundData.stopSoundTimer, true) -- 取消停止定时器
        soundData.stopSoundTimer = nil -- 清除定时器引用

        PlaySilence() -- 播放静音以中断VO音效
        SetCVar("Sound_MusicVolume", 0) -- 音乐音量设为0

        local function ResumeMusic()
            StopMusic() -- 停止当前音乐
            RestoreCVars() -- 恢复之前的音频设置
        end

        -- 尝试顺滑音量恢复到之前的水平
        if not SlideVolume(tonumber(prev_Sound_MusicVolume) or 1, ResumeMusic) then
            ResumeMusic() -- 直接恢复音乐
        end
    end

    -- Frame fade-in animation to help alleviate the UX damage caused by delaying the VO
    hooksecurefunc(SoundQueueUI, "InitDisplay", function(self)
        local fadeIn, animation
        -- 创建渐显动画逻辑
        if self.frame.CreateAnimationGroup then
            fadeIn = self.frame:CreateAnimationGroup() -- 创建动画组
            animation = fadeIn:CreateAnimation("Alpha") -- 创建透明度动画
            animation:SetOrder(1) -- 设置动画顺序
            animation:SetDuration(0) -- 第一阶段的持续时间
            animation:SetChange(-1) -- 透明度变化为-1
            animation = fadeIn:CreateAnimation("Alpha") -- 创建第二个透明度动画
            animation:SetOrder(2) -- 设置为第二顺序
            animation:SetDuration(1) -- 第二阶段的持续时间
            animation:SetChange(1) -- 透明度变化为1
            animation:SetSmoothing("OUT") -- 平滑动画
        else
            fadeIn, animation = { frame = self.frame }, {} -- 为不支持动画的框架创建自定义实现
            function fadeIn:Stop()
                self.frame:SetAlpha(1) -- 完全可见
                self.enabled = nil -- 禁用
            end
            function fadeIn:Play()
                self.frame:SetAlpha(0) -- 完全透明
                self.enabled = true -- 启用
            end
            function animation:SetDuration(duration)
                self.duration = duration -- 设置动画持续时间
            end

            -- 在每次更新时检查并调节透明度
            self.frame:HookScript("OnUpdate", function(self, elapsed)
                if fadeIn.enabled then
                    local alpha = math.min(1, self:GetAlpha() + elapsed / animation.duration) -- 更新透明度
                    if alpha >= 1 then
                        fadeIn:Stop() -- 完全可见时停止
                    else
                        self:SetAlpha(alpha) -- 设置新的透明度
                    end
                end
            end)
        end
        -- 在框架显示时触发渐显动画
        self.frame:HookScript("OnShow", function()
            fadeIn:Stop() -- 如果显示时已在逐渐显现，停止
            local soundData = SoundQueue:GetCurrentSound() -- 获取当前声音数据
            local duration = soundData and sound
            local duration = soundData and soundData.delay or 0 -- 获取声音的延迟长度，若没有则设为0
            if duration > 0 then
                animation:SetDuration(duration) -- 设置动画持续时间
                fadeIn:Play() -- 播放渐显动画
            end
        end)
    end)

end
if Version.IsLegacyWrath then

    function Utils:GetQuestLogScrollOffset()
        return HybridScrollFrame_GetOffset(QuestLogScrollFrame)
    end

    function Utils:GetQuestLogTitleFrame(index)
        return _G["QuestLogScrollFrameButton" .. index]
    end

    function Utils:GetQuestLogTitleNormalText(index)
        return _G["QuestLogScrollFrameButton" .. index .. "NormalText"]
    end

    function Utils:GetQuestLogTitleCheck(index)
        return _G["QuestLogScrollFrameButton" .. index .. "Check"]
    end

    local prefix
    local QuestLogTitleButton_Resize = QuestLogTitleButton_Resize
    function QuestOverlayUI:UpdateQuestTitle(questLogTitleFrame, playButton, normalText, questCheck)
        if not prefix then
            local text = normalText:GetText()
            for i = 1, 20 do
                normalText:SetText(string.rep(" ", i))
                if normalText:GetStringWidth() >= 24 then
                    prefix = normalText:GetText()
                    break
                end
            end
            prefix = prefix or "  "
            normalText:SetText(text)
        end

        playButton:SetPoint("LEFT", normalText, "LEFT", 4, 0)
        normalText:SetText(prefix .. (normalText:GetText() or ""):trim())
        QuestLogTitleButton_Resize(questLogTitleFrame)
    end

    hooksecurefunc(Addon, "OnInitialize", function()
        QuestLogScrollFrame.update = QuestLog_Update
    end)

    function hookModel(self)
        local function HasModelLoaded(self)
            local model = self:GetModel()
            return model and type(model) == "string" and self:GetModelFileID() ~= 130737
        end
        self._sequence = 0
        hooksecurefunc(self, "ClearModel", function(self)
            self._awaitingModel = nil
            self._camera = nil
            self._sequence = 0
            self._sequenceStart = nil
        end)
        local oldSetSequence = self.SetSequence
        function self:SetSequence(sequence)
            self._sequence = sequence
            self._sequenceStart = GetTime()
            if not self._awaitingModel then
                oldSetSequence(self, sequence)
            end
        end
        local oldSetCreature = self.SetCreature
        function self:SetCreature(id)
            self:ClearModel()
            self:SetModel([[Interface\Buttons\TalkToMeQuestion_White.mdx]])
            oldSetCreature(self, id)
            self._awaitingModel = not HasModelLoaded(self)
        end
        local oldSetCamera = self.SetCamera
        function self:SetCamera(id)
            self._camera = id
            if not self._awaitingModel then
                oldSetCamera(self, id)
            end
        end
        self:HookScript("OnUpdate", function(self, elapsed)
            if self._awaitingModel and HasModelLoaded(self) then
                self._awaitingModel = nil
                self:SetModelScale(2)
                self:SetPosition(0, 0, 0)

                if self._sequence ~= 0 then
                    self:SetSequence(self._sequence)
                end
            elseif self._awaitingModel then
                self:SetModelScale(0.71 / self:GetEffectiveScale())
                self:SetPosition(5 * self:GetModelScale(), 0, 2 * self:GetModelScale())
            end
            if self._sequence ~= 0 and not self._awaitingModel then
                self:SetSequenceTime(self._sequence, (GetTime() - self._sequenceStart) * 1000)
            end
        end)
    end

    hooksecurefunc(SoundQueueUI, "InitPortrait", function(self)
        self.frame.portrait.pause:HookScript("OnEnter", function()
            if self.frame.portrait.model._awaitingModel then
                GameTooltip:SetOwner(self.frame.portrait.pause, "ANCHOR_NONE")
                GameTooltip:SetPoint("BOTTOMLEFT", self.frame.portrait.pause, "BOTTOMRIGHT", 4, -4)
                GameTooltip:SetText("Uncached NPC", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
                GameTooltip:AddLine("Encounter this NPC in the world again to be able to see their model.", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
                GameTooltip:Show()
            end
        end)
        self.frame.portrait.pause:HookScript("OnLeave", GameTooltip_Hide)
    end)

end
if Version.IsRetailVanilla then

    GetGossipText = C_GossipInfo.GetText
    GetNumGossipActiveQuests = C_GossipInfo.GetNumActiveQuests
    GetNumGossipAvailableQuests = C_GossipInfo.GetNumAvailableQuests
    
    function Addon.OnAddonLoad.Leatrix_Plus()
        C_Timer.After(0, function() -- Let it run its ADDON_LOADED code
            hooksecurefunc("QuestLog_Update", function()
                -- Update QuestOverlayUI again after Leatrix_Plus replaces the titles with prepended quest levels
                QuestOverlayUI:Update()
            end)
        end)
    end
    function Addon.OnAddonLoad.Guidelime()
        QuestLogFrame:HookScript("OnUpdate", function()
            -- Update QuestOverlayUI again after Guidelime decorates the titles
            QuestOverlayUI:Update()
        end)
    end

end
if Version.IsRetailWrath then

    GetGossipText = C_GossipInfo.GetText
    GetNumGossipActiveQuests = C_GossipInfo.GetNumActiveQuests
    GetNumGossipAvailableQuests = C_GossipInfo.GetNumAvailableQuests

    function Utils:GetQuestLogScrollOffset()
        return HybridScrollFrame_GetOffset(QuestLogListScrollFrame)
    end

    function Utils:GetQuestLogTitleFrame(index)
        return _G["QuestLogListScrollFrameButton" .. index]
    end

    function Utils:GetQuestLogTitleNormalText(index)
        return _G["QuestLogListScrollFrameButton" .. index .. "NormalText"]
    end

    function Utils:GetQuestLogTitleCheck(index)
        return _G["QuestLogListScrollFrameButton" .. index .. "Check"]
    end

    local QuestLogTitleButton_Resize = QuestLogTitleButton_Resize -- Store original function before LeatrixPlus's "Enhance quest log" hooks into it
    local prefix
    function QuestOverlayUI:UpdateQuestTitle(questLogTitleFrame, playButton, normalText, questCheck)
        if not prefix then
            local text = normalText:GetText()
            for i = 1, 20 do
                normalText:SetText(string.rep(" ", i))
                if normalText:GetStringWidth() >= 24 then
                    prefix = normalText:GetText()
                    break
                end
            end
            prefix = prefix or "  "
            normalText:SetText(text)
        end

        playButton:SetPoint("LEFT", normalText, "LEFT", 4, 0)
        normalText:SetText(prefix .. (normalText:GetText() or ""):trim())
        QuestLogTitleButton_Resize(questLogTitleFrame)
    end

    hooksecurefunc(Addon, "OnInitialize", function()
        QuestLogListScrollFrame.update = QuestLog_Update
    end)

    function Addon.OnAddonLoad.Guidelime()
        QuestLogFrame:HookScript("OnUpdate", function()
            -- Update QuestOverlayUI again after Guidelime decorates the titles
            QuestOverlayUI:Update()
        end)
    end

end
if Version.IsRetailMainline then

    GetGossipText = C_GossipInfo.GetText
    GetNumGossipActiveQuests = C_GossipInfo.GetNumActiveQuests
    GetNumGossipAvailableQuests = C_GossipInfo.GetNumAvailableQuests

    function Utils:GetCurrentModelSet()
        return "HD"
    end

end
