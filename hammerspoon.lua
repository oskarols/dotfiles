flair = "ᕙ(⇀‸↼‶)ᕗ";

hyper = {"cmd", "ctrl", "alt", "shift"}

partial = hs.fnutils.partial
sequence = hs.fnutils.sequence

function centerOnApplication(applicationName) 

end


function test()
	local title = hs.window.focusedWindow():application():title()

	hs.alert.show(title)
end 

appState = {}

function t (table) 
	for key, val in pairs(table) do  -- Table iteration.
	  print(key, val)
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

		hs.alert.show('saving state of ' .. applicationName)


		appState[applicationName] = {
			["screen"] = hs.mouse.getCurrentScreen(),
			["mouse"] =  hs.mouse.getRelativePosition() -- mouse or nil
		}

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

		-- hs.alert.show(hs.inspect.inspect(lastState))

		if lastState then 
			restoreState(lastState)	
		end

		hs.application.launchOrFocus(name)
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
--
-- Automagic reload!
--
function reload_config(files)
    hs.reload()
end
hs.pathwatcher.new(hs.configdir, reload_config):start()
hs.alert.show("Config Re-loaded")
