flair = "ᕙ(⇀‸↼‶)ᕗ";

hyper = {"cmd", "ctrl", "alt", "shift"}

-- disable animations
hs.window.animationDuration = 0

-- hide window shadows
hs.window.setShadows(false)

partial = hs.fnutils.partial
sequence = hs.fnutils.sequence

local fnutils = require "hs.fnutils"
local partial = fnutils.partial
local indexOf = fnutils.indexOf
local filter = fnutils.filter

local window = require "hs.window"
local alert = require "hs.alert"
local grid = require "hs.grid"

require "fntools"
require "extensions"
require "window_tracker"

-- TODOS

-- when switching to a window, make sure the mouse is within the boundaries
-- of that window, else center

-- if switching from a non-bound app to an explicitly bound one
-- there should be a key to switch back

-- handle finder having more than 1 window

-- applications having multiple windows is very poorly handled

-- security policy based on the wifi ID connected to,
-- i.e. locks
-- maybe base this on the location somehow via GPS?

-- need some bridge between browser and database or notes of URIs
-- similar to PathFinder

-- have some sort of bookmark application separate from chrome and firefox (perhaps that's evernote?)

-- modal if there are multiple windows, else just normal hotkey

-- holding a focus button for a longer period will upon release refocus
-- the previous application

-- you should be able to indicate size changes using two keys to judge
-- the distance between those keys
-- e.g. E -> T would increase cell size by two to the right

-- hyper + C / V should save a specific window + application, not just app

-- extend the objects with .get('propertyName', {default: Primitive || Function})
-- like so: :get('focusedWindow'):get('application'):get('title')
-- would also have good exceptions, be able to say things like
-- you tried getting the focusedWindow on object <application>

function centerOnApplication(applicationName)
    -- hs.geometry.rectMidPoint(rect) -> point
end

local mouseCircle = nil
local mouseCircleTimer = nil

function mouseHighlight()
  -- Delete an existing highlight if it exists
  result(mouseCircle, "delete")
  result(mouseCircleTimer, "stop")

  -- Get the current co-ordinates of the mouse pointer
  mousepoint = hs.mouse.get()

  -- Prepare a big red circle around the mouse pointer
  mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
  mouseCircle:setFillColor({["red"]=0,["blue"]=1,["green"]=0,["alpha"]=0.5})
  mouseCircle:setStrokeWidth(0)
  mouseCircle:show()

  -- Set a timer to delete the circle after 3 seconds
  mouseCircleTimer = hs.timer.doAfter(0.2, function()
    mouseCircle:delete()
  end)
end

screenOrder = {
    "Color LCD"
}




local cycleScreens = hs.fnutils.cycle(hs.screen.allScreens())

hs.hotkey.bind(hyper, "S", function()
  hs.window.focusedWindow():moveToScreen(cycleScreens())
end)

screenMoveMode = hs.hotkey.modal.new(hyper, "s")
function screenMoveMode:entered()
  hs.alert.show('Mode: Move to screen', 10)

  -- main display = 1
  -- screen to

  manualScreenOrder = {
      [69677504] = 1 -- Macbook display
  }
  screenMappings = {}
  allScreens = hs.screen.allScreens()

  for i, screen in pairs(allScreens) do
    local id = screen:id()
    local name = screen:name()

    hs.alert(string.format('display: %s real ID: %s', name, id), 10)
  end

end

hs.hotkey.bind(hyper, "1", launchOrFocus("Sublime Text"))
hs.hotkey.bind(hyper, "2", launchOrFocus("iTerm"))
hs.hotkey.bind(hyper, "3", launchOrFocus("Google Chrome"))
hs.hotkey.bind(hyper, "4", launchOrFocus("Firefox"))
hs.hotkey.bind(hyper, "5", launchOrFocus("Evernote"))
hs.hotkey.bind(hyper, "6", launchOrFocus("Spotify"))
hs.hotkey.bind(hyper, "7", launchOrFocus("Vox"))

hs.hotkey.bind(hyper, "Z", launchOrFocus("Finder"))

hs.hotkey.bind(hyper, "F", fullScreenCurrent)
hs.hotkey.bind(hyper, "D", screenToRight)
hs.hotkey.bind(hyper, "A", screenToLeft)

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


-- Temporarily bind an application to be toggled by the V key
-- useful for once-in-a-while applications like Preview
boundApplication = nil

hs.hotkey.bind(hyper, "C", function()
  appName = hs.window.focusedWindow():application():title()

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

function screenMoveMode:exited()  hs.alert.show('Exited mode')  end

screenGrid = hs.hotkey.modal.new(hyper, "T")

screenGrid:bind({}, 'escape', function()
  screenGrid:exit()
  alert('Exited screenGrid')
end)

function screenGrid:entered()
  alert(string.format('Entered Grid Configuration Mode'))

  local function describeGrid()

    local topCoord =    gridCoordinates(topLeftGrid)
    local bottomCoord = gridCoordinates(bottomRightGrid)

    newGrid = customizeGrid(gridKeys, topCoord, bottomCoord)

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

hs.hotkey.bind(hyper, "X", function()
  hs.focus()
end)

hs.hotkey.bind(hyper, "K", function()
  hs.hints.windowHints()
end)

hs.hotkey.bind(hyper, "H", function()
  local current = hs.application.frontmostApplication()
  current:selectMenuItem({"Help"})
end)

hs.hotkey.bind(hyper, "R", function()
  hs.reload()
  hs.alert.show("Config loaded")
end)

hs.hotkey.bind(hyper, "Q", function()
  window = hs.window.focusedWindow()
  hs.grid.snap(window)
end)

evernote = hs.hotkey.modal.new(hyper, "E")

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

  hsX.eventtap.keyStroke({'ctrl', 'cmd'}, 0)
  evernoteExit()
end)
