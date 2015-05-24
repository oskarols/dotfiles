flair = "ᕙ(⇀‸↼‶)ᕗ";

hyper = {"cmd", "ctrl", "alt", "shift"}

-- disable animations
hs.window.animationDuration = 0

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

-- TODOS

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

function centerOnApplication(applicationName)
    -- hs.geometry.rectMidPoint(rect) -> point
end

i = require('hs.inspect')
dbg = function(...)
  print(i.inspect(...))
end




function tap (a)
  dbg(a)
  return a
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


applicationStates = {}

function launchOrFocus(name)

  -- switching to an app, states:
  -- * focusing an app
  -- * focusing an app, mouse over another app
  local saveState = function()
    local function saveApplicationState (applicationName)
      applicationStates[applicationName] = {
        ["screen"] = hs.mouse.getCurrentScreen(),
        ["mouse"] =  hs.mouse.getRelativePosition() -- mouse or nil
      }
    end

    compose(
      getProperty("focusedWindow"),
      getProperty("application"),
      getProperty("title"),
      saveApplicationState
    )(hs.window)
  end

  local lookupState = partial(result, applicationStates)

  local restoreState = function(state)
    hs.mouse.setAbsolutePosition(state.mouse)
  end

  return function()
    saveState()

    local lastState = lookupState(name)

    if lastState then
        restoreState(lastState)
    end

    hs.application.launchOrFocus(name)
    mouseHighlight()
  end
end

function manipulateScreen(func)
  return function()
    local window = hs.window.focusedWindow()
    local windowFrame = window:frame()
    local screen = window:screen()
    local screenFrame = screen:frame()

    func(window, windowFrame, screen, screenFrame)
  end
end

fullScreenCurrent = manipulateScreen(function(window, windowFrame, screen, screenFrame)
  window:setFrame(screenFrame)
end)

screenToRight = manipulateScreen(function(window, windowFrame, screen, screenFrame)
  windowFrame.x = screenFrame.w / 2
  windowFrame.y = screenFrame.y
  windowFrame.w = screenFrame.w / 2
  windowFrame.h = screenFrame.h
  window:setFrame(windowFrame)
end)

screenToLeft = manipulateScreen(function(window, windowFrame, screen, screenFrame)
  windowFrame.x = screenFrame.x
  windowFrame.y = screenFrame.y
  windowFrame.w = screenFrame.w / 2
  windowFrame.h = screenFrame.h
  window:setFrame(windowFrame)
end)

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

function getApplicationWindow(applicationName)
  local apps = hs.application.runningApplications()
  local app = hs.fnutils.filter(apps, function(app)
    return result(app, 'title') == applicationName
  end)

  if app and #app then
    windows = app[1]:allWindows()
    window = windows[1]
    return window
  else
    return nil
  end
end

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



grid.GRIDHEIGHT = 3
grid.GRIDWIDTH = 3

grid.MARGINX = 0
grid.MARGINY = 0

gridKeys = {
  { 1,   2,   3,   4,   5,   6,   7 },
  {"q", "w", "e", "r", "t", "y", "u"},
  {"a", "s", "d", "f", "g", "h", "j"},
  {"z", "x", "c", "v", "b", "n", "m"}
}

local allGridKeys = flatten(gridKeys)

customizedGrid = nil

function setCustomizedGrid(grid)
  local gridHeight = #newGrid
  local gridWidth  = #newGrid[1]

  print(string.format("Grid width: %s, height %s", #newGrid[1], #newGrid))

  dbg(newGrid)

  grid.GRIDHEIGHT = gridHeight
  grid.GRIDWIDTH  = gridWidth

  customizedGrid = grid
end

-- TODO: refactor to a hs.rect
-- rename; subdivideGrid
-- subGrid
function customizeGrid (grid, topCoord, bottomCoord) -- -> sliced grid

  -- sentinel value, used to indicate a non-value
  NIL = 999

  -- first pass, set all invalid y-row to NIL
  for i = 1, #grid do
    if i < topCoord.y or i > bottomCoord.y then
      grid[i] = NIL
    end
  end

  dbg(grid)

  -- nested pass, set all invalid cells to NIL
  for i = 1, #grid do
    local row = grid[i]
    if row ~= NIL then
      for j = 1, #row do
        if j < topCoord.x or j > bottomCoord.x then
          row[j] = NIL
        end
      end
    end
  end

  -- remove all NIL values
  function notNill(row)
    return row ~= NIL
  end

  grid = filter(grid, notNill)

  for i = 1, #grid do
    grid[i] = filter(grid[i], notNill)
  end

  return grid
end

screenGrid = hs.hotkey.modal.new(hyper, "T")

screenGrid:bind({}, 'escape', function()
  screenGrid:exit()
  alert('Exited screenGrid')
end)

local topLeftGrid = nil
local bottomRightGrid = nil

-- grid = {
--   {1, 2, 3},
--   {4, 5, 6},
--   {7, 8, 9}
-- }
--
-- > getCoordinates(grid, 9)
-- { x = 3, y = 3}
--
-- > getCoordinates(grid, 4)
-- { x = 1, y = 2}

function getCoordinates(table, value)
  local x
  local y

  for i = 1, #table do
    local row = table[i]

    for j = 1, #row do
      if row[j] == value then
        x = j
        break
      end
    end

    if x then
      y = i
      break
    end
  end

  return {
    ['x'] = x,
    ['y'] = y
  }
end

function gridExtensionAdapter(coordinate)
end

local gridCoordinates = partial(getCoordinates, gridKeys)

function isValidGridKey(char)
  return indexOf(allGridKeys, char)
end


function screenGrid:entered()
  local keyupType = hs.eventtap.event.types.keyup

  alert(string.format('Entered Grid Configuration Mode'))

  local function describeGrid()

    local topCoord =    gridCoordinates(topLeftGrid)
    local bottomCoord = gridCoordinates(bottomRightGrid)

    newGrid = customizeGrid(gridKeys, topCoord, bottomCoord)

    setCustomizedGrid(newGrid)
  end

  local function listenForKeyToAssign(callback)

    local eventToCharacter = compose(
      getProperty('getKeyCode'),
      partial(result, hs.keycodes.map),
      partial(flip(invoke), 'lower')
    )

    local event = hs.eventtap.new({keyupType}, function(event)
      local char = eventToCharacter(event)
      if char == 't' then
        return 5
      end

      alert(string.format('Received char: %s', char))

      if isValidGridKey(char) then
        callback(char)
      else
        alert(string.format('Invalid key %s', char))
        return true
      end

      return true
    end)

    event:start()

    return event
  end

   a = listenForKeyToAssign(function(char)
    topLeftGrid = char
    a:stop()

    b = listenForKeyToAssign(function(char)
      bottomRightGrid = char
      b:stop()

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

  hs.eventtap.keyStroke({'ctrl', 'cmd'}, 0)
  evernoteExit()
end)

function serializeUserData(ud)
  local serialization = {}
end
