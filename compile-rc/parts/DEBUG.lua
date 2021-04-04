-- rc_msg("DEBUG")

-- yesno (prompt, safe[, safeanswer[, clear_after=true[, interrupt_delays=true[, noprompt=false]]]])
-- http://doc.dcss.io/modules/crawl.html#yesno
-- Ask the player a yes/no question. The player is supposed to answer by pressing Y or N.
-- Parameters:
-- prompt string question for the user
-- safe boolean accept lowercase answers
-- safeanswer string or nil if a letter, this will be considered a safe default (optional)
-- clear_after boolean clear the question after the user answers (default true)
-- interrupt_delays boolean interrupt any ongoing delays to ask the question (default true)
-- noprompt boolean skip asking the question; just wait for the answer (default false)

-- local result = crawl.yesno("Answer this question (result)")
-- rc_msg(string.format("result=[%s]", tostring(result)))

-- rc_msg(you.race())
-- rc_msg(tostring(not table_has({"Merfolk", "Octopode", "Barachi"}, you.race())))

-- if not table_has({"Merfolk", "Octopode", "Barachi"}, you.race()) then
--   rc_msg("1 Is NOT deep water walking race")
-- else
--   rc_msg("1 Is deep water walking race")
-- end

-- function colortest()
--   for i, color in pairs(COLORS) do
--     crawl.mpr(string.format("\n>> 🤖 colortest <%s>%s</%s>", color, color, color))
--   end
-- end

-- colortest()

-- rc_out("COLORS", COLORS.brown, COLORS.brown)
