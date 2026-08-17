Name = "chrome-bookmarks"
NamePretty = "Chrome Bookmarks"
Icon = "web-browser"
Terminal = false
Cache = false

-- Keep the URL out of the shell command's interpolated argument. The bridge
-- emits a numeric row id as its third field, and re-reads the bookmark file
-- before opening the corresponding URL.
Action = "walker-chrome-bookmarks --open-index '%VALUE%'"

function GetEntries()
  local entries = {}
  local handle = io.popen("walker-chrome-bookmarks 2>/dev/null")
  if not handle then
    return entries
  end

  for line in handle:lines() do
    local title, url, index = line:match("^(.-)\t([^\t]+)\t([0-9]+)$")
    if title and url and index then
      table.insert(entries, {
        Text = title,
        Subtext = url,
        Value = index,
        Icon = "web-browser",
      })
    end
  end

  handle:close()
  return entries
end
