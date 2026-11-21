-- Appearance settings. Edit these numbers, save the file, then type /reload in WoW.
local EAGLE_SIZE_PERCENT = 92      -- 100 is the original Blizzard size.
local EAGLE_GRAY_PERCENT = 60      -- 0 keeps the original bronze. 100 makes both eagles fully gray.
local EAGLE_OUTWARD_LEFT_PX = -6   -- Left eagle moves away from its nearest button. 0 is tucked in. EIV: -12 når BUTTON_SPACING_REDUCTION_PX = 3
local EAGLE_OUTWARD_RIGHT_PX = -16 -- Right eagle moves away from its nearest button. 0 is tucked in. EIV: -24 når BUTTON_SPACING_REDUCTION_PX = 3
local EAGLE_DOWN_PX = 4            -- Larger values lower the eagles toward the screen edge.
local XP_EXTRA_HEIGHT_PX = 0       -- 0 meets the lower rim. +1 raises the top one pixel, -1 lowers it.
local LEDGE_HEIGHT_PX = 6          -- Extra space for the stone ledge between the two bottom rows.
local LEDGE_STONE_BRIGHTNESS = 0.5 -- Brightness of the stone ledge texture.
local UPPER_BAR_GAP_PX = 0         -- Extra space between the stone ledge and the bar above it. Does not change the ledge art.
local BUTTON_SPACING_REDUCTION_PX = 2 -- Reduce spacing between buttons by this many pixels.

-- Constants tied to the sampled artwork. Leave these alone unless the art changes.
local REF_BUTTON_PX = 55          -- Button width the rim and XP track were sampled at.
local RIM_REF = { left = 31.5, right = 29.5, bottom = 32, top = 31 } -- Rim edges, in reference pixels from the button centers.
local BACKING_INSET_RATIO = 0.09  -- Backing and ledge overhang, as a fraction of the row height.
local SLOT_RIGHT_LIMIT = 0.82     -- Buttons right of this fraction of the screen width are not part of the extension.
local HALF_GAP_COUNT = 5.5        -- A 12-button row has 11 gaps. Half of them shift the bar when spacing shrinks.
local RIM_IDLE_BRIGHTNESS = 0.75  -- 1 uses the sampled bronze at full brightness.
local RIM_DRAG_BRIGHTNESS = 1.00  -- Brightness while WoW shows the action-button grid.
local COLOR_BACKING = { 0.13, 0.095, 0.065, 1 }
local COLOR_SHADOW = { 0.10, 0.072, 0.049, 1 }

local function ScreenPixel()
    return UIParent:GetHeight() / select(2, GetPhysicalScreenSize())
end

local bar = MainActionBar or MainMenuBar
if not bar then
    return
end

---------------------------------------------------------------------------
-- Geometry helpers. Everything is measured in UIParent screen units.
---------------------------------------------------------------------------

local function GetRelativeScale(frame)
    return frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

-- Returns left, bottom, right, top, or nothing if the frame has no position yet.
local function GetScreenRect(frame, scaleFrame)
    local left, bottom, width, height = frame:GetRect()
    if not left then
        return
    end

    local scale = GetRelativeScale(scaleFrame or frame)
    return left * scale, bottom * scale, (left + width) * scale, (bottom + height) * scale
end

-- Returns x, y, or nothing if the frame has no position yet.
local function GetScreenCenter(frame)
    local x, y = frame:GetCenter()
    if not x then
        return
    end

    local scale = GetRelativeScale(frame)
    return x * scale, y * scale
end

-- Edit Mode's SetPoint also rewrites snap relationships and marks every system
-- for an anchor update. These out-of-combat adjustments are display offsets.
local function SetLayoutPoint(frame, ...)
    local setPoint = frame.SetPointBase or frame.SetPoint
    setPoint(frame, ...)
end

local function ClearLayoutPoints(frame)
    local clearPoints = frame.ClearAllPointsBase or frame.ClearAllPoints
    clearPoints(frame)
end

local function SetScreenPoint(frame, point, x, y)
    local scale = GetRelativeScale(frame)
    SetLayoutPoint(frame, point, UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

---------------------------------------------------------------------------
-- Backing behind the main row
---------------------------------------------------------------------------

-- Keep addon frames out of the child lists that Blizzard walks during layout.
-- The visual parent mirrors the original owner's visibility and scale.
local artParents = {}
local function GetArtParent(owner)
    local parent = artParents[owner]
    if not parent then
        parent = CreateFrame("Frame", nil, UIParent)
        parent:SetAllPoints(UIParent)
        owner:HookScript("OnShow", function() parent:Show() end)
        owner:HookScript("OnHide", function() parent:Hide() end)
        artParents[owner] = parent
    end
    parent:SetShown(owner:IsVisible())
    parent:SetScale(GetRelativeScale(owner))
    return parent
end

local backing = CreateFrame("Frame", nil, GetArtParent(bar), "BackdropTemplate")
backing:SetFrameStrata("BACKGROUND")
backing:SetFrameLevel(1)
backing:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
})
backing:SetBackdropColor(unpack(COLOR_BACKING))
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

---------------------------------------------------------------------------
-- Eagle joins (stone behind the eagles)
---------------------------------------------------------------------------

local function CreateEagleJoin()
    -- The action bar can raise its children during a drag. Keep these behind the XP track.
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("BACKGROUND")
    frame:SetFrameLevel(0)
    frame:Hide()

    local shadow = frame:CreateTexture(nil, "BACKGROUND")
    shadow:SetAllPoints()
    shadow:SetColorTexture(unpack(COLOR_SHADOW))

    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    frame.texture = texture
    return frame
end

local leftJoin = CreateEagleJoin()
local rightJoin = CreateEagleJoin()
local endCaps = bar.EndCaps

local function UpdateJoinVisibility()
    if not endCaps then return end
    local show = endCaps:IsVisible() and leftJoin:GetNumPoints() > 0
    leftJoin:SetShown(show)
    rightJoin:SetShown(show)
end

if endCaps then
    endCaps:HookScript("OnShow", UpdateJoinVisibility)
    endCaps:HookScript("OnHide", UpdateJoinVisibility)
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

---------------------------------------------------------------------------
-- XP track backing
---------------------------------------------------------------------------

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
    shadow:SetColorTexture(unpack(COLOR_SHADOW))

    xpBacking = statusBar:CreateTexture(nil, "BACKGROUND", nil, -7)
    xpBacking:SetAllPoints()
    ApplyUnderlayTexture(xpBacking, atlas, false)
end

---------------------------------------------------------------------------
-- Button artwork
---------------------------------------------------------------------------

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
    local parent = GetArtParent(button:GetParent())
    local art = slotArtwork[button]
    if not art then
        -- Keep the art visible when Blizzard hides the empty action button itself.
        art = CreateFrame("Frame", nil, parent)
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

---------------------------------------------------------------------------
-- Lower-row rim and pager plate
---------------------------------------------------------------------------

-- The rim was sampled from Bar 1 at a 55-pixel button width, so it scales with the
-- button size and not with the spacing. Only its four edges are opaque.
-- The button faces and pager draw separately.
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

local function IsActionDragActive()
    local cursorType = GetCursorInfo and GetCursorInfo()
    return gridShown or cursorType == "action" or cursorType == "spell"
end

local function UpdateRim()
    if not bar3 then return end
    local strata, level = bar3:GetFrameStrata(), bar3:GetFrameLevel()
    -- The eagle can inherit a higher layer when WoW raises the drag grid.
    local eagle = endCaps and endCaps.RightEndCap
    for _, frame in pairs({ backing, MainStatusTrackingBarContainer, endCaps, eagle }) do
        if frame.GetFrameStrata then
            local other = frame:GetFrameStrata()
            if strataOrder[other] > strataOrder[strata] then
                strata, level = other, frame:GetFrameLevel()
            elseif other == strata then
                level = math.max(level, frame:GetFrameLevel())
            end
        end
    end
    extensionTrim:SetFrameStrata(strata)
    extensionTrim:SetFrameLevel(level + 1)
    local light = IsActionDragActive() and RIM_DRAG_BRIGHTNESS or RIM_IDLE_BRIGHTNESS
    rim:SetVertexColor(light, light, light)
    pagerPlate:SetVertexColor(light, light, light)
end

-- Sample the straight rails. The adjacent bar rims already frame the pager's sides.
local function LayoutPagerPlate(left, right)
    local _, low, _, high = GetScreenRect(extensionTrim)
    if not low then return end
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
    local firstX, centerY = GetScreenCenter(first)
    local lastX = GetScreenCenter(last)
    if not firstX or not lastX then return end
    local pixel = first:GetWidth() * GetRelativeScale(first) / REF_BUTTON_PX
    if pixel <= 0 then return end

    bar3 = first.bar or MultiBarBottomRight
    UpdateRim()
    extensionTrim:ClearAllPoints()
    local screenPixel = ScreenPixel()
    SetScreenPoint(extensionTrim, "BOTTOMLEFT",
        firstX - RIM_REF.left * pixel, centerY - RIM_REF.bottom * pixel + screenPixel)
    SetScreenPoint(extensionTrim, "TOPRIGHT",
        lastX + RIM_REF.right * pixel, centerY + RIM_REF.top * pixel + screenPixel)
    extensionTrim:Show()
end

---------------------------------------------------------------------------
-- XP track
---------------------------------------------------------------------------

local xpFoot = CreateFrame("Frame", nil, UIParent)
xpFoot:SetFrameStrata("BACKGROUND")
xpFoot:SetFrameLevel(0)
xpFoot:Hide()
local footTexture = xpFoot:CreateTexture(nil, "BACKGROUND")
footTexture:SetAllPoints()
footTexture:SetColorTexture(unpack(COLOR_BACKING))

local function FitXPBar()
    local track = MainStatusTrackingBarContainer
    if not track then return end
    local face = track.BarFrameTexture or track
    local l, b, r = GetScreenRect(face, track)
    if not l or r <= l then return end
    local firstX = GetScreenCenter(ActionButton1)
    local cx = track:GetCenter()
    if not firstX or not cx then return end

    local buttonWidth = ActionButton1:GetWidth() * GetRelativeScale(ActionButton1)
    local targetLeft = firstX - buttonWidth * RIM_REF.left / REF_BUTTON_PX
    local targetRight
    if extensionTrim:IsShown() then
        targetRight = select(3, GetScreenRect(extensionTrim))
    else
        -- Profiles with a different button arrangement still get the prototype's XP width.
        local width = buttonWidth * (1088 / REF_BUTTON_PX)
        targetLeft = (l + r - width) / 2
        targetRight = targetLeft + width
    end
    if not targetRight then return end

    -- Measured before SetScale below, because scaling changes the relative scale.
    local factor = (targetRight - targetLeft) / (r - l)
    local newX = targetLeft + (cx * GetRelativeScale(track) - l) * factor
    local setScale = track.SetScaleBase or track.SetScale
    setScale(track, track:GetScale() * factor)

    local _, floorY = GetScreenRect(extensionTrim)
    local pixel = ScreenPixel()
    local dockTop
    if extensionTrim:IsShown() and floorY then
        dockTop = (math.floor(floorY / pixel + 0.5) + XP_EXTRA_HEIGHT_PX) * pixel
    end
    if dockTop and dockTop > 2 * pixel then
        ClearLayoutPoints(track)
        SetScreenPoint(track, "BOTTOMLEFT", targetLeft, 0)
        SetScreenPoint(track, "TOPRIGHT", targetRight, dockTop)
        if face ~= track then
            face:ClearAllPoints()
            face:SetAllPoints(track)
        end
    else
        local _, cy = track:GetCenter()
        local _, faceBottom = GetScreenRect(face, track)
        ClearLayoutPoints(track)
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
            for _, region in ipairs({ overlay:GetRegions() }) do
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

---------------------------------------------------------------------------
-- Stone ledge and upper bar
---------------------------------------------------------------------------

-- Keep the stone behind the eagle artwork even when action bars change strata.
local ledge = CreateFrame("Frame", nil, UIParent)
ledge:SetFrameStrata("BACKGROUND")
ledge:SetFrameLevel(0)
local stone = ledge:CreateTexture(nil, "ARTWORK")
stone:SetTexture("Interface\\AddOns\\EivindBars\\StoneLedge.tga")
stone:SetVertexColor(0.34 * LEDGE_STONE_BRIGHTNESS, 0.31 * LEDGE_STONE_BRIGHTNESS, 0.27 * LEDGE_STONE_BRIGHTNESS) -- 
stone:SetAllPoints()
local ledgeHighlight = ledge:CreateTexture(nil, "OVERLAY")
ledgeHighlight:SetColorTexture(0.36, 0.27, 0.18, 0.75)
ledgeHighlight:SetPoint("TOPLEFT")
ledgeHighlight:SetPoint("TOPRIGHT")
ledge:Hide()

-- Remember the Edit Mode anchor so repeated layouts don't add the lift twice.
-- Returns the ledge height only. The extra gap lifts the bar but not the ledge art.
local upperAnchor
local function LiftUpperBar()
    local upperBar = MultiBarBottomLeft
    if not upperBar or upperBar:GetNumPoints() ~= 1 then return 0 end
    local point, relative, relativePoint, x, y = upperBar:GetPoint(1)
    if not upperAnchor or point ~= upperAnchor.point or relative ~= upperAnchor.relative
        or relativePoint ~= upperAnchor.relativePoint or math.abs(y - upperAnchor.applied) > 0.001 then
        upperAnchor = { point = point, relative = relative, relativePoint = relativePoint, base = y }
    end
    local pixel = ScreenPixel()
    local lift = LEDGE_HEIGHT_PX * pixel
    local gap = UPPER_BAR_GAP_PX * pixel
    upperAnchor.applied = upperAnchor.base + (lift + gap) / GetRelativeScale(upperBar)
    SetLayoutPoint(upperBar, point, relative, relativePoint, x, upperAnchor.applied)
    return lift
end

-- Bar 3 has two rows of six. Measure both rows before moving any grid anchors.
local function AlignBar3()
    local upper = MultiBarBottomLeftButton1
    if not upper or not MultiBarBottomRightButton1 then return end
    local mainRightX = GetScreenCenter(ActionButton12)
    local _, lowerY = GetScreenCenter(ActionButton1)
    local _, upperY = GetScreenCenter(upper)
    if not mainRightX or not lowerY or not upperY or upperY <= lowerY then return end

    local rightLimit = UIParent:GetWidth() * SLOT_RIGHT_LIMIT
    local positions = {}
    for i = 1, 12 do
        local button = _G["MultiBarBottomRightButton" .. i]
        if not button then return end
        local x, y = GetScreenCenter(button)
        if not x or x <= mainRightX or x >= rightLimit then return end
        local holder = button.container or button
        local hx, hy = GetScreenCenter(holder)
        if not hx then return end
        positions[i] = { button = button, holder = holder, x = hx, y = y, offsetY = hy - y }
    end

    local lift = LiftUpperBar()
    local liftedUpperY = select(2, GetScreenCenter(upper))
    if liftedUpperY then
        upperY = liftedUpperY
    end

    local lowerRow = {}
    local lowerCount = 0
    for _, pos in ipairs(positions) do
        local targetY = pos.y > (upperY + lowerY) / 2 and upperY or lowerY
        lowerRow[pos.button] = targetY == lowerY
        if lowerRow[pos.button] then lowerCount = lowerCount + 1 end
        local holder = pos.holder
        local parent = holder:GetParent()
        local px, py = GetScreenCenter(parent)
        if px then
            local scale = GetRelativeScale(holder)
            holder:ClearAllPoints()
            holder:SetPoint("CENTER", parent, "CENTER",
                (pos.x - px) / scale,
                (targetY + pos.offsetY - py) / scale)
        end
    end
    if lowerCount == 6 and MultiBarBottomRight.numButtonsShowable == 12 then
        return lift, lowerRow
    end
    return lift
end

local bar3Rows
local savedAlpha = {}
local function MaskRegion(region, mask)
    if mask then
        if savedAlpha[region] == nil then savedAlpha[region] = region:GetAlpha() end
        region:SetAlpha(0)
    elseif not mask and savedAlpha[region] ~= nil then
        region:SetAlpha(savedAlpha[region])
        savedAlpha[region] = nil
    end
end

-- Only fade artwork. Blizzard owns button visibility, mouse handling and cooldowns.
local function RefreshBar3Art()
    if not bar3Rows then return end
    local dragging = IsActionDragActive()
    local preview = dragging or MultiBarBottomRight:GetShowAllButtons() or KeybindFrames_InQuickKeybindMode()
    for button, isLower in pairs(bar3Rows) do
        local empty = not button:HasAction()
        -- HotKey belongs to TextOverlayContainer, a child of the button.
        if isLower then
            MaskRegion(button.HotKey, empty and not dragging)
        else
            local maskUpper = empty and not preview
            MaskRegion(button.HotKey, maskUpper)
            for _, region in ipairs({ button:GetRegions() }) do
                MaskRegion(region, maskUpper)
            end
        end
    end
end

local function ApplyBar3Rows(rows)
    for region in pairs(savedAlpha) do
        MaskRegion(region, false)
    end
    bar3Rows = rows
    RefreshBar3Art()
end

---------------------------------------------------------------------------
-- Eagles
---------------------------------------------------------------------------

-- Keep the inner bottom corner fixed while shrinking the native eagle.
local eagleSizes = {}
local function TuckEagle(cap, isLeft, edge, baseline, rowHeight, outwardPx)
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
    ClearLayoutPoints(cap)
    local sizeFactor = EAGLE_SIZE_PERCENT / 100
    cap:SetSize(size.width * sizeFactor, size.height * sizeFactor)
    local outward = outwardPx * ScreenPixel()
    local x = edge + size.inset * rowHeight + (isLeft and -outward or outward)
    local y = baseline + size.bottom * rowHeight - EAGLE_DOWN_PX * ScreenPixel()
    SetLayoutPoint(cap, isLeft and "BOTTOMRIGHT" or "BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

local function LayoutEagles(left, right, bottom, rowHeight, atlas)
    if not endCaps then return end

    endCaps:SetFrameStrata("BACKGROUND")
    endCaps:SetFrameLevel(2)
    local gray = math.max(0, math.min(100, EAGLE_GRAY_PERCENT)) / 100
    for _, cap in pairs({ endCaps.LeftEndCap, endCaps.RightEndCap }) do
        cap.Texture:SetDesaturation(gray)
        if cap.SetFrameStrata then
            cap:SetFrameStrata("BACKGROUND")
            cap:SetFrameLevel(2)
        end
    end

    TuckEagle(endCaps.LeftEndCap, true, left, bottom, rowHeight, EAGLE_OUTWARD_LEFT_PX)
    TuckEagle(endCaps.RightEndCap, false, right, bottom, rowHeight, EAGLE_OUTWARD_RIGHT_PX)

    local pixel = ScreenPixel()
    local leftOverlap = rowHeight * 0.38 + math.max(0, EAGLE_OUTWARD_LEFT_PX) * pixel
    local rightOverlap = rowHeight * 0.38 + math.max(0, EAGLE_OUTWARD_RIGHT_PX) * pixel
    local innerOverlap = rowHeight * 0.68
    local joinBottom = math.max(0, bottom - rowHeight * 0.55)
    local joinTop = bottom + rowHeight * 0.81
    LayoutEagleJoin(leftJoin, left - leftOverlap, left + innerOverlap, joinBottom, joinTop, atlas, false)
    LayoutEagleJoin(rightJoin, right - innerOverlap, right + rightOverlap, joinBottom, joinTop, atlas, true)
    UpdateJoinVisibility()
end

---------------------------------------------------------------------------
-- Button spacing
---------------------------------------------------------------------------

local horizontalAnchors = {}
local function CenterTightenedBar(actionBar, offset)
    if not actionBar or actionBar:GetNumPoints() ~= 1 then return end
    local point, relative, relativePoint, x, y = actionBar:GetPoint(1)
    local state = horizontalAnchors[actionBar]
    if not state or state.point ~= point or state.relative ~= relative
        or state.relativePoint ~= relativePoint or math.abs(x - state.applied) > 0.001 then
        state = { point = point, relative = relative, relativePoint = relativePoint, base = x }
        horizontalAnchors[actionBar] = state
    end
    state.applied = state.base + offset / GetRelativeScale(actionBar)
    SetLayoutPoint(actionBar, point, relative, relativePoint, state.applied, y)
end

-- Offset buttons inside Blizzard's spacers. Writing padding or rebuilding the
-- native grid here would put addon-owned state into later combat layout updates.
local function TightenButtonSpacing(actionBar)
    local holders = actionBar.shownButtonContainers
    if not holders or #holders == 0 or not actionBar.numRows or actionBar.numRows < 1 then return end
    local point = actionBar:GetPoint(1)
    if not point then return end
    local stride = math.ceil(#holders / actionBar.numRows)
    local lines = math.ceil(#holders / stride)
    local columns, rows = stride, lines
    if not actionBar.isHorizontal then columns, rows = lines, stride end
    -- Contract toward the same edge (or center) as the bar's Edit Mode anchor.
    local pivotX = point:find("LEFT") and 0 or point:find("RIGHT") and 1 or 0.5
    local pivotY = point:find("BOTTOM") and 0 or point:find("TOP") and 1 or 0.5
    local padding = math.max(actionBar.buttonPadding, actionBar.minButtonPadding)
    local reduction = math.min(BUTTON_SPACING_REDUCTION_PX * ScreenPixel(), padding * GetRelativeScale(actionBar))
    local index = 0
    for _, button in ipairs(actionBar.actionButtons) do
        local holder = button.container
        if holder == holders[index + 1] then
            local col, row = index % stride, math.floor(index / stride)
            if not actionBar.isHorizontal then col, row = row, col end
            if not actionBar.addButtonsToRight then col = columns - 1 - col end
            if not actionBar.addButtonsToTop then row = rows - 1 - row end
            local step = reduction / GetRelativeScale(button)
            button:SetPoint("CENTER", holder, "CENTER",
                (pivotX * (columns - 1) - col) * step, (pivotY * (rows - 1) - row) * step)
            index = index + 1
        end
    end
end

local function TightenBottomBars()
    for _, actionBar in pairs({ bar, MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight, MultiBarLeft }) do
        TightenButtonSpacing(actionBar)
    end
    local inward = HALF_GAP_COUNT * BUTTON_SPACING_REDUCTION_PX * ScreenPixel()
    CenterTightenedBar(bar, inward)
    CenterTightenedBar(MultiBarBottomLeft, inward)
    CenterTightenedBar(MultiBarBottomRight, -inward)
end

---------------------------------------------------------------------------
-- Main layout pass
---------------------------------------------------------------------------

local EXTENSION_BAR_PREFIXES = {
    "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBar5Button",
    "MultiBar6Button", "MultiBar7Button", "MultiBarLeftButton", "MultiBarRightButton",
}

-- Find the separate lower-right group in the supplied Edit Mode layout.
local function FindExtension(mainRight, bottom, rowHeight)
    local rightLimit = UIParent:GetWidth() * SLOT_RIGHT_LIMIT
    local found = { buttons = {}, right = mainRight }
    for _, prefix in ipairs(EXTENSION_BAR_PREFIXES) do
        for index = 1, 12 do
            local button = _G[prefix .. index]
            -- A hidden empty button still has a visible spacer for our lower-row artwork.
            if button and (button:IsVisible() or (bar3Rows and bar3Rows[button] and button.container:IsVisible())) then
                local x, y, edge = GetScreenRect(button)
                if x and x >= mainRight and edge <= rightLimit and math.abs(y - bottom) < rowHeight * 0.25 then
                    if not found.left or x < found.left then
                        found.left, found.first = x, button
                    end
                    if edge > found.right then
                        found.right, found.last = edge, button
                    end
                    found.buttons[button] = true
                end
            end
        end
    end
    return found
end

local function LayoutLedge(lift, left, rowHeight)
    ledge:Hide()
    if not (lift and lift > 0 and extensionTrim:IsShown()) then return end
    local _, _, rimRight, rimTop = GetScreenRect(extensionTrim)
    if not rimTop then return end
    local pixel = ScreenPixel()
    ledge:ClearAllPoints()
    SetScreenPoint(ledge, "BOTTOMLEFT", left - rowHeight * BACKING_INSET_RATIO, rimTop - pixel)
    SetScreenPoint(ledge, "TOPRIGHT", rimRight, rimTop + lift)
    ledgeHighlight:SetHeight(pixel / GetRelativeScale(ledge))
    ledge:Show()
end

-- The native border normally follows the full grid. Its right bevel must end
-- at the last button after spacing is tightened, before the pager arrows.
local originalBorderPoints
local function FitMainBorder(first, last, fit)
    local border = bar.BorderArt
    if not border then return end
    if not fit then
        if originalBorderPoints then
            border:ClearAllPoints()
            for _, point in ipairs(originalBorderPoints) do
                border:SetPoint(unpack(point, 1, 5))
            end
            originalBorderPoints = nil
        end
        return
    end

    if not originalBorderPoints then
        originalBorderPoints = {}
        for i = 1, border:GetNumPoints() do
            originalBorderPoints[i] = { border:GetPoint(i) }
        end
    end
    -- Keep the native texture's top-left and bottom-right margins.
    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", first, "TOPLEFT", -6, 6)
    border:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", 4, -5)
end

local function LayoutPager(extensionLeft, mainRight, bottom, top, rowHeight)
    local pager = bar.ActionBarPageNumber
    pagerPlate:Hide()
    if not (pager and extensionLeft and extensionLeft - mainRight > rowHeight * 0.35) then return end

    local center = (mainRight + extensionLeft) / 2
    pager:ClearAllPoints()
    SetScreenPoint(pager, "CENTER", center, (bottom + top) / 2)
    if extensionTrim:IsShown() then
        local trimLeft = GetScreenRect(extensionTrim)
        if trimLeft then
            LayoutPagerPlate(2 * center - trimLeft, trimLeft)
        end
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

local function LayoutArt()
    if InCombatLockdown() then
        return
    end

    GetArtParent(bar)
    TightenBottomBars()
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

    local lift, rows = AlignBar3()
    ApplyBar3Rows(rows)
    local rowHeight = top - bottom
    local extension = FindExtension(mainRight, bottom, rowHeight)
    local right = extension.right
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

    for button in pairs(framedButtons) do
        if not extension.buttons[button] then
            framedButtons[button] = nil
            button:UpdateButtonArt()
        end
    end
    for button in pairs(extension.buttons) do
        FrameButton(button)
        ShowSlotArtwork(button, featherAtlas)
    end

    LayoutExtensionTrim(extension.first, extension.last)
    FitMainBorder(first, last, extensionTrim:IsShown() and bar.isHorizontal and bar.numRows == 1
        and bar.numButtonsShowable == 12 and extension.left - mainRight > rowHeight * 0.35)
    LayoutLedge(lift, left, rowHeight)

    local inset = rowHeight * BACKING_INSET_RATIO
    backing:ClearAllPoints()
    SetScreenPoint(backing, "BOTTOMLEFT", left - inset, bottom - inset)
    -- End the square backing under the last button, inside the rim's curved end.
    local backingRight = extensionTrim:IsShown() and (right - inset) or (right + inset)
    SetScreenPoint(backing, "TOPRIGHT", backingRight, top + inset)
    backing:Show()

    FitXPBar()
    LayoutEagles(left, right, bottom, rowHeight, atlas)
    LayoutPager(extension.left, mainRight, bottom, top, rowHeight)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

-- Several events can fire in the same frame (Edit Mode especially). Run one layout for all of them.
local layoutQueued = false
local function QueueLayout()
    if layoutQueued then return end
    layoutQueued = true
    C_Timer.After(0, function()
        layoutQueued = false
        LayoutArt()
    end)
end

local artQueued = false
local function RefreshDragAppearance()
    artQueued = false
    UpdateRim()
    RefreshBar3Art()
end
local function QueueBarArt()
    if not artQueued then
        artQueued = true
        C_Timer.After(0, RefreshDragAppearance)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
events:RegisterEvent("ACTIONBAR_SHOWGRID")
events:RegisterEvent("ACTIONBAR_HIDEGRID")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterEvent("CURSOR_CHANGED")
events:RegisterEvent("UPDATE_BINDINGS")
events:SetScript("OnEvent", function(_, event)
    if event == "ACTIONBAR_SHOWGRID" or event == "ACTIONBAR_HIDEGRID" then
        gridShown = event == "ACTIONBAR_SHOWGRID"
    elseif event ~= "CURSOR_CHANGED" and event ~= "ACTIONBAR_SLOT_CHANGED" and event ~= "UPDATE_BINDINGS" then
        QueueLayout()
        return
    end
    QueueBarArt()
end)

if MultiBarBottomRight then
    hooksecurefunc(MultiBarBottomRight, "SetShowGrid", QueueBarArt)
end

if EditModeManagerFrame and EditModeManagerFrame.ExitEditMode then
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", QueueLayout)
end
