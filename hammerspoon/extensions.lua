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

---------------------------------------------------------
-- SCREEN
---------------------------------------------------------

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

---------------------------------------------------------
-- APPLICATION / WINDOW
---------------------------------------------------------

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


applicationStates = {}

function launchOrFocus(name)

  -- switching to an app, states:
  -- * focusing an app
  -- * focusing an app, mouse over another app
  local saveCurrentState = function()
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

  local restoreState = function(applicationName)
    compose(
      partial(result, applicationStates),
      maybe(getProperty('mouse')),
      maybe(hs.mouse.setAbsolutePosition)
    )(applicationName)
  end

  return function()
    -- save the state of currently focused app
    saveCurrentState()

    -- try to restore previous state for app about to launch/focus
    restoreState(name)

    hs.application.launchOrFocus(name)

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

  customizedGrid = grid
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

function listenForKeys(numberOfKeys, callback)


end