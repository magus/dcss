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

  -- wearing artefact/ego/branded? skip pickup
  if cur.branded or cur.ego() or cur.artefact then return end
  -- wearing dragon scales? skip pickup
  if string.find(cur.name("qual"), "dragon scale") then return end

  -- if we got to this point we are not wearing dragon scales/artefact/ego/branded
  -- pickup if item is ego/branded/plus
  local plus = i2.plus and i2.plus > 0
  if i2.branded or i2.ego() or plus then return true end

  return false
end

-- Equipment autopickup (by Medar and various others)
-- Source http://crawl.berotato.org/crawl/rcfiles/crawl-0.23/Freakazoid.rc
local armour_slots = {cloak="Cloak", helmet="Helmet", gloves="Gloves", boots="Boots", body="Armour", shield="Shield"}
local two_handed_always = {"shortbow", "longbow", "arbalest", "triple crossbow"}

local function pickup_equipment(it, name)
  -- DEBUG
  -- rc_msg(string.format("[pickup_equipment] name: %s", name))

  -- do not pickup forbidden items
  if string.match(name, "forbidden") then return end

  -- do not pickup useless items
  if it.is_useless then return end

  -- always pickup artefacts
  if it.artefact then return true end

  local class = it.class(true)
  -- get currently equipped item in slot
  local currentWeapon = items.equipped_at("weapon")

  if class == "weapon" then
    -- when using unarmed combat, we want to skip the should_pickup_equip for weapons
    if currentWeapon == nil and you.skill("Unarmed Combat") > 3 then
      -- always pickup god gift equipment
      if it.god_gift then return true end

      return false
    end

    if should_pickup_equip(currentWeapon, it) then return true end

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

      if should_pickup_equip(equipped_item, it) then return true end
    end
  end

  return
end

-- Runs once when parsed during rc init
add_autopickup_func(pickup_equipment)
