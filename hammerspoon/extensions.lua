require "fntools"

partial = hs.fnutils.partial
sequence = hs.fnutils.sequence

local fnutils = require "hs.fnutils"
local partial = fnutils.partial
local indexOf = fnutils.indexOf
local filter = fnutils.filter

local window = require "hs.window"
local alert = require "hs.alert"
local grid = require "hs.grid"
local geometry = require "hs.geometry"


dbgf = function (...)
  return dbg(string.format(...))
end

---------------------------------------------------------
-- COORDINATES, POINTS, RECTS, FRAMES, TABLES
---------------------------------------------------------

-- > getNextIndex({1,2,3}, 3)
-- 1
-- > getNextIndex({1}, 1)
-- 1
--
-- Note: Nice to have to cycle back to beginning
local function getNextIndex(table, currentIndex)
  nextIndex = currentIndex + 1
  if nextIndex > #table then
    nextIndex = 1
  end

  return nextIndex
end

---------------------------------------------------------
-- SCREEN
---------------------------------------------------------


-- NOTE, Screens use relative coordinates, all the screens
-- make up a big screen, so you have do adjust accordingly
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
  windowFrame.w = screenFrame.w / 2
  windowFrame.x = (screenFrame.w / 2) + screenFrame.x
  windowFrame.h = screenFrame.h

  window:setFrame(windowFrame)
end)

screenToLeft = manipulateScreen(function(window, windowFrame, screen, screenFrame)
  screenFrame.w = screenFrame.w / 2
  window:setFrame(screenFrame)
end)

---------------------------------------------------------
-- MOUSE
---------------------------------------------------------

local function centerMouseOnRect(frame)
  hs.mouse.setAbsolutePosition(geometry.rectMidPoint(frame))
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

---------------------------------------------------------
-- APPLICATION / WINDOW
---------------------------------------------------------

local function getNextWindow(applicationName)
  windows = hs.appfinder.appFromName(applicationName):allWindows()

  -- since chrome has windows which are non-standard, and not
  -- focusable
  windows = filter(windows, hs.window.isStandard)
  windows = filter(windows, hs.window.isVisible)

  lastIndex = indexOf(windows, hs.window.focusedWindow())

  dbgf('finding next window for appName: %s', applicationName)
  dbgf('resolved last index to: %s', lastIndex)

  dbg(windows[getNextIndex(windows, lastIndex)])

  return windows[getNextIndex(windows, lastIndex)]
end

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

-- save mouse position
applicationStates = {}

-- Needed to cycle upon multiple presses
lastToggledApplication = nil

function launchOrFocus(name)

  -- switching to an app, states:
  -- * focusing an app
  -- * focusing an app, mouse over another app

  local getStateKey = function(window)
    local applicationName = compose(
      getProperty("application"),
      getProperty("title")
    )(window)

    return applicationName .. window:id()
  end

  -- TODO: should be a method on applicationStates
  local saveCurrentState = function()
    local window = hs.window.focusedWindow()
    local applicationStateKey = getStateKey(window)

    applicationStates[applicationStateKey] = {
      ["screen"] = hs.mouse.getCurrentScreen(),
      ["mouse"]  = hs.mouse.getAbsolutePosition(), -- mouse or nil
      ["window"] = window
    }
  end

  local lookupState = function(window)
    local key = getStateKey(window)
    return applicationStates[key]
  end

  local restoreState = function(window)
    local key = getStateKey(window)

    compose(
      partial(result, applicationStates),
      maybe(getProperty('mouse')),
      -- even if the mouse goes outside the window, and that app is saved
      -- make sure it appears within the window
      maybe(function(mouseCoordinates)
        local windowFrame = window:frame()

        if geometry.isPointInRect(mouseCoordinates, windowFrame) then
          hs.mouse.setAbsolutePosition(mouseCoordinates)
        else
          centerMouseOnRect(windowFrame)
        end
      end)
    )(key)
  end

  return function()
    -- other things we could do:
    -- when you change to another screen other than the main one

    -- save the state of currently focused app
    saveCurrentState()

    local nextWindow = nil

    lastToggledApplication = hs.window.focusedWindow():application():title()

    dbgf('last: %s, current: %s', lastToggledApplication, name)

    if lastToggledApplication == name then
      nextWindow = getNextWindow(name)
      nextWindow:becomeMain()
    end

    -- try to restore previous state for app about to launch/focus

    hs.application.launchOrFocus(name)

    local targetWindow = nil

    if nextWindow then -- won't be available when appState empty
      targetWindow = nextWindow
    else
      targetWindow = hs.window.focusedWindow()
    end

    if lookupState(targetWindow) then
      dbgf('restoring state of: %s', targetWindow:application():title())
      restoreState(targetWindow)
    else
      local windowFrame = targetWindow:frame()
      centerMouseOnRect(windowFrame)
    end

    mouseHighlight()
  end
end


---------------------------------------------------------
-- GRID RELATED
---------------------------------------------------------

grid.GRIDHEIGHT = 3
grid.GRIDWIDTH = 3

grid.MARGINX = 0
grid.MARGINY = 0

local topLeftGrid = nil
local bottomRightGrid = nil

gridKeys = {
  { 1,   2,   3,   4,   5,   6,   7 },
  {"q", "w", "e", "r", "t", "y", "u"},
  {"a", "s", "d", "f", "g", "h", "j"},
  {"z", "x", "c", "v", "b", "n", "m"}
}

local allGridKeys = flatten(gridKeys)

function isValidGridKey(char)
  return indexOf(allGridKeys, char)
end

customizedGrid = nil

function setCustomizedGrid(grid)
  local gridHeight = #newGrid
  local gridWidth  = #newGrid[1]

  print(string.format("Grid width: %s, height %s", #newGrid[1], #newGrid))

  dbg(newGrid)

  grid.GRIDHEIGHT = gridHeight
  grid.GRIDWIDTH  = gridWidth

  subGrid = grid
end


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

gridCoordinates = partial(getCoordinates, gridKeys)

-- Extract a subset of a grid using coordinates
--
-- grid = {
--   {1, 2, 3, 4, 5}
--   {6, 7, 8, 9, 4}
--   {9, 8, 8, 7, 6}
-- }
--
-- > subGrid(grid, {x = 2, y = 2}, {x = 3, y = 3})
-- {
--   {2, 3}
--   {7, 8}
--   {8, 8}
-- }
function subGrid (grid, topCoord, bottomCoord) -- -> table

  -- sentinel value, used to indicate a non-value
  NIL = 999

  -- first pass, set all y-row outside our coordinates to NIL
  for i = 1, #grid do
    if i < topCoord.y or i > bottomCoord.y then
      grid[i] = NIL
    end
  end

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

---------------------------------------------------------
-- KEYBOARD / MOUSE
---------------------------------------------------------


eventToCharacter = compose(
  getProperty('getKeyCode'),
  partial(result, hs.keycodes.map),
  partial(flip(invoke), 'lower')
)

function listenForKeyToAssign(callback)
  local keyupType = hs.eventtap.event.types.keyup
  local eventObject

  eventObject = hs.eventtap.new({keyupType}, function(event)

    local char = eventToCharacter(event)
    -- Since is instantly triggered by the thing that triggered
    -- the modal ...
    if char == 't' then
      return 5
    end

    alert(string.format('Received char: %s', char))

    if isValidGridKey(char) then
      eventObject:stop()
      callback(char)
    else
      alert(string.format('Invalid key %s', char))
    end

    return true
  end)

  eventObject:start()

  return eventObject
end
