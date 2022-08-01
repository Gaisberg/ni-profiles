--------------------------------
-- Blood
-- Version: 12340  (3.3.5a)
-- Author: Nuok
--------------------------------

local ni = ...

local GlyphofVampiricBlood = ni.player.has_glyph(58676)
local GlyphofHornofWinter = ni.player.has_glyph(58680)
local GlyphofDisease = ni.player.has_glyph(63334)
local GlyphofPestilence = ni.player.has_glyph(59309)
local KillingMachine = 51124

local queue = {
   "Pause",
   "Cache",
   "AutoAttack",
   "IceboundFortitude",
   "RuneTap",
   "RuneStrike",
   "VampiricBlood",
   "AntiMagicShell",
   "MindFreeze",
   "GCD",
   "Presence",
   "MindFreeze",
   "GlyphofPestilence",
   "DeathandDecay",
   "Pestilence",
   "KillingMachine",
   "BloodBoil",
   "IcyTouch",
   "PlagueStrike",
   "DeathStrikeHP",
   "HeartStrike",
   "BloodStrike",
   "DeathStrikeFiller",
   "DeathCoil",
   "HornofWinter"
}

local values = {
   ["DeathandDecay"] = 2,
   ["IceboundFortitude"] = 40,
   ["RuneTap"] = 70,
   ["VampiricBlood"] = 50,
   ["DeathStrike"] = 90
}


local guid =  ni.player.guid()

local function get_setting(key)
      return ni.profile["Blood"].get_setting(key)
end

local ui = {
   settingsfile = guid .. "_blood_dk_wrath.json",
   {type = "separator"},
   {
      type = "combobox",
      text = "Presence Selection",
      combobox = {
         "Blood Presence",
         "Frost Presence",
         "Unholy Presence",
      },
      selected = "",
      key = "Presence"
   },
   {type = "separator"},
   {
      type = "checkbox",
      text = "Anti-Magic Shell",
      enabled = true,
      key = "AntiMagicShell"
   },
   {
      type = "checkbox",
      text = "Icebound Fortitude",
      enabled = true,
      key = "IceboundFortitude"
   },
   {
      type = "checkbox",
      text = "Vampiric Blood",
      enabled = true,
      key = "VampiricBlood"
   },
}


local t, p = "target", "player"
local cache = {
	blood_plauge = 0,
	frost_fever = 0,
	targets = nil,
   target_count = 0,
	blood_rune = 0,
   runicpower = 0
}

local abilities = {
   ["Pause"] = function()
      if ni.mount.is_mounted() or ni.player.is_dead_or_ghost() or not ni.unit.exists(t) or ni.unit.is_dead_or_ghost(t) or
            not ni.player.can_attack(t)
       then
         return true
      end
   end,
   ["GCD"] = function ()
      if ni.spell.on_gcd() then
         return true
      end
   end,
   ["Cache"] = function()
		_, cache.blood_rune = ni.runes.blood.status()
		cache.blood_plauge = ni.unit.debuff_remaining(t, 55078, p)
		cache.frost_fever = ni.unit.debuff_remaining(t, 55095, p)
      cache.runicpower = ni.player.power(6)
		cache.targets = ni.unit.enemies_in_range(t, 10)
      cache.target_count = ni.table.length(cache.targets)
      cache.hp = ni.player.hp()
	end,
   ["AutoAttack"] = function()
      if not ni.spell.is_current(ni.spells.auto_attack) and ni.player.in_melee(t) then
         ni.spell.cast(spells.AutoAttack.id)
      end
   end,
   ["Presence"] = function ()
      if get_setting("Presence") == select(1, ni.spell.info(ni.spells.frost_presence)) and not ni.player.buff(ni.spells.frost_presence) and
      ni.spell.available(ni.spells.frost_presence) then
         ni.spell.cast(ni.spells.frost_presence)
         return true
      end
      if get_setting("Presence") == select(1, ni.spell.info(ni.spells.blood_presence)) and not ni.player.buff(ni.spells.blood_presence) and
      ni.spell.available(ni.spells.blood_presence) then
         ni.spell.cast(ni.spells.blood_presence)
         return true
      end
      if get_setting("Presence") == select(1, ni.spell.info(ni.spells.unholy_presence)) and not ni.player.buff(ni.spells.unholy_presence) and
      ni.spell.available(ni.spells.unholy_presence) then
         ni.spell.cast(ni.spells.unholy_presence)
         return true
      end
   end,
   ["IcyTouch"] = function()
      if cache.frost_fever < 2 and ni.spell.valid(ni.spells.icy_touch, t, true, true) then
         ni.spell.cast(ni.spells.icy_touch, t)
         return true
      end
   end,
   ["PlagueStrike"] = function()
      if cache.blood_plauge < 2 and ni.spell.valid(ni.spells.plague_strike, t, true, true) then
         ni.spell.cast(ni.spells.plague_strike, t)
         return true
      end
   end,
   ["BloodStrike"] = function()
      if ni.spell.valid(ni.spells.blood_strike, t, true, true) then
         ni.spell.cast(ni.spells.blood_strike, t)
         return true
      end
   end,
   ["DeathStrikeHP"] = function()
      if ni.spell.valid(ni.spells.death_strike, t, true, true) and cache.hp <= values["DeathStrike"] then
         ni.spell.cast(ni.spells.death_strike, t)
         return true
      end
   end,
   ["DeathStrikeFiller"] = function()
      if ni.spell.valid(ni.spells.death_strike, t, true, true) then
         ni.spell.cast(ni.spells.death_strike, t)
         return true
      end
   end,
   ["HeartStrike"] = function()
      if ni.spell.valid(ni.spells.heart_strike, t, true, true) then
         ni.spell.cast(ni.spells.heart_strike, t)
         return true
      end
   end,
   ["DeathCoil"] = function()
      if cache.runicpower > 80 and ni.spell.valid(ni.spells.death_coil, t, true, true) then
         ni.spell.cast(ni.spells.death_coil, t)
         return true
      end
   end,
   ["Pestilence"] = function ()
      local should_cast = false
      if cache.blood_plauge > 1 and cache.frost_fever > 1 and cache.target_count >= 1 then
         if ni.spell.valid(ni.spells.pestilence, t, true, true) then
            for guid in ni.table.opairs(cache.targets) do
               if ni.unit.debuff_remaining(guid, 55078, p) < 2 or ni.unit.debuff_remaining(guid, 55095, p) < 2 then
                  should_cast = true
                  break
               end
            end
            if should_cast then
               ni.spell.cast(ni.spells.pestilence, t)
               return true
            end
         end
      end
   end,
   ["RuneTap"] = function ()
      if ni.spell.available(ni.spells.rune_tap) and cache.hp < values["RuneTap"] then
         ni.spell.delay_cast(ni.spells.rune_tap, p, 0.2)
      end
   end,
   ["MindFreeze"] = function()
      if ni.spell.valid(ni.spells.mind_freeze, t, true, true) and ni.unit.can_interupt(t, 30) then
         ni.spell.delay_cast(ni.spells.mind_freeze, t, 0.2)
         return true
      end
   end,
   ["DeathandDecay"] = function ()
      if ni.spell.available(ni.spells.death_and_decay) and cache.target_count >= values["DeathandDecay"] and
      ni.spell.in_range(ni.spells.death_and_decay, t) then
         ni.spell.cast_on(ni.spells.death_and_decay, t)
         return true
      end
   end,
   ["BloodBoil"] = function ()
      if ni.spell.available(ni.spells.blood_boil) then
         local nearby = ni.unit.enemies_in_range(t, 10)
         local count = 0
         for guid in ni.table.opairs(nearby) do
            if ni.unit.debuff_remaining(guid, 55078, p) > 2 or ni.unit.debuff_remaining(guid, 55095, p) > 2 then
               count = count + 1
            end
         end
         if count > 2 then
            ni.spell.cast(ni.spells.blood_boil)
            return
         end
      end
   end,
   ["HornofWinter"] = function ()
      if ni.spell.available(ni.spells.horn_of_winter) then
         ni.spell.cast(ni.spells.horn_of_winter)
         return
      end
   end,
   ["RuneStrike"] = function ()
      if not ni.spell.is_current(ni.spells.rune_strike) and ni.spell.is_usable(ni.spells.rune_strike) and
      ni.spell.valid(ni.spells.rune_strike, t, true, true) then
         ni.spell.delay_cast(ni.spells.rune_strike, t, 0.2)
      end
   end,
   ["IceboundFortitude"] = function ()
      if get_setting("IceboundFortitude") and ni.spell.available(ni.spells.icebound_fortitude) and cache.hp < values["IceboundFortitude"] then
         ni.spell.delay_cast(ni.spells.icebound_fortitude, p, 0.2)
      end
   end,
   ["VampiricBlood"] = function ()
      if ni.profile["Blood"].get_setting("VampiricBlood") and ni.spell.available(ni.spells.vampiric_blood) and cache.hp < values["VampiricBlood"] then
         ni.spell.cast(ni.spells.vampiric_blood, p, 0.2)
      end
   end,
   ["AntiMagicShell"] = function ()
      if ni.profile["Blood"].get_setting("AntiMagicShell") and ni.spell.available(ni.spells.anti_magic_shell) and
      ni.unit.cast_not_interruptable(t) and ni.unit.target(t) == guid then
         ni.spell.delay_cast(ni.spells.anti_magic_shell, p, 0.2)
      end
   end,
   ["GlyphofPestilence"] = function ()
      if GlyphofPestilence and ni.spell.valid(ni.spells.pestilence, t, true, true) and
      cache.blood_plauge > 0 and cache.frost_fever > 0 and (cache.blood_plauge < 5 or cache.frost_fever < 5) then
         ni.spell.cast(ni.spells.pestilence, t)
      end
   end,
   ["KillingMachine"] = function ()
      if ni.player.buff(KillingMachine) and ni.spell.valid(ni.spells.icy_touch, t, true, true) then
         ni.spell.cast(ni.spells.icy_touch, t)
         return true
      end
   end
}

ni.profile.new("Blood", queue, abilities, ui, nil)