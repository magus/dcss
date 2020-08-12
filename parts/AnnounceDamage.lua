-- announce_damage
-- TODO improve output styling and formatting
-- e.g. [HP(+X)/MHP][MP(+X)/MMP]

local previous_hp = 0
local previous_mp = 0
local previous_form = ""
local was_berserk_last_turn = false

function announce_damage()
  local current_hp, max_hp = you.hp()
  local current_mp, max_mp = you.mp()
  --Things that increase hp/mp temporarily really mess with this
  local current_form = you.transform()
  local you_are_berserk = you.berserk()
  local max_hp_increased = false
  local max_hp_decreased = false

  if (current_form ~= previous_form) then
    if (previous_form:find("dragon") or
        previous_form:find("statue") or
        previous_form:find("tree") or
        previous_form:find("ice")) then
      max_hp_decreased = true
    elseif (current_form:find("dragon") or
        current_form:find("statue") or
        current_form:find("tree") or
        current_form:find("ice")) then
      max_hp_increased = true
    end
  end
  if (was_berserk_last_turn and not you_are_berserk) then
    max_hp_decreased = true
  elseif (you_are_berserk and not was_berserk_last_turn) then
    max_hp_increased = true
  end

  --crawl.mpr(string.format("previous_form is: %s", previous_form))
  --crawl.mpr(string.format("current_form is: %s", current_form))
  --crawl.mpr(string.format("max_hp_increased is: %s", max_hp_increased and "True" or "False"))
  --crawl.mpr(string.format("max_hp_decreased is: %s", max_hp_decreased and "True" or "False"))

  --crawl.mpr(string:format("you_are_berserk is: %s", you_are_berserk and "True" or "False"))
  --crawl.mpr(string:format("was_berserk_last_turn is: %s", was_berserk_last_turn and "True" or "False"))


  --Skips message on initializing game
  if previous_hp > 0 then
    local hp_difference = previous_hp - current_hp
    local mp_difference = previous_mp - current_mp

    if max_hp_increased or max_hp_decreased then
      if max_hp_increased then
        crawl.mpr("<green>You now have " .. current_hp .. "/" .. max_hp .. " hp.</green>")
      else
        crawl.mpr("<yellow>You now have " .. current_hp .. "/" .. max_hp .. " hp.</yellow>")
      end
    else
      --On losing health
      if (current_hp < previous_hp) then
        if current_hp <= (max_hp * 0.30) then
          crawl.mpr("<red>You take " .. hp_difference .. " damage,</red><lightred> and have " .. current_hp .. "/" .. max_hp .. " hp.</lightred>")
        elseif current_hp <= (max_hp * 0.50) then
          crawl.mpr("<red>You take " .. hp_difference .. " damage, and have " .. current_hp .. "/" .. max_hp .. " hp.</red>")
        elseif current_hp <= (max_hp *  0.70) then
          crawl.mpr("<red>You take " .. hp_difference .. " damage,</red><yellow> and have " .. current_hp .. "/" .. max_hp .. " hp.</yellow>")
        elseif current_hp <= (max_hp * 0.90) then
          crawl.mpr("<red>You take " .. hp_difference .. " damage,</red><lightgrey> and have " .. current_hp .. "/" .. max_hp .. " hp.</lightgrey>")
        else
          crawl.mpr("<red>You take " .. hp_difference .. " damage,</red><green> and have " .. current_hp .. "/" .. max_hp .. " hp.</green>")
        end
        if hp_difference > (max_hp * 0.20) then
          crawl.mpr(string.format("<lightred>MASSIVE DAMAGE!! (%s)</lightred>", PAUSE_MORE))
        end
      end

      --On gaining more than 1 health
      if (current_hp > previous_hp) then
        --Removes the negative sign
        local health_inturn = (0 - hp_difference)
        if (health_inturn > 1) and not (current_hp == max_hp) then
          if current_hp <= (max_hp * 0.30) then
            crawl.mpr("<green>You regained " .. health_inturn .. " hp,</green><lightred> and now have " .. current_hp .. "/" .. max_hp .. " hp.</lightred>")
          elseif current_hp <= (max_hp * 0.50) then
            crawl.mpr("<green>You regained " .. health_inturn .. " hp,</green><red> and now have " .. current_hp .. "/" .. max_hp .. " hp.</red>")
          elseif current_hp <= (max_hp *  0.70) then
            crawl.mpr("<green>You regained " .. health_inturn .. " hp,</green><yellow> and now have " .. current_hp .. "/" .. max_hp .. " hp.</yellow>")
          elseif current_hp <= (max_hp * 0.90) then
            crawl.mpr("<green>You regained " .. health_inturn .. " hp,</green><lightgrey> and now have " .. current_hp .. "/" .. max_hp .. " hp.</lightgrey>")
          else
            crawl.mpr("<green>You regained " .. health_inturn .. " hp, and now have " .. current_hp .. "/" .. max_hp .. " hp.</green>")
          end
        end
        if (current_hp == max_hp) then
          crawl.mpr("<green>Health restored: " .. current_hp .. "</green>")
        end
      end

      --On gaining more than 1 magic
      if (current_mp > previous_mp) then
        --Removes the negative sign
        local mp_inturn = (0 - mp_difference)
        if (mp_inturn > 1) and not (current_mp == max_mp) then
          if current_mp < (max_mp * 0.25) then
            crawl.mpr("<lightcyan>You regained " .. mp_inturn .. " mp,</lightcyan><red> and now have " .. current_mp .. "/" .. max_mp .. " mp.</red>")
          elseif current_mp < (max_mp * 0.50) then
            crawl.mpr("<lightcyan>You regained " .. mp_inturn .. " mp,</lightcyan><yellow> and now have " .. current_mp .. "/" .. max_mp .. " mp.</yellow>")
          else
            crawl.mpr("<lightcyan>You regained " .. mp_inturn .. " mp,</lightcyan><green> and now have " .. current_mp .. "/" .. max_mp .. " mp.</green>")
          end
        end
        if (current_mp == max_mp) then
          crawl.mpr("<lightcyan>MP restored: " .. current_mp .. "</lightcyan>")
        end
      end

      --On losing magic
      if current_mp < previous_mp then
        if current_mp <= (max_mp / 5) then
          crawl.mpr("<lightcyan>You now have </lightcyan><red>" .. current_mp .. "/" ..max_mp .." mp.</red>")
        elseif current_mp <= (max_mp / 2) then
          crawl.mpr("<lightcyan>You now have </lightcyan><yellow>" .. current_mp .. "/" ..max_mp .." mp.</yellow>")
        else
          crawl.mpr("<lightcyan>You now have </lightcyan><green>" .. current_mp .. "/" ..max_mp .." mp.</green>")
        end
      end
    end
  end

  --Set previous hp/mp and form at end of turn
  previous_hp = current_hp
  previous_mp = current_mp
  previous_form = current_form
  was_berserk_last_turn = you_are_berserk
end
