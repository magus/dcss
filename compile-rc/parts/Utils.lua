function withColor(color, str)
  return string.format("<%s>%s</%s>", color, str, color)
end

function rc_out(symbol, color, msg, channel)
  -- crawl_mpr source
  -- https://sourcegraph.com/search?q=context%3Aglobal+repo%3A%5Egithub%5C.com%2Fcrawl%2Fcrawl%24+file%3A%5Ecrawl-ref%2Fsource%2Fl-crawl%5C.cc+crawl_mpr&patternType=standard&sm=1&groupBy=path
  --
  -- static const string message_channel_names[] =
  -- {
  --     "plain", "friend_action", "prompt", "god", "duration", "danger", "warning",
  --     "recovery", "sound", "talk", "talk_visual", "intrinsic_gain",
  --     "mutation", "monster_spell", "monster_enchant", "friend_spell",
  --     "friend_enchant", "monster_damage", "monster_target", "banishment",
  --     "equipment", "floor", "multiturn", "examine", "examine_filter", "diagnostic",
  --     "error", "tutorial", "orb", "timed_portal", "hell_effect", "monster_warning",
  --     "dgl_message",
  -- };

  crawl.mpr(string.format("%s %s", symbol, withColor(color, msg)), channel)
end

function rc_msg(msg)
  rc_out("🤖", "blue", msg, "diagnostic")
end

function rc_scs(msg)
  rc_out("✅", "green", msg, "diagnostic")
end

function rc_err(msg)
  rc_out("❌", "lightred", msg, "danger")
end

function rc_warn(msg)
  rc_out("⚠️", "yellow", msg, "warning")
end


function table_has(table, match)
  for index, value in ipairs(table) do
    if value == match then
      return true
    end
  end

  return false
end
