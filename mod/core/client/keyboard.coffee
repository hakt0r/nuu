###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2018 flyc0r

  This file is part of NUU.

  NUU is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  NUU is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with NUU.  If not, see <http://www.gnu.org/licenses/>.

###

$static 'Kbd', new EventEmitter

Kbd.init = ->
  Kbd    = @
  @help  = {}
  @state = {}
  @mmap  = {}
  @rmap  = {}
  @up    = {}
  @dn    = {}
  window.addEventListener 'keyup',   @onKeyUp.bind @
  window.addEventListener 'keydown', @onKeyDown.bind @
  null

# source: mdn these keycodes should be available on all major platforms
Kbd.workingKeycodes2018 = ["AltLeft","AltRight","ArrowDown","ArrowLeft","ArrowRight","ArrowUp","Backquote","Backslash","Backspace","BracketLeft","BracketRight","CapsLock","Comma","ContextMenu","ControlLeft","ControlRight","Convert","Copy","Cut","Delete","Digit0","Digit1","Digit2","Digit3","Digit4","Digit5","Digit6","Digit7","Digit8","Digit9","End","Enter","Equal","Escape","F1","F10","F11","F12","F13","F14","F15","F16","F17","F18","F19","F2","F20","F3","F4","F5","F6","F7","F8","F9","Find","Help","Home","Insert","IntlBackslash","KeyA","KeyB","KeyC","KeyD","KeyE","KeyF","KeyG","KeyH","KeyI","KeyJ","KeyK","KeyL","KeyM","KeyN","KeyO","KeyP","KeyQ","KeyR","KeyS","KeyT","KeyU","KeyV","KeyW","KeyX","KeyY","KeyZ","Minus","NonConvert","NumLock","Numpad0","Numpad1","Numpad2","Numpad3","Numpad4","Numpad5","Numpad6","Numpad7","Numpad8","Numpad9","NumpadAdd","NumpadDecimal","NumpadDivide","NumpadEnter","NumpadEqual","NumpadMultiply","NumpadSubtract","Open","OSLeft","OSRight","PageDown","PageUp","Paste","Pause","Period","PrintScreen","Props","Quote","ScrollLock","Select","Semicolon","ShiftLeft","ShiftRight","Slash","Space","Tab","Undo"]

Kbd.macro = (name,key,d10,func)->
  NUU.settings.bind = {} unless NUU.settings.bind?
  key = NUU.settings.bind[name] || key
  console.log key, name, NUU.settings.bind[name]? if debug
  @macro[name] = func
  @bind key, name if key
  @d10[name] = d10

Kbd.bind = (combo,macro,opt) ->
  opt = @macro[macro] unless opt?
  delete @rmap[combo]
  delete @help[combo]
  return console.log ':kbd', 'bind:opt:undefined', macro, key, combo, opt unless opt?
  opt = up: opt if typeof opt is 'function'
  key = combo.replace /^[cas]+/,''
  return console.log ':kbd', 'bind:key:unknown', macro, key, combo, opt if -1 is @workingKeycodes2018.indexOf key
  console.log ':kbd', 'bind', combo, opt if debug
  @up[macro] = opt.up if opt.up?
  @dn[macro] = opt.dn if opt.dn?
  @mmap[macro] = combo
  @rmap[combo] = macro
  @help[combo] = macro
  @state[key] = off

Kbd.onKeyDown = (e) ->
  # allow some browser-wide shortcuts that would otherwise not work
  return if e.ctrlKey and e.code is 'KeyC'                if isClient
  return if e.ctrlKey and e.code is 'KeyV'                if isClient
  return if e.ctrlKey and e.code is 'KeyR'                if isClient
  return if e.ctrlKey and e.code is 'KeyL'                if isClient
  # allow the inspector; but only in debug mode ;)
  return if e.ctrlKey and e.shiftKey and e.code is 'KeyI' if debug
  code = e.code
  code = 'c' + code if e.ctrlKey
  code = 'a' + code if e.altKey
  code = 's' + code if e.shiftKey
  if @onkeydown
    return @onkeydown e, code
  return true if @onkeyup
  e.preventDefault() unless e.allowDefault
  macro = @rmap[code]
  notice 500, "d[#{code}]:#{macro} #{e.code}" if debug
  return if @state[code] is true
  @state[code] = true
  @dn[macro](e) if @dn[macro]?

Kbd.onKeyUp = (e) ->
  e.preventDefault()
  code = e.code
  code = 'c' + code if e.ctrlKey
  code = 'a' + code if e.altKey
  code = 's' + code if e.shiftKey
  return @onkeyup e, code if @onkeyup
  macro = @rmap[code]
  notice 500, "u[#{code}]:#{macro}" if debug
  return if @state[code] is false
  @state[code] = false
  @up[macro](e) if @up[macro]?

Kbd.stack = []

Kbd.clearHooks = (key)->
  @focus = null
  document.removeEventListener 'paste', @onpaste if @onpaste
  delete @onpaste
  delete @onkeyup
  delete @onkeydown
  true

Kbd.grab = (focus,opts)->
  # console.log ':kbd', 'grab', focus.name if debug
  if @focus
    if @focus is focus and opts.onkeydown is @onkeydown and opts.onkeyup is @onkeyup and opts.onpaste is @onpaste
      console.log ':kbd', 'same', @focus.name if debug
    else
      console.log ':kbd', 'obscure', @focus.name # if debug
      @stack.push focus:@focus, onkeydown:@onkeydown, onkeyup:@onkeyup, onpaste:@onpaste
      do @clearHooks
  else
    console.log ':kbd', 'grab', focus.name if debug
  @focus = focus
  Object.assign @, opts
  @focus.raise() if @focus.raise?
  document.addEventListener 'paste', @onpaste if @onpaste
  Mouse.disable() if @hadMouse = Mouse.state
  # console.log ':kbd', 'grabbed', @focus.name  if debug
  true

Kbd.release = (focus)->
  if @focus is focus
    console.log ':kbd', 'release_current', focus.name if debug
    do @clearHooks
    if @stack.length is 0
      console.log ':kbd', 'main-focus' if debug
      Mouse.enable() if @hadMouse
      return true
    item = @stack.pop()
    @grab item.focus, item
    console.log ':kbd', 'main' unless @focus if debug
    true
  else if @stack.length > 0 and item = @stack.reverse().reduce( (v,c=no)-> if v.focus is focus then v else c )
    console.log ':kbd', 'release_obscured', focus.name if debug
    Array.splice idx, 0 if idx = @stack.indexOf item
    console.log ':kbd', 'main' unless @focus if debug
    true
  else false

Kbd.defaultMap =
  boost:      'sArrowUp'
  accel:      'ArrowUp'
  retro:      'ArrowDown'
  left:  'ArrowLeft'
  right: 'ArrowRight'

Kbd.d10 =
  execute:    "Execute something"
  accel:      "Accelerate"
  retro:      "Decelerate"
  left:  "Turn left"
  right: "Turn right"
  autopilot:  "Turn to target"
  escape:     "Exit something"
  boost:      "Boost"

do Kbd.init
