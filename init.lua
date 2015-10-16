-- hammerspoon config by jmgpena
local mod = {'ctrl', 'alt'}
local mod1 = {'ctrl', 'alt', 'cmd'}
local mod2 = {'ctrl', 'alt', 'shift'}

-- Grid config 6x6 is the simplest size that allows 1/2 and 1/3 windows. This
-- should be more than enough for all use cases
hs.grid.GRIDWIDTH = 12
hs.grid.GRIDHEIGHT = 12
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0
local gw = hs.grid.GRIDWIDTH
local gh = hs.grid.GRIDHEIGHT

local log = hs.logger.new('jmgpena', 'debug')

-- calculate grid positions based on virtual grid size
function gridCalc(size,coords)
  return {
    x = coords.x * gw/size,
    y = coords.y * gh/size,
    w = coords.w * gw/size,
    h = coords.h * gh/size,
  }
end
-- 2x2 grid
function g2(x,y,w,h)
  return gridCalc(2,{x=x,y=y,w=w,h=h})
end
-- 3x3 grid
function g3(x,y,w,h)
  return gridCalc(3,{x=x,y=y,w=w,h=h})
end

hs.window.animationDuration = 0

hs.hints.style = 'vimperator'

local bigscr = "PHL BDM3270"
local laptop = "Color LCD"
local screenWatcher = nil
myScreen = hs.screen.mainScreen():name()

hs.window.animationDuration = 0     -- Disable window animations (janky for iTerm)

function chime()
   local min = os.date('%M') + 0
   local sec = os.date('%S') + 0
   local timeLeft = 0

   if min < 30 then
      timeLeft = (29 - min)*60 + (60-sec)
   else
      timeLeft = (59 - min)*60 + (60-sec)
   end
   hs.alert.show(timeLeft)
   hs.timer.doAfter(timeLeft, showTime)
end

function showTime()
   hs.alert.show(os.date("%X"))
   chime()
end

   -- showTime()
   -- hs.hotkey.bind(mod, 't', showTime)

function fullScreen()
   local win = hs.window.focusedWindow()
   if not win then end

   hs.grid.maximizeWindow()
end

function hints()
   local windows = hs.window.allWindows()
   hs.hints.windowHints(windows)
end

function info()
   local win = hs.window.focusedWindow()
   local app = win:application()
   hs.alert.show(app:title() .. hs.inspect(hs.grid.get(win)))
end

function reload()
   hs.reload()
   hs.alert.show('Config Reloaded')
end

function emacs()
   hs.application.launchOrFocus('Emacs')
end

function emacs_org_capture()
   emacs()
   -- updated for spacemacs keybindings
   hs.eventtap.keyStroke({},'space')
   hs.eventtap.keyStrokes('oc')
end

function win2NextScreen()
  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  win:moveToScreen(win:screen():next())
  hs.grid.snap(win)
end

hs.hotkey.bind(mod, 'r', reload)
hs.hotkey.bind(mod, 'y', hs.toggleConsole)
hs.hotkey.bind(mod, 'f', fullScreen)
hs.hotkey.bind(mod, 'i', info)
hs.hotkey.bind(mod, 'o', win2NextScreen)
hs.hotkey.bind(mod, 'e', emacs)
hs.hotkey.bind({'alt'}, 'tab', hints)

function wMove(dir)
  local win = hs.window.focusedWindow()
   if not win then return end

   local g = hs.grid.get(win)

   if dir       == 'up' then g.y = g.y - 1
     elseif dir == 'down' then g.y = g.y + 1
     elseif dir == 'left' then g.x = g.x - 1
     elseif dir == 'right' then g.x = g.x + 1
   end

   if ((g.x + g.w) <= ( hs.grid.GRIDWIDTH )) and (( g.y + g.h ) <= ( hs.grid.GRIDHEIGHT )) then
     hs.grid.set(win, g, win:screen())
   end
end

function wResize(dir)
   local win = hs.window.focusedWindow()
   if not win then return end

   local g = hs.grid.get(win)

   if dir       == 'up' then g.h = g.h - 1
     elseif dir == 'down' then g.h = g.h + 1
     elseif dir == 'left' then g.w = g.w - 1
     elseif dir == 'right' then g.w = g.w + 1
   end

   hs.grid.set(win, g , win:screen())
end

function wThrowRight(k)
  local win = hs.window.focusedWindow()
  if not win then return end

  local g = hs.grid.get(win)

  g.x = gw / 2
  g.w = gw / 2
  g.y = 0
  g.h = gh

  hs.grid.set(win, g, win:screen())

  if k then
    k:exit()
  end
end

function wThrowLeft(k)
  local win = hs.window.focusedWindow()
  if not win then return end

  local g = hs.grid.get(win)

  g.x = 0
  g.w = gw / 2
  g.y = 0
  g.h = gh

  hs.grid.set(win, g, win:screen())

  if k then
    k:exit()
  end
end

-- modal hotkey config
k = hs.hotkey.modal.new({'ctrl'}, 'space')

function k:entered()
  hs.screen.primaryScreen():setGamma({alpha=1.0,red=0.0,green=0.0,blue=0.0},{blue=0.5,green=0.5,red=0.5})
end

function k:exited()
  hs.screen.primaryScreen():setGamma({alpha=1.0,red=0.0,green=0.0,blue=0.0},{blue=1.0,green=1.0,red=1.0})
end

local layout1 = {
  {app = "Google Chrome", grid = {x=0, y=0, w=5, h=12} },
  {app = "Emacs", grid = {x=5,y=0,w=4,h=8} },
  {app = "iTerm", grid = {x=5,y=7,w=4,h=5} },
  {app = "TweetDeck", grid = {x=9,y=0,w=3,h=7} },
  {app = "Slack", grid = {x=8,y=6,w=4,h=6} }
}

function applyLayout(layout)
  -- loop through the layout and set standard windows
  for k,val in pairs(layout) do
    app = hs.application.find(val.app)
    if app then
      wins = app:allWindows()
      for k,win in pairs(wins) do
        if win:isStandard() then
          hs.grid.set(win,val.grid)
        end
      end
    end
  end
end

k:bind({}, 'escape', function() k:exit() end)
k:bind({}, 'space', function() k:exit() end)
k:bind({'ctrl'}, 'space', function() k:exit() end)
k:bind({}, 'r', reload)
k:bind({}, 'j', function() wMove('down') end)
k:bind({}, 'k', function() wMove('up') end)
k:bind({}, 'h', function() wMove('left') end)
k:bind({}, 'l', function() wMove('right') end)
k:bind({'shift'}, 'j', function() wResize('down') end)
k:bind({'shift'}, 'k', function() wResize('up') end)
k:bind({'shift'}, 'h', function() wResize('left') end)
k:bind({'shift'}, 'l', function() wResize('right') end)
k:bind({}, 'f', function() fullScreen() k:exit() end)
k:bind({}, 'd', function() wThrowRight(k) end)
k:bind({}, 'a', function() wThrowLeft(k) end)
k:bind({}, 'c', function() k:exit() emacs_org_capture() end)
k:bind({}, 'g', function() k:exit() hs.application.launchOrFocus('Google Chrome') end)
k:bind({}, '1', function() k:exit() applyLayout(layout1) end)
k:bind({}, 'o', function() k:exit() win2NextScreen() end)

-- application watcher
-- local apps = {
--   'Slack' = 1
-- }
function appWatcherCallback (name, evType, app)
  if name == 'Slack' and evType == hs.application.watcher.launched then
    win = app:focusedWindow()
    hs.grid.set(win, {x=5,w=5,y=0,h=8}, win:screen())
  end
end
appWatcher = hs.application.watcher.new(appWatcherCallback)
appWatcher:start()
