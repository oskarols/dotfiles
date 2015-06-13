require "fntools"

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

gridKeys = {
  { 1,   2,   3,   4,   5,   6,   7 },
  {"q", "w", "e", "r", "t", "y", "u"},
  {"a", "s", "d", "f", "g", "h", "j"},
  {"z", "x", "c", "v", "b", "n", "m"}
}

-- @param table
-- @returns height, width
function table.dimensions(self)
  return #self, #self[1]
end

customizedGrid = nil

-- basically we want something that behaves just like a table
-- but extended with extra methods ..
-- KeyboardGrid = {
--   layout = nil
-- }

-- KeyboardGrid.new = function(layout, topPoint, bottomPoint)
--   topPoint, bottomPoint = normalizePoints(topPoint, bottomPoint)
-- end

-- callback called at the end of creating a new grid
-- de-facto used to exit any state used when creating the grid
function newKeyboardGrid(callback)

  function createGridFromCoordinates(topLeftGridKey, bottomRightGridKey)
    local keyboardGridPoint = partial(getCoordinates, gridKeys)
    local topPoint, bottomPoint = normalizePoints(keyboardGridPoint(topLeftGridKey),
                                                  keyboardGridPoint(bottomRightGridKey))

    local newGrid = subGrid(gridKeys, topPoint, bottomPoint)

    grid.GRIDHEIGHT, grid.GRIDWIDTH = table.dimensions(newGrid)

    -- persist
    customizedGrid = newGrid

    callback()
  end

  local allGridKeys = flatten(gridKeys)
  local keyValidator = partial(contains, allGridKeys)

  captureKeys(2, createGridFromCoordinates, keyValidator)
end

-- grid cell being a poor name for a basically a grid within a grid ..
-- should probably be called table-rect or something
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

  function manipulateWindow(topLeftGridKey, bottomRightGridKey)
    local getGridPoint = partial(getCoordinates, customizedGrid)
    local topPoint, bottomPoint = normalizePoints(getGridPoint(topLeftGridKey),
                                                  getGridPoint(bottomRightGridKey))

    local window = hs.window.focusedWindow()
    local gridCell = subGrid(customizedGrid, topPoint, bottomPoint)
    local rect = topPoint
    rect.h, rect.w = table.dimensions(gridCell)

    rect = HSGridCellAdapter(rect)

    hs.grid.set(window, rect, window:screen())

    callback()
  end

  local allValidKeys = flatten(customizedGrid)
  local keyValidator = partial(contains, allValidKeys)

  captureKeys(2, manipulateWindow, keyValidator)
end

---------------------------------------------------------
-- GRID / TABLE UTILS
---------------------------------------------------------

-- given two points {x, y} normalizes them
-- so the first point will always be in the top left
-- and the bottom point always bottom right
function normalizePoints(top, bottom)

  -- top point is to the right of bottom point
  function isVerticallyReverseOrder(top, bottom)
    return top.x > bottom.x
  end

  -- top is in the bottom left corner
  function isYReverseOrder(top, bottom)
    return top.y > bottom.y
  end

  if isVerticallyReverseOrder(top, bottom) then
    top, bottom = bottom, top
  end
  if isYReverseOrder(top, bottom) then
    top, bottom = {
      x = top.x,
      y = bottom.y
    },
    {
      x = bottom.x,
      y = top.y
    }
  end

  return top, bottom
end

-- Get the point {x, y} from a given value inside
-- a table. Multidimensional index-of.
--
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
  -- since we don't want to change it in-place
  grid = deepcopy(grid)

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