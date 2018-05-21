###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2008 flyc0r

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

$static 'Kbd', new class KeyboardInput extends EventEmitter

  # source: mdn these keycodes should be available on all major platforms
  workingKeycodes2018:["AltLeft","AltRight","ArrowDown","ArrowLeft","ArrowRight","ArrowUp","Backquote","Backslash","Backspace","BracketLeft","BracketRight","CapsLock","Comma","ContextMenu","ControlLeft","ControlRight","Convert","Copy","Cut","Delete","Digit0","Digit1","Digit2","Digit3","Digit4","Digit5","Digit6","Digit7","Digit8","Digit9","End","Enter","Equal","Escape","F1","F10","F11","F12","F13","F14","F15","F16","F17","F18","F19","F2","F20","F3","F4","F5","F6","F7","F8","F9","Find","Help","Home","Insert","IntlBackslash","KeyA","KeyB","KeyC","KeyD","KeyE","KeyF","KeyG","KeyH","KeyI","KeyJ","KeyK","KeyL","KeyM","KeyN","KeyO","KeyP","KeyQ","KeyR","KeyS","KeyT","KeyU","KeyV","KeyW","KeyX","KeyY","KeyZ","Minus","NonConvert","NumLock","Numpad0","Numpad1","Numpad2","Numpad3","Numpad4","Numpad5","Numpad6","Numpad7","Numpad8","Numpad9","NumpadAdd","NumpadDecimal","NumpadDivide","NumpadEnter","NumpadEqual","NumpadMultiply","NumpadSubtract","Open","OSLeft","OSRight","PageDown","PageUp","Paste","Pause","Period","PrintScreen","Props","Quote","ScrollLock","Select","Semicolon","ShiftLeft","ShiftRight","Slash","Space","Tab","Undo"]

  # source: trial and error
  kmap:  { "(":57, ")":48, '~':192 ,"/":191,"capslock":20,"+":109, "-":107, "-":107, ",":188, ".":190, bksp:8, tab:9, return:13, ' ':32, pgup:33, pgdn:34, esc:27, left:37, up:38, right:39, down:40, del:46, 0:48, 1:49, 2:50, 3:51, 4:52, 5:53, 6:54, 7:55, 8:56, 9:57, a:65, b:66, c:67, d:68, e:69, f:70, g:71, h:72, i:73, j:74, k:75, l:76, m:77, n:78, o:79, p:80, q:81, r:82, s:83, t:84, u:85, v:86, w:87, x:88, y:89, z:90 }

  defaultMap:
    accel: 'ArrowUp'
    boost: 'sArrowUp'
    retro: 'ArrowDown'
    steerLeft: 'ArrowLeft'
    steerRight: 'ArrowRight'

  d10:
    execute:          "Execute something"
    accel:            "Accelerate"
    retro:            "Decellerate"
    steerLeft:        "Turn left"
    steerRight:       "Turn right"
    autopilot:        "Turn to target"
    escape:           "Exit something"
    boost:            "Boost"

  help:  {}
  state: {}
  cmap:  {}
  mmap:  {}
  rmap:  {}
  _up:   {}
  _dn:   {}

  constructor:->
    Kbd = @
    @cmap[v] = k for k,v of @kmap
    for a in ["accel","retro","steerRight","steerLeft","boost"]
      @macro a, @defaultMap[a], @d10[a], up: @setState(a,false), dn: @setState(a,true)
    null

  setState: (key,value)-> =>
    @state[@mmap[key]] = value
    rid = 0
    rid = VEHICLE.relto.id if VEHICLE.relto
    NET.state.write(VEHICLE,[
      @state[@mmap["accel"]],
      @state[@mmap["retro"]],
      @state[@mmap["steerRight"]],
      @state[@mmap["steerLeft"]],
      @state[@mmap["boost"]],
      0,0,rid])

  macro:(name,key,d10,func)->
    app.settings.bind = {} unless app.settings.bind?
    key = app.settings.bind[name] || key
    console.log key, name, app.settings.bind[name]? if debug
    @macro[name] = func
    @bind key, name
    @d10[name] = d10

  bind: (combo,macro,opt) =>
    opt = @macro[macro] unless opt?
    delete @rmap[combo]
    delete @help[combo]
    return console.log 'bind:opt:undefined', macro, key, combo, opt unless opt?
    opt = up: opt if typeof opt is 'function'
    key = combo.replace /^[cas]/,''
    return console.log 'bind:key:unknown', macro, key, combo, opt if -1 is @workingKeycodes2018.indexOf key
    console.log '$bind', combo, opt
    @_up[macro] = opt.up if opt.up?
    @_dn[macro] = opt.dn if opt.dn?
    @mmap[macro] = combo
    @rmap[combo] = macro
    @help[combo] = macro
    @state[key] = off

  __dn: (e) =>
    code = e.code
    code = 'c'+code if e.ctrlKey
    code = 'a'+code if e.altKey
    code = 's'+code if e.shiftKey
    macro = @rmap[code]
    notice 500, "d[#{code}]:#{macro} #{e.code}" if debug
    return if @state[code] is true
    @state[code] = true
    @_dn[macro](e) if @_dn[macro]?
    e.preventDefault()

  __up: (e) =>
    code = e.code
    code = 'c'+code if e.ctrlKey
    code = 'a'+code if e.altKey
    code = 's'+code if e.shiftKey
    macro = @rmap[code]
    notice 500, "u[#{code}]:#{macro}" if debug
    return if @state[code] is false
    @state[code] = false
    @_up[macro](e) if @_up[macro]?
    e.preventDefault()

  focus: =>
    window.addEventListener 'keydown', @__dn
    window.addEventListener 'keyup',   @__up

  unfocus: =>
    window.removeEventListener 'keydown', @__dn
    window.removeEventListener 'keyup',   @__up

Kbd.macro 'debug', 'sBackquote', 'Debug', ->
  window.debug = not debug

Kbd.macro 'debark', 'sKeyQ', 'Leave vehicle', ->
  NET.json.write switchShip: 'Exosuit' unless VEHICLE and VEHICLE.class is 'Exosuit'

Kbd.macro 'weapNext',    'Digit1', 'Next weapon (primary)', ->
  VEHICLE.nextWeap(NUU.player)

Kbd.macro 'weapPrev',    'sDigit1', 'Previous weapon (primary)', ->
  VEHICLE.prevWeap(NUU.player)

Kbd.macro 'weapNextSec', 'Digit2', 'Next weapon (secondary)', ->
  VEHICLE.nextWeap(NUU.player,'secondary')

Kbd.macro 'weapPrevSec', 'sDigit2', 'Previous weapon (secondary)', ->
  VEHICLE.prevWeap(NUU.player,'secondary')

Kbd.macro 'primaryTrigger', 'Space', 'Primary trigger',
  dn:-> if f = NUU.player.primary.trigger then do f
  up:-> if f = NUU.player.primary.release then do f

Kbd.macro 'secondaryTrigger', 'KeyX', 'Secondary trigger',
  dn:-> if f = NUU.player.secondary.trigger then do f
  up:-> if f = NUU.player.secondary.release then do f
