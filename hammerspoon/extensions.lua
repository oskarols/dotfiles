require "fntools"

partial = hs.fnutils.partial
sequence = hs.fnutils.sequence

local fnutils = require "hs.fnutils"
local map = fnutils.map
local each = fnutils.each
local partial = fnutils.partial
local indexOf = fnutils.indexOf
local filter = fnutils.filter
local concat = fnutils.concat
local contains = fnutils.contains

local window = require "hs.window"
local alert = require "hs.alert"
local grid = require "hs.grid"
local geometry = require "hs.geometry"

---------------------------------------------------------
-- Debugging
---------------------------------------------------------

dbg = function(...)
  print(hs.inspect(...))
end

dbgf = function (...)
  return dbg(string.format(...))
end

function tap (a)
  dbg(a)
  return a
end

local yay = "ᕙ(⇀‸↼‶)ᕗ"

local boo = "ლ(ಠ益ಠლ)"

---------------------------------------------------------
-- COORDINATES, POINTS, RECTS, FRAMES, TABLES
---------------------------------------------------------

-- Fetch next index but cycle back when at the end
--
-- > getNextIndex({1,2,3}, 3)
-- 1
-- > getNextIndex({1}, 1)
-- 1
-- @return int
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
  windowFrame.h = screenFrame.h + 10

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

-- Returns the next successive window given a collection of windows
-- and a current selected window
--
-- @param  windows  list of hs.window or applicationName
-- @param  window   instance of hs.window
-- @return hs.window
local function getNextWindow(windows, window)
  if type(windows) == "string" then
    windows = hs.appfinder.appFromName(windows):allWindows()
  end

  windows = filter(windows, hs.window.isStandard)
  windows = filter(windows, hs.window.isVisible)
  lastIndex = indexOf(windows, window)

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

-- Captured snapshots of an application windows state
-- used to save and restore snapshots when moving
-- between applications

ApplicationWindowStates = {}

function ApplicationWindowStates:new()
  self.__index = self
  return setmetatable({}, self)
end

function ApplicationWindowStates:key(window)
  if not window then return '' end
  local applicationName = compose(
    getProperty("application"),
    getProperty("title")
  )(window)

  return applicationName..':'..window:id()
end

function ApplicationWindowStates:save()
  local window = hs.window.focusedWindow()
  local applicationStateKey = self.key(window)

  self[applicationStateKey] = {
    ["screen"] = hs.mouse.getCurrentScreen(),
    ["mouse"]  = hs.mouse.getAbsolutePosition(), -- mouse or nil
    ["window"] = window
  }
end

function ApplicationWindowStates:lookup(window)
  local key = self.key(window)
  return self[key]
end

function ApplicationWindowStates:restore(window)
  local key = self.key(window)

  compose(
    partial(result, self),
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


appStates = ApplicationWindowStates:new()

-- Needed to enable cycling of application windows
lastToggledApplication = ''

function launchOrCycleFocus(name)
  return function()
    local nextWindow = nil
    local targetWindow = nil
    local focusedWindow          = hs.window.focusedWindow()
    local lastToggledApplication = focusedWindow and focusedWindow:application():title()

    if not focusedWindow then return nil end

    -- save the state of currently focused app
    appStates:save()

    dbgf('last: %s, current: %s', lastToggledApplication, name)

    if lastToggledApplication == name then
      nextWindow = getNextWindow(name, focusedWindow)

      -- Becoming main means
      -- * gain focus (although docs say differently?)
      -- * next call to launchOrFocus will focus the main window <- important
      --
      -- If we have two applications, each with multiple windows
      -- i.e:
      --
      -- Google Chrome: {window1} {window2}
      -- Firefox:       {window1} {window2} {window3}
      --
      -- and we want to move between Google Chrome {window2} and Firefox {window3}
      -- when pressing the hotkeys for those applications, then using becomeMain
      -- we cycle until those windows (i.e press hotkey twice for Chrome) have focus
      -- and then the launchOrFocus will trigger that specific window.
      nextWindow:becomeMain()
    else
      hs.application.launchOrFocus(name)
    end

    if nextWindow then -- won't be available when appState empty
      targetWindow = nextWindow
    else
      targetWindow = hs.window.focusedWindow()
    end

    if appStates:lookup(targetWindow) then
      dbgf('restoring state of: %s', targetWindow:application():title())
      appStates:restore(targetWindow)
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

customizedGrid = nil

function newKeyboardGrid(callback)

  function gridFromCoordinates(topLeftGrid, bottomRightGrid)
    local topCoord =    gridCoordinates(topLeftGrid)
    local bottomCoord = gridCoordinates(bottomRightGrid)
    local gridCopy =    deepcopy(gridKeys)
    local newGrid =     subGrid(gridCopy, topCoord, bottomCoord)

    dbg(topCoord)
    dbg(bottomCoord)

    dbg(newGrid)
    dbgf("Grid width: %s, height %s", #newGrid[1], #newGrid)

    customizedGrid = newGrid

    local gridHeight = #newGrid
    local gridWidth  = #newGrid[1]
    grid.GRIDHEIGHT = gridHeight
    grid.GRIDWIDTH  = gridWidth

    callback()
  end

  local allGridKeys = flatten(gridKeys)

  captureKeys(2, gridFromCoordinates, partial(contains, allGridKeys))
end

function drawGrid()
  if not customizedGrid then
    return nil
  end

  alert('drawing grid')

  local grid = customizedGrid
  local cells = {}

  for i = 1, #grid do
    for j = 1, #grid[i] do
      table.insert(cells, {
        y = i,
        x = j,
        char = grid[i][j]
      })
    end
  end

  local rectWidth = 60
  local rectHeight = 60
  local margin = 10
  local roundedRadius = 10
  local shapes = {}

  local rects = each(cells, function(cellData)
    local rect = {
      x = (cellData.x * rectWidth) + (margin * cellData.x),
      y = (cellData.y * rectHeight) + (margin * cellData.y),
      w = rectWidth,
      h = rectHeight
    }
    local rectangle = hs.drawing.rectangle(rect)

    rectangle:setRoundedRectRadii(roundedRadius, roundedRadius)
    rectangle:setFillColor({
      red = 0.5,
      blue = 0.5,
      green = 0.5,
      alpha = 1
    })
    rectangle:setStrokeColor({
      red = 1,
      blue = 1,
      green = 1,
      alpha = 1
    })
    rectangle:setStrokeWidth(5)
    rectangle:show()

    rect.x = rect.x + 10
    rect.y = rect.y + 10

    local text = hs.drawing.text(rect, cellData.char:upper())
    text:show()
    text:setTextSize(35)
    text:bringToFront()

    table.insert(shapes, rectangle)
    table.insert(shapes, text)
  end)

  function hideShapes()
    dbg(shapes)
    each(shapes, function(shape)
      shape:hide()
    end)
  end

  return hideShapes
end

function resizeGridWithCell(callback)
  if not customizedGrid then
    alert("No keyboard grid defined "..boo)
    callback()
    return
  end

  -- since hs.grid uses 0 based indeces ..
  local function HSGridCellAdapter(cell)
    cell.x = cell.x - 1
    cell.y = cell.y - 1
    return cell
  end

  function manipulateWindow(topLeftGrid, bottomRightGrid)
    local topCoord = getCoordinates(customizedGrid, topLeftGrid)
    local bottomCoord = getCoordinates(customizedGrid, bottomRightGrid)
    local window = hs.window.focusedWindow()
    local gridCell = subGrid(deepcopy(customizedGrid), topCoord, bottomCoord)
    local cell = {
      x = topCoord.x,
      y = topCoord.y,
      h = #gridCell,
      w = #gridCell[1]
    }

    cell = HSGridCellAdapter(cell)
    hs.grid.set(window, cell, window:screen())

    callback()
  end

  local allValidKeys = flatten(customizedGrid)

  captureKeys(2, manipulateWindow, partial(contains, allValidKeys))
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

function drawgrid(grid, cells)

end

gridCoordinates = partial(getCoordinates, gridKeys)

-- Extract a subset of a grid using coordinates
--
-- grid = {
--   {1, 2, 3, 4, 5},
--   {6, 7, 8, 9, 4},
--   {9, 8, 8, 7, 6}
-- }
--
-- > subGrid(grid, {x = 2, y = 1}, {x = 3, y = 3})
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

-- Returns what key was pressed on an eventtap object
-- @param   event   the parameter for eventtap callbacks
-- @return  string
local eventToCharacter = compose(
  getProperty('getKeyCode'),
  partial(result, hs.keycodes.map),
  partial(flip(invoke), 'lower')
)



-- Capture a number of keystrokes and sends it to a function
--
-- Example:
--
-- captureKeys(1, function(firstKey) print(firstKey) end)
--
-- captureKeys(2, function(firstKey, secondKey) print(secondKey) end, function(key)
--   return hs.fnutils.contains({"a", "b", "c"}, key)
-- end)
--
-- @param {int} numberOfKeystrokes
-- @param {Function} callback gets each of the keystrokes as a parameter
-- @param {Function} Optional validator for each of the keypresses
-- @return nil
function captureKeys(numberOfKeystrokes, callback, keyValidator)
  local events = {
    hs.eventtap.event.types.keydown
  }
  local capturedKeys = {}
  local currentWatcher = nil

  function captureKeystroke()
    local watcher = hs.eventtap.new(events, keystrokeHandler)
    watcher:start()
    currentWatcher = watcher
    return watcher
  end

  function keystrokeHandler(event, foo, bar)
    currentWatcher:stop()

    local char = eventToCharacter(event)

    if isFunction(keyValidator) and not keyValidator(char) then
      alert('received invalid char: '..char)
      captureKeystroke()
      return true
    end

    hs.alert('received char: '..char)
    table.insert(capturedKeys, char)

    if #capturedKeys < numberOfKeystrokes then
      captureKeystroke()
    else
      callback(table.unpack(capturedKeys))
    end

    -- delete the event handler
    return true
  end

  captureKeystroke()
end
