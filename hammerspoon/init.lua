local hyper = {"cmd", "ctrl", "alt", "shift"}

-- disable animations
hs.window.animationDuration = 0

-- hide window shadows
hs.window.setShadows(false)

local fnutils = require "hs.fnutils"
local partial = fnutils.partial
local indexOf = fnutils.indexOf
local filter = fnutils.filter

local window = require "hs.window"
local alert = require "hs.alert"
local grid = require "hs.grid"

require "fntools"
require "extensions"

---------------------------------------------------------
-- SCREENS
---------------------------------------------------------

local cycleScreens = hs.fnutils.cycle(hs.screen.allScreens())

hs.hotkey.bind(hyper, "S", function()
  hs.window.focusedWindow():moveToScreen(cycleScreens())
end)

-- screenOrder = {
--     "Color LCD"
-- }

-- screenMoveMode = hs.hotkey.modal.new(hyper, "s")
-- function screenMoveMode:entered()
--   hs.alert.show('Mode: Move to screen', 10)

--   -- main display = 1
--   -- screen to

--   manualScreenOrder = {
--       [69677504] = 1 -- Macbook display
--   }
--   screenMappings = {}
--   allScreens = hs.screen.allScreens()

--   for i, screen in pairs(allScreens) do
--     local id = screen:id()
--     local name = screen:name()

--     hs.alert(string.format('display: %s real ID: %s', name, id), 10)
--   end
-- end

-- function screenMoveMode:exited()  hs.alert.show('Exited mode')  end

---------------------------------------------------------
-- APP HOTKEYS
---------------------------------------------------------

hs.hotkey.bind(hyper, "1", launchOrCycleFocus("Sublime Text"))
hs.hotkey.bind(hyper, "2", launchOrCycleFocus("iTerm"))
hs.hotkey.bind(hyper, "3", launchOrCycleFocus("Google Chrome"))
hs.hotkey.bind(hyper, "4", launchOrCycleFocus("Firefox"))
hs.hotkey.bind(hyper, "5", launchOrCycleFocus("Evernote"))
hs.hotkey.bind(hyper, "6", launchOrCycleFocus("Spotify"))
hs.hotkey.bind(hyper, "7", launchOrCycleFocus("Vox"))

hs.hotkey.bind(hyper, "Z", launchOrCycleFocus("Finder"))

hs.hotkey.bind(hyper, "F", fullScreenCurrent)
hs.hotkey.bind(hyper, "D", screenToRight)
hs.hotkey.bind(hyper, "A", screenToLeft)

---------------------------------------------------------
-- KEYBOARD LANGUAGE SWITCH
---------------------------------------------------------

local getLanguage = hs.fnutils.cycle({
  "Swedish - Pro",
  "U.S. International - PC"
})

hs.hotkey.bind(hyper, "L", function()
  local language = getLanguage()

  -- http://stackoverflow.com/a/23741934
  script = [[
  tell application "System Events" to tell process "SystemUIServer"
    tell (menu bar item 1 of menu bar 1 whose description is "text input")
      select
      tell menu 1
        click (first menu item whose title = (get "%s"))
      end tell
    end tell
  end tell
  ]]

  hs.applescript.applescript(script:format(language))
end)

---------------------------------------------------------
-- ON-THE-FLY KEYBIND
---------------------------------------------------------

-- Temporarily bind an application to be toggled by the V key
-- useful for once-in-a-while applications like Preview
local boundApplication = nil

hs.hotkey.bind(hyper, "C", function()
  local appName = hs.window.focusedWindow():application():title()

  if boundApplication then
    boundApplication:disable()
  end
  hs.alert(appName)

  boundApplication = hs.hotkey.bind(hyper, "V", launchOrFocus(appName))

  -- https://github.com/Hammerspoon/hammerspoon/issues/184#issuecomment-102835860
  boundApplication:disable()
  boundApplication:enable()

  hs.alert(string.format("Binding: %s", appName))
end)

---------------------------------------------------------
-- EVERNOTE
---------------------------------------------------------

local evernote = hs.hotkey.modal.new(hyper, "E")

function evernote:entered()
  alert('Evernote Modal')
end

local function evernoteExit()
  evernote:exit()
  alert('Exited Evernote Modal')
end

evernote:bind({}, 'escape', evernoteExit)

evernote:bind({}, 'F', function()
  hs.eventtap.keyStroke({'ctrl', 'cmd'}, 9)
  evernoteExit()
end)

evernote:bind({}, 'N', function()
  hs.eventtap.keyStroke({'ctrl', 'cmd'}, 0)
  evernoteExit()
end)

---------------------------------------------------------
-- VOX
---------------------------------------------------------

hs.hotkey.bind(hyper, "I", function()
  local currentlyFocusedWindow = hs.window.focusedWindow()
  local vox = getApplicationWindow('VOX')
  local voxapp = vox:application()
  vox:focus()

  voxapp:selectMenuItem({"Controls", "Go to Current Track"})
  vox:selectMenuItem({"Edit", "Delete and Move to Trash"})

  -- Have to use long timeout, else doesn't enable the
  -- menu items .. :(
  hs.timer.doAfter(1, function()
    voxapp:selectMenuItem({"Controls", "Play"})
    currentlyFocusedWindow:focus()
  end)
end)

---------------------------------------------------------
-- KEY GRID
---------------------------------------------------------

local screenGrid = hs.hotkey.modal.new(hyper, "T")

screenGrid:bind({}, 'escape', function()
  screenGrid:exit()
  alert('Exited screenGrid')
end)

function screenGrid:entered()
  alert(string.format('Entered Grid Configuration Mode'))

  local function describeGrid()

    local topCoord =    gridCoordinates(topLeftGrid)
    local bottomCoord = gridCoordinates(bottomRightGrid)

    local gridCopy = deepcopy(gridKeys)

    newGrid = subGrid(gridCopy, topCoord, bottomCoord)

    setCustomizedGrid(newGrid)
  end

   a = listenForKeyToAssign(function(char)
    topLeftGrid = char

    b = listenForKeyToAssign(function(char)
      bottomRightGrid = char

      describeGrid()
    end)
  end)
end


hs.hotkey.bind(hyper, "K", function()
  hs.hints.windowHints()
end)

hs.hotkey.bind(hyper, "H", function()
  local current = hs.application.frontmostApplication()
  current:selectMenuItem({"Help"})
end)

hs.hotkey.bind(hyper, "X", function()
  hs.openConsole()
  hs.focus()
end)

hs.hotkey.bind(hyper, "R", function()
  hs.reload()
  hs.alert.show("Config loaded")
end)

hs.hotkey.bind(hyper, "Q", function()
  window = hs.window.focusedWindow()
  hs.grid.snap(window)
end)

