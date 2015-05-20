flair = "ᕙ(⇀‸↼‶)ᕗ";

hyper = {"cmd", "ctrl", "alt", "shift"}

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

function centerOnApplication(applicationName) 
	-- hs.geometry.rectMidPoint(rect) -> point
end

local mouseCircle = nil
local mouseCircleTimer = nil

function mouseHighlight()
    -- Delete an existing highlight if it exists
    if mouseCircle then
        mouseCircle:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
    end
    -- Get the current co-ordinates of the mouse pointer
    mousepoint = hs.mouse.get()
    -- Prepare a big red circle around the mouse pointer
    mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
    mouseCircle:setFillColor({["red"]=0,["blue"]=1,["green"]=0,["alpha"]=0.5})
    mouseCircle:setStrokeWidth(0)
    mouseCircle:show()

    -- Set a timer to delete the circle after 3 seconds
    mouseCircleTimer = hs.timer.doAfter(0.2, function() mouseCircle:delete() end)
end



function test()
	local title = hs.window.focusedWindow():application():title()

	hs.alert.show(title)
end 

appState = {}

unpack = table.unpack

function t (table) 
	for key, val in pairs(table) do  -- Table iteration.
	  print(key, val)
	end
end

-- https://gist.github.com/walterlua/978150
table.indexOf = function(t, object)
    if "table" == type(t) then
        for i = 1, #t do
            if object == t[i] then
                return i
            end
        end
        return -1
    else
        error("table.indexOf expects table for first argument, " .. type(t) .. " given")
    end
end

local NIL = {} -- placeholder value for nil, storable in table.
function pack2(...)
  local n = select('#', ...)
  local t = {...}
  for i = 1,n do
    if t[i] == nil then
      t[i] = NIL
    end
  end
  return t
end

function unpack2(t, k, n)
  k = k or 1
  n = n or #t
  if k > n then return end
  local v = t[k]
  if v == NIL then v = nil end
  return v, unpack2(t, k + 1, n)
end

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

inspect = hs.inspect.inspect

function tt(a)
	hs.alert.show(inspect(a))
end

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

-- function mm(a) print(a.." you're a real peopleperson!") end
-- mm = maybe(mm)
-- mm(nil)

function maybe (func)
	return function (argument)
		if argument then
			return func(argument)
		else
			return nil
		end
	end
end

function launchOrFocus(name)

	-- switching to an app, states:
	-- * focusing an app
	-- * focusing an app, mouse over another app
	local saveState = function()
		local window = hs.window.focusedWindow()
		
		if window == nil then 
			return nil
		end

		local applicationName = window:application()

		if applicationName == nil then 
			return nil
		end

		applicationName = applicationName:title()

		appState[applicationName] = {
			["screen"] = hs.mouse.getCurrentScreen(),
			["mouse"] =  hs.mouse.getRelativePosition() -- mouse or nil
		}
	end

	-- TODO: WIP
	local saveStateFunctional = function()
		local window = hs.window.focusedWindow()

		function getApplication(window)
			return window:application()
		end

		function getApplicationTitle(application)
			return application:title()
		end

		function saveApplication (applicationName)
			hs.alert.show('saving state of ' .. applicationName)
			appState[applicationName] = {
				["screen"] = hs.mouse.getCurrentScreen(),
				["mouse"] =  hs.mouse.getRelativePosition() -- mouse or nil
			}
		end

		-- compose(
		-- 	maybe(getApplication),
		-- 	maybe(getApplicationTitle)
		-- 	maybe(saveApplication)
		-- )(hs.window.focusedWindow)

	end


	local lookupState = function(applicationName)
		return appState[applicationName]
	end

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

-- disable animations
hs.window.animationDuration = 0

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
	windowFrame.x = screenFrame.x
	windowFrame.y = screenFrame.y
	windowFrame.w = screenFrame.w
	windowFrame.h = screenFrame.h
	window:setFrame(windowFrame)
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

hs.hotkey.bind(hyper, "Q", test)
hs.hotkey.bind(hyper, "1", launchOrFocus("Sublime Text"))
hs.hotkey.bind(hyper, "2", launchOrFocus("iTerm"))
hs.hotkey.bind(hyper, "3", launchOrFocus("Google Chrome"))
hs.hotkey.bind(hyper, "4", launchOrFocus("Firefox"))
hs.hotkey.bind(hyper, "5", launchOrFocus("Evernote"))
hs.hotkey.bind(hyper, "6", launchOrFocus("Spotify"))

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

	hs.applescript.applescript(string.format(script, language))
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
