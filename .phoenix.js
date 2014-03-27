var padding = 0;
var rageOfDongers = "ヽ༼ ಠ益ಠ ༽ﾉ";

//////////////////////////////
// MousePosition extensions //
//////////////////////////////

MousePosition.centerOn = function(point, rect) {
  MousePosition.restore({
    x: point.x + (rect.width  / 2),
    y: point.y + (rect.height / 2)
  });
}

MousePosition.centerOnWindow = function(window) {
  var size = window.size(),
      topLeft = window.topLeft();

  MousePosition.centerOn(topLeft, size);
}


//////////////////////
// Window extension //
//////////////////////

var lastFrames = {};

Window.prototype.rememberFrame = function() {
  lastFrames[this] = this.frame();
}

Window.prototype.forgetFrame = function() {
  delete lastFrames[this];
}

Window.prototype.rollbackFullscreen = function() {
  this.setFrame(lastFrames[this]);
  this.forgetFrame();
}

Window.prototype.toFullscreen = function() {
  this.rememberFrame();
  this.toGrid(0, 0, 1, 1);
}

Window.prototype.toggleFullscreen = function() {
  if (lastFrames[this]) {
    this.rollbackFullscreen();
  } else {
    this.toFullscreen();
  }
  return this;
}

Window.prototype.toGrid = function(x, y, width, height) {
  windowToGrid(this, x, y, width, height);
  return this;
}

Window.prototype.centerCursor = function() {
  MousePosition.centerOnWindow(this);
  return this;
}


////////////////////
// App Extensions //
////////////////////

var appStateSnapshots = {};
var savedTitle = undefined;

App.allWithTitle = function(title) {
  return _(this.runningApps()).filter(function(app) {
    return app.title() === title;
  });
};

App.focusOrStart = function (title) {
  var apps = App.allWithTitle(title),
      restoreCursor = false,
      previouslyStartedAnotherApp = (savedTitle !== title),
      previouslyStartedThisApp = (savedTitle === title && appStateSnapshots[title]);

  if (previouslyStartedAnotherApp || previouslyStartedThisApp)
    appStateSnapshots[savedTitle] = MousePosition.capture();

  if (appStateSnapshots[title]) {
    restoreCursor = true;
    MousePosition.restore(appStateSnapshots[title]);
  }

  savedTitle = title;

  if (_.isEmpty(apps)) {
    api.alert(rageOfDongers + " Starting " + title);
    api.launch(title);
    return;
  }

  var activeWindows = _.chain(apps)
    .map(function(x) { return x.allWindows(); })
    .flatten()
    .reject(function(win) { return win.isWindowMinimized(); })
    .tap(function(all) {
      _.invoke(all, 'focusWindow');
      if (!restoreCursor) _.invoke(all, 'centerCursor');
    })
    .value();

  if (_.isEmpty(activeWindows)) api.alert(" All windows minimized for " + title);
};

App.prototype.findWindow = function(findBy) {
  return _.find(this.visibleWindows(), findBy);
};

App.prototype.findWindowMatchingTitle = function(title) {
  var regexp = new RegExp(title);

  return this.findWindow(function(win) {
    return regexp.test(win.title());
  });
};

App.prototype.findWindowNotMatchingTitle = function(title) {
  var regexp = new RegExp(title);

  return this.findWindow(function(win) {
    return !regexp.test(win.title());
  });
};

///////////////////////////
// Misc Helper Functions //
///////////////////////////

// This method can be used to push a window to a certain position and size on
// the screen by using four floats instead of pixel sizes.  Examples:
//
//     // Window position: top-left; width: 25%, height: 50%
//     someWindow.toGrid( 0, 0, 0.25, 0.5 );
//
//     // Window position: 30% top, 20% left; width: 50%, height: 35%
//     someWindow.toGrid( 0.3, 0.2, 0.5, 0.35 );
//
// The window will be automatically focused.  Returns the window instance.
function windowToGrid(window, x, y, width, height) {
  var screen = window.screen().frameWithoutDockOrMenu();

  window.setFrame({
    x:      Math.round( x *      screen.width )  + padding + screen.x,
    y:      Math.round( y *      screen.height ) + padding + screen.y,
    width:  Math.round( width *  screen.width )  - ( 2 * padding ),
    height: Math.round( height * screen.height ) - ( 2 * padding )
  });

  window.focusWindow();

  return window;
}

// Move windows between monitors

function moveToScreen(win, screen) {
  if (!screen) return;

  var frame = win.frame();
  var oldScreenRect = win.screen().frameWithoutDockOrMenu();
  var newScreenRect = screen.frameWithoutDockOrMenu();

  var xRatio = newScreenRect.width / oldScreenRect.width;
  var yRatio = newScreenRect.height / oldScreenRect.height;

  win.setFrame({
    x: (Math.round(frame.x - oldScreenRect.x) * xRatio) + newScreenRect.x,
    y: (Math.round(frame.y - oldScreenRect.y) * yRatio) + newScreenRect.y,
    width: Math.round(frame.width * xRatio),
    height: Math.round(frame.height * yRatio)
  });

  refocusWindow(win);
}

function circularLookup(array, index) {
  if (index < 0)
    return array[array.length + (index % array.length)];
  return array[index % array.length];
}

function rotateMonitors(offset) {
  var win = Window.focusedWindow();
  var currentScreen = win.screen();
  var screens = [currentScreen];
  for (var x = currentScreen.previousScreen(); x != win.screen(); x = x.previousScreen()) {
    screens.push(x);
  }

  screens = _(screens).sortBy(function(s) { return s.frameWithoutDockOrMenu().x; });
  var currentIndex = _(screens).indexOf(currentScreen);
  moveToScreen(win, circularLookup(screens, currentIndex + offset));
}

function leftOneMonitor() {
  rotateMonitors(-1);
}

function rightOneMonitor() {
  rotateMonitors(1);
}

/////////////////
// Keybindings //
/////////////////

// A composite modifier key. Almost guaranteed to not clash with any application / OS keybindings.
var hyper = ['cmd', 'alt', 'shift', 'ctrl'];

api.bind('f', hyper, function() { Window.focusedWindow().toggleFullscreen().centerCursor(); });
api.bind('d', hyper, function() { Window.focusedWindow().centerCursor(); });

api.bind('q', hyper, rightOneMonitor);
api.bind('e', hyper, leftOneMonitor);

api.bind('1', hyper, function() { App.focusOrStart('Sublime Text');  });
api.bind('2', hyper, function() { App.focusOrStart('iTerm');         });
api.bind('3', hyper, function() { App.focusOrStart('Google Chrome'); });
api.bind('4', hyper, function() { App.focusOrStart('Firefox');       });
api.bind('5', hyper, function() { App.focusOrStart('Evernote');      });
api.bind('6', hyper, function() { App.focusOrStart('Spotify');       });
api.bind('7', hyper, function() { App.focusOrStart('Colloquy');      });
api.bind('8', hyper, function() { App.focusOrStart('Skype');         });