---@class LM_ActionBar : Frame
---@field hideBarArt boolean?
---@field BorderArt Texture?
---@field UpdateEndCaps fun(self: LM_ActionBar, forceHide: boolean?)?
---@field UpdateDividers fun(self: LM_ActionBar)?

---@class LM_ActionButton : ActionBarButtonTemplate
---@field HotKey FontString?
---@field Count FontString?
---@field Name FontString?
---@field icon Texture?
---@field IconMask MaskTexture?
---@field Border Texture?
---@field SlotArt Texture?
---@field SlotBackground Texture?
---@field HighlightTexture Texture?
---@field CheckedTexture Texture?
---@field NewActionTexture Texture?
---@field SpellHighlightTexture Texture?
---@field Flash Texture?
---@field PushedTexture Texture?
---@field cooldown Cooldown?
---@field bindingAction string?
---@field TextOverlayContainer LM_TextOverlayContainer?
---@field ProfessionQualityOverlayFrame LM_ProfessionQualityOverlay?
---@field ClearProfessionQuality fun(self: LM_ActionButton)?

---@class LM_BlizzardBar : Frame
---@field HideBase fun(self: LM_BlizzardBar)?

---@class LM_ProfessionQualityOverlay : Frame
---@field Texture Texture?

---@class LM_TextOverlayContainer : Frame
---@field HotKey FontString?
---@field Count FontString?
