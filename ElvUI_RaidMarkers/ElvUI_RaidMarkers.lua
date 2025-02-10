local E, L, V, P, G = unpack(ElvUI)
local RM = E:NewModule('RaidMarkersBar')
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local CreateFrame = CreateFrame
local UnregisterStateDriver = UnregisterStateDriver
local RegisterStateDriver = RegisterStateDriver

-- Profile
P['actionbar']['raidmarkersbar'] = {
    ['visible'] = 'AUTOMATIC',
    ['orient'] = 'HORIZONTAL',
    ['sort'] = 'DESCENDING',
    ['buttonSize'] = 18,
    ['buttonSpacing'] = 5,
    ['backdropShow'] = true,
    ['buttonBackdropShow'] = true,
    ['frameStrata'] = 'LOW'
}

-- Config
local function RaidMarkersBarOptions()
    E.Options.args.actionbar.args.raidMarkers = ACH:Group(L["Raid Markers Bar"], nil, 1000, nil, function(info) return E.db.actionbar.raidmarkersbar[info[#info]] end, function(info, value) E.db.actionbar.raidmarkersbar[info[#info]] = value; RM:UpdateBar() end)
    E.Options.args.actionbar.args.raidMarkers.args = {
        visible = ACH:Select(L["Visibility"], L["Select how the raid markers bar will be displayed."], 1, {
            ['HIDE'] = L["Hide"],
            ['SHOW'] = L["Show"],
            ['AUTOMATIC'] = L["Automatic"]
        }),
        sort = ACH:Select(L["Sort Direction"], L["The direction that the mark frames will grow from the anchor."], 2, {
            ['ASCENDING'] = L["Ascending"],
            ['DESCENDING'] = L["Descending"]
        }),
        orient = ACH:Select(L["Bar Direction"], L["Choose the orientation of the raid markers bar."], 3, {
            ['HORIZONTAL'] = L["Horizontal"],
            ['VERTICAL'] = L["Vertical"]
        }),
        buttonSize = ACH:Range(L["Button Size"], L["The size of the action buttons."], 4, {min = 15, max = 60, step = 1}),
        buttonSpacing = ACH:Range(L["Button Spacing"], L["The spacing between buttons."], 5, {min = -1, max = 10, step = 1}),
        backdropShow = ACH:Toggle(L["Show Bar Backdrop"], L["Toggle the visibility of the bar backdrop."], 6),
        buttonBackdropShow = ACH:Toggle(L["Show Button Backdrop"], L["Toggle the visibility of the button backdrops."], 7),
        frameStrata = ACH:Select(L["Frame Strata"], L["Set the frame strata for the raid markers bar."], 8, {
            ['BACKGROUND'] = L["Background"],
            ['LOW'] = L["Low"],
            ['MEDIUM'] = L["Medium"],
            ['HIGH'] = L["High"],
            ['DIALOG'] = L["Dialog"],
            ['FULLSCREEN'] = L["Fullscreen"],
            ['FULLSCREEN_DIALOG'] = L["Fullscreen Dialog"],
            ['TOOLTIP'] = L["Tooltip"]
        })
    }
end

function RM:UpdateButtons()
    for i = 1, 9 do
        local button = RM.frame.buttons[i]
        if RM.db.buttonBackdropShow then
            button:SetTemplate('Transparent')
        else
            button:SetTemplate('NoBackdrop')
        end
        button:Size(RM.db.buttonSize)
    end
end

function RM:UpdateBar(first)
    if first then
        RM.frame:ClearAllPoints()
        RM.frame:Point('CENTER')
    end

    if RM.db.orient == 'VERTICAL' then
        RM.frame:Height((RM.db.buttonSize + RM.db.buttonSpacing) * 9 + RM.db.buttonSpacing)
        RM.frame:Width(RM.db.buttonSize + (RM.db.buttonSpacing*2))
    else
        RM.frame:Width((RM.db.buttonSize + RM.db.buttonSpacing) * 9 + RM.db.buttonSpacing)
        RM.frame:Height(RM.db.buttonSize + (RM.db.buttonSpacing*2))
    end

    -- Set the frame strata
    RM.frame:SetFrameStrata(RM.db.frameStrata)

    -- Toggle bar backdrop
    if RM.db.backdropShow then
        RM.frame:SetTemplate('Transparent')
    else
        RM.frame:SetTemplate('NoBackdrop')
    end

    RM:UpdateButtons()

    for i = 1, 9 do
        local button = RM.frame.buttons[i]
        local prev = RM.frame.buttons[i - 1]
        button:ClearAllPoints()

        if RM.db.orient == 'HORIZONTAL' and RM.db.sort == 'ASCENDING' then
            if i == 1 then
                button:Point('LEFT', RM.db.buttonSpacing, 0)
            elseif prev then
                button:Point('LEFT', prev, 'RIGHT', RM.db.buttonSpacing, 0)
            end
        elseif RM.db.orient == 'VERTICAL' and RM.db.sort == 'ASCENDING' then
            if i == 1 then
                button:Point('TOP', 0, -RM.db.buttonSpacing)
            elseif prev then
                button:Point('TOP', prev, 'BOTTOM', 0, -RM.db.buttonSpacing)
            end
        elseif RM.db.orient == 'HORIZONTAL' and RM.db.sort == 'DESCENDING' then
            if i == 1 then
                button:Point('RIGHT', -RM.db.buttonSpacing, 0)
            elseif prev then
                button:Point('RIGHT', prev, 'LEFT', -RM.db.buttonSpacing, 0)
            end
        else
            if i == 1 then
                button:Point('BOTTOM', 0, RM.db.buttonSpacing, 0)
            elseif prev then
                button:Point('BOTTOM', prev, 'TOP', 0, RM.db.buttonSpacing)
            end
        end
    end

    if RM.db.visible == 'HIDE' then
        UnregisterStateDriver(RM.frame, 'visibility')
        if RM.frame:IsShown() then
            RM.frame:Hide()
        end
    elseif RM.db.visible == 'SHOW' then
        UnregisterStateDriver(RM.frame, 'visibility')
        if not RM.frame:IsShown() then
            RM.frame:Show()
        end
    else
        RegisterStateDriver(RM.frame, 'visibility', '[noexists,nogroup] hide; show')
    end
end

function RM:ButtonFactory()
    for i = 1, 9 do
        local button = CreateFrame('Button', ('ElvUI_RaidMarkersBarButton%d'):format(i), RM.frame, 'SecureActionButtonTemplate')

        local image = button:CreateTexture(nil, 'OVERLAY')
        image:SetInside()
        image:SetTexture(i == 9 and [[Interface\BUTTONS\UI-GroupLoot-Pass-Up]] or ([[Interface\TargetingFrame\UI-RaidTargetingIcon_%d]]):format(i))

        button:SetAttribute('type1', 'macro')
        button:SetAttribute('macrotext1', ('/run SetRaidTargetIcon(\'target\', %d)'):format(i < 9 and i or 0))

        button:SetScript('OnEnter', function(self)
            _G.GameTooltip:SetOwner(self, 'ANCHOR_BOTTOM')
            _G.GameTooltip:AddLine(i == 9 and L["Click to clear the mark."] or L["Click to mark the target."], 1, 1, 1)
            _G.GameTooltip:Show()
        end)
        button:SetScript('OnLeave', function() _G.GameTooltip:Hide() end)

        button:StyleButton()
        button:RegisterForClicks('AnyDown')

        RM.frame.buttons[i] = button
    end
end

function RM:Initialize()
    RM.db = E.db.actionbar.raidmarkersbar

    RM.frame = CreateFrame('Frame', 'ElvUI_RaidMarkersBar', E.UIParent, 'SecureHandlerStateTemplate')
    RM.frame:SetResizable(false)
    RM.frame:SetClampedToScreen(true)
    RM.frame:SetTemplate('Transparent')
    RM.frame:SetFrameStrata(RM.db.frameStrata)

    RM.frame.buttons = {}
    RM:ButtonFactory()
    RM:UpdateBar(true)

    E:CreateMover(RM.frame, 'ElvUI_RMBarMover', L["Raid Markers Bar"])
end

E:RegisterModule(RM:GetName())

EP:RegisterPlugin(..., RaidMarkersBarOptions)