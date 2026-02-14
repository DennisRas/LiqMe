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

-- Dev-only options (stored in LiqMeDB, not used by addon logic) for testing settings UI
local function devGet(key) return LiqMeDB.dev and LiqMeDB.dev[key] end
local function devSet(key, val)
  LiqMeDB.dev = LiqMeDB.dev or {}
  LiqMeDB.dev[key] = val
end

f.ADDON_LOADED = function(self, event, arg1)
  if arg1 == addonName then
    LiqMeDB = LiqMeDB or {}
    local options = {
      type = "group",
      args = {
        general = {
          type = "group",
          name = "General",
          order = 1,
          args = {
            header = { type = "header", name = "LiqMe", order = 0 },
            showActionBar = {
              type = "toggle",
              name = "Show action bar frame",
              desc = "Show the frame around action bars",
              get = function() return LiqMeDB.showActionBar ~= false end,
              set = function(_, v)
                LiqMeDB.showActionBar = v
                f.renderActionBarFrame()
              end,
              order = 10,
            },
            testButton = {
              type = "execute",
              name = "Print test",
              func = function() f.print("Settings test") end,
              order = 20,
            },
          },
        },
        appearance = {
          type = "group",
          name = "Appearance",
          order = 2,
          args = {
            header = { type = "header", name = "Appearance", order = 0 },
            desc = { type = "description", name = "Placeholder options for layout testing. Values are stored but not used.", order = 1 },
            showMinimapIcon = {
              type = "toggle",
              name = "Show minimap icon",
              desc = "Display the addon icon on the minimap (dev placeholder).",
              get = function() return devGet("showMinimapIcon") end,
              set = function(_, v) devSet("showMinimapIcon", v) end,
              order = 10,
            },
            windowScale = {
              type = "input",
              name = "Window scale",
              desc = "Scale factor for the main window (e.g. 100 for 100%%).",
              get = function() return tostring(devGet("windowScale") or "100") end,
              set = function(_, v) devSet("windowScale", v) end,
              order = 20,
            },
            useCompactMode = {
              type = "toggle",
              name = "Compact mode",
              desc = "Use a more compact layout for the interface.",
              get = function() return devGet("useCompactMode") end,
              set = function(_, v) devSet("useCompactMode", v) end,
              order = 30,
            },
            theme = {
              type = "select",
              name = "Theme",
              desc = "UI theme (dev placeholder).",
              values = { light = "Light", dark = "Dark", system = "System" },
              get = function() return devGet("theme") or "dark" end,
              set = function(_, v) devSet("theme", v) end,
              order = 40,
            },
            accentColor = {
              type = "color",
              name = "Accent color",
              desc = "Primary accent color (dev placeholder).",
              hasAlpha = false,
              get = function()
                local c = LiqMeDB.dev and LiqMeDB.dev.accentColor
                if c then return c.r, c.g, c.b, 1 end
                return 0.3, 0.5, 0.8, 1
              end,
              set = function(_, r, g, b)
                LiqMeDB.dev = LiqMeDB.dev or {}
                LiqMeDB.dev.accentColor = { r = r, g = g, b = b }
              end,
              order = 50,
            },
          },
        },
        notifications = {
          type = "group",
          name = "Notifications",
          order = 3,
          args = {
            header = { type = "header", name = "Notifications", order = 0 },
            desc = { type = "description", name = "Configure when and how you are notified (dev placeholders).", order = 1 },
            enableSound = {
              type = "toggle",
              name = "Enable sound",
              desc = "Play a sound when a notification is shown.",
              get = function() return devGet("enableSound") ~= false end,
              set = function(_, v) devSet("enableSound", v) end,
              order = 10,
            },
            notifyInCombat = {
              type = "toggle",
              name = "Notify in combat",
              desc = "Show notifications even while in combat.",
              get = function() return devGet("notifyInCombat") end,
              set = function(_, v) devSet("notifyInCombat", v) end,
              order = 20,
            },
            notificationDuration = {
              type = "input",
              name = "Duration (seconds)",
              desc = "How long notifications stay on screen.",
              get = function() return tostring(devGet("notificationDuration") or "5") end,
              set = function(_, v) devSet("notificationDuration", v) end,
              order = 30,
            },
            testNotify = {
              type = "execute",
              name = "Test notification",
              func = function() f.print("Test notification (dev)") end,
              order = 40,
            },
          },
        },
        combat = {
          type = "group",
          name = "Combat",
          order = 4,
          args = {
            header = { type = "header", name = "Combat", order = 0 },
            autoToggleCombatLog = {
              type = "toggle",
              name = "Auto combat log",
              desc = "Automatically enable combat logging in instances (current LiqMe behaviour).",
              get = function() return devGet("autoCombatLog") ~= false end,
              set = function(_, v) devSet("autoCombatLog", v) end,
              order = 10,
            },
            showCombatFeedback = {
              type = "toggle",
              name = "Combat feedback",
              desc = "Show on-screen feedback during combat (placeholder).",
              get = function() return devGet("combatFeedback") end,
              set = function(_, v) devSet("combatFeedback", v) end,
              order = 20,
            },
            hideInCombat = {
              type = "toggle",
              name = "Hide UI in combat",
              desc = "Hide certain UI elements when entering combat.",
              get = function() return devGet("hideInCombat") end,
              set = function(_, v) devSet("hideInCombat", v) end,
              order = 30,
            },
          },
        },
        raid = {
          type = "group",
          name = "Raid & Dungeons",
          order = 5,
          args = {
            header = { type = "header", name = "Raid & Dungeons", order = 0 },
            desc = { type = "description", name = "Options for group content. None of these affect addon behaviour yet.", order = 1 },
            showRaidFrames = {
              type = "toggle",
              name = "Show raid frames",
              desc = "Display custom raid frames when in a raid group.",
              get = function() return devGet("showRaidFrames") end,
              set = function(_, v) devSet("showRaidFrames", v) end,
              order = 10,
            },
            announceKeystones = {
              type = "toggle",
              name = "Announce keystones",
              desc = "Announce your mythic+ keystone to party or guild.",
              get = function() return devGet("announceKeystones") end,
              set = function(_, v) devSet("announceKeystones", v) end,
              order = 20,
            },
            dungeonFilter = {
              type = "input",
              name = "Dungeon filter",
              desc = "Filter dungeons by name or ID (placeholder).",
              get = function() return tostring(devGet("dungeonFilter") or "") end,
              set = function(_, v) devSet("dungeonFilter", v) end,
              order = 30,
            },
            resetSettings = {
              type = "execute",
              name = "Reset raid options",
              func = function() f.print("Raid options reset (dev)") end,
              order = 40,
            },
          },
        },
        interface = {
          type = "group",
          name = "Interface",
          order = 6,
          args = {
            header = { type = "header", name = "Interface", order = 0 },
            tooltipsEnabled = {
              type = "toggle",
              name = "Show tooltips",
              desc = "Enable tooltips for addon elements.",
              get = function() return devGet("tooltips") ~= false end,
              set = function(_, v) devSet("tooltips", v) end,
              order = 10,
            },
            fontSize = {
              type = "input",
              name = "Font size",
              desc = "Base font size for addon text (e.g. 12).",
              get = function() return tostring(devGet("fontSize") or "12") end,
              set = function(_, v) devSet("fontSize", v) end,
              order = 20,
            },
            language = {
              type = "input",
              name = "Language code",
              desc = "Override language (e.g. enUS, deDE). Leave empty for game locale.",
              get = function() return tostring(devGet("language") or "") end,
              set = function(_, v) devSet("language", v) end,
              order = 30,
            },
          },
        },
        debug = {
          type = "group",
          name = "Debug",
          order = 7,
          args = {
            header = { type = "header", name = "Debug", order = 0 },
            desc = { type = "description", name = "Development and debugging options. Only use if you know what you're doing.", order = 1 },
            verboseLogging = {
              type = "toggle",
              name = "Verbose logging",
              desc = "Print extra debug messages to chat.",
              get = function() return devGet("verbose") end,
              set = function(_, v) devSet("verbose", v) end,
              order = 10,
            },
            dumpSettings = {
              type = "execute",
              name = "Dump settings to chat",
              func = function()
                f.print("LiqMeDB keys: " .. (LiqMeDB and "present" or "nil"))
                if LiqMeDB and LiqMeDB.dev then
                  for k, v in pairs(LiqMeDB.dev) do f.print("  dev." .. tostring(k) .. " = " .. tostring(v)) end
                end
              end,
              order = 20,
            },
            reloadUI = {
              type = "execute",
              name = "Reload UI",
              func = function() ReloadUI() end,
              order = 30,
            },
          },
        },
        testing = {
          type = "group",
          name = "Testing",
          order = 8,
          args = {
            header = { type = "header", name = "Scroll & controls test", order = 0 },
            desc = { type = "description", name = "Many options to test scrollbar and all control types.", order = 1 },
            singleChoice = {
              type = "select",
              name = "Single choice",
              values = { a = "Option A", b = "Option B", c = "Option C" },
              get = function() return devGet("singleChoice") or "a" end,
              set = function(_, v) devSet("singleChoice", v) end,
              order = 5,
            },
            multiChoice = {
              type = "multiselect",
              name = "Multi choice",
              desc = "Pick multiple options.",
              values = { x = "Extra", y = "Yes", z = "Zoom" },
              get = function(_, k) return (devGet("multiChoice") or {})[k] end,
              set = function(_, k, v)
                LiqMeDB.dev = LiqMeDB.dev or {}
                LiqMeDB.dev.multiChoice = LiqMeDB.dev.multiChoice or {}
                LiqMeDB.dev.multiChoice[k] = v
              end,
              order = 6,
            },
            testColor = {
              type = "color",
              name = "Test color",
              hasAlpha = true,
              get = function()
                local c = LiqMeDB.dev and LiqMeDB.dev.testColor
                if c then return c.r, c.g, c.b, c.a or 1 end
                return 0.5, 0.5, 0.5, 1
              end,
              set = function(_, r, g, b, a)
                LiqMeDB.dev = LiqMeDB.dev or {}
                LiqMeDB.dev.testColor = { r = r, g = g, b = b, a = a or 1 }
              end,
              order = 7,
            },
          },
        },
        scrollTest = {
          type = "group",
          name = "Scroll test",
          order = 9,
          args = {},
        },
      },
    }
    -- Fill scrollTest with many rows so scrollbar is visible
    do
      local scrollArgs = options.args.scrollTest.args
      scrollArgs.header = { type = "header", name = "Many rows for scrollbar", order = 0 }
      for i = 1, 28 do
        local isInput = (i % 4 == 0)
        scrollArgs["row" .. i] = {
          type = isInput and "input" or "toggle",
          name = "Option " .. i,
          order = 10 + i,
        }
        if isInput then
          scrollArgs["row" .. i].get = function() return tostring(devGet("scroll_" .. i) or "") end
          scrollArgs["row" .. i].set = function(_, v) devSet("scroll_" .. i, v) end
        else
          scrollArgs["row" .. i].get = function() return devGet("scroll_" .. i) end
          scrollArgs["row" .. i].set = function(_, v) devSet("scroll_" .. i, v) end
        end
      end
    end
    LiqUI.Settings:Register(addonName, options, "LiqMe")
    SLASH_LIQME1 = "/liqme"
    SlashCmdList.LIQME = function() LiqUI.Settings:Toggle() end
    f.print("Addon loaded. /liqme to open settings.")
  end
end

f.PLAYER_ENTERING_WORLD = function(self, event, ...)
  self.renderActionBarFrame()
  self.toggleCombatLog()
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", f.OnEvent)
