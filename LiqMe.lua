---@type string
local addonName = select(1, ...)
---@class LM_Addon
local addon = select(2, ...)

local f = CreateFrame("Frame")
local ActionBarFrame
local UIHider

local ICON_ZOOM_INSET = 0.07
-- Shrink icon so it sits inside Blizzard's default highlight. Slot spacing is Edit Mode Icon Padding.
local ICON_EDGE_INSET = 1
local TEXT_FONT = "Fonts\\ARIALN.TTF"
local TEXT_FLAGS = "OUTLINE"
local HOTKEY_FONT_SIZE = 14
local COUNT_FONT_SIZE = 17
local MACRO_FONT_SIZE = 11
local TEXT_R, TEXT_G, TEXT_B = 1, 1, 1
local HIGHLIGHT_WIDTH = 50
local HIGHLIGHT_HEIGHT = 49
local HIGHLIGHT_OFFSET_X = -2.5
local HIGHLIGHT_OFFSET_Y = 2.5
-- Match Blizzard AddRow pressed chrome, slightly larger so it covers the icon.
local PUSHED_WIDTH = 53
local PUSHED_HEIGHT = 53
local PUSHED_OFFSET_X = -1
local PUSHED_OFFSET_Y = 1

local ACTION_BUTTON_PREFIXES = {
  "ActionButton",
  "MultiBarBottomLeftButton",
  "MultiBarBottomRightButton",
  "MultiBarLeftButton",
  "MultiBarRightButton",
  "MultiBar5Button",
  "MultiBar6Button",
  "MultiBar7Button",
}

local ACTION_BARS = {
  "MainActionBar",
  "MultiBarBottomLeft",
  "MultiBarBottomRight",
  "MultiBarLeft",
  "MultiBarRight",
  "MultiBar5",
  "MultiBar6",
  "MultiBar7",
}

--@debug@
_G[addonName] = addon
--@end-debug@

---@param button Button
local function getHotKey(button)
  return button.HotKey or (button.TextOverlayContainer and button.TextOverlayContainer.HotKey)
end

---@param button Button
local function getCount(button)
  return button.Count or (button.TextOverlayContainer and button.TextOverlayContainer.Count)
end

-- LibKeyBound:ToShortKey style used by Bartender/LAB (uppercase + short modifiers).
---@param key string
---@return string
local function toShortKey(key)
  key = key:upper()
  key = key:gsub(" ", "")
  key = key:gsub("ALT%-", "A")
  key = key:gsub("CTRL%-", "C")
  key = key:gsub("SHIFT%-", "S")
  key = key:gsub("META%-", "M")
  key = key:gsub("NUMPAD", "N")
  key = key:gsub("PLUS", "%+")
  key = key:gsub("MINUS", "%-")
  key = key:gsub("MULTIPLY", "%*")
  key = key:gsub("DIVIDE", "%/")
  key = key:gsub("BACKSPACE", "BS")
  for index = 1, 31 do
    key = key:gsub("BUTTON" .. index, "B" .. index)
  end
  key = key:gsub("CAPSLOCK", "Cp")
  key = key:gsub("CLEAR", "Cl")
  key = key:gsub("DELETE", "Del")
  key = key:gsub("END", "En")
  key = key:gsub("HOME", "HM")
  key = key:gsub("INSERT", "Ins")
  key = key:gsub("MOUSEWHEELDOWN", "WD")
  key = key:gsub("MOUSEWHEELUP", "WU")
  key = key:gsub("NUMLOCK", "NL")
  key = key:gsub("PAGEDOWN", "PD")
  key = key:gsub("PAGEUP", "PU")
  key = key:gsub("SCROLLLOCK", "SL")
  key = key:gsub("SPACEBAR", "Sp")
  key = key:gsub("SPACE", "Sp")
  key = key:gsub("TAB", "Tb")
  key = key:gsub("DOWNARROW", "Dn")
  key = key:gsub("LEFTARROW", "Lf")
  key = key:gsub("RIGHTARROW", "Rt")
  key = key:gsub("UPARROW", "Up")
  return key
end

---@param fontString FontString?
---@param size number
local function styleButtonText(fontString, size)
  if not fontString then
    return
  end
  fontString:SetFont(TEXT_FONT, size, TEXT_FLAGS)
  fontString:SetTextColor(TEXT_R, TEXT_G, TEXT_B)
  fontString:SetShadowOffset(0, 0)
end

---@param button Button
local function styleActionButtonText(button)
  local icon = button.icon
  local hotKey = getHotKey(button)
  if hotKey then
    styleButtonText(hotKey, HOTKEY_FONT_SIZE)
    hotKey:SetParent(button)
    hotKey:SetJustifyH("RIGHT")
    hotKey:ClearAllPoints()
    if icon then
      hotKey:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -2, -2)
    else
      hotKey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -(ICON_EDGE_INSET + 2), -(ICON_EDGE_INSET + 2))
    end
    local hotKeyWidth = hotKey:GetStringWidth()
    if hotKeyWidth and hotKeyWidth > 0 then
      hotKey:SetWidth(hotKeyWidth + 2)
    end
    hotKey:SetHeight(HOTKEY_FONT_SIZE + 4)
  end

  local count = getCount(button)
  if count then
    styleButtonText(count, COUNT_FONT_SIZE)
    count:SetParent(button)
    count:SetJustifyH("RIGHT")
    count:ClearAllPoints()
    if icon then
      count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    else
      count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -(ICON_EDGE_INSET + 1), ICON_EDGE_INSET + 1)
    end
    local countWidth = count:GetStringWidth()
    if countWidth and countWidth > 0 then
      count:SetWidth(countWidth + 2)
    end
    count:SetHeight(COUNT_FONT_SIZE + 4)
  end

  local macroName = button.Name
  if macroName then
    styleButtonText(macroName, MACRO_FONT_SIZE)
    macroName:ClearAllPoints()
    if icon then
      macroName:SetPoint("BOTTOM", icon, "BOTTOM", -3, 1)
    else
      macroName:SetPoint("BOTTOM", button, "BOTTOM", 0, ICON_EDGE_INSET + 1)
    end
    macroName:SetJustifyH("CENTER")
    macroName:SetWidth(36)
    macroName:SetHeight(MACRO_FONT_SIZE + 2)
  end
end

---@param button Button
local function formatActionButtonHotkey(button)
  local hotKey = getHotKey(button)
  if not hotKey then
    return
  end
  local key = button.bindingAction and GetBindingKey(button.bindingAction) or nil
  if not key then
    key = GetBindingKey("CLICK " .. button:GetName() .. ":LeftButton")
  end
  if key and key ~= "" then
    hotKey:SetText(toShortKey(key))
    hotKey:Show()
  end
end

---@param texture Texture?
---@param width number
---@param height number
---@param offsetX number?
---@param offsetY number?
local function applyButtonOverlay(texture, width, height, offsetX, offsetY)
  if not texture then
    return
  end
  texture:ClearAllPoints()
  texture:SetSize(width, height)
  texture:SetPoint("TOPLEFT", offsetX or 0, offsetY or 0)
end

---@param button Button
local function hideQualityOverlays(button)
  if not button then
    return
  end
  if button.Border then
    button.Border:SetTexture()
    button.Border:Hide()
  end
  local qualityOverlay = button.ProfessionQualityOverlayFrame
  if qualityOverlay then
    qualityOverlay:Hide()
    if qualityOverlay.Texture then
      qualityOverlay.Texture:SetTexture()
      qualityOverlay.Texture:Hide()
    end
  end
end

---@param button Button
local function skinActionButton(button)
  if not button then
    return
  end

  if button.SlotArt then
    button.SlotArt:SetTexture()
    button.SlotArt:Hide()
  end
  if button.SlotBackground then
    button.SlotBackground:SetTexture()
    button.SlotBackground:Hide()
  end

  local normal = button.NormalTexture or button:GetNormalTexture()
  if normal then
    normal:SetTexture()
    normal:Hide()
  end

  hideQualityOverlays(button)

  local icon = button.icon
  if icon then
    if button.IconMask then
      icon:RemoveMaskTexture(button.IconMask)
    end
    -- 1) Crop (zoom). 2) Shrink the icon rect so default highlight covers it and neighbors show a gap.
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", ICON_EDGE_INSET, -ICON_EDGE_INSET)
    icon:SetPoint("BOTTOMRIGHT", -ICON_EDGE_INSET, ICON_EDGE_INSET)
    icon:SetTexCoord(ICON_ZOOM_INSET, 1 - ICON_ZOOM_INSET, ICON_ZOOM_INSET, 1 - ICON_ZOOM_INSET)

    if button.cooldown then
      button.cooldown:ClearAllPoints()
      button.cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT")
      button.cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
    end
  end

  -- Hover a bit larger than stock; pressed uses AddRow size so it is not tiny under the icon.
  applyButtonOverlay(button.HighlightTexture, HIGHLIGHT_WIDTH, HIGHLIGHT_HEIGHT, HIGHLIGHT_OFFSET_X, HIGHLIGHT_OFFSET_Y)
  applyButtonOverlay(button.CheckedTexture, HIGHLIGHT_WIDTH, HIGHLIGHT_HEIGHT, HIGHLIGHT_OFFSET_X, HIGHLIGHT_OFFSET_Y)
  applyButtonOverlay(button.NewActionTexture, HIGHLIGHT_WIDTH, HIGHLIGHT_HEIGHT, HIGHLIGHT_OFFSET_X, HIGHLIGHT_OFFSET_Y)
  applyButtonOverlay(button.SpellHighlightTexture, HIGHLIGHT_WIDTH, HIGHLIGHT_HEIGHT, HIGHLIGHT_OFFSET_X, HIGHLIGHT_OFFSET_Y)
  applyButtonOverlay(button.Flash, HIGHLIGHT_WIDTH, HIGHLIGHT_HEIGHT, HIGHLIGHT_OFFSET_X, HIGHLIGHT_OFFSET_Y)

  if button.PushedTexture then
    button:SetPushedAtlas("UI-HUD-ActionBar-IconFrame-AddRow-Down")
    applyButtonOverlay(button.PushedTexture, PUSHED_WIDTH, PUSHED_HEIGHT, PUSHED_OFFSET_X, PUSHED_OFFSET_Y)
  end

  formatActionButtonHotkey(button)
  styleActionButtonText(button)
end

local function skinAllActionButtons()
  for _, prefix in ipairs(ACTION_BUTTON_PREFIXES) do
    for index = 1, 12 do
      skinActionButton(_G[prefix .. index])
    end
  end
end

local function hideActionBarChrome()
  for _, barName in ipairs(ACTION_BARS) do
    local bar = _G[barName]
    if bar then
      bar.hideBarArt = true
      if bar.BorderArt then
        bar.BorderArt:Hide()
      end
      if bar.UpdateEndCaps then
        bar:UpdateEndCaps(true)
      end
      if bar.UpdateDividers then
        bar:UpdateDividers()
      end
    end
  end
end

---@param frame Frame?
local function hideBlizzardFrame(frame)
  if not frame then
    return
  end
  if frame.HideBase then
    frame:HideBase()
  else
    frame:Hide()
  end
  frame:SetParent(UIHider)
end

local function hideBagsAndMicroMenu()
  if not UIHider then
    UIHider = CreateFrame("Frame")
    UIHider:Hide()
  end

  hideBlizzardFrame(_G.BagsBar)
  hideBlizzardFrame(_G.MicroMenu)
  hideBlizzardFrame(_G.MicroButtonAndBagsBar)
end

local function hookButtonArtUpdates()
  if f.buttonArtHooked then
    return
  end
  if BaseActionButtonMixin and BaseActionButtonMixin.UpdateButtonArt then
    hooksecurefunc(BaseActionButtonMixin, "UpdateButtonArt", function(button)
      skinActionButton(button)
    end)
  end
  if ActionBarActionButtonMixin then
    -- Crafting-quality gem (bronze/silver/gold) on item actions — never show it.
    ActionBarActionButtonMixin.UpdateProfessionQuality = function(button)
      if button.ClearProfessionQuality then
        button:ClearProfessionQuality()
      end
      hideQualityOverlays(button)
    end
    if ActionBarActionButtonMixin.Update then
      hooksecurefunc(ActionBarActionButtonMixin, "Update", function(button)
        hideQualityOverlays(button)
      end)
    end
    if ActionBarActionButtonMixin.UpdateHotkeys then
      hooksecurefunc(ActionBarActionButtonMixin, "UpdateHotkeys", function(button)
        formatActionButtonHotkey(button)
        styleActionButtonText(button)
      end)
    end
    if ActionBarActionButtonMixin.UpdateCount then
      hooksecurefunc(ActionBarActionButtonMixin, "UpdateCount", function(button)
        styleActionButtonText(button)
      end)
    end
  end
  if EditModeActionBarSystemMixin and EditModeActionBarSystemMixin.UpdateSystemSettingHideBarArt then
    hooksecurefunc(EditModeActionBarSystemMixin, "UpdateSystemSettingHideBarArt", function()
      hideActionBarChrome()
    end)
  end
  if MicroMenu and MicroMenu.ResetMicroMenuPosition then
    hooksecurefunc(MicroMenu, "ResetMicroMenuPosition", function()
      hideBagsAndMicroMenu()
    end)
  end
  f.buttonArtHooked = true
end

f.renderActionBarFrame = function()
  local offset = 4
  local MainBar = _G["MainActionBar"]
  local TopBar = _G["MultiBarBottomRight"]

  -- Detect Bartender
  if C_AddOns.IsAddOnLoaded("Bartender4") then
    local BT4Bar1 = _G["BT4Button1"]
    local BT4Bar6 = _G["BT4Button60"]
    if (BT4Bar6 and BT4Bar1) then
      MainBar = BT4Bar1
      TopBar = BT4Bar6
    end
  end

  if (not MainBar or not TopBar) then
    f.print("No ActionBars found")
    return
  end

  if not ActionBarFrame then
    ActionBarFrame = CreateFrame("Frame", "LM_ActionBarFrame", UIParent, "BackdropTemplate")
    ActionBarFrame:Hide()
    ActionBarFrame:SetFrameStrata("BACKGROUND")
    ActionBarFrame:SetFrameLevel(1)
    ActionBarFrame:SetPoint("BOTTOMLEFT", MainBar, "BOTTOMLEFT", -offset, -offset)
    ActionBarFrame:SetPoint("TOPRIGHT", TopBar, "TOPRIGHT", offset, offset)
    ActionBarFrame:EnableMouse(false)
    ActionBarFrame:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    ActionBarFrame:SetBackdropColor(0, 0, 0, 0.8)
    ActionBarFrame:SetBackdropBorderColor(0, 0, 0, 1)
  end
  if LiqMeDB and LiqMeDB.showActionBar ~= false then
    ActionBarFrame:Show()
  else
    ActionBarFrame:Hide()
  end
end

f.print = function(...)
  print("|cff67AFD6" .. addonName .. ":|r", ...)
end

f.toggleCombatLog = function()
  local inInstance, instanceType = IsInInstance()
  local logEnabled = LoggingCombat()
  if inInstance and (instanceType == "party" or instanceType == "raid") then
    if not logEnabled then
      LoggingCombat(true)
      f.print("Logging enabled")
    end
  else
    if logEnabled then
      LoggingCombat(false)
      f.print("Logging disabled")
    end
  end
end

f.OnEvent = function(self, event, ...)
  if self[event] == nil then return end
  self[event](self, event, ...)
end

f.ADDON_LOADED = function(self, event, arg1)
  if arg1 == addonName then
    LiqMeDB = LiqMeDB or {}
    hookButtonArtUpdates()
    SLASH_LIQME1 = "/liqme"
    SlashCmdList.LIQME = function()
      LiqMeDB.showActionBar = not (LiqMeDB.showActionBar ~= false)
      f.renderActionBarFrame()
      if LiqMeDB.showActionBar ~= false then
        f.print("Action bar frame shown.")
      else
        f.print("Action bar frame hidden.")
      end
    end
    f.print("Addon loaded. /liqme to toggle action bar frame.")
  end
end

f.PLAYER_ENTERING_WORLD = function(self, event, ...)
  hookButtonArtUpdates()
  skinAllActionButtons()
  hideActionBarChrome()
  hideBagsAndMicroMenu()
  self.renderActionBarFrame()
  self.toggleCombatLog()
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", f.OnEvent)
