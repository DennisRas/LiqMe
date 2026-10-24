---@class LM_Addon
local addon = select(2, ...)

---@class LM_Core
local Core = addon.libs.AceAddon:NewAddon(addon.name, "AceConsole-3.0")
addon.Core = Core

local Data = addon.Data
local LiqUI = addon.libs.LiqUI
local Events = LiqUI.Events

local ActionBarFrame
local UIHider
local buttonArtHooked = false

local SKIN_ACTION_BARS = false

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

---@param message string
local function say(message)
  Core:Print(message)
  if addon.logger then
    addon.logger:Log(message)
  end
end

---@param button LM_ActionButton
---@return FontString?
local function getHotKey(button)
  return button.HotKey or (button.TextOverlayContainer and button.TextOverlayContainer.HotKey)
end

---@param button LM_ActionButton
---@return FontString?
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

---@param button LM_ActionButton
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

---@param button LM_ActionButton
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

---@param button LM_ActionButton?
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

---@param button LM_ActionButton?
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
      ---@type LM_ActionButton?
      local button = _G[prefix .. index]
      skinActionButton(button)
    end
  end
end

local function hideActionBarChrome()
  for _, barName in ipairs(ACTION_BARS) do
    ---@type LM_ActionBar?
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

---@param frame LM_BlizzardBar?
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

  ---@type LM_BlizzardBar?
  local bagsBar = _G.BagsBar
  ---@type LM_BlizzardBar?
  local microMenu = _G.MicroMenu
  ---@type LM_BlizzardBar?
  local microButtonAndBagsBar = _G.MicroButtonAndBagsBar
  hideBlizzardFrame(bagsBar)
  hideBlizzardFrame(microMenu)
  hideBlizzardFrame(microButtonAndBagsBar)
end

---@param button LM_ActionButton
local function onUpdateButtonArt(button)
  skinActionButton(button)
end

---@param button LM_ActionButton
local function onUpdateProfessionQuality(button)
  if button.ClearProfessionQuality then
    button:ClearProfessionQuality()
  end
  hideQualityOverlays(button)
end

---@param button LM_ActionButton
local function onActionButtonUpdate(button)
  hideQualityOverlays(button)
end

---@param button LM_ActionButton
local function onUpdateHotkeys(button)
  formatActionButtonHotkey(button)
  styleActionButtonText(button)
end

---@param button LM_ActionButton
local function onUpdateCount(button)
  styleActionButtonText(button)
end

local function onHideBarArt()
  hideActionBarChrome()
end

local function onResetMicroMenuPosition()
  hideBagsAndMicroMenu()
end

local function hookButtonArtUpdates()
  if buttonArtHooked then
    return
  end
  if BaseActionButtonMixin and BaseActionButtonMixin.UpdateButtonArt then
    hooksecurefunc(BaseActionButtonMixin, "UpdateButtonArt", onUpdateButtonArt)
  end
  if ActionBarActionButtonMixin then
    -- Crafting-quality gem (bronze/silver/gold) on item actions — never show it.
    ActionBarActionButtonMixin.UpdateProfessionQuality = onUpdateProfessionQuality
    if ActionBarActionButtonMixin.Update then
      hooksecurefunc(ActionBarActionButtonMixin, "Update", onActionButtonUpdate)
    end
    if ActionBarActionButtonMixin.UpdateHotkeys then
      hooksecurefunc(ActionBarActionButtonMixin, "UpdateHotkeys", onUpdateHotkeys)
    end
    if ActionBarActionButtonMixin.UpdateCount then
      hooksecurefunc(ActionBarActionButtonMixin, "UpdateCount", onUpdateCount)
    end
  end
  if EditModeActionBarSystemMixin and EditModeActionBarSystemMixin.UpdateSystemSettingHideBarArt then
    hooksecurefunc(EditModeActionBarSystemMixin, "UpdateSystemSettingHideBarArt", onHideBarArt)
  end
  if MicroMenu and MicroMenu.ResetMicroMenuPosition then
    hooksecurefunc(MicroMenu, "ResetMicroMenuPosition", onResetMicroMenuPosition)
  end
  buttonArtHooked = true
end

local function renderActionBarFrame()
  local offset = 4
  ---@type Frame?
  local MainBar = _G["MainActionBar"]
  ---@type Frame?
  local TopBar = _G["MultiBarBottomRight"]

  -- Detect Bartender
  if C_AddOns.IsAddOnLoaded("Bartender4") then
    ---@type Frame?
    local BT4Bar1 = _G["BT4Button1"]
    ---@type Frame?
    local BT4Bar6 = _G["BT4Button60"]
    if (BT4Bar6 and BT4Bar1) then
      MainBar = BT4Bar1
      TopBar = BT4Bar6
    end
  end

  if (not MainBar or not TopBar) then
    say("No ActionBars found")
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
  if Data.db.global.showActionBar ~= false then
    ActionBarFrame:Show()
  else
    ActionBarFrame:Hide()
  end
end

local function toggleCombatLog()
  local inInstance, instanceType = IsInInstance()
  local logEnabled = LoggingCombat()
  if inInstance and (instanceType == "party" or instanceType == "raid") then
    if not logEnabled then
      LoggingCombat(true)
      say("Logging enabled")
    end
  else
    if logEnabled then
      LoggingCombat(false)
      say("Logging disabled")
    end
  end
end

---@param _frame Frame
---@param _event string
local function onPlayerEnteringWorld(_frame, _event)
  if SKIN_ACTION_BARS then
    hookButtonArtUpdates()
    skinAllActionButtons()
    hideActionBarChrome()
    hideBagsAndMicroMenu()
  end
  renderActionBarFrame()
  toggleCombatLog()
end

function Core:OnInitialize()
  Data:Initialize()
  ---@type LiqUI_NewLoggerOptions
  local loggerOptions = {
    name = addon.name,
    title = addon.title,
    storage = Data.db.global.logs,
  }
  addon.logger = LiqUI:NewLogger(loggerOptions)
  self:RegisterChatCommand(addon.name:lower(), "OnChatCommand")
end

function Core:OnEnable()
  Events:RegisterEvent("PLAYER_ENTERING_WORLD", onPlayerEnteringWorld, true)
  say("Addon loaded. /liqme to toggle the action bar frame.")
end

function Core:OnChatCommand()
  Data.db.global.showActionBar = Data.db.global.showActionBar == false
  renderActionBarFrame()
  if Data.db.global.showActionBar then
    say("Action bar frame shown.")
  else
    say("Action bar frame hidden.")
  end
end
