---@type string
local addonName = select(1, ...)
---@class LM_Addon
local addon = select(2, ...)

local f = CreateFrame("Frame")
local ActionBarFrame

--@debug@
_G[addonName] = addon
--@end-debug@

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
    f.print("Addon loaded.")
  end
end

f.PLAYER_ENTERING_WORLD = function(self, event, ...)
  self.renderActionBarFrame()
  self.toggleCombatLog()
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", f.OnEvent)
