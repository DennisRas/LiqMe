---@class LM_Addon
local addon = select(2, ...)

---@class LM_Data
local Data = {}
addon.Data = Data

local LibAceDB = addon.libs.AceDB

Data.dbVersion = 1

---@type LM_Global
local defaultGlobal = {
  dbVersion = 1,
  showActionBar = true,
  liqui = {
    windows = {},
    tables = {},
  },
  logs = {
    lines = {},
    autoScroll = true,
    autoShow = false,
  },
}

---@type LM_DefaultDB
local defaultDB = {
  global = defaultGlobal,
}

Data.defaultDB = defaultDB

function Data:Initialize()
  ---@type LM_AceDB
  local db = LibAceDB:New("LiqMeDB", self.defaultDB, true)
  self.db = db
end
