---@diagnostic disable: inject-field

local addonName, addonTable = ...;

PortalInviter = LibStub("AceAddon-3.0"):NewAddon("PortalInviter", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local minimap_icon = LibStub("LibDBIcon-1.0")
local CTL = _G.ChatThrottleLib

-- Set your desired portal price
local desiredGoldAmount = 5

-- Default settings
local options = {
    name = "PortalInviter",
    handler = PortalInviter,
    type = "group",
    args = {
        generalSettings = {
            type = "group",
            name = "General Settings",
            inline = true,
            order = 0,
            args = {
                enabled = {
                    type = 'toggle',
                    name = 'Enabled',
                    desc = 'Enable or disable portal auto-inviting.',
                    set = 'SetEnabled',
                    get = 'GetEnabled',
                    order = 1,
                },
                debug = {
                    type = 'toggle',
                    name = 'Debug Mode',
                    desc = 'Enable or disable debug messages.',
                    set = 'SetDebug',
                    get = 'GetDebug',
                    order = 2,
                },
                minimap = {
                    type = 'toggle',
                    name = 'Hide Minimap Icon',
                    desc = 'Show or hide the minimap icon.',
                    set = function(info, val)
                        PortalInviter.db.profile.minimap.hide = val
                        if val then
                            minimap_icon:Hide("PortalInviter")
                        else
                            minimap_icon:Show("PortalInviter")
                        end
                    end,
                    get = function(info)
                        return PortalInviter.db.profile.minimap.hide
                    end,
                    order = 3,
                },
            },
        },

        messagingSettings = {
            type = "group",
            name = "Messaging Settings",
            inline = true,
            order = 1,
            args = {
                triggers = {
                    type = 'input',
                    name = 'Invite Triggers',
                    desc = 'Comma-separated words to trigger inviting for portals.',
                    set = 'SetTriggers',
                    get = 'GetTriggers',
                    order = 1,
                },
                inviteWhisper = {
                    type = 'toggle',
                    name = 'Whisper Invites',
                    desc = 'Send a whisper to players when inviting them.',
                    set = function(info, val)
                        PortalInviter.db.profile.inviteWhisper = val
                    end,
                    get = function(info)
                        return PortalInviter.db.profile.inviteWhisper
                    end,
                    order = 2,
                },
                inviteWhisperTemplate = {
                    type = 'input',
                    width = 'double',
                    name = 'Whisper Template',
                    desc = 'Template for invite whispers. Use %s for destination.',
                    set = function(info, val)
                        PortalInviter.db.profile.inviteWhisperTemplate = val
                    end,
                    get = function(info)
                        return PortalInviter.db.profile.inviteWhisperTemplate
                    end,
                    order = 3,
                },
            },
        },
    },
}

local defaults = {
    profile = {
        enabled = true,
        debug = false,
        triggers = "portal,port,teleport",
        inviteWhisper = true,
        inviteWhisperTemplate = "Inviting you for a portal to %s...",
        minimap = {
            hide = false,
        },
    }
}

function PortalInviter:OnInitialize()
    LibStub("AceConfig-3.0"):RegisterOptionsTable("PortalInviter", options)
    self.db = LibStub("AceDB-3.0"):New("PortalInviterDB", defaults)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("PortalInviter", "PortalInviter")

    local icon = self.db.profile.enabled and "Interface\\Icons\\Spell_arcane_portalundercity" or "Interface\\Icons\\Spell_arcane_blink"
    local bunnyLDB = LibStub("LibDataBroker-1.1"):NewDataObject("PortalInviter", {
        type = "data source",
        text = "PortalInviter",
        icon = icon,
        OnClick = function(_, button)
            if button == "LeftButton" then
                PortalInviter:Toggle()
            elseif button == "RightButton" then
                PortalInviter:ShowInvitedListGUI()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("PortalInviter")
            tooltip:AddLine("Left-click to toggle")
            tooltip:AddLine("Right-click to show invited list")
        end,
    })

    addonTable.bunnyLDB = bunnyLDB
    minimap_icon:Register("PortalInviter", bunnyLDB, self.db.profile.minimap)

    self.invitedPlayers = {}
    self.whoQueue = {}

    self:RegisterEvent("CHAT_MSG_WHISPER", "ProcessMessage")
    self:RegisterEvent("CHAT_MSG_CHANNEL", "ProcessMessage")
    self:RegisterEvent("WHO_LIST_UPDATE", "OnWhoListUpdate")

    -- Create slash commands
    self:RegisterChatCommand("testportal", "TestPortalCommand")
    self:RegisterChatCommand("testaddinvite", "TestAddInviteCommand")
    self:RegisterChatCommand("testtrade", "TestTradeCommands")

    -- Create secure buttons here
    self:CreateSecureButtons()

    -- Trade frame events
    self:SetupTradeEvents()

    -- Register group update event
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnGroupUpdate")
end

----------------------------------------------------
-- Configuration Functions
----------------------------------------------------
function PortalInviter:SetEnabled(info, val)
    self.db.profile.enabled = val
end

function PortalInviter:GetEnabled(info)
    return self.db.profile.enabled
end

function PortalInviter:SetDebug(info, val)
    self.db.profile.debug = val
end

function PortalInviter:GetDebug(info)
    return self.db.profile.debug
end

function PortalInviter:SetTriggers(info, val)
    self.db.profile.triggers = val
end

function PortalInviter:GetTriggers(info)
    return self.db.profile.triggers
end

function PortalInviter:ParseTriggers()
    local triggers = {}
    for trigger in string.gmatch(self.db.profile.triggers, "[^,]+") do
        table.insert(triggers, strtrim(trigger):lower())
    end
    return triggers
end

function PortalInviter:DebugPrint(...)
    if self.db.profile.debug then
        self:Print(...)
    end
end

----------------------------------------------------
-- Toggle Function
----------------------------------------------------
function PortalInviter:Toggle()
    self.db.profile.enabled = not self.db.profile.enabled
    self:Print(self.db.profile.enabled and "enabled" or "disabled")

    if self.db.profile.enabled then
        addonTable.bunnyLDB.icon = "Interface\\Icons\\Spell_arcane_portalundercity"
    else
        addonTable.bunnyLDB.icon = "Interface\\Icons\\Spell_arcane_blink"
    end
end

----------------------------------------------------
-- Test Commands
----------------------------------------------------
function PortalInviter:TestPortalCommand(input)
    local msg = input or "portal"
    self:ProcessMessage("CHAT_MSG_WHISPER", msg, "Testplayer", nil, nil)
    self:Print("Simulated whisper: " .. msg .. " from Testplayer")
end

function PortalInviter:TestAddInviteCommand(input)
    local name, dest = strsplit(" ", input, 2)
    name = name or "Testplayer"
    dest = dest or "Unknown Destination"

    table.insert(self.invitedPlayers, { name = name, destination = dest, time = time() })
    self:Print("Added " .. name .. " going to " .. dest .. " to invited list.")
    self:RefreshInvitedListGUI()
end

function PortalInviter:TestTradeCommands(input)
    local cmd, arg = strsplit(" ", input, 2)
    cmd = cmd:lower()
    
    local originalGetMoney = GetMoney
    local originalGetTargetTradeMoney = GetTargetTradeMoney

    local mockPlayerMoney = 1000000 -- 100g
    local mockTargetMoney = 500000  -- 50g

    GetMoney = function()
        return mockPlayerMoney
    end

    GetTargetTradeMoney = function()
        return mockTargetMoney
    end

    if cmd == "start" then
        self:Print("Simulating trade start...")
        self.tradeFrame:GetScript("OnEvent")(self.tradeFrame, "TRADE_SHOW")
    elseif cmd == "money" then
        self:Print("Simulating TRADE_MONEY_CHANGED...")
        self.tradeFrame:GetScript("OnEvent")(self.tradeFrame, "TRADE_MONEY_CHANGED")
    elseif cmd == "close" then
        self:Print("Simulating TRADE_CLOSED...")
        mockPlayerMoney = mockPlayerMoney + 50000
        self.tradeFrame:GetScript("OnEvent")(self.tradeFrame, "TRADE_CLOSED")
    else
        self:Print("Usage: /testtrade start|money|close")
    end

    GetMoney = originalGetMoney
    GetTargetTradeMoney = originalGetTargetTradeMoney
end

----------------------------------------------------
-- Secure Buttons Setup
----------------------------------------------------
function PortalInviter:CreateSecureButtons()
    -- Portal Button
    self.portalButton = CreateFrame("Button", "PortalInviterPortalButton", UIParent, "SecureActionButtonTemplate")
    self.portalButton:SetAttribute("type", "macro")
    self.portalButton:Hide()
    self.portalButton:SetWidth(120)
    self.portalButton:SetHeight(30)
    self.portalButton:SetPoint("CENTER", UIParent, "CENTER")
    local btnTex = self.portalButton:CreateTexture(nil, "BACKGROUND")
    btnTex:SetAllPoints()
    btnTex:SetColorTexture(0, 0.5, 1, 0.5)
    local btnText = self.portalButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetPoint("CENTER")
    btnText:SetText("Cast Portal")

    -- Target Button
    self.targetButton = CreateFrame("Button", "PortalInviterTargetButton", UIParent, "SecureActionButtonTemplate")
    self.targetButton:SetAttribute("type", "macro")
    self.targetButton:Hide()
    self.targetButton:SetWidth(120)
    self.targetButton:SetHeight(30)
    self.targetButton:SetPoint("CENTER", UIParent, "CENTER", 0, -40)
    local tbtnTex = self.targetButton:CreateTexture(nil, "BACKGROUND")
    tbtnTex:SetAllPoints()
    tbtnTex:SetColorTexture(0, 0.5, 0, 0.5)
    local tbtnText = self.targetButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tbtnText:SetPoint("CENTER")
    tbtnText:SetText("Target Player")

    -- Trade Button
    self.tradeButton = CreateFrame("Button", "PortalInviterTradeButton", UIParent, "SecureActionButtonTemplate")
    self.tradeButton:SetAttribute("type", "macro")
    self.tradeButton:Hide()
    self.tradeButton:SetWidth(120)
    self.tradeButton:SetHeight(30)
    self.tradeButton:SetPoint("CENTER", UIParent, "CENTER", 0, -80)
    local tradeBtnTex = self.tradeButton:CreateTexture(nil, "BACKGROUND")
    tradeBtnTex:SetAllPoints()
    tradeBtnTex:SetColorTexture(0.5, 0.5, 0, 0.5)
    local tradeBtnText = self.tradeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tradeBtnText:SetPoint("CENTER")
    tradeBtnText:SetText("Trade Player")
end

----------------------------------------------------
-- Party Update Event
----------------------------------------------------
function PortalInviter:OnGroupUpdate()
    if not self.db.profile.enabled then return end

    local numMembers = GetNumGroupMembers()
    if numMembers > 0 then
        local playerName = UnitName("player")
        for i = 1, numMembers do
            local memberName = GetRaidRosterInfo(i)
            if memberName and memberName ~= playerName then
                -- Open the UI if not already open
                if not (self.invitedListFrame and self.invitedListFrame:IsShown()) then
                    self:ShowInvitedListGUI()
                end
                return
            end
        end
    end
end

----------------------------------------------------
-- UI Handling
----------------------------------------------------
function PortalInviter:ShowInvitedListGUI()
    if self.invitedListFrame and self.invitedListFrame:IsShown() then
        self.invitedListFrame:Hide()
        return
    end

    self.invitedListFrame = AceGUI:Create("Frame")
    self.invitedListFrame:SetTitle("PortalInviter - Current Party")
    self.invitedListFrame:SetStatusText("List of recently invited players")
    self.invitedListFrame:SetLayout("Flow")
    self.invitedListFrame:SetWidth(300)
    self.invitedListFrame:SetHeight(300)

    self.invitedListScroll = AceGUI:Create("ScrollFrame")
    self.invitedListScroll:SetLayout("List")
    self.invitedListScroll:SetFullWidth(true)
    self.invitedListScroll:SetFullHeight(true)
    self.invitedListFrame:AddChild(self.invitedListScroll)

    self:RefreshInvitedListGUI()
end

function PortalInviter:RefreshInvitedListGUI()
    if not self.invitedListFrame or not self.invitedListFrame:IsShown() or not self.invitedListScroll then
        return
    end

    self.invitedListScroll:ReleaseChildren()

    local lastClickedName = nil  -- Declare outside the loop if you want it to persist between updates

    for _, info in ipairs(self.invitedPlayers) do
        local timestamp = date("%H:%M:%S", info.time)
        local nameLabel = AceGUI:Create("InteractiveLabel")
        nameLabel:SetFullWidth(true)
        nameLabel:SetText(string.format("[%s] %s - %s", timestamp, info.name, info.destination))

        nameLabel:SetCallback("OnClick", function()
            if lastClickedName == info.name then
                self:HideAllButtons()
                lastClickedName = nil
                return
            end

            lastClickedName = info.name

            -- Show all your buttons here as you normally do:
            self.targetButton:SetAttribute("macrotext", "/target " .. info.name)
            self.targetButton:Show()
            self:Print("Click the 'Target Player' button to target " .. info.name)

            self.tradeButton:SetAttribute("macrotext", "/trade " .. info.name)
            self.tradeButton:Show()
            self:Print("Click the 'Trade Player' button to attempt a trade with " .. info.name)

            self.portalButton:SetAttribute("macrotext", "/cast Frost Armor")
            self.portalButton:Show()
            self:Print("Click to send the player to " .. info.destination)
        end)

        self.invitedListScroll:AddChild(nameLabel)
    end
end

----------------------------------------------------
-- Trade Handling and Gold Checking
----------------------------------------------------
function PortalInviter:SetupTradeEvents()
    self.tradeFrame = CreateFrame("Frame", nil, UIParent)
    self.tradeFrame:RegisterEvent("TRADE_SHOW")
    self.tradeFrame:RegisterEvent("TRADE_CLOSED")
    self.tradeFrame:RegisterEvent("TRADE_MONEY_CHANGED")
    self.tradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")

    local initialPlayerMoney = 0
    self.tradeFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "TRADE_SHOW" then
            initialPlayerMoney = GetMoney()
            PortalInviter:Print("Trade started. Waiting for customer to put gold.")

        elseif event == "TRADE_MONEY_CHANGED" or event == "TRADE_ACCEPT_UPDATE" then
            local targetMoney = GetTargetTradeMoney()
            local targetGold = floor(targetMoney / 10000)
            if targetGold >= desiredGoldAmount then
                PortalInviter:Print("The other player has offered enough gold ("..targetGold.."g). You can now press Trade.")
                self.portalButton:SetAttribute("macrotext", "/cast Portal: Orgrimmar")
                self.portalButton:Show()
                PortalInviter:Print("Click the 'Cast Portal' button after trade to open the portal.")
            else
                PortalInviter:Print("Customer hasn't offered enough gold yet. Currently: "..targetGold.."g")
            end

        elseif event == "TRADE_CLOSED" then
            local finalMoney = GetMoney()
            local gained = finalMoney - initialPlayerMoney
            if gained > 0 then
                local gainedGold = gained / 10000
                PortalInviter:Print("Trade completed. You gained " .. gainedGold .. " gold.")
            else
                PortalInviter:Print("Trade closed with no gain.")
            end
        end
    end)
end

----------------------------------------------------
-- Core Logic
----------------------------------------------------
function PortalInviter:ProcessMessage(event, msg, sender, _, channelName)
    if not self.db.profile.enabled then return end

    local nameWithoutRealm = Ambiguate(sender, "short")
    if nameWithoutRealm == UnitName("player") then return end
    if not isRelevantChannel(event, channelName) then return end

    local trigger = containsTrigger(msg, self:ParseTriggers())
    if not trigger then return end

    self:DebugPrint("Matched trigger from:", nameWithoutRealm, "Event:", event, "Msg:", msg)

    local dest = guessDestination(msg)
    SendWho(nameWithoutRealm)

    self.whoQueue[nameWithoutRealm] = { requestedDest = dest, sourceMsg = msg }
    self:DebugPrint("Sent who query for:", nameWithoutRealm)
end

function PortalInviter:OnWhoListUpdate()
    if not self.db.profile.enabled then return end
    self:DebugPrint("OnWhoListUpdate triggered")
    local count = GetNumWhoResults()
    self:DebugPrint("Number of who results:", count)

    for i = 1, count do
        local name, guild, level, race, class, zone = GetWhoInfo(i)
        local shortName = Ambiguate(name, "short")
        self:DebugPrint("Who result:", i, name, zone)

        if self.whoQueue[shortName] then
            local info = self.whoQueue[shortName]
            self.whoQueue[shortName] = nil

            self:DebugPrint("OnWhoListUpdate: Found who result for", shortName, "RequestDest:", info.requestedDest)
            
            -- Invite the player
            self:DebugPrint("Inviting", shortName, "for a portal to", info.requestedDest)
            InviteUnit(name)

            if self.db.profile.inviteWhisper then
                local whisperMsg = "[PortalInviter] " .. string.format(self.db.profile.inviteWhisperTemplate, info.requestedDest)
                self:DebugPrint("Whispering:", shortName, whisperMsg)
                CTL:SendChatMessage("NORMAL", "portal_inviter", whisperMsg, "WHISPER", nil, name)
            end

            table.insert(self.invitedPlayers, { name = shortName, destination = info.requestedDest, time = time() })
            self:RefreshInvitedListGUI()
        end
    end
end
