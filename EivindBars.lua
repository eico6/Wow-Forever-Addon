-- Appearance settings. Edit these numbers, save the file, then type /reload in WoW.
local EAGLE_SIZE_PERCENT = 89    -- 100 is the original Blizzard size.
local EAGLE_OUTWARD_PX = 3       -- Each eagle moves away from its nearest button. 0 is tucked in.
local EAGLE_DOWN_PX = 4          -- Larger values lower the eagles toward the screen edge.
local XP_EXTRA_HEIGHT_PX = 0     -- 0 meets the lower rim. +1 raises the top one pixel, -1 lowers it.
local LEDGE_HEIGHT_PX = 5        -- Extra space for the stone ledge between the two bottom rows.
local RIM_IDLE_BRIGHTNESS = 0.75 -- 1 uses the sampled bronze at full brightness.
local RIM_DRAG_BRIGHTNESS = 1.00 -- Brightness while WoW shows the action-button grid.
local UPPER_BAR_GAP_PX = 0       -- Extra space between the stone ledge and the bar above it. Does not change the ledge art.

local function ScreenPixel()
    return UIParent:GetHeight() / select(2, GetPhysicalScreenSize())
end

local bar = MainActionBar or MainMenuBar
if not bar then
    return
end

local backing = CreateFrame("Frame", nil, bar, "BackdropTemplate")
backing.ignoreInLayout = true
backing:SetFrameStrata("BACKGROUND")
backing:SetFrameLevel(1)
backing:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
})
backing:SetBackdropColor(0.13, 0.095, 0.065, 1)
backing:SetBackdropBorderColor(0.64, 0.47, 0.30, 1)
backing:Hide()

local function AddRail(point, inset, red, green, blue)
    local rail = backing:CreateTexture(nil, "ARTWORK")
    rail:SetColorTexture(red, green, blue, 1)
    rail:SetPoint(point .. "LEFT", inset, point == "TOP" and -inset or inset)
    rail:SetPoint(point .. "RIGHT", -inset, point == "TOP" and -inset or inset)
    rail:SetHeight(1)
end

AddRail("TOP", 3, 0.43, 0.31, 0.20)
AddRail("BOTTOM", 3, 0.25, 0.17, 0.10)

local function CreateEagleJoin()
    -- The action bar can raise its children during a drag. Keep these behind the XP track.
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(0)
    frame:Hide()

    local shadow = frame:CreateTexture(nil, "BACKGROUND")
    shadow:SetAllPoints()
    shadow:SetColorTexture(0.10, 0.072, 0.049, 1)

    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    frame.texture = texture
    return frame
end

local leftJoin = CreateEagleJoin()
local rightJoin = CreateEagleJoin()
local endCaps = bar.EndCaps

local function UpdateJoinVisibility()
    local show = endCaps:IsVisible() and leftJoin:GetNumPoints() > 0
    leftJoin:SetShown(show)
    rightJoin:SetShown(show)
end

if endCaps then
    endCaps:HookScript("OnShow", UpdateJoinVisibility)
    endCaps:HookScript("OnHide", UpdateJoinVisibility)
end

local function GetRelativeScale(frame)
    return frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

local function GetScreenRect(frame, scaleFrame)
    local left, bottom, width, height = frame:GetRect()
    if not left then
        return
    end

    local scale = GetRelativeScale(scaleFrame or frame)
    return left * scale, bottom * scale, (left + width) * scale, (bottom + height) * scale
end

local function SetScreenPoint(frame, point, x, y)
    local scale = GetRelativeScale(frame)
    frame:SetPoint(point, UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

local function ApplyUnderlayTexture(texture, atlas, mirrored)
    -- Sample inside the native slot texture to reuse the material without a second rim.
    if atlas and (atlas.file or atlas.filename) then
        local width = atlas.rightTexCoord - atlas.leftTexCoord
        local height = atlas.bottomTexCoord - atlas.topTexCoord
        local u1 = atlas.leftTexCoord + width * 0.19
        local u2 = atlas.rightTexCoord - width * 0.19
        texture:SetTexture(atlas.file or atlas.filename)
        texture:SetTexCoord(mirrored and u2 or u1, mirrored and u1 or u2,
            atlas.topTexCoord + height * 0.18, atlas.bottomTexCoord - height * 0.13)
        texture:SetVertexColor(0.84, 0.79, 0.71)
    end
end

local function LayoutEagleJoin(frame, left, right, bottom, top, atlas, mirrored)
    ApplyUnderlayTexture(frame.texture, atlas, mirrored)
    frame:ClearAllPoints()
    SetScreenPoint(frame, "BOTTOMLEFT", left, bottom)
    SetScreenPoint(frame, "TOPRIGHT", right, top)
end

local xpBacking
local xpBar

local function AddXPBacking(atlas)
    if xpBacking then
        return
    end

    local container = MainStatusTrackingBarContainer
    local barTypes = StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum
    local experience = container and container.bars and barTypes and container.bars[barTypes.Experience]
    if not experience and container then
        for _, child in ipairs({ container:GetChildren() }) do
            if child.StatusBar and child.GetLevelData then
                experience = child
                break
            end
        end
    end

    local statusBar = experience and experience.StatusBar
    if not statusBar then
        return
    end
    xpBar = experience

    -- Draw in the XP bar's own background so action-bar strata changes cannot lift it over the fill.
    local shadow = statusBar:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetAllPoints()
    shadow:SetColorTexture(0.10, 0.072, 0.049, 1)

    xpBacking = statusBar:CreateTexture(nil, "BACKGROUND", nil, -7)
    xpBacking:SetAllPoints()
    ApplyUnderlayTexture(xpBacking, atlas, false)
end

local slotArtwork = {}
local framedButtons = {}
local artHooks = {}

local function ApplyFramedButtonArt(button)
    if not framedButtons[button] then
        return
    end

    button.SlotArt:Show()
    button.SlotBackground:Hide()
    button:SetNormalAtlas("UI-HUD-ActionBar-IconFrame")
    button.NormalTexture:SetDrawLayer("OVERLAY")
    button.NormalTexture:SetSize(46, 45)
    button:SetPushedAtlas("UI-HUD-ActionBar-IconFrame-Down")
    button.PushedTexture:SetDrawLayer("OVERLAY")
    button.PushedTexture:SetSize(46, 45)
end

local function FrameButton(button)
    if not button.SlotArt or not button.SlotBackground or not button.UpdateButtonArt then
        return
    end

    framedButtons[button] = true
    if not artHooks[button] then
        hooksecurefunc(button, "UpdateButtonArt", ApplyFramedButtonArt)
        artHooks[button] = true
    end
    ApplyFramedButtonArt(button)
end

local function ShowSlotArtwork(button, featherAtlas)
    local art = slotArtwork[button]
    if not art then
        -- Keep the art visible when Blizzard hides the empty action button itself.
        art = CreateFrame("Frame", nil, button:GetParent())
        art.ignoreInLayout = true
        art:SetAllPoints(button)

        local feather = art:CreateTexture(nil, "BACKGROUND")
        feather:SetAtlas(featherAtlas)
        feather:SetAllPoints()

        local normal = button:GetNormalTexture()
        local border = art:CreateTexture(nil, "ARTWORK")
        border:SetAllPoints(normal or art)
        art.border = border
        slotArtwork[button] = art
    end

    local normal = button:GetNormalTexture()
    art.border:SetAtlas(normal and normal:GetAtlas() or "UI-HUD-ActionBar-IconFrame")
    art:SetFrameStrata(button:GetFrameStrata())
    art:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
    art:Show()
end

-- The rim was sampled from Bar 1 at this layout's 58-pixel button pitch.
-- Only its four edges are opaque. The button faces and pager draw separately.
local extensionTrim = CreateFrame("Frame", nil, UIParent)
extensionTrim:Hide()
local rim = extensionTrim:CreateTexture(nil, "ARTWORK")
rim:SetTexture("Interface\\AddOns\\EivindBars\\LowerRowRim")
rim:SetTexCoord(0, 353 / 512, 0, 63 / 64)
rim:SetAllPoints()

local pagerPlate = extensionTrim:CreateTexture(nil, "ARTWORK", nil, -1)
pagerPlate:SetTexture("Interface\\AddOns\\EivindBars\\LowerRowRim")
pagerPlate:SetTexCoord(140 / 512, 180 / 512, 0, 63 / 64)
pagerPlate:Hide()

local gridShown = false
local bar3 = MultiBarBottomRight
local strataOrder = { WORLD = 0, BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4,
    DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }
local function UpdateRim()
    if not bar3 then return end
    local strata, level = bar3:GetFrameStrata(), bar3:GetFrameLevel()
    -- The eagle can inherit a higher layer when WoW raises the drag grid.
    local eagle = endCaps and endCaps.RightEndCap
    for _, frame in pairs({backing, MainStatusTrackingBarContainer, endCaps,
        eagle and eagle.GetFrameLevel and eagle}) do
        local other = frame:GetFrameStrata()
        if strataOrder[other] > strataOrder[strata] then
            strata, level = other, frame:GetFrameLevel()
        elseif other == strata then
            level = math.max(level, frame:GetFrameLevel())
        end
    end
    extensionTrim:SetFrameStrata(strata)
    extensionTrim:SetFrameLevel(level + 1)
    local cursorType = GetCursorInfo and GetCursorInfo()
    local dragging = gridShown or cursorType == "action" or cursorType == "spell"
    local light = dragging and RIM_DRAG_BRIGHTNESS or RIM_IDLE_BRIGHTNESS
    rim:SetVertexColor(light, light, light)
    pagerPlate:SetVertexColor(light, light, light)
end

-- Sample the straight rails. The adjacent bar rims already frame the pager's sides.
local function LayoutPagerPlate(left, right)
    local _, low, _, high = GetScreenRect(extensionTrim)
    -- The horizontal rails meet the rims at the tips of their chamfered corners.
    -- Extend past each side wall by the corner width in the sampled rim.
    local cornerWidth = (high - low) * 10 / 63
    local scale = GetRelativeScale(extensionTrim)
    pagerPlate:ClearAllPoints()
    pagerPlate:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (left - cornerWidth) / scale, low / scale)
    pagerPlate:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", (right + cornerWidth) / scale, high / scale)
    pagerPlate:Show()
end

local function LayoutExtensionTrim(first, last)
    extensionTrim:Hide()
    if not first or not last then return end
    local firstX, centerY = first:GetCenter()
    local lastX = last:GetCenter()
    local scale = GetRelativeScale(first)
    firstX, centerY = firstX * scale, centerY * scale
    lastX = lastX * GetRelativeScale(last)
    local pixel = (lastX - firstX) / (5 * 58)
    if pixel <= 0 then return end

    bar3 = first.bar or MultiBarBottomRight
    UpdateRim()
    extensionTrim:ClearAllPoints()
    local screenPixel = ScreenPixel()
    SetScreenPoint(extensionTrim, "BOTTOMLEFT", firstX - 31.5 * pixel, centerY - 32 * pixel + screenPixel)
    SetScreenPoint(extensionTrim, "TOPRIGHT", lastX + 29.5 * pixel, centerY + 31 * pixel + screenPixel)
    extensionTrim:Show()
end

local xpFoot = CreateFrame("Frame", nil, UIParent)
xpFoot:SetFrameStrata("BACKGROUND")
xpFoot:SetFrameLevel(0)
xpFoot:Hide()
local footTexture = xpFoot:CreateTexture(nil, "BACKGROUND")
footTexture:SetAllPoints()
footTexture:SetColorTexture(0.13, 0.095, 0.065, 1)

local function FitXPBar()
    local track = MainStatusTrackingBarContainer
    if not track then return end
    local face = track.BarFrameTexture or track
    local l, b, r = GetScreenRect(face, track)
    if not l or r <= l then return end
    local firstX = ActionButton1:GetCenter() * GetRelativeScale(ActionButton1)
    local secondX = ActionButton2:GetCenter() * GetRelativeScale(ActionButton2)
    local targetLeft = firstX - (secondX - firstX) * 31.5 / 58
    local targetRight
    if extensionTrim:IsShown() then
        targetRight = select(3, GetScreenRect(extensionTrim))
    else
        -- Profiles with a different button arrangement still get the prototype's XP width.
        local width = ActionButton1:GetWidth() * GetRelativeScale(ActionButton1) * (1088 / 55)
        targetLeft = (l + r - width) / 2
        targetRight = targetLeft + width
    end
    if not targetRight then return end
    local factor = (targetRight - targetLeft) / (r - l)
    local cx = track:GetCenter()
    local newX = targetLeft + (cx * GetRelativeScale(track) - l) * factor
    track:SetScale(track:GetScale() * factor)
    local _, floorY = GetScreenRect(extensionTrim)
    local pixel = ScreenPixel()
    local dockTop
    if extensionTrim:IsShown() and floorY then
        dockTop = (math.floor(floorY / pixel + 0.5) + XP_EXTRA_HEIGHT_PX) * pixel
    end
    if dockTop and dockTop > 2 * pixel then
        track:ClearAllPoints()
        SetScreenPoint(track, "BOTTOMLEFT", targetLeft, 0)
        SetScreenPoint(track, "TOPRIGHT", targetRight, dockTop)
        if face ~= track then
            face:ClearAllPoints()
            face:SetAllPoints(track)
        end
    else
        local _, cy = track:GetCenter()
        local _, faceBottom = GetScreenRect(face, track)
        track:ClearAllPoints()
        SetScreenPoint(track, "CENTER", newX, cy * GetRelativeScale(track) + b - faceBottom)
    end
    if xpBar and extensionTrim:IsShown() then
        local fill = xpBar.StatusBar
        local inset = pixel / GetRelativeScale(fill)
        fill:ClearAllPoints()
        fill:SetPoint("TOPLEFT", face, "TOPLEFT", 2 * inset, -inset)
        fill:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", -2 * inset, inset)
        local rested = xpBar.ExhaustionLevelFillBar
        if rested then
            rested:ClearAllPoints()
            rested:SetAllPoints(fill)
        end
        local overlay = xpBar.OverlayFrame
        if overlay then
            overlay:ClearAllPoints()
            overlay:SetAllPoints(fill)
            for _, region in ipairs({overlay:GetRegions()}) do
                if region:IsObjectType("FontString") then
                    region:ClearAllPoints()
                    region:SetPoint("CENTER", fill, "CENTER")
                    local available = fill:GetHeight() * GetRelativeScale(fill)
                    local textHeight = region:GetStringHeight()
                    if textHeight > 0 then
                        region:SetScale(math.min(1, available / (textHeight * GetRelativeScale(overlay))))
                    end
                end
            end
        end
    end
    xpFoot:SetShown(extensionTrim:IsShown() and track:IsVisible())
    xpFoot:ClearAllPoints()
    SetScreenPoint(xpFoot, "BOTTOMLEFT", targetLeft, 0)
    SetScreenPoint(xpFoot, "TOPRIGHT", targetRight, math.max(2 * pixel, (dockTop or 0) + pixel))
end

-- Keep the stone behind the eagle artwork even when action bars change strata.
local ledge = CreateFrame("Frame", nil, UIParent)
ledge:SetFrameStrata("BACKGROUND")
ledge:SetFrameLevel(0)
local stone = ledge:CreateTexture(nil, "ARTWORK")
stone:SetTexture("Interface\\AddOns\\EivindBars\\StoneLedge.tga")
stone:SetVertexColor(0.34, 0.31, 0.27)
stone:SetAllPoints()
local ledgeHighlight = ledge:CreateTexture(nil, "OVERLAY")
ledgeHighlight:SetColorTexture(0.36, 0.27, 0.18, 0.75)
ledgeHighlight:SetPoint("TOPLEFT")
ledgeHighlight:SetPoint("TOPRIGHT")
ledge:Hide()

-- Remember the Edit Mode anchor so repeated layouts don't add the lift twice.
local upperAnchor
local function LiftUpperBar()
    local upperBar = MultiBarBottomLeft
    if not upperBar or upperBar:GetNumPoints() ~= 1 then return 0 end
    local point, relative, relativePoint, x, y = upperBar:GetPoint(1)
    if not upperAnchor or point ~= upperAnchor.point or relative ~= upperAnchor.relative
        or relativePoint ~= upperAnchor.relativePoint or math.abs(y - upperAnchor.applied) > 0.001 then
        upperAnchor = {point = point, relative = relative, relativePoint = relativePoint, base = y}
    end
    local lift = LEDGE_HEIGHT_PX * ScreenPixel()
    local gap = UPPER_BAR_GAP_PX * ScreenPixel()
    upperAnchor.applied = upperAnchor.base + (lift + gap) / GetRelativeScale(upperBar)
    upperBar:SetPoint(point, relative, relativePoint, x, upperAnchor.applied)
    return lift
end

-- Bar 3 has two rows of six. Measure both rows before moving any grid anchors.
local function AlignBar3()
    local upper = MultiBarBottomLeftButton1
    if not upper or not MultiBarBottomRightButton1 then return end
    local _, lowerY = ActionButton1:GetCenter()
    local _, upperY = upper:GetCenter()
    if not lowerY or not upperY then return end
    lowerY = lowerY * GetRelativeScale(ActionButton1)
    upperY = upperY * GetRelativeScale(upper)
    if upperY <= lowerY then return end

    local positions = {}
    for i = 1, 12 do
        local button = _G["MultiBarBottomRightButton" .. i]
        if not button then return end
        local x, y = button:GetCenter()
        if not x then return end
        local scale = GetRelativeScale(button)
        if x * scale <= select(1, ActionButton12:GetCenter()) * GetRelativeScale(ActionButton12) or x * scale >= UIParent:GetWidth() * 0.82 then return end
        local holder = button.container or button
        local hx, hy = holder:GetCenter()
        local holderScale = GetRelativeScale(holder)
        positions[i] = {holder = holder, x = hx * holderScale, y = y * scale,
            offsetY = hy * holderScale - y * scale}
    end
    local lift = LiftUpperBar()
    upperY = select(2, upper:GetCenter()) * GetRelativeScale(upper)
    for _, pos in ipairs(positions) do
        local targetY = pos.y > (upperY + lowerY) / 2 and upperY or lowerY
        local holder = pos.holder
        local scale = GetRelativeScale(holder)
        local parent = holder:GetParent()
        local px, py = parent:GetCenter()
        local parentScale = GetRelativeScale(parent)
        holder:ClearAllPoints()
        holder:SetPoint("CENTER", parent, "CENTER",
            (pos.x - px * parentScale) / scale,
            (targetY + pos.offsetY - py * parentScale) / scale)
    end
    return lift
end

-- Keep the inner bottom corner fixed while shrinking the native eagle.
local eagleSizes = {}
local function TuckEagle(cap, isLeft, edge, baseline, rowHeight)
    if not cap then return end
    local owner = cap.GetEffectiveScale and cap or cap:GetParent()
    local scale = GetRelativeScale(owner)
    local size = eagleSizes[cap]
    if not size then
        local l, b, r = GetScreenRect(cap, owner)
        if not l then return end
        size = { width = cap:GetWidth(), height = cap:GetHeight(),
            inset = ((isLeft and r or l) - edge) / rowHeight,
            bottom = (b - baseline) / rowHeight }
        eagleSizes[cap] = size
    end
    cap:ClearAllPoints()
    local sizeFactor = EAGLE_SIZE_PERCENT / 100
    cap:SetSize(size.width * sizeFactor, size.height * sizeFactor)
    local outward = EAGLE_OUTWARD_PX * ScreenPixel()
    local x = edge + size.inset * rowHeight + (isLeft and -outward or outward)
    local y = baseline + size.bottom * rowHeight - EAGLE_DOWN_PX * ScreenPixel()
    cap:SetPoint(isLeft and "BOTTOMRIGHT" or "BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

local function LayoutArt()
    if InCombatLockdown() then
        return
    end

    local first = ActionButton1
    local last = ActionButton12
    if not first or not last then
        return
    end

    local left, bottom, _, top = GetScreenRect(first)
    local _, _, mainRight = GetScreenRect(last)
    if not left or not mainRight then
        return
    end

    local lift = AlignBar3()
    local rowHeight = top - bottom
    local extensionLeft, right = nil, mainRight
    local extensionFirst, extensionLast
    local extensionButtons = {}
    local rightLimit = UIParent:GetWidth() * 0.82
    local featherAtlas = first.SlotArt and first.SlotArt:GetAtlas() or "UI-HUD-ActionBar-IconFrame-Slot"
    local atlas = C_Texture.GetAtlasInfo(featherAtlas)
    AddXPBacking(atlas)

    for _, art in pairs(slotArtwork) do
        art:Hide()
    end
    for index = 1, 12 do
        local button = _G["ActionButton" .. index]
        if button then
            ShowSlotArtwork(button, featherAtlas)
        end
    end

    -- Find the separate lower-right group in the supplied Edit Mode layout.
    for _, prefix in ipairs({
        "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBar5Button",
        "MultiBar6Button", "MultiBar7Button", "MultiBarLeftButton", "MultiBarRightButton",
    }) do
        for index = 1, 12 do
            local button = _G[prefix .. index]
            if button and button:IsVisible() then
                local x, y, edge = GetScreenRect(button)
                if x and x >= mainRight and edge <= rightLimit and math.abs(y - bottom) < rowHeight * 0.25 then
                    if not extensionLeft or x < extensionLeft then
                        extensionLeft, extensionFirst = x, button
                    end
                    if edge > right then
                        right, extensionLast = edge, button
                    end
                    extensionButtons[button] = true
                end
            end
        end
    end

    for button in pairs(framedButtons) do
        if not extensionButtons[button] then
            framedButtons[button] = nil
            button:UpdateButtonArt()
        end
    end
    for button in pairs(extensionButtons) do
        FrameButton(button)
        ShowSlotArtwork(button, featherAtlas)
    end
    LayoutExtensionTrim(extensionFirst, extensionLast)
    ledge:Hide()
    if lift and lift > 0 and extensionTrim:IsShown() then
        local _, _, rimRight, rimTop = GetScreenRect(extensionTrim)
        local pixel = ScreenPixel()
        ledge:ClearAllPoints()
        SetScreenPoint(ledge, "BOTTOMLEFT", left - rowHeight * 0.09, rimTop - pixel)
        SetScreenPoint(ledge, "TOPRIGHT", rimRight, rimTop + lift)
        ledgeHighlight:SetHeight(pixel / GetRelativeScale(ledge))
        ledge:Show()
    end

    local inset = rowHeight * 0.09
    backing:ClearAllPoints()
    SetScreenPoint(backing, "BOTTOMLEFT", left - inset, bottom - inset)
    -- End the square backing under the last button, inside the rim's curved end.
    local backingRight = extensionTrim:IsShown() and (right - inset) or (right + inset)
    SetScreenPoint(backing, "TOPRIGHT", backingRight, top + inset)
    backing:Show()
    FitXPBar()

    if endCaps then
        endCaps:SetFrameStrata("BACKGROUND")
        endCaps:SetFrameLevel(2)
        for _, cap in pairs({ endCaps.LeftEndCap, endCaps.RightEndCap }) do
            if cap.SetFrameStrata then
                cap:SetFrameStrata("BACKGROUND")
                cap:SetFrameLevel(2)
            end
        end

        TuckEagle(endCaps.LeftEndCap, true, left, bottom, rowHeight)
        TuckEagle(endCaps.RightEndCap, false, right, bottom, rowHeight)
        local outerOverlap = rowHeight * 0.38 + math.max(0, EAGLE_OUTWARD_PX) * ScreenPixel()
        local innerOverlap = rowHeight * 0.68
        local joinBottom = math.max(0, bottom - rowHeight * 0.55)
        local joinTop = bottom + rowHeight * 0.81
        LayoutEagleJoin(leftJoin, left - outerOverlap, left + innerOverlap, joinBottom, joinTop, atlas, false)
        LayoutEagleJoin(rightJoin, right - innerOverlap, right + outerOverlap, joinBottom, joinTop, atlas, true)
        UpdateJoinVisibility()
    end

    local pager = bar.ActionBarPageNumber
    pagerPlate:Hide()
    if pager and extensionLeft and extensionLeft - mainRight > rowHeight * 0.35 then
        pager:ClearAllPoints()
        SetScreenPoint(pager, "CENTER", (mainRight + extensionLeft) / 2, (bottom + top) / 2)
        if extensionTrim:IsShown() then
            local trimLeft = GetScreenRect(extensionTrim)
            local center = (mainRight + extensionLeft) / 2
            LayoutPagerPlate(2 * center - trimLeft, trimLeft)
        end

        if pager.UpButton and pager.DownButton and pager.Text then
            pager.UpButton:ClearAllPoints()
            pager.UpButton:SetPoint("CENTER", pager, "CENTER", 0, 10)
            pager.DownButton:ClearAllPoints()
            pager.DownButton:SetPoint("CENTER", pager, "CENTER", 0, -10)
            pager.Text:ClearAllPoints()
            pager.Text:SetPoint("CENTER", pager, "CENTER", 0, 0)
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
events:RegisterEvent("ACTIONBAR_SHOWGRID")
events:RegisterEvent("ACTIONBAR_HIDEGRID")
events:RegisterEvent("CURSOR_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
        gridShown = event == "ACTIONBAR_SHOWGRID"
    end
    if event == "CURSOR_CHANGED" or event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
        -- Read the final strata after the game's handlers for this event have run.
        C_Timer.After(0, UpdateRim)
        return
    end
    C_Timer.After(0, LayoutArt)
end)

if EditModeManagerFrame and EditModeManagerFrame.ExitEditMode then
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        C_Timer.After(0, LayoutArt)
    end)
end
