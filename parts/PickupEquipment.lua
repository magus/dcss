local function should_pickup_equip(cur, i2)
  -- always pickup god gift equipment
  if i2.god_gift then return true end

  --  not wearing any item in the slot? pickup!
  if cur == nil then return true end

  -- items names are the same, pickup higher plus
  if cur.name("qual") == i2.name("qual") then
    if i2.plus ~= nil and i2.plus > cur.plus then
      return true
    end
  end

  -- not wearing artefact/ego/branded but item is? pickup!
  if cur.branded or cur.ego() or cur.artefact then return end
  if i2.branded or i2.ego() then return true end

  return false
end

-- Equipment autopickup (by Medar and various others)
-- Source http://crawl.berotato.org/crawl/rcfiles/crawl-0.23/Freakazoid.rc
local armour_slots = {cloak="Cloak", helmet="Helmet", gloves="Gloves", boots="Boots", body="Armour", shield="Shield"}
local function pickup_equipment(it, name)
  -- DEBUG
  -- rc_msg(string.format("pickup_equipment: %s", name))

  -- do not pickup forbidden items
  if string.match(name, "forbidden") then return end

  -- do not pickup useless items
  if it.is_useless then return end

  -- always pickup artefacts
  if it.artefact then return true end

  local class = it.class(true)

  if class == "weapon" then
    -- get currently equipped item in slot
    local cur = items.equipped_at("weapon")

    -- when using unarmed combat, we want to skip the should_pickup_equip for weapons
    if cur == nil and you.skill("Unarmed Combat") > 3 then
      -- always pickup god gift equipment
      if it.god_gift then return true end

      return false
    end

    if should_pickup_equip(cur, it) then return true end

  elseif class == "armour" then
    local sub_type = it.subtype()

    if sub_type == "gloves" and you.has_claws() > 0 then return end

    local armor_slot = armour_slots[sub_type];

    if armor_slot ~= nil then
      -- get currently equipped item in slot
      local equipped_item = items.equipped_at(armor_slot)

      if should_pickup_equip(equipped_item, it) then return true end
    end
  end

  return
end

-- Runs once when parsed during rc init
add_autopickup_func(pickup_equipment)
