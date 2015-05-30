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
-- KEYBOARD DRIVEN WINDOW MANIPULATION
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

  function normalizeCoordinates(top, bottom)
    if isReverseOrder(top, bottom) then
      top, bottom = bottom, top
    end
    if bottomRightToTopLeftConfiguration(top, bottom) then
      top, bottom = {
        x = top.x,
        y = bottom.y
      },
      {
        x = bottom.x,
        y = top.y
      }
    end

    return {top, bottom}
  end

  function bottomRightToTopLeftConfiguration(top, bottom)
    return top.y > bottom.y
  end

  function isReverseOrder(top, bottom)
    return top.x > bottom.x
  end

  function createGridFromCoordinates(topLeftGrid, bottomRightGrid)
    local coords = normalizeCoordinates(gridCoordinates(topLeftGrid), gridCoordinates(bottomRightGrid))
    local topCoord = coords[1]
    local bottomCoord = coords[2]

    local gridCopy =    deepcopy(gridKeys)
    local newGrid =     subGrid(gridCopy, topCoord, bottomCoord)
    local gridHeight = #newGrid
    local gridWidth  = #newGrid[1]

    grid.GRIDHEIGHT = gridHeight
    grid.GRIDWIDTH  = gridWidth
    customizedGrid = newGrid

    dbgf("Grid width: %s, height %s", #newGrid[1], #newGrid)

    callback()
  end

  local allGridKeys = flatten(gridKeys)
  local keyValidator = partial(contains, allGridKeys)

  captureKeys(2, createGridFromCoordinates, keyValidator)
end

function resizeGridWithCell(callback)
  if not customizedGrid then
    alert("No keyboard grid defined "..boo)
    callback()
    return
  end

  -- since hs.grid uses 0 based indeces ..
  local function HSGridCellAdapter(rect)
    rect.x = rect.x - 1
    rect.y = rect.y - 1
    return rect
  end

  function manipulateWindow(topLeftGrid, bottomRightGrid)
    local coords = normalizeCoordinates(getCoordinates(customizedGrid, topLeftGrid), getCoordinates(customizedGrid, bottomRightGrid))
    local topCoord = coords[1]
    local bottomCoord = coords[2]

    local window = hs.window.focusedWindow()
    local gridCell = subGrid(deepcopy(customizedGrid), topCoord, bottomCoord)
    local rect = {
      x = topCoord.x,
      y = topCoord.y,
      h = #gridCell,
      w = #gridCell[1]
    }

    rect = HSGridCellAdapter(rect)
    hs.grid.set(window, rect, window:screen())

    callback()
  end

  local allValidKeys = flatten(customizedGrid)

  captureKeys(2, manipulateWindow, partial(contains, allValidKeys))
end

---------------------------------------------------------
-- GRID / TABLE UTILS
---------------------------------------------------------

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
    x = x,
    y = y
  }
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
-- DRAWING RELATED
---------------------------------------------------------

function currentScreen()
  local window =  hs.window.focusedWindow()
  if not window then return nil end
  return window:screen()
end

function drawGrid()
  if not customizedGrid then
    return nil
  end

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
  local margin = 2
  local roundedRadius = 10
  local shapes = {}

  local cellRowCount = #grid[1]
  local gridWidth = (cellRowCount * (rectWidth + margin))
  local s = currentScreen()
  local m = s:currentMode()

  dbgf('mode w: %d, grid w: %d', m.w / 2, gridWidth)
  local t = (m.w - gridWidth) / 2


  local rects = each(cells, function(cellData)
    local rect = {
      -- -1 since indexes start at 0, hence otherwise the cells would be offset
      x = ((cellData.x - 1) * rectWidth) + (margin * cellData.x) + t,
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
    text:setTextFont("Lucida Grande")
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