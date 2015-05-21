flair = "ᕙ(⇀‸↼‶)ᕗ";

hyper = {"cmd", "ctrl", "alt", "shift"}

-- disable animations
hs.window.animationDuration = 0

partial = hs.fnutils.partial
sequence = hs.fnutils.sequence

-- TODOS

-- if switching from a non-bound app to an explicitly bound one
-- there should be a key to switch back

-- bind current app to key

-- handle finder having more than 1 window

-- applications having multiple windows is very poorly handled

-- security policy based on the wifi ID connected to,
-- i.e. locks
-- maybe base this on the location somehow via GPS?

-- need some bridge between browser and database or notes of URIs
-- similar to PathFinder

-- globally turn spellcheck off?

-- have some sort of bookmark application separate from chrome and firefox (perhaps that's evernote?)

-- modal if there are multiple windows, else just normal hotkey

function centerOnApplication(applicationName) 
    -- hs.geometry.rectMidPoint(rect) -> point
end

i = require('hs.inspect')
dbg = function(...)
  print(i.inspect(...))
end

function isFunction(a)
  return type(a) == "function"
end

function maybe(func)
  return function (argument)
    if argument then
      return func(argument)
    else
      return nil
    end
  end
end

-- Flips the order of parameters passed to a function
function flip(func)
  return function(...)
    return func(table.unpack(reverse({...})))
  end
end

-- gets propery or method value 
-- on a table
function result(obj, property)
  if not obj then return nil end

  if isFunction(property) then
    return property(obj)
  elseif isFunction(obj[property]) then -- string
    return obj[property](obj) -- <- this will be the source of bugs
  else
    return obj[property]
  end
end

function getProperty(property)
    return partial(flip(result), property)
end

local resultRight = flip(result)

-- from Moses
--- Reverses values in a given array. The passed-in array should not be sparse.
-- @name reverse
-- @tparam table array an array
-- @treturn table a copy of the given array, reversed
function reverse(array)
  local _array = {}
  for i = #array,1,-1 do
    _array[#_array+1] = array[i]
  end
  return _array
end

function compose(...)
  local functions = {...}

  return function (...)
    local result

    for i, func in ipairs(functions) do
      if i == 1 then
        result = func(...)
      else
        result = func(result)
      end
    end

    return result
  end
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



unpack = table.unpack

function variadic_maybe (func)

  -- the basic problem here is that it dumps
  -- nil values, i.e there's no way of telling ..
  function all (...)
    local args = pack2{...}
    hs.alert.show(hs.inspect.inspect(...), hs.inspect.inspect(args))
    for i, v in pairs(args) do
      print(v)
      if not v then 
        print("FOO")
        return false 
      end
    end
    return true
  end

  return function (...)
    hs.alert.show(hs.inspect.inspect(...))
    if all(...) then
      return func(...)
    else
      return nil
    end
  end
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
function screenMoveMode:exited()  hs.alert.show('Exited mode')  end

screenMoveMode:bind({}, 'escape', function() screenMoveMode:exit() end)
screenMoveMode:bind({}, 'J', function() hs.alert.show("Pressed J") end)

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

hs.hotkey.bind(hyper, "I", function()
  local apps = hs.application.runningApplications()
  local vox = hs.fnutils.filter(apps, function(app) return result(app, 'title') == 'VOX' end)
  local currentlyFocusedWindow = hs.window.focusedWindow()
  
  if vox then
    windows = vox[1]:allWindows()
    window = windows[1]
    window:focus()

    vox[1]:selectMenuItem({"Controls", "Go to Current Track"})
    vox[1]:selectMenuItem({"Edit", "Delete and Move to Trash"})
    
    -- need some sort of timeout here I guess ..
    

    -- Have to use long timeout, else doesn't 
    hs.timer.doAfter(1, function()
      vox[1]:selectMenuItem({"Controls", "Play"})
      currentlyFocusedWindow:focus()
    end)
  end

  
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
