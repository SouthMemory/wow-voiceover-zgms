SoundQueueUI = {}
SoundQueueUI.__index = SoundQueueUI

local SPEAKER_ICON_SIZE = 16

function SoundQueueUI:new(soundQueue)
    local soundQueueUI = {}
    setmetatable(soundQueueUI, SoundQueueUI)

    soundQueueUI.soundQueue = soundQueue

    soundQueueUI.animtimer = time()

    soundQueueUI:initDisplay()
    soundQueueUI:initNPCHead()

    soundQueueUI.isDragging = false

    return soundQueueUI
end


function SoundQueueUI:initDisplay()
    self.soundQueueFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    self.soundQueueScrollFrame = CreateFrame("ScrollFrame", nil, self.soundQueueFrame)
    self.soundQueueButtonContainer = CreateFrame("Frame", nil, self.soundQueueScrollFrame)
    self.soundQueueFrame:SetWidth(300)
    self.soundQueueFrame:SetHeight(300)
    self.soundQueueFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    self.soundQueueFrame.buttons = {}
    self.soundQueueFrame:SetMovable(true) -- Allow the frame to be moved
    self.soundQueueFrame:EnableMouse(true) -- Allow the frame to be clicked on

    -- Create a local variable to track whether the frame is being dragged
    local soundQueueUI = self

    -- Register the OnMouseDown event handler for the frame
    self.soundQueueFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not soundQueueUI.isDragging then
            self:StartMoving()
            soundQueueUI.isDragging = true
        end
    end)

    -- Register the OnMouseUp event handler for the frame
    self.soundQueueFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and soundQueueUI.isDragging then
            self:StopMovingOrSizing()
            soundQueueUI.isDragging = false
        end
    end)

    -- Create a scroll frame to hold the sound queue contents
    self.soundQueueScrollFrame:SetPoint("TOPLEFT", self.soundQueueFrame, "TOPLEFT", 10, -30)
    self.soundQueueScrollFrame:SetPoint("BOTTOMRIGHT", self.soundQueueFrame, "BOTTOMRIGHT", -30, 10)

    -- Create a container frame to hold the sound queue buttons
    self.soundQueueButtonContainer:SetSize(200, 300)
    self.soundQueueScrollFrame:SetScrollChild(self.soundQueueButtonContainer)
end

function SoundQueueUI:initNPCHead()
    self.npcHead = CreateFrame("PlayerModel", nil, self.soundQueueButtonContainer)

    local soundQueueUI = self
    self.npcHead:SetSize(64, 64)

    self.npcHead:SetScript("OnHide", function(self)
        self:ClearModel()
    end)

    self.npcHead:SetScript("OnUpdate", function(self)
        if self:IsShown() and time() - soundQueueUI.animtimer >= 2 then
            self:SetAnimation(60)
            soundQueueUI.animtimer = time()
        end
    end)
end


function SoundQueueUI:createButton(i)
    local button = CreateFrame("Button", nil, self.soundQueueButtonContainer)
    self.soundQueueFrame.buttons[i] = button

    local speakerIcon = button:CreateTexture(nil, "ARTWORK")
    speakerIcon:SetTexture("Interface\\Buttons\\CancelButton-Up")
    speakerIcon:SetSize(SPEAKER_ICON_SIZE, SPEAKER_ICON_SIZE)
    speakerIcon:SetPoint("LEFT", button, "LEFT", 0, 0)

    local questTitle = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")

    button.textWidget = questTitle
    button.iconWidget = speakerIcon
    return button
end

function SoundQueueUI:configureButton(button, soundData, i, yPos)
    button:SetPoint("TOPLEFT", self.soundQueueButtonContainer, "TOPLEFT", 0, yPos)
    button:SetScript("OnClick", function()
        self.soundQueue:removeSoundFromQueue(soundData)
    end)

    button.textWidget:SetText(soundData.title)

    if i == 1 then
        self:configureFirstButton(button, soundData)
        yPos = yPos - 64
    else
        button:SetSize(300, 20)
        button.textWidget:SetPoint("LEFT", button.iconWidget, "RIGHT", 5, 0)
        yPos = yPos - 20
    end
    button:Show()

    return yPos
end

function SoundQueueUI:configureFirstButton(button, soundData)
    if self.npcHead:IsShown() == false then
        self.npcHead:Show()
    end

    button:SetSize(300, 64)
    button.textWidget:SetPoint("LEFT", button.iconWidget, "RIGHT", 70, 0)

    local creatureID = select(6, strsplit("-", soundData.unitGuid))
    if creatureID ~= self.oldCreatureId then
        self.npcHead:SetCreature(creatureID)
        self.npcHead:SetCustomCamera(0)
        self.npcHead:SetAnimation(60)

        self.oldCreatureId = creatureID
    else
        self.npcHead:SetCustomCamera(0)
    end

    self.npcHead:SetPoint("LEFT", button.iconWidget, "RIGHT", 0, 0)
end

function SoundQueueUI:updateSoundQueueDisplay()
    local yPos = -10
    for i, soundData in ipairs(self.soundQueue.sounds) do
        local button = self.soundQueueFrame.buttons[i] or self:createButton(i)
        yPos = self:configureButton(button, soundData, i, yPos)
    end

    if #self.soundQueue.sounds == 0 then
        self.npcHead:Hide()
    end

    for i = #self.soundQueue.sounds + 1, #self.soundQueueFrame.buttons do
        self.soundQueueFrame.buttons[i]:Hide()
    end
end