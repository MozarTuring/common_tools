-- rm ~/.hammerspoon/init.lua;ln -s /Users/maojingwei/Library/CloudStorage/OneDrive-Personal/project/common_tools/hamperspoon.lua ~/.hammerspoon/init.lua
-- Translation of your AHK script to Hammerspoon (Lua)

------------------------------------------------------------
-- CONFIG: update these to match your setup
-----------------------------------------------------------
--local SRC_TITLE = "com.microsoft.VSCode"   -- source window/app title substring
local SRC_TITLE = "com.googlecode.iterm2"   -- source window/app title substring
-- local TGT_TITLE = "com.google.Chrome"               
-- target window/app title substring (e.g., "iTerm2" or "Terminal")
local TGT_TITLE = "com.apple.Terminal"
local MOVE_MOUSE_TO_CENTER = false       -- set true if you also want to move the cursor to window center

------------------------------------------------------------
-- Utilities
------------------------------------------------------------
local function usleep(ms) hs.timer.usleep(ms * 1000) end

-- local function findWindowByTitleSubstr(substr)
--   local wins = hs.window.filter.new():getWindows(hs.window.filter.sortByFocusedLast)
--   substr = substr:lower()
--   for _,w in ipairs(wins) do
--     local t = (w:title() or ""):lower()
--     if t:find(substr, 1, true) then return w end
--   end
--   return nil
-- end

-- local function focusWindowByTitle(substr)
--   local w = findWindowByTitleSubstr(substr)
--   if not w then
--     hs.alert.show("Window not found: " .. substr)
--     return false
--   end
--   w:focus()
--   if MOVE_MOUSE_TO_CENTER then
--     local f = w:frame()
--     hs.mouse.setAbsolutePosition({x=f.x+f.w/2, y=f.y+f.h/2})
--   end
--   return true
-- end

hs.hotkey.bind({"ctrl","cmd"}, "I", function()
    local app = hs.application.frontmostApplication()
    local bundleID = app and app:bundleID() or "unknown"
    local appName = app and app:name() or "unknown"
    hs.alert.show(string.format("App: %s\nBundle ID: %s", appName, bundleID))
end)

-- Copy active file path from VS Code (assumes VS Code has ⌥⇧C bound to “Copy Path of Active File”)
local function getPath(mode)
    hs.pasteboard.clearContents()
    usleep(500)
    if SRC_TITLE == "com.microsoft.VSCode" then
        hs.eventtap.keyStroke({"alt","cmd"}, "c",1000) -- hold the key down for 1s
    end
    if SRC_TITLE == "com.googlecode.iterm2" then
        hs.eventtap.keyStrokes("cp") -- hold the key down for 1s
    end
  usleep(1000) -- Wait for clipboard to update
  local tmp_path = hs.pasteboard.getContents() or ""
  if tmp_path == "" then
    hs.alert.show("No path on clipboard")
    return nil
  end

  local new_path = tmp_path
  new_path = new_path:gsub("\\", "/")
  local part = new_path:match("project/(.+)")
  if part then new_path = part end
--  new_path = new_path:gsub("%.ipynb$", ".py")
--  hs.pasteboard.setContents(new_path)
  return new_path
end

-- Send keys to the target (Vim inside terminal): :Jwtabnew <path> + some motions/paste
local function tgtAction(path, tgtTitle, tgteditor, shell)
  hs.application.launchOrFocusByBundleID(tgtTitle)
  -- local app = hs.application.frontmostApplication()
  -- for i, w in ipairs(app:allWindows()) do
  --   hs.alert.show(string.format("[%d] id=%s  title=%s  frame=%s", i, w:id(), w:title(), hs.inspect(w:frame())))
  --   break
  -- end

  usleep(500) -- Wait for the target app to focus
  -- local pos = hs.mouse.getAbsolutePosition()
  -- hs.eventtap.leftClick(pos, 0, 2)
  -- usleep(500) -- Wait for the click to register
--  hs.eventtap.keyStroke({}, "escape") -- Hide the target app
--  usleep(500) -- Wait for the escape to register
  if tgteditor == "notebook" then
    hs.eventtap.keyStroke({}, "b") 
    usleep(500) -- Wait for the command to be processed
    hs.eventtap.keyStroke({}, "return")
    

    elseif tgteditor == "vim" then
      if shell == "0" then
--      hs.eventtap.keyStroke({"ctrl"}, "\\")
--      hs.eventtap.keyStroke({"ctrl"}, "n")
        hs.eventtap.keyStrokes("nvim") 
      usleep(1000)
        hs.eventtap.keyStroke({}, "return")
      usleep(200)
        hs.eventtap.keyStrokes(":Jwtabnew " .. path)
        usleep(200)
        hs.eventtap.keyStroke({}, "return")
        usleep(200)
        hs.eventtap.keyStrokes("gg")
        usleep(200)
        hs.eventtap.keyStrokes("v")
        usleep(200)
        hs.eventtap.keyStrokes("G")
        usleep(200)
        hs.eventtap.keyStrokes("d")
        usleep(300)
        hs.eventtap.keyStrokes("i")
        usleep(200)
  hs.eventtap.keyStroke({"cmd"}, "v")
  usleep(1500)
    hs.eventtap.keyStroke({}, "escape")
  usleep(300)
    hs.eventtap.keyStrokes(";a")
    elseif shell == "1" then
--      hs.eventtap.keyStroke({"ctrl"}, "\\")
--      hs.eventtap.keyStroke({"ctrl"}, "n")
--      hs.eventtap.keyStrokes(";a")
--      usleep(200)
--        hs.eventtap.keyStroke({}, "return")
--      usleep(200)
--        hs.eventtap.keyStrokes(":lua goto_or_open_terminal()")
--        usleep(500)
--        hs.eventtap.keyStroke({}, "return")
--        usleep(500)
--        hs.eventtap.keyStrokes("i")
--        usleep(300)
  hs.eventtap.keyStroke({"cmd"}, "v")
  usleep(500)
        hs.eventtap.keyStroke({}, "return")
      end
  usleep(500)
  hs.application.launchOrFocusByBundleID(SRC_TITLE)
  end

  return true
end

------------------------------------------------------------
-- HOTKEYS (translated)
-- AHK: Space & l   -> Space-leader then 'l'
--      ^h          -> Ctrl+h
--      Space & j   -> Space-leader then 'j' (toggle focus)
------------------------------------------------------------

-- Implement “Space as leader” modal so Space works as normal if tapped, but acts as a prefix if followed by a key
-- local leader = hs.hotkey.modal.new()
-- local spaceDownAt = nil
-- local leaderConsumed = false

-- local keydown = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(ev)
--   local keyCode = ev:getKeyCode()
--   local isSpace = (keyCode == hs.keycodes.map.space)
--   local flags = ev:getFlags()
--   -- Only plain Space (no modifiers) starts leader
--   if isSpace and next(flags) == nil then
--     spaceDownAt = hs.timer.secondsSinceEpoch()
--     leaderConsumed = false
--     leader:enter()
--     -- Swallow the Space for now; we'll emit a real Space on keyUp if unused
--     return true
--   end
--   return false
-- end)

-- local keyup = hs.eventtap.new({hs.eventtap.event.types.keyUp}, function(ev)
--   local keyCode = ev:getKeyCode()
--   if keyCode == hs.keycodes.map.space and leader:isEnabled() then
--     leader:exit()
--     -- If no chord was used, send a normal space
--     if not leaderConsumed then
--       hs.eventtap.keyStroke({}, "space", 0)
--     end
--     return true
--   end
--   return false
-- end)

-- keydown:start()
-- keyup:start()


local function share1(tgteditor, shell)
  local win = hs.window.frontmostWindow()
  local app = win and win:application()
  local title = app and app:bundleID() or "unknown"
  if title:lower():find(SRC_TITLE:lower(), 1, true) then
    local path = getPath("a")
    if title:lower() == "com.microsoft.VSCode" then
        hs.eventtap.keyStroke({"cmd"}, "c")
    end

    if title:lower() == "com.googlecode.iterm2" then
        if shell == "0" then
            hs.eventtap.keyStrokes(":Git add ")
            local gitPath = path:match("/(.+)")
            hs.eventtap.keyStrokes(gitPath)
            usleep(100)
            hs.eventtap.keyStroke({}, "return")
            usleep(200)
            hs.eventtap.keyStrokes("gg")
            usleep(200)
            hs.eventtap.keyStrokes("v")
            usleep(200)
            hs.eventtap.keyStrokes("G")
            usleep(200)
            hs.eventtap.keyStrokes("y")
        else
            hs.eventtap.keyStrokes("V")
            usleep(200)
            hs.eventtap.keyStrokes("y")
        end
    end


    if not path then
      hs.alert.show("No path on clipboard")
      return
    end
    if not tgtAction(path, TGT_TITLE, tgteditor, shell) then
      hs.alert.show("Failed to perform target action")
      return
    end
  end
end

hs.hotkey.bind({"ctrl"}, "h", function()
  share1("vim", "0")
end)

hs.hotkey.bind({"ctrl"}, "l", function()
  share1("vim", "1")
end)


--hs.hotkey.bind({"cmd"}, "l", function()
--  tgteditor = "vim"
--  share1(tgteditor)
--  usleep(500)
--
--  if tgteditor == "notebook" then
--    hs.eventtap.keyStroke({"shift"}, "return")
--  else
--    hs.eventtap.keyStrokes("v")
--    hs.eventtap.keyStrokes("gg")
--    hs.eventtap.keyStrokes("m")
--  end
--end)

-- Leader+j  (AHK: Space & j) — toggle focus between source and target windows
-- leader:bind({}, "j", function()
--   leaderConsumed = true
--   local cur = hs.window.frontmostWindow()
--   local title = cur and cur:title() or ""
--   if title:lower():find(TGT_TITLE:lower(), 1, true) then
--     focusWindowByTitle(SRC_TITLE)
--   elseif title:lower():find(SRC_TITLE:lower(), 1, true) then
--     focusWindowByTitle(TGT_TITLE)
--   else
--     -- If neither, try to jump to source first
--     if not focusWindowByTitle(SRC_TITLE) then
--       focusWindowByTitle(TGT_TITLE)
--     end
--   end
-- end)

------------------------------------------------------------
-- Ready
------------------------------------------------------------
hs.alert.show("Hammerspoon AHK translation loaded")

