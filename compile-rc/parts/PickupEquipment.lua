local favor_egos = false
local favor_plus = false

local function is_branded_ego(item)
  return item.branded or item.ego()
end
local function is_magical(item)
  return is_branded_ego(item) or item.artefact
end

local function debug_item(item)
  return string.format("name: %s; subtype: %s, magical: %s, plus: %s", item.name("qual"), item.subtype(), tostring(is_magical(item)), tostring(item.plus))
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
  if is_magical(cur) or is_dragon_scales then return end

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
local armour_slots = {cloak="Cloak", helmet="Helmet", gloves="Gloves", boots="Boots", body="Body Armour", shield="Shield"}
local two_handed_always = {
  "great sword", "triple sword",
  "battleaxe", "executioner's axe",
  "dire flail", "great mace", "giant club", "giant spiked club",
  "halberd", "scythe", "glaive", "bardiche",
  "quarterstaff", "lajatang",
  "shortbow", "longbow",
  "arbalest", "triple crossbow"}

local function pickup_equipment(it, name)
  local class = it.class(true)
  -- get currently equipped item in slot
  local currentWeapon = items.equipped_at("weapon")

  -- DEBUG
  -- rc_msg(string.format("[pickup_equipment] name: %s", name))
  -- rc_msg(string.format("[pickup_equipment] currentWeapon.subtype: %s", currentWeapon.subtype()))


  -- do not pickup forbidden items
  if string.match(name, "forbidden") then return end

  -- do not pickup useless items
  if it.is_useless then return end

  -- always pickup artefacts
  if it.artefact then return true end



  if class == "weapon" then
    -- when using unarmed combat, we want to skip the should_pickup for weapons
    if currentWeapon == nil then
      -- always pickup god gift equipment
      if it.god_gift then return true end

      return false
    end

    if should_pickup(currentWeapon, it) then return true end

  elseif class == "armour" then
    local sub_type = it.subtype()

    if sub_type == "gloves" and you.has_claws() > 0 then return end

    -- skip picking up shields, when
    if sub_type == "shield" then
      -- using 2 handed weapons
      if currentWeapon then
        if table_has(two_handed_always, currentWeapon.subtype()) then return end
      end

      -- shield skill less than 3
      if you.skill("Shields") <= 3 then return end
    end

    local armor_slot = armour_slots[sub_type];

    if armor_slot ~= nil then
      -- get currently equipped item in slot
      local equipped_item = items.equipped_at(armor_slot)

      if should_pickup(equipped_item, it) then return true end
    end
  end

  return
end

-- Runs once when parsed during rc init
add_autopickup_func(pickup_equipment)
