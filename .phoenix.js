var hyper = ['cmd', 'alt', 'shift', 'ctrl'];

api.bind('E', ['cmd'], function() {
  var win = Window.focusedWindow();
  var frame = win.frame();
  frame.x += 10;
  frame.height -= 10;
  win.setFrame(frame);
  return true;
});



//https://github.com/jakemcc/dotfiles/blob/master/phoenix.js
// Start/select apps
App.allWithTitle = function( title ) {
  return _(this.runningApps()).filter( function( app ) {
    if (app.title() === title) {
      return true;
    }
  });
};

var rageOfDongers="ヽ༼ ಠ益ಠ ༽ﾉ";


App.focusOrStart = function ( title ) {
  var apps = App.allWithTitle( title );
  if (_.isEmpty(apps)) {
    api.alert(rageOfDongers + " Starting " + title);
    api.launch(title)
    return;
  }

  var windows = _.chain(apps)
    .map(function(x) { return x.allWindows(); })
    .flatten()
    .value();

  activeWindows = _(windows).reject(function(win) { return win.isWindowMinimized();});
  if (_.isEmpty(activeWindows)) {
    api.alert(" All windows minimized for " + title);
    return;
  }

  activeWindows.forEach(function(win) {
    win.focusWindow();
  });
};

api.bind('1', hyper, function() {App.focusOrStart('Sublime Text');});
api.bind('2', hyper, function() {App.focusOrStart('iTerm');});
api.bind('3', hyper , function() {App.focusOrStart('Google Chrome');});
api.bind('6', hyper , function() {App.focusOrStart('Spotify');});