###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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

$static 'Kbd', new class KeyboardInput extends EventEmitter

  # source: mdn these keycodes should be available on all major platforms
  workingKeycodes2018:["AltLeft","AltRight","ArrowDown","ArrowLeft","ArrowRight","ArrowUp","Backquote","Backslash","Backspace","BracketLeft","BracketRight","CapsLock","Comma","ContextMenu","ControlLeft","ControlRight","Convert","Copy","Cut","Delete","Digit0","Digit1","Digit2","Digit3","Digit4","Digit5","Digit6","Digit7","Digit8","Digit9","End","Enter","Equal","Escape","F1","F10","F11","F12","F13","F14","F15","F16","F17","F18","F19","F2","F20","F3","F4","F5","F6","F7","F8","F9","Find","Help","Home","Insert","IntlBackslash","KeyA","KeyB","KeyC","KeyD","KeyE","KeyF","KeyG","KeyH","KeyI","KeyJ","KeyK","KeyL","KeyM","KeyN","KeyO","KeyP","KeyQ","KeyR","KeyS","KeyT","KeyU","KeyV","KeyW","KeyX","KeyY","KeyZ","Minus","NonConvert","NumLock","Numpad0","Numpad1","Numpad2","Numpad3","Numpad4","Numpad5","Numpad6","Numpad7","Numpad8","Numpad9","NumpadAdd","NumpadDecimal","NumpadDivide","NumpadEnter","NumpadEqual","NumpadMultiply","NumpadSubtract","Open","OSLeft","OSRight","PageDown","PageUp","Paste","Pause","Period","PrintScreen","Props","Quote","ScrollLock","Select","Semicolon","ShiftLeft","ShiftRight","Slash","Space","Tab","Undo"]

  defaultMap:
    boost:      'sArrowUp'
    accel:      'ArrowUp'
    retro:      'ArrowDown'
    steerLeft:  'ArrowLeft'
    steerRight: 'ArrowRight'

  d10:
    execute:          "Execute something"
    accel:            "Accelerate"
    retro:            "Decelerate"
    steerLeft:        "Turn left"
    steerRight:       "Turn right"
    autopilot:        "Turn to target"
    escape:           "Exit something"
    boost:            "Boost"

  help:  {}
  state: {}
  mmap:  {}
  rmap:  {}
  _up:   {}
  _dn:   {}

  constructor:->
    Kbd = @
    $ =>
      $('body').prepend @input$ = $ """<input type="text" id="nKeyboardInput">"""
      window.addEventListener 'keydown', @onKeyDown
      window.addEventListener 'keyup',   @onKeyUp
      @input$.focus()
    for a in ["accel","retro","steerRight","steerLeft","boost"]
      @macro a, @defaultMap[a], @d10[a], up: @setState(a,false), dn: @setState(a,true)
    null
  grab:(name,@callbackHandler,@callbackHandlerUp,@callbackHandlerPaste)->
    document.addEventListener 'paste', @callbackHandlerPaste if @callbackHandlerPaste
  release:->
    document.removeEventListener 'paste', @callbackHandlerPaste if @callbackHandlerPaste
    delete @callbackHandlerPaste
    delete @callbackHandlerUp
    delete @callbackHandler

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
    NUU.settings.bind = {} unless NUU.settings.bind?
    key = NUU.settings.bind[name] || key
    console.log key, name, NUU.settings.bind[name]? if debug
    @macro[name] = func
    @bind key, name
    @d10[name] = d10

  bind: (combo,macro,opt) =>
    opt = @macro[macro] unless opt?
    delete @rmap[combo]
    delete @help[combo]
    return console.log ':kbd', 'bind:opt:undefined', macro, key, combo, opt unless opt?
    opt = up: opt if typeof opt is 'function'
    key = combo.replace /^[cas]+/,''
    return console.log ':kbd', 'bind:key:unknown', macro, key, combo, opt if -1 is @workingKeycodes2018.indexOf key
    console.log ':kbd', 'bind', combo, opt if debug
    @_up[macro] = opt.up if opt.up?
    @_dn[macro] = opt.dn if opt.dn?
    @mmap[macro] = combo
    @rmap[combo] = macro
    @help[combo] = macro
    @state[key] = off

  onKeyDown: (e) =>
    # allow some browser-wide shortcuts that would otherwise not work
    return if e.ctrlKey and e.code is 'KeyC'                if isClient
    return if e.ctrlKey and e.code is 'KeyV'                if isClient
    return if e.ctrlKey and e.code is 'KeyR'                if isClient
    return if e.ctrlKey and e.code is 'KeyL'                if isClient
    # allow the inspector; but only in debug mode ;)
    return if e.ctrlKey and e.shiftKey and e.code is 'KeyI' if debug
    e.preventDefault()
    code = e.code
    code = 'c'+code if e.ctrlKey
    code = 'a'+code if e.altKey
    code = 's'+code if e.shiftKey
    return @callbackHandler e, code if @callbackHandler
    macro = @rmap[code]
    notice 500, "d[#{code}]:#{macro} #{e.code}" if debug
    return if @state[code] is true
    @state[code] = true
    @_dn[macro](e) if @_dn[macro]?

  onKeyUp: (e) =>
    e.preventDefault()
    code = e.code
    code = 'c'+code if e.ctrlKey
    code = 'a'+code if e.altKey
    code = 's'+code if e.shiftKey
    return if @callbackHandler
    macro = @rmap[code]
    notice 500, "u[#{code}]:#{macro}" if debug
    return if @state[code] is false
    @state[code] = false
    @_up[macro](e) if @_up[macro]?

Kbd.macro 'debug', 'sBackquote', 'Debug', ->
  window.debug = not debug

Kbd.macro 'mountNext',   'KeyM', 'Next mount', ->
  m = ++NUU.player.mountId % VEHICLE.mount.length
  NET.json.write switchMount: m

Kbd.macro 'weapPri1', 'Digit1', 'Set primary #1', -> VEHICLE.setWeap 0
Kbd.macro 'weapPri2', 'Digit2', 'Set primary #2', -> VEHICLE.setWeap 1
Kbd.macro 'weapPri3', 'Digit3', 'Set primary #3', -> VEHICLE.setWeap 2
Kbd.macro 'weapPri4', 'Digit4', 'Set primary #4', -> VEHICLE.setWeap 3
Kbd.macro 'weapPri5', 'Digit5', 'Set primary #5', -> VEHICLE.setWeap 4
Kbd.macro 'weapPri6', 'Digit6', 'Set primary #6', -> VEHICLE.setWeap 5
Kbd.macro 'weapPri7', 'Digit7', 'Set primary #7', -> VEHICLE.setWeap 6
Kbd.macro 'weapPri8', 'Digit8', 'Set primary #8', -> VEHICLE.setWeap 7

Kbd.macro 'weapNext',    'F1', 'Next weapon (primary)',       -> VEHICLE.nextWeap(NUU.player)
Kbd.macro 'weapPrev',    'F2', 'Previous weapon (primary)',   -> VEHICLE.prevWeap(NUU.player)
Kbd.macro 'weapNextSec', 'F3', 'Next weapon (secondary)',     -> VEHICLE.nextWeap(NUU.player,'secondary')
Kbd.macro 'weapPrevSec', 'F4', 'Previous weapon (secondary)', -> VEHICLE.prevWeap(NUU.player,'secondary')

Kbd.macro 'primaryTrigger', 'Space', 'Primary trigger',
  dn:-> if f = NUU.player.primary.trigger then do f
  up:-> if f = NUU.player.primary.release then do f

Kbd.macro 'secondaryTrigger', 'KeyX', 'Secondary trigger',
  dn:-> if f = NUU.player.secondary.trigger then do f
  up:-> if f = NUU.player.secondary.release then do f
