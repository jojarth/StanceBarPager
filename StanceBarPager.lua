local addonName, addon = ...

SLASH_STANCEBARPAGER1 = "/sbp"
SLASH_STANCEBARPAGER2 = "/stancebar"
SLASH_STANCEBARPAGER3 = "/sdp"
SlashCmdList["STANCEBARPAGER"] = function()
    if addon.ToggleWindow then
        addon.ToggleWindow()
    else
        print("|cffff5555StanceBarPager:|r UI failed to initialize.")
    end
end

local TARGET_BARS = {
    { id = 2, name = "Action Bar 2", frame = "MultiBarBottomLeft",  defaultPage = 6 },
    { id = 3, name = "Action Bar 3", frame = "MultiBarBottomRight", defaultPage = 5 },
    { id = 4, name = "Action Bar 4", frame = "MultiBarRight",       defaultPage = 3 },
    { id = 5, name = "Action Bar 5", frame = "MultiBarLeft",        defaultPage = 4 },
}

local ALL_PAGES = {
    { page = 0,  label = "Default (Keep Bar's Normal Page)",  editBar = nil },
    { page = 1,  label = "Page 1 (Action Bar 1)",             editBar = nil },
    { page = 2,  label = "Page 2 (Bar 1 Scroll Page)",        editBar = nil },
    { page = 3,  label = "Page 3 (Action Bar 4)",             editBar = "MultiBarRight" },
    { page = 4,  label = "Page 4 (Action Bar 5)",             editBar = "MultiBarLeft" },
    { page = 5,  label = "Page 5 (Action Bar 3)",             editBar = "MultiBarBottomRight" },
    { page = 6,  label = "Page 6 (Action Bar 2)",             editBar = "MultiBarBottomLeft" },
    { page = 7,  label = "Page 7 (Stance 1 / Cat / Stealth)", editBar = nil },
    { page = 8,  label = "Page 8 (Stance 2 / Bear / Shadow)", editBar = nil },
    { page = 9,  label = "Page 9 (Stance 3 / Moonkin)",       editBar = nil },
    { page = 10, label = "Page 10 (Extra Form / Override)",   editBar = nil },
    { page = 11, label = "Page 11 (Special / Skyriding)",     editBar = nil },
    { page = 12, label = "Page 12 (Legacy Bonus Page)",       editBar = nil },
    { page = 13, label = "Page 13 (Action Bar 6)",            editBar = "MultiBar5" },
    { page = 14, label = "Page 14 (Action Bar 7)",            editBar = "MultiBar6" },
    { page = 15, label = "Page 15 (Action Bar 8)",            editBar = "MultiBar7" },
}

local CLASS_STANCES = {
    WARRIOR = { "No Stance", "Stance 1 (Battle)", "Stance 2 (Defensive)", "Stance 3 (Berserker)", "Stance 4 (Extra)" },
    DRUID   = { "Humanoid Form", "Form 1 (Bear)", "Form 2 (Cat)", "Form 3 (Travel)", "Form 4 (Moonkin / Treant)" },
    ROGUE   = { "Normal (Unstealthed)", "Stance 1 (Stealth)", "Stance 2 (Shadow Dance / Vanish)", "Stance 3 (Extra)", "Stance 4 (Extra)" },
    PRIEST  = { "Normal Form", "Form 1 (Shadowform)", "Form 2 (Extra)", "Form 3 (Extra)", "Form 4 (Extra)" },
    PALADIN = { "No Aura", "Aura 1", "Aura 2", "Aura 3", "Aura 4" },
    DEFAULT = { "Stance 0 (Default)", "Stance 1", "Stance 2", "Stance 3", "Stance 4" },
}

local stateHandlers = {}

local function InitDB()
    if not StanceBarPagerDB then StanceBarPagerDB = {} end
    for _, bar in ipairs(TARGET_BARS) do
        if not StanceBarPagerDB[bar.id] then StanceBarPagerDB[bar.id] = {} end
    end
end

local function CountSpellsOnPage(pageNum)
    if not pageNum or pageNum < 1 or pageNum > 15 then return 0 end
    local count = 0
    local startSlot = (pageNum - 1) * 12 + 1
    for slot = startSlot, startSlot + 11 do
        if HasAction(slot) then count = count + 1 end
    end
    return count
end
local function GetPageStatus(pageNum, currentBarId, currentStanceKey)
    if not pageNum or pageNum == 0 then return "", false end
    local pageInfo
    for _, p in ipairs(ALL_PAGES) do
        if p.page == pageNum then pageInfo = p break end
    end
    if not pageInfo then return "", false end

    local notes = {}
    local spellCount = CountSpellsOnPage(pageNum)
    local isBlocked = false

    for _, b in ipairs(TARGET_BARS) do
        if b.id == currentBarId and b.defaultPage == pageNum then
            table.insert(notes, "|cff00ff00Default|r")
        end
    end

    for barId, stances in pairs(StanceBarPagerDB) do
        for stanceKey, assignedPage in pairs(stances) do
            if assignedPage == pageNum and not (barId == currentBarId and stanceKey == currentStanceKey) then
                local stanceNum = tonumber(string.match(stanceKey, "%d+")) or 0
                table.insert(notes, string.format("|cffffaa00[USED: Bar %d Stance %d]|r", barId, stanceNum))
                isBlocked = true
            end
        end
    end

    if pageInfo.editBar then
        local frame = _G[pageInfo.editBar]
        local isSelf = false
        for _, b in ipairs(TARGET_BARS) do
            if b.id == currentBarId and b.frame == pageInfo.editBar then isSelf = true end
        end
        if frame and frame:IsShown() and not isSelf then
            table.insert(notes, "|cffff5555[IN USE - Visible Bar]|r")
            isBlocked = true
        end
    end

    if pageNum == 1 then
        table.insert(notes, "|cffff5555[IN USE - Action Bar 1]|r")
        isBlocked = true
    elseif pageNum == 2 then
        table.insert(notes, "|cffffaa00[Bar 1 Scroll Page]|r")
        isBlocked = true
    elseif pageNum >= 7 and pageNum <= 10 then
        local formIndex = pageNum - 6
        local numForms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
        if formIndex <= numForms then
            table.insert(notes, "|cffff5555[RESERVED - Bar 1 Form " .. formIndex .. "]|r")
            isBlocked = true
        end
    elseif pageNum == 11 or pageNum == 12 then
        table.insert(notes, "|cffff5555[RESERVED - Skyriding/System]|r")
        isBlocked = true
    end

    if not isBlocked then
        if spellCount > 0 then
            table.insert(notes, string.format("|cff88ccff[FREE - %d Spells]|r", spellCount))
        else
            table.insert(notes, "|cff00ff00[FREE - Empty]|r")
        end
    elseif spellCount > 0 then
        table.insert(notes, string.format("|cffaaaaaa(%d spells)|r", spellCount))
    end

    local statusStr = (#notes > 0) and (" - " .. table.concat(notes, " ")) or ""
    return statusStr, isBlocked
end

local SECURE_SNIPPET = "local page = tonumber(newstate)\nif not page then return end\nlocal bar = self:GetFrameRef('bar')\nif bar then bar:SetAttribute('actionpage', page) end\nfor i = 1, 12 do\nlocal btn = self:GetFrameRef('btn' .. i)\nif btn then\nbtn:SetAttribute('actionpage', page)\nbtn:SetAttribute('action', (page - 1) * 12 + i)\nend\nend"

local function ApplyPagingRules()
    if InCombatLockdown() then
        print("|cffff5555StanceBarPager:|r Cannot update bar bindings in combat. Will apply after combat.")
        return
    end

    for _, bar in ipairs(TARGET_BARS) do
        local barFrame = _G[bar.frame]
        if barFrame then
            if not stateHandlers[bar.id] then
                local handler = CreateFrame("Frame", "StanceBarPagerHandler" .. bar.id, UIParent, "SecureHandlerStateTemplate")
                handler:SetFrameRef("bar", barFrame)
                for btnIdx = 1, 12 do
                    local btn = _G[bar.frame .. "Button" .. btnIdx]
                    if btn then
                        handler:SetFrameRef("btn" .. btnIdx, btn)
                        if not btn.sbpHooked then
                            btn:HookScript("OnAttributeChanged", function(self, name)
                                if (name == "actionpage" or name == "action") and self.UpdateAction then
                                    self:UpdateAction(true)
                                end
                            end)
                            btn.sbpHooked = true
                        end
                    end
                end
                handler:SetAttribute("_onstate-stancepage", SECURE_SNIPPET)
                stateHandlers[bar.id] = handler
            end

            local rules = {}
            local db = StanceBarPagerDB[bar.id]
            for stanceIdx = 1, 4 do
                local targetPage = db["s" .. stanceIdx]
                if targetPage and targetPage > 0 then
                    table.insert(rules, string.format("[stance:%d] %d", stanceIdx, targetPage))
                end
            end

            local basePage = db["s0"]
            local fallbackPage = (basePage and basePage > 0) and basePage or bar.defaultPage
            table.insert(rules, tostring(fallbackPage))
            RegisterStateDriver(stateHandlers[bar.id], "stancepage", table.concat(rules, "; "))
        end
    end
end

local function ExportProfileString()
    local parts = {}
    for _, bar in ipairs(TARGET_BARS) do
        local db = StanceBarPagerDB[bar.id]
        if db then
            local entries = {}
            for stanceIdx = 0, 4 do
                local key = "s" .. stanceIdx
                local page = db[key]
                if page and page > 0 then table.insert(entries, key .. "=" .. page) end
            end
            if #entries > 0 then table.insert(parts, bar.id .. "," .. table.concat(entries, ",")) end
        end
    end
    return "SBP1:" .. table.concat(parts, ";")
end

local function ImportProfileString(str)
    if not str or type(str) ~= "string" then return false, "Empty string" end
    str = str:match("^%s*(.-)%s*$")
    if not str:match("^SBP1:") then return false, "Invalid code (must start with SBP1:)" end

    local body = str:sub(6)
    local newDB = {}
    for _, bar in ipairs(TARGET_BARS) do newDB[bar.id] = {} end

    if body ~= "" then
        for barChunk in string.gmatch(body, "[^;]+") do
            local tokens = {}
            for tok in string.gmatch(barChunk, "[^,]+") do table.insert(tokens, tok) end
            local barId = tonumber(tokens)
            if barId and newDB[barId] then
                for i = 2, #tokens do
                    local k, v = string.match(tokens[i], "^(s[0-4])=(%d+)$")
                    local pageNum = tonumber(v)
                    if k and pageNum and pageNum >= 1 and pageNum <= 15 then newDB[barId][k] = pageNum end
                end
            end
        end
    end

    StanceBarPagerDB = newDB
    ApplyPagingRules()
    return true, "Profile imported successfully!"
end
local function CreateOptionsUI()
    local win = CreateFrame("Frame", "StanceBarPagerWindow", UIParent, "BasicFrameTemplateWithInset")
    win:SetSize(610, 415)
    win:SetPoint("CENTER")
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:SetFrameStrata("DIALOG")
    win:Hide()
    win.TitleText:SetText("StanceBarPager - Stance & Form Bar Paging")

    local _, playerClass = UnitClass("player")
    local stanceNames = CLASS_STANCES[playerClass] or CLASS_STANCES.DEFAULT
    local selectedBarId = 2
    local selectorButtons = {}
    local showBlocked = false

    local picker = CreateFrame("Frame", "StanceBarPagerPicker", win, "BackdropTemplate")
    picker:SetSize(450, 345)
    picker:SetFrameStrata("FULLSCREEN_DIALOG")
    picker:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    picker:Hide()

    local activeStanceKey = nil
    local pickerRows = {}

    local function RefreshSelectorButtons()
        for stanceIdx = 0, 4 do
            local key = "s" .. stanceIdx
            local btn = selectorButtons[key]
            local savedPage = StanceBarPagerDB[selectedBarId][key] or 0
            if savedPage == 0 then
                btn:SetText("Default (Keep Bar's Normal Page)")
            else
                local statusStr = GetPageStatus(savedPage, selectedBarId, key)
                btn:SetText("Page " .. savedPage .. statusStr)
            end
        end
    end

    for idx, p in ipairs(ALL_PAGES) do
        local rowBtn = CreateFrame("Button", nil, picker)
        rowBtn:SetSize(430, 20)
        rowBtn:SetPoint("TOPLEFT", 10, -8 - ((idx - 1) * 20))
        rowBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        local txt = rowBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        txt:SetPoint("LEFT", 6, 0)
        txt:SetJustifyH("LEFT")
        rowBtn.label = txt

        rowBtn:SetScript("OnClick", function()
            if activeStanceKey then
                StanceBarPagerDB[selectedBarId][activeStanceKey] = (p.page == 0) and nil or p.page
                RefreshSelectorButtons()
                ApplyPagingRules()
            end
            picker:Hide()
        end)
        pickerRows[idx] = { btn = rowBtn, info = p }
    end

    local showAllCheck = CreateFrame("CheckButton", "StanceBarPagerShowAllCheck", win, "UICheckButtonTemplate")
    showAllCheck:SetSize(24, 24)
    showAllCheck:SetPoint("TOPRIGHT", -205, -32)
    showAllCheck.text = showAllCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    showAllCheck.text:SetPoint("LEFT", showAllCheck, "RIGHT", 2, 0)
    showAllCheck.text:SetText("Show unavailable / reserved pages")
    showAllCheck:SetScript("OnClick", function(self)
        showBlocked = self:GetChecked()
        picker:Hide()
    end)

    local function OpenPickerFor(anchorBtn, stanceKey)
        if picker:IsShown() and activeStanceKey == stanceKey then
            picker:Hide()
            return
        end
        activeStanceKey = stanceKey
        local visibleIndex = 0
        for _, item in ipairs(pickerRows) do
            local status, isBlocked = GetPageStatus(item.info.page, selectedBarId, stanceKey)
            local isCurrentlySelected = (StanceBarPagerDB[selectedBarId][stanceKey] == item.info.page)
            if not isBlocked or showBlocked or isCurrentlySelected then
                visibleIndex = visibleIndex + 1
                item.btn:ClearAllPoints()
                item.btn:SetPoint("TOPLEFT", 10, -8 - ((visibleIndex - 1) * 20))
                if isBlocked then
                    item.btn.label:SetText("|cff888888" .. item.info.label .. "|r" .. status)
                else
                    item.btn.label:SetText(item.info.label .. status)
                end
                item.btn:Show()
            else
                item.btn:Hide()
            end
        end
        picker:SetHeight(math.max(40, visibleIndex * 20 + 18))
        picker:ClearAllPoints()
        picker:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)
        picker:Show()
    end
    local barLabel = win:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    barLabel:SetPoint("TOPLEFT", 18, -36)
    barLabel:SetText("1. Choose Which Bar to Configure:")

    local barButtons = {}
    for idx, bar in ipairs(TARGET_BARS) do
        local btn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
        btn:SetSize(132, 26)
        btn:SetPoint("TOPLEFT", barLabel, "BOTTOMLEFT", (idx - 1) * 140, -8)
        btn:SetText(bar.name)
        btn:SetScript("OnClick", function()
            selectedBarId = bar.id
            picker:Hide()
            for _, b in ipairs(barButtons) do b:Enable() end
            btn:Disable()
            RefreshSelectorButtons()
        end)
        if bar.id == selectedBarId then btn:Disable() end
        table.insert(barButtons, btn)
    end

    local stanceHeader = win:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    stanceHeader:SetPoint("TOPLEFT", barLabel, "BOTTOMLEFT", 0, -50)
    stanceHeader:SetText("2. Click a Button Below to Assign a Page per Stance / Form:")

    for stanceIdx = 0, 4 do
        local key = "s" .. stanceIdx
        local rowLabel = win:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        rowLabel:SetPoint("TOPLEFT", stanceHeader, "BOTTOMLEFT", 0, -18 - (stanceIdx * 38))
        rowLabel:SetText(stanceNames[stanceIdx + 1] or ("Stance " .. stanceIdx))

        local selBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
        selBtn:SetSize(370, 26)
        selBtn:SetPoint("LEFT", rowLabel, "LEFT", 195, 0)
        selBtn:SetScript("OnClick", function() OpenPickerFor(selBtn, key) end)
        selectorButtons[key] = selBtn
    end

    RefreshSelectorButtons()

    local tip = win:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    tip:SetPoint("BOTTOMLEFT", 18, 14)
    tip:SetWidth(425)
    tip:SetJustifyH("LEFT")
    tip:SetText("|cff88ccffTip:|r Enable Bar 6, 7, or 8 in Edit Mode to place spells on Pages 13-15, then hide them.")

    local ieWin = CreateFrame("Frame", "StanceBarPagerIEWindow", win, "BasicFrameTemplateWithInset")
    ieWin:SetSize(440, 175)
    ieWin:SetPoint("CENTER", win, "CENTER", 0, 0)
    ieWin:SetFrameStrata("FULLSCREEN_DIALOG")
    ieWin:Hide()
    ieWin.TitleText:SetText("Import / Export Profile String")

    local ieDesc = ieWin:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    ieDesc:SetPoint("TOPLEFT", 16, -32)
    ieDesc:SetText("Press Ctrl+C to copy your export code, or paste a code below and click Import:")

    local editBox = CreateFrame("EditBox", nil, ieWin, "InputBoxTemplate")
    editBox:SetSize(390, 28)
    editBox:SetPoint("TOPLEFT", ieDesc, "BOTTOMLEFT", 6, -12)
    editBox:SetAutoFocus(true)
    editBox:SetScript("OnEscapePressed", function() ieWin:Hide() end)

    local statusTxt = ieWin:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    statusTxt:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", -4, -8)
    statusTxt:SetText("")

    local applyImportBtn = CreateFrame("Button", nil, ieWin, "UIPanelButtonTemplate")
    applyImportBtn:SetSize(130, 26)
    applyImportBtn:SetPoint("BOTTOMRIGHT", -16, 14)
    applyImportBtn:SetText("Import Code")
    applyImportBtn:SetScript("OnClick", function()
        local ok, msg = ImportProfileString(editBox:GetText())
        if ok then
            statusTxt:SetText("|cff00ff00" .. msg .. "|r")
            RefreshSelectorButtons()
        else
            statusTxt:SetText("|cffff5555" .. msg .. "|r")
        end
    end)

    local copyRefreshBtn = CreateFrame("Button", nil, ieWin, "UIPanelButtonTemplate")
    copyRefreshBtn:SetSize(140, 26)
    copyRefreshBtn:SetPoint("BOTTOMLEFT", 16, 14)
    copyRefreshBtn:SetText("Generate Export")
    copyRefreshBtn:SetScript("OnClick", function()
        local code = ExportProfileString()
        editBox:SetText(code)
        editBox:HighlightText()
        editBox:SetFocus()
        statusTxt:SetText("|cff88ccffPress Ctrl+C to copy!|r")
    end)

    local ieBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    ieBtn:SetSize(130, 26)
    ieBtn:SetPoint("BOTTOMRIGHT", -16, 14)
    ieBtn:SetText("Import / Export")
    ieBtn:SetScript("OnClick", function()
        local code = ExportProfileString()
        editBox:SetText(code)
        editBox:HighlightText()
        editBox:SetFocus()
        statusTxt:SetText("|cff88ccffPress Ctrl+C to copy, or paste a code to import.|r")
        ieWin:Show()
    end)

    addon.ToggleWindow = function()
        if win:IsShown() then
            picker:Hide()
            ieWin:Hide()
            win:Hide()
        else
            RefreshSelectorButtons()
            win:Show()
        end
    end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local panel = CreateFrame("Frame")
        panel.name = "StanceBarPager"
        local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        openBtn:SetSize(220, 32)
        openBtn:SetPoint("TOPLEFT", 20, -20)
        openBtn:SetText("Open StanceBarPager Config")
        openBtn:SetScript("OnClick", function() addon.ToggleWindow() end)
        local cat = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(cat)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitDB()
        CreateOptionsUI()
        ApplyPagingRules()
        print("|cff00ff00StanceBarPager loaded!|r Type |cff88ccff/sbp|r or |cff88ccff/sdp|r to open the config window.")
    elseif event == "PLAYER_REGEN_ENABLED" then
        ApplyPagingRules()
    end
end)
