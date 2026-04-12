local favor_egos = false
local favor_plus = false

local function is_branded_ego(item)
  return item.branded or item.ego()
end
local function is_magical(item)
  return is_branded_ego(item) or item.artefact
end

local nil_item = "item: nil";

local function debug_item(item)
  if item == nil then
    return nil_item
  end

  local qual = item.name("qual");
  local subtype = item.subtype();

  if qual == nil or subtype == nil then
    return nil_item
  end

  local magical = tostring(is_magical(item));
  local plus = tostring(item.plus);

  return string.format("name: %s; subtype: %s, magical: %s, plus: %s", qual, subtype, magical, plus)
end


local function should_pickup(cur, i2)
  -- always pickup god gift equipment
  if i2.god_gift then return true end

  --  not wearing any item in the slot? pickup!
  if cur == nil then return true end

  local higher_plus = i2.plus ~= nil and i2.plus > (cur.plus or 0)
  local more_magical = not is_magical(cur) and is_magical(i2)

  -- DEBUG
  -- rc_msg(string.format("[should_pickup] (cur): %s", debug_item(cur)))
  -- rc_msg(string.format("[should_pickup] (i2): %s", debug_item(i2)))
  -- rc_msg(string.format("[should_pickup] higher_plus: %s, more_magical: %s", tostring(higher_plus), tostring(more_magical)))

  -- items names are the same, pickup higher plus or more magical
  if cur.name("qual") == i2.name("qual") then
    if  higher_plus or more_magical then
      return true
    end
  end

  local is_dragon_scales = string.find(cur.name("qual"), "dragon scale")
  -- wearing magical item (artefact/ego/branded) or dragon scales? skip pickup
  if is_magical(cur) or is_dragon_scales then return false end

  -- if we got to this point we are not wearing dragon scales/artefact/ego/branded

  -- if favoring egos and item is ego/branded, pickup
  if favor_egos and is_magical(i2) then return true end
  -- if favoring plus and plus is higher, pickup
  if favor_plus and higher_plus then return true end

  -- no not pickup by default
  return false
end

-- Equipment autopickup (by Medar and various others)
-- Source http://crawl.berotato.org/crawl/rcfiles/crawl-0.23/Freakazoid.rc

-- https://sourcegraph.com/search?q=context:global+repo:%5Egithub%5C.com/crawl/crawl%24+file:%5Ecrawl-ref/source/output%5C.cc+s_equip_slot_names%5B%5D&patternType=standard&sm=1&groupBy=path
-- static const char *s_equip_slot_names[] =
-- {
--     "Weapon", "Cloak",  "Helmet", "Gloves", "Boots",
--     "Shield", "Armour", "Left Ring", "Right Ring", "Amulet",
--     "First Ring", "Second Ring", "Third Ring", "Fourth Ring",
--     "Fifth Ring", "Sixth Ring", "Seventh Ring", "Eighth Ring",
--     "Amulet Ring"
-- };
local item_subtype_equip_slot = {
  cloak="Cloak",
  helmet="Helmet",
  gloves="Gloves",
  boots="Boots",
  shield="Shield"
} -- end item_subtype_equip_slot (comment prevents crawl rc parser ending outer lua block)

local function equip_slot(item_sub_type)
  if item_sub_type == "body" then
    -- ok this is weird but the equip slot required by `items.equipped_at`
    -- seems to depend on whether we are running in webtiles or locally
    -- webtiles expects `items.equipped_at("Body Armour")`
    -- local expects    `items.equipped_at("Armour")`
    -- try both and return whichever isn't `nil`
    local body_armour = items.equipped_at("Body Armour");
    local armour = items.equipped_at("Armour");
    local result = body_armour or armour;
    return result;
  end

  -- we can handle non-body armor with lua table (map)
  local equip_slot = item_subtype_equip_slot[item_sub_type];
  return items.equipped_at(equip_slot);
end

-- source for form wiz_name, talisman, and melds values
-- https://github.com/crawl/crawl/tree/0.34.0/crawl-ref/source/dat/forms
-- you.transform() returns transform_name(), which returns the form wiz_name
-- https://github.com/crawl/crawl/blob/0.34.0/crawl-ref/source/l-you.cc#L399-L404
-- https://github.com/crawl/crawl/blob/0.34.0/crawl-ref/source/transform.cc#L1449-L1457
local form_meld_key = {
  ["appendages"] =     "appendages",
  ["aqua"] =           "aqua",
  ["bat"] =            "bat",
  ["bat swarm"] =      "bat swarm",
  ["blade"] =          "blade",
  ["death"] =          "death",
  ["dragon"] =         "dragon",
  ["eel hands"] =      "eel",
  ["fortress crab"] =  "fortress",
  ["flux"] =           "flux",
  ["fungus"] =         "fungus",
  ["hive"] =           "hive",
  ["hydra"] =          "hydra",
  ["jelly"] =          "jelly",
  ["maw"] =            "maw",
  ["medusa"] =         "medusa",
  ["pig"] =            "pig",
  ["porcupine"] =      "porcupine",
  ["quill"] =          "quill",
  ["rime yak"] =       "rimehorn",
  ["amphisbaena"] =    "serpent",
  ["shadow"] =         "shadow",
  ["slaughter"] =      "slaughter",
  ["sphinx"] =         "sphinx",
  ["spider"] =         "spider",
  ["spore"] =          "spore",
  ["statue"] =         "statue",
  ["storm"] =          "storm",
  ["sun scarab"] =     "scarab",
  ["tree"] =           "tree",
  ["vampire"] =        "vampire",
  ["walking scroll"] = "inkwell",
  ["werewolf"] =       "werewolf",
  ["wisp"] =           "wisp"
} -- end form_meld_key (comment prevents crawl rc parser ending outer lua block)

local armour_slots_melded_by_form_key = {
  ["appendages"] = {shield = false, body = false, cloak = false, helmet = true,  gloves = false, boots = true,  barding = false},
  ["aqua"] =       {shield = false, body = true,  cloak = false, helmet = false, gloves = false, boots = false, barding = false},
  ["bat"] =        {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["bat swarm"] =  {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["blade"] =      {shield = false, body = false, cloak = false, helmet = false, gloves = false, boots = false, barding = false},
  ["dragon"] =     {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["death"] =      {shield = false, body = false, cloak = false, helmet = false, gloves = false, boots = false, barding = false},
  ["eel"] =        {shield = true,  body = false, cloak = false, helmet = false, gloves = true,  boots = false, barding = false},
  ["fortress"] =   {shield = true,  body = false, cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["flux"] =       {shield = true,  body = true,  cloak = false, helmet = false, gloves = true,  boots = false, barding = false},
  ["fungus"] =     {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["hive"] =       {shield = false, body = true,  cloak = false, helmet = true,  gloves = false, boots = false, barding = false},
  ["hydra"] =      {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["inkwell"] =    {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["jelly"] =      {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["maw"] =        {shield = false, body = false, cloak = false, helmet = false, gloves = false, boots = false, barding = false},
  ["medusa"] =     {shield = false, body = false, cloak = true,  helmet = true,  gloves = false, boots = false, barding = false},
  ["pig"] =        {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["porcupine"] =  {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["quill"] =      {shield = false, body = false, cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["rimehorn"] =   {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["serpent"] =    {shield = true,  body = true,  cloak = true,  helmet = false, gloves = true,  boots = true,  barding = true },
  ["scarab"] =     {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["shadow"] =     {shield = false, body = false, cloak = false, helmet = false, gloves = false, boots = false, barding = false},
  ["slaughter"] =  {shield = false, body = false, cloak = false, helmet = false, gloves = false, boots = false, barding = false},
  ["sphinx"] =     {shield = true,  body = true,  cloak = false, helmet = true,  gloves = true,  boots = true,  barding = false},
  ["spider"] =     {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["spore"] =      {shield = true,  body = false, cloak = false, helmet = false, gloves = false, boots = true,  barding = false},
  ["statue"] =     {shield = false, body = true,  cloak = false, helmet = false, gloves = true,  boots = true,  barding = true },
  ["storm"] =      {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["tree"] =       {shield = false, body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true },
  ["vampire"] =    {shield = false, body = false, cloak = false, helmet = false, gloves = false, boots = false, barding = false},
  ["werewolf"] =   {shield = false, body = false, cloak = false, helmet = false, gloves = true,  boots = true,  barding = true },
  ["wisp"] =       {shield = true,  body = true,  cloak = true,  helmet = true,  gloves = true,  boots = true,  barding = true }
} -- end armour_slots_melded_by_form_key (comment prevents crawl rc parser ending outer lua block)

local function is_melded_by_current_form(item)
  if item == nil or item.class(true) ~= "armour" then return false end

  local form = you.transform()
  
  -- player not transformed
  if form == "" then return false end

  local meld_key = form_meld_key[form]
  if meld_key == nil then
    rc_warn(string.format("[PickupEquipment] is_melded_by_current_form unhandled form=%s", form))
    return false
  end

  local melded_slots = armour_slots_melded_by_form_key[meld_key]
  if melded_slots == nil then
    rc_warn(string.format("[PickupEquipment] is_melded_by_current_form unhandled meld_key=%s", meld_key))
    return false
  end

  return melded_slots[item.subtype()] == true
end

local function permanent_mutation_level(name)
  return you.get_base_mutation_level(name, true, false, true)
end

local function permanent_armour_slot_blocked(item)
  if item == nil or item.class(true) ~= "armour" then return false end

  local race = you.race()
  local subtype = item.subtype()
  local name = item.name("qual")
  local no_armour = permanent_mutation_level("no armour") > 0
  local formless = permanent_mutation_level("formless") > 0
  local little = race == "Felid" or race == "Spriggan"
  local large = race == "Ogre" or race == "Troll"

  if subtype == "body" then
    return formless or no_armour or race == "Octopode"
      or race == "Draconian" or string.find(race, "Draconian")
  elseif subtype == "helmet" then
    if formless or no_armour or permanent_mutation_level("horns") >= 3
      or permanent_mutation_level("antennae") >= 3 then
      return true
    end

    local hard_helmet = string.find(name, "helmet")
    return hard_helmet and (little or large or race == "Octopode"
      or race == "Draconian" or string.find(race, "Draconian")
      or permanent_mutation_level("horns") > 0
      or permanent_mutation_level("antennae") > 0
      or permanent_mutation_level("beak") > 0)
  elseif subtype == "gloves" then
    return formless or no_armour or race == "Octopode" or little or large
      or permanent_mutation_level("claws") >= 3
      or permanent_mutation_level("demonic touch") >= 3
  elseif subtype == "boots" then
    return formless or no_armour or race == "Octopode" or little or large
      or race == "Naga" or race == "Armataur"
      or permanent_mutation_level("hooves") >= 3
      or permanent_mutation_level("talons") >= 3
      or permanent_mutation_level("float") > 0
  elseif subtype == "barding" then
    return not (race == "Naga" or race == "Armataur")
  elseif subtype == "cloak" then
    return formless or no_armour or race == "Octopode"
      or permanent_mutation_level("weakness stinger") >= 3
  end

  return false
end



local two_handed_always = {
  "great sword", "triple sword",
  "battleaxe", "executioner's axe",
  "dire flail", "great mace", "giant club", "giant spiked club",
  "halberd", "scythe", "glaive", "bardiche",
  "quarterstaff", "lajatang",
  "shortbow", "longbow",
  "arbalest", "triple crossbow"
} -- end two_handed_always (comment prevents crawl rc parser ending outer lua block)

local function should_skip_shield_pickup(sub_type)
  if sub_type ~= "shield" then return false end

  local curr_weapon = items.equipped_at("weapon")

  -- using 2 handed weapons
  if curr_weapon then
    if table_has(two_handed_always, curr_weapon.subtype()) then return true end
  end

  -- shield skill less than 3
  return you.skill("Shields") <= 3
end

-- `talisman_type_name` source for item.subtype() talisman names
-- https://github.com/crawl/crawl/blob/0.34.0/crawl-ref/source/item-prop.cc#L3163-L3192
-- `_talisman_tiers` source for internal talisman tiers
-- https://github.com/crawl/crawl/blob/0.34.0/crawl-ref/source/item-prop.cc#L3194-L3221
local talisman_skill_min = {
  ["inkwell talisman"] =     0,
  ["quill talisman"] =       0,
  ["scarab talisman"] =      8,
  ["medusa talisman"] =      8,
  ["rimehorn talisman"] =    8,
  ["spore talisman"] =       8,
  ["maw talisman"] =         8,
  ["eel talisman"] =         12,
  ["fortress talisman"] =    12,
  ["lupine talisman"] =      12,
  ["serpent talisman"] =     12,
  ["spider talisman"] =      12,
  ["wellspring talisman"] =  12,
  ["blade talisman"] =       17,
  ["dragon-coil talisman"] = 17,
  ["granite talisman"] =     17,
  ["hive talisman"] =        17,
  ["riddle talisman"] =      17,
  ["sanguine talisman"] =    17,
  ["storm talisman"] =       23,
  ["talisman of death"] =    26
} -- end talisman_skill_min (comment prevents crawl rc parser ending outer lua block)

local function talisman_rank(item)
  if item == nil or item.class(true) ~= "talisman" then return nil end
  return talisman_skill_min[item.subtype()]
end

local function should_pickup_talisman(item)
  if you.skill("Shapeshifting") < 3 then return false end

  local rank = talisman_rank(item)
  if rank == nil then return false end

  local best_inv_rank = nil
  for _, inv_item in ipairs(items.inventory()) do
    local inv_rank = talisman_rank(inv_item)
    if inv_rank ~= nil and (best_inv_rank == nil or inv_rank > best_inv_rank) then
      best_inv_rank = inv_rank
    end
  end

  if best_inv_rank == nil then
    return true
  end

  if rank > best_inv_rank then
    return true
  end

  return false
end

local function pickup_equipment(it, name)
  local class = it.class(true)

  -- -- DEBUG
  -- rc_warn(string.format("[pickup_equipment] it:   [%s]", name))
  -- rc_warn(string.format("[pickup_equipment] name: [%s]", debug_item(it)))

  -- -- debugging equipped items
  -- rc_msg(string.format("[pickup_equipment] -------- START EQUIPPED --------"))
  -- rc_msg(string.format("[pickup_equipment]   weapon  [%s]", debug_item(equip_slot("weapon"))))
  -- rc_msg(string.format("[pickup_equipment]   shield  [%s]", debug_item(equip_slot("shield"))))
  -- rc_msg(string.format("[pickup_equipment]   helmet  [%s]", debug_item(equip_slot("helmet"))))
  -- rc_msg(string.format("[pickup_equipment]   body    [%s]", debug_item(equip_slot("body"))))
  -- rc_msg(string.format("[pickup_equipment]   cloak   [%s]", debug_item(equip_slot("cloak"))))
  -- rc_msg(string.format("[pickup_equipment]   gloves  [%s]", debug_item(equip_slot("gloves"))))
  -- rc_msg(string.format("[pickup_equipment]   boots   [%s]", debug_item(equip_slot("boots"))))
  -- rc_msg(string.format("[pickup_equipment] -------- END EQUIPPED --------"))


  -- do not pickup forbidden items
  if string.match(name, "forbidden") then return false end

  -- permanent species/mutation slot blockers should win over temporary form
  if permanent_armour_slot_blocked(it) then return false end

  -- do not pickup useless items
  if it.is_useless then
    -- except armour that is only useless because the current form temporarily melds that slot
    if is_melded_by_current_form(it) then
      -- evaluate normal pickup rules below
    else
      return false
    end
  end

  if class == "armour" then
    local sub_type = it.subtype()

    if should_skip_shield_pickup(sub_type) then return false end

    local equipped_item = equip_slot(sub_type)

    -- always pickup empty slots
    if equipped_item == nil then
      return true
    end

    -- always pickup artefacts
    if it.artefact then return true end

    if should_pickup(equipped_item, it) then return true end

    return false
  end

  -- always pickup artefacts
  if it.artefact then return true end

  if class == "talisman" then
    return should_pickup_talisman(it)
  end

  if class == "weapon" then
    -- get currently equipped item in slot
    local currentWeapon = items.equipped_at("weapon");
    -- rc_msg(string.format("[pickup_equipment] currentWeapon.subtype: %s", currentWeapon.subtype()))

    -- when using unarmed combat, we want to skip the should_pickup for weapons
    if currentWeapon == nil then
      -- always pickup god gift equipment
      if it.god_gift then return true end

      return false
    end

    if should_pickup(currentWeapon, it) then return true end

    return false
  end

  -- add_autopickup_func treats false as "never pick this up"
  -- nil means "no opinion" and allows other pickup rules to apply
  return nil
end

-- Runs once when parsed during rc init
add_autopickup_func(pickup_equipment)
