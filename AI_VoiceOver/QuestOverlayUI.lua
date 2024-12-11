setfenv(1, VoiceOver)

---@class QuestPlayButton : Button
---@field soundData SoundData

QuestOverlayUI = {
    ---@type table<number, QuestPlayButton>
    questPlayButtons = {}, -- 存储所有任务播放按钮的表
    ---@type QuestPlayButton[]
    displayedButtons = {}, -- 存储当前显示的按钮
}

function QuestOverlayUI:CreatePlayButton(questID)
    local playButton = CreateFrame("Button", nil, QuestLogFrame) -- 创建新按钮
    playButton:SetWidth(20) -- 设置按钮宽度
    playButton:SetHeight(20) -- 设置按钮高度
    playButton:SetHitRectInsets(2, 2, 2, 2) -- 设置按钮可点击区域
    playButton:SetNormalTexture([[Interface\AddOns\AI_VoiceOver\Textures\QuestLogPlayButton]]) -- 设置正常纹理
    playButton:SetDisabledTexture([[Interface\AddOns\AI_VoiceOver\Textures\QuestLogPlayButton]]) -- 设置禁用纹理
    playButton:GetDisabledTexture():SetDesaturated(true) -- 设置禁用纹理为去饱和色
    playButton:GetDisabledTexture():SetAlpha(0.33) -- 设置禁用纹理透明度
    playButton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight") -- 设置高亮纹理
    ---@cast playButton QuestPlayButton
    self.questPlayButtons[questID] = playButton -- 将按钮添加到questPlayButtons表中
end

local prefix
function QuestOverlayUI:UpdateQuestTitle(questLogTitleFrame, playButton, normalText, questCheck)
    if not prefix then -- 如果前缀尚未设置
        local text = normalText:GetText() -- 获取正常文本
        for i = 1, 20 do
            normalText:SetText(string.rep(" ", i)) -- 设置文本为空格
            if normalText:GetStringWidth() >= 24 then -- 检查文本宽度
                prefix = normalText:GetText() -- 设置前缀
                break
            end
        end
        prefix = prefix or "  " -- 如果没有找到前缀，使用默认空格
        normalText:SetText(text) -- 恢复原始文本
    end

    playButton:SetPoint("LEFT", normalText, "LEFT", 4, 0) -- 设置按钮的位置

    local formatedText = prefix .. string.trim(normalText:GetText() or "") -- 格式化文本，添加前缀

    normalText:SetText(formatedText) -- 更新正常文本
    QuestLogDummyText:SetText(formatedText) -- 更新虚拟文本

    questCheck:SetPoint("LEFT", normalText, "LEFT", normalText:GetStringWidth(), 0) -- 设置勾选框位置
end

function QuestOverlayUI:UpdatePlayButtonTexture(questID)
    local button = self.questPlayButtons[questID] -- 获取任务播放按钮
    if button then
        local isPlaying = button.soundData and SoundQueue:Contains(button.soundData) -- 检查是否正在播放
        local texturePath = isPlaying and [[Interface\AddOns\AI_VoiceOver\Textures\QuestLogStopButton]] or [[Interface\AddOns\AI_VoiceOver\Textures\QuestLogPlayButton]] -- 根据播放状态设置纹理路径
        button:SetNormalTexture(texturePath) -- 设置按钮的正常纹理
    end
end

function QuestOverlayUI:UpdatePlayButton(soundTitle, questID, questLogTitleFrame, normalText, questCheck)
    self.questPlayButtons[questID]:SetParent(questLogTitleFrame:GetParent()) -- 设置按钮的父级
    self.questPlayButtons[questID]:SetFrameLevel(questLogTitleFrame:GetFrameLevel() + 2) -- 设置按钮的框架层级

    QuestOverlayUI:UpdateQuestTitle(questLogTitleFrame, self.questPlayButtons[questID], normalText, questCheck) -- 更新任务标题

    self.questPlayButtons[questID]:SetScript("OnClick", function(self) -- 设置按钮的点击事件
        if not QuestOverlayUI.questPlayButtons[questID].soundData then -- 如果没有音频数据
            local type, id = DataModules:GetQuestLogQuestGiverTypeAndID(questID) -- 获取任务提供者类型和ID
            QuestOverlayUI.questPlayButtons[questID].soundData = {
                event = Enums.SoundEvent.QuestAccept, -- 事件类型
                questID = questID,
                name = id and DataModules:GetObjectName(type, id) or "Unknown Name", -- 获取提供者姓名或设置为未知
                title = soundTitle, -- 任务标题
                unitGUID = id and Enums.GUID:CanHaveID(type) and Utils:MakeGUID(type, id) or nil -- 获取单位GUID
            }
        end

        local soundData = self.soundData -- 获取音频数据
        local questID = soundData.questID -- 获取任务ID
        local isPlaying = SoundQueue:Contains(soundData) -- 检查音频是否正在播放

        if not isPlaying then -- 如果未在播放音频
            SoundQueue:AddSoundToQueue(soundData) -- 将音频添加到队列
            QuestOverlayUI:UpdatePlayButtonTexture(questID) -- 更新播放按钮的纹理

            soundData.stopCallback = function()
                QuestOverlayUI:UpdatePlayButtonTexture(questID) -- 更新按钮纹理
                self.soundData = nil -- 清除音频数据
            end
        else
            SoundQueue:RemoveSoundFromQueue(soundData) -- 从队列中移除音频
        end
    end)
end

function QuestOverlayUI:Update()
    if not QuestLogFrame:IsShown() then -- 如果任务日志未显示
        return
    end

    local numEntries, numQuests = GetNumQuestLogEntries() -- 获取任务日志条目数和任务数

    -- 隐藏所有显示的按钮
    for _, button in pairs(self.displayedButtons) do
        button:Hide()
    end

    if numEntries == 0 then -- 如果没有任务条目
        return
    end

    -- 清除显示的按钮列表
    table.wipe(self.displayedButtons)

    -- 遍历当前UI中显示的任务
    for i = 1, QUESTS_DISPLAYED do
        local questIndex = i + Utils:GetQuestLogScrollOffset(); -- 获取任务索引
        if questIndex > numEntries then -- 如果索引超出条目数范围
            break
        end

        -- 获取任务标题
        local questLogTitleFrame = Utils:GetQuestLogTitleFrame(i) -- 获取任务标题框架
        local normalText = Utils:GetQuestLogTitleNormalText(i) -- 获取正常文本
        local questCheck = Utils:GetQuestLogTitleCheck(i) -- 获取勾选框
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(questIndex) -- 获取任务信息

        if not isHeader then -- 如果不是标题项
            if not self.questPlayButtons[questID] then -- 如果按钮不存在
                self:CreatePlayButton(questID) -- 创建新按钮
            end

            if DataModules:PrepareSound({ event = Enums.SoundEvent.QuestAccept, questID = questID }) then -- 准备音频
                self:UpdatePlayButton(title, questID, questLogTitleFrame, normalText, questCheck) -- 更新播放按钮
                self.questPlayButtons[questID]:Enable() -- 启用按钮
            else
                self:UpdateQuestTitle(questLogTitleFrame, self.questPlayButtons[questID], normalText, questCheck) -- 更新任务标题
                self.questPlayButtons[questID]:Disable() -- 禁用按钮
            end

            self.questPlayButtons[questID]:Show() -- 显示按钮
            self:UpdatePlayButtonTexture(questID) -- 更新按钮纹理

            -- 将按钮添加到显示的按钮列表
            table.insert(self.displayedButtons, self.questPlayButtons[questID])
        end
    end
end
