local didRun = false
function note_version()
  if didRun then
    return
  end

  local version = "magus.rc [v{{VERSION}}]"
  crawl.take_note(version)
  didRun = true
end
