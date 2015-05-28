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

function launchOrCycleFocus(applicationName)
  return function()
    local nextWindow = nil
    local targetWindow = nil
    local focusedWindow          = hs.window.focusedWindow()
    local lastToggledApplication = focusedWindow and focusedWindow:application():title()

    if not focusedWindow then return nil end

    -- save the state of currently focused app
    appStates:save()

    dbgf('last: %s, current: %s', lastToggledApplication, applicationName)

    if lastToggledApplication == applicationName then
      nextWindow = getNextWindow(applicationName, focusedWindow)

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
      hs.application.launchOrFocus(applicationName)
    end

    if nextWindow then -- won't be available when appState empty
      targetWindow = nextWindow
    else
      targetWindow = hs.window.focusedWindow()

    end

    if not targetWindow then
      dbgf('failed finding a window for application: %s', applicationName)
      return nil
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
