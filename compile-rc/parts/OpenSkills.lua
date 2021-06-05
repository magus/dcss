-- Open skills menu at start of runs
local is_gnoll = table_has({"Gnoll"}, you.race())
local need_skills_opened = not is_gnoll

local function start_open_skills()
  if you.turns() == 0 and need_skills_opened then
    need_skills_opened = false
    crawl.sendkeys("m")
  end
end

-- Runs once when parsed during rc init
start_open_skills()
