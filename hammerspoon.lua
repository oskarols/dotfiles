flair = "ᕙ(⇀‸↼‶)ᕗ";

hyper = {"cmd", "ctrl", "alt", "shift"}

partial = hs.fnutils.partial
sequence = hs.fnutils.sequence

function launchOrFocus(name)
	return function()
		hs.application.launchOrFocus(name)
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
