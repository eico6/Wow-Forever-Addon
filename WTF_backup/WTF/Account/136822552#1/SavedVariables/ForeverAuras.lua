
ForeverAurasSaved = {
["dynamicIconCache"] = {
},
["editor_tab_spaces"] = 4,
["displays"] = {
["Battle Shout"] = {
["iconSource"] = -1,
["color"] = {
1,
1,
1,
1,
},
["adjustedMax"] = "",
["adjustedMin"] = "",
["yOffset"] = 0,
["anchorPoint"] = "CENTER",
["cooldownSwipe"] = true,
["cooldownEdge"] = true,
["actions"] = {
["start"] = {
},
["finish"] = {
},
["init"] = {
},
},
["triggers"] = {
{
["trigger"] = {
["auraReadableSettings"] = {
["debuffType"] = "HELPFUL",
},
["subeventSuffix"] = "_CAST_START",
["auraRankSpellIDs"] = {
"Battle Shout",
},
["auraTracking"] = "native",
["type"] = "secretAura",
["event"] = "Health",
["unit"] = "player",
["secretUseRankSpellIDs"] = true,
["useExactSpellId"] = true,
["spellIds"] = {
},
["subeventPrefix"] = "SPELL",
["auraspellids"] = {
},
["names"] = {
},
["secretUseSpellIDs"] = false,
["debuffType"] = "HELPFUL",
},
["untrigger"] = {
},
},
["activeTriggerMode"] = 1,
},
["internalVersion"] = 93,
["progressSource"] = {
-1,
"",
},
["animation"] = {
["start"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
["main"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
["finish"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
},
["desaturate"] = false,
["subRegions"] = {
{
["type"] = "subbackground",
},
{
["text_shadowXOffset"] = 0,
["text_text"] = "%p",
["text_shadowColor"] = {
0,
0,
0,
1,
},
["text_selfPoint"] = "AUTO",
["text_automaticWidth"] = "Auto",
["text_fixedWidth"] = 64,
["text_fontType"] = "OUTLINE",
["anchorYOffset"] = 0,
["text_justify"] = "CENTER",
["rotateText"] = "NONE",
["anchorXOffset"] = 0,
["text_text_format_p_time_mod_rate"] = true,
["text_text_format_p_time_legacy_floor"] = false,
["type"] = "subtext",
["text_anchorXOffset"] = 0,
["text_color"] = {
1,
1,
1,
1,
},
["text_font"] = "Friz Quadrata TT",
["text_alpha"] = 1,
["text_anchorYOffset"] = 20,
["text_text_format_p_format"] = "timed",
["text_wordWrap"] = "WordWrap",
["text_visible"] = true,
["text_text_format_p_time_format"] = -3,
["text_shadowYOffset"] = 0,
["anchor_point"] = "CENTER",
["text_fontSize"] = 22,
["text_text_format_p_time_dynamic_threshold"] = 2,
["text_text_format_p_time_precision"] = 1,
},
{
["glowFrequency"] = 0.25,
["type"] = "subglow",
["useGlowColor"] = false,
["glowType"] = "buttonOverlay",
["glowLength"] = 10,
["glowYOffset"] = 0,
["glowColor"] = {
1,
1,
1,
1,
},
["glowDuration"] = 1,
["glowXOffset"] = 0,
["glowThickness"] = 1,
["glowScale"] = 1,
["glow"] = false,
["glowLines"] = 8,
["glowBorder"] = false,
},
},
["height"] = 50,
["load"] = {
["class_and_spec"] = {
["single"] = 1491,
},
["talent"] = {
["multi"] = {
},
},
["use_class_and_spec"] = true,
["class"] = {
["multi"] = {
},
},
["spec"] = {
["multi"] = {
},
},
["size"] = {
["multi"] = {
},
},
},
["useAdjustededMax"] = false,
["config"] = {
},
["cooldownTextDisabled"] = true,
["xOffset"] = 0,
["useAdjustededMin"] = false,
["regionType"] = "icon",
["parent"] = "Buffs",
["information"] = {
},
["conditions"] = {
},
["selfPoint"] = "CENTER",
["useCooldownModRate"] = true,
["anchorFrameType"] = "SCREEN",
["zoom"] = 0,
["alpha"] = 1,
["icon"] = true,
["id"] = "Battle Shout",
["authorOptions"] = {
},
["frameStrata"] = 1,
["width"] = 50,
["blizzardAuraDisplay"] = {
["auraStart"] = {
},
["actionSounds"] = true,
["sharedDisplay"] = true,
["auraMain"] = {
},
},
["uid"] = "2sSTPcsPSb8",
["inverse"] = false,
["keepAspectRatio"] = false,
["displayIcon"] = 132333,
["cooldown"] = true,
["texYOffset"] = 0,
},
["Buffs"] = {
["controlledChildren"] = {
"Battle Shout",
},
["borderBackdrop"] = "Blizzard Tooltip",
["xOffset"] = -80,
["yOffset"] = 72,
["anchorPoint"] = "CENTER",
["borderColor"] = {
0,
0,
0,
1,
},
["actions"] = {
["start"] = {
},
["finish"] = {
},
["init"] = {
},
},
["triggers"] = {
{
["trigger"] = {
["type"] = "aura2",
["subeventSuffix"] = "_CAST_START",
["auraTracking"] = "readable",
["event"] = "Health",
["subeventPrefix"] = "SPELL",
["spellIds"] = {
},
["names"] = {
},
["unit"] = "player",
["debuffType"] = "HELPFUL",
},
["untrigger"] = {
},
},
},
["internalVersion"] = 93,
["animation"] = {
["start"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
["main"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
["finish"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
},
["subRegions"] = {
},
["load"] = {
["talent"] = {
["multi"] = {
},
},
["spec"] = {
["multi"] = {
},
},
["class"] = {
["multi"] = {
},
},
["size"] = {
["multi"] = {
},
},
},
["backdropColor"] = {
1,
1,
1,
0.5,
},
["groupIcon"] = "Interface\\AddOns\\ForeverAuras\\Media\\Icons\\Emojis\\BroKiss.tga",
["scale"] = 0.5,
["border"] = false,
["anchorFrameFrame"] = "PlayerFrame",
["regionType"] = "group",
["borderSize"] = 2,
["blizzardFlow"] = true,
["borderPixelPerfect"] = true,
["blizzardFlowOrigin"] = "group",
["uid"] = "LnUrzxZM7nu",
["parent"] = "WARRIOR",
["blizzardFlowSpacing"] = 2,
["selfPoint"] = "CENTER",
["borderInset"] = 1,
["id"] = "Buffs",
["borderOffset"] = 4,
["frameStrata"] = 1,
["anchorFrameType"] = "SELECTFRAME",
["authorOptions"] = {
},
["config"] = {
},
["alpha"] = 1,
["blizzardFlowGrowth"] = "RIGHT",
["conditions"] = {
},
["information"] = {
},
["borderEdge"] = "Square Full White",
},
["WARRIOR"] = {
["controlledChildren"] = {
"Buffs",
},
["borderBackdrop"] = "Blizzard Tooltip",
["xOffset"] = 0,
["yOffset"] = 0,
["anchorPoint"] = "CENTER",
["borderColor"] = {
0,
0,
0,
1,
},
["actions"] = {
["start"] = {
},
["finish"] = {
},
["init"] = {
},
},
["triggers"] = {
{
["trigger"] = {
["type"] = "aura2",
["subeventSuffix"] = "_CAST_START",
["auraTracking"] = "readable",
["event"] = "Health",
["subeventPrefix"] = "SPELL",
["spellIds"] = {
},
["names"] = {
},
["unit"] = "player",
["debuffType"] = "HELPFUL",
},
["untrigger"] = {
},
},
},
["internalVersion"] = 93,
["selfPoint"] = "CENTER",
["subRegions"] = {
},
["load"] = {
["talent"] = {
["multi"] = {
},
},
["spec"] = {
["multi"] = {
},
},
["class"] = {
["multi"] = {
},
},
["size"] = {
["multi"] = {
},
},
},
["backdropColor"] = {
1,
1,
1,
0.5,
},
["scale"] = 1,
["border"] = false,
["borderEdge"] = "Square Full White",
["regionType"] = "group",
["borderSize"] = 2,
["borderOffset"] = 4,
["frameStrata"] = 1,
["groupIcon"] = 626008,
["id"] = "WARRIOR",
["authorOptions"] = {
},
["alpha"] = 1,
["anchorFrameType"] = "SCREEN",
["borderPixelPerfect"] = true,
["uid"] = "AYD70THQe)(",
["config"] = {
},
["animation"] = {
["start"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
["main"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
["finish"] = {
["easeStrength"] = 3,
["type"] = "none",
["duration_type"] = "seconds",
["easeType"] = "none",
},
},
["conditions"] = {
},
["information"] = {
},
["borderInset"] = 1,
},
},
["totemSpells"] = {
},
["login_squelch_time"] = 10,
["lastArchiveClear"] = 1794684060,
["minimap"] = {
["minimapPos"] = 204.7091480695568,
["hide"] = true,
},
["historyCutoff"] = 730,
["dbVersion"] = 93,
["migrationCutoff"] = 730,
["registered"] = {
},
["editor_font_size"] = 12,
["lastUpgrade"] = 1795726819,
["totemNames"] = {
},
["features"] = {
},
}
