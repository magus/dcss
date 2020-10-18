function withColor(color, str)
  return string.format("<%s>%s</%s>", color, str, color)
end

function rc_out(symbol, color, msg)
  crawl.mpr(string.format("%s <%s>%s</%s>", symbol, color, msg, color))
end
function rc_msg(msg)
  rc_out("🤖", "blue", msg)
end
function rc_scs(msg)
  rc_out("✅", "green", msg)
end
function rc_err(msg)
  rc_out("❌", "lightred", msg)
end


function table_has(table, match)
  for index, value in ipairs(table) do
    if value == match then
      return true
    end
  end

  return false
end
