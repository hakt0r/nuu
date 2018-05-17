###

  * c) 2007-2016 Sebastian Glaser <anx@ulzq.de>
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

  kmap:  { "/":191,"capslock":20,"+":109, "-":107, "-":107, ",":188, ".":190, bksp:8, tab:9, return:13, ' ':32, pgup:33, pgdn:34, esc:27, left:37, up:38, right:39, down:40, del:46, 0:48, 1:49, 2:50, 3:51, 4:52, 5:53, 6:54, 7:55, 8:56, 9:57, a:65, b:66, c:67, d:68, e:69, f:70, g:71, h:72, i:73, j:74, k:75, l:76, m:77, n:78, o:79, p:80, q:81, r:82, s:83, t:84, u:85, v:86, w:87, x:88, y:89, z:90 }
  _up:   {}
  _dn:   {}
  mmap:  {}
  help:  {}
  state: {}
  rmap:  {}

  constructor:->
    Kbd = @

    @defaultMap =
      accel: 'up'
      boost: 'Sup'
      retro: 'down'
      steerLeft: 'left'
      steerRight: 'right'

    if navigator.appVersion.match(/WebKit/g)?
      @layout = "mac/webkit"
      @kmap["+"] = 187; @kmap["-"] = 189
    else if navigator.appName.match(/Netscape/g)? and navigator.appVersion.match(/Macintosh/g)?
      @layout = "mac/mozilla"
    else if navigator.appName.match(/Netscape/g)? and navigator.appVersion.match(/X11/g)?
      @layout = "unix/mozilla"

    sendAction = =>
      rid = 0
      rid = VEHICLE.relto.id if VEHICLE.relto
      NET.state.write(VEHICLE,[
        @state[@mmap["accel"]] || Mouse.accel,
        @state[@mmap["retro"]],
        @state[@mmap["steerRight"]],
        @state[@mmap["steerLeft"]],
        @state[@mmap["boost"]],
        0,0,rid])

    @setState = (key,value)=> sendAction @state[@mmap[key]] = value

    @cmap = {}
    @cmap[v] = k for k,v of @kmap
    for macro in ["accel","retro","steerRight","steerLeft","boost"]
      @macro macro, @defaultMap[macro], @d10[macro], up: sendAction, dn: sendAction
    null

  macro:(name,key,d10,func)->
    console.log key, name
    @macro[name] = func
    @bind key, name
    @d10[name] = d10

  __dn: (e) =>
    code = e.keyCode
    code = 'S'+code if e.shiftKey
    macro = @rmap[code]
    return if @state[code] is true
    notice 100, "d[#{code}]:#{macro}"
    @state[code] = true
    @_dn[macro](e) if @_dn[macro]?
    e.preventDefault()

  __up: (e) =>
    code = e.keyCode
    code = 'S'+code if e.shiftKey
    macro = @rmap[code]
    return if @state[code] is false
    notice 100, "u[#{code}]:#{macro}"
    @state[code] = false
    @_up[macro](e) if @_up[macro]?
    e.preventDefault()

  bind: (key,macro,opt) =>
    opt = @macro[macro] unless opt?
    opt = up: opt if typeof opt is 'function'
    unless opt?
      console.log 'misbind', key, macro, opt
      return
    @_up[macro] = opt.up if opt.up?
    @_dn[macro] = opt.dn if opt.dn?
    if key.match /S/
      keyCode = 'S' + @kmap[key.replace /^S/, '']
    else keyCode = @kmap[key]
    @mmap[macro] = keyCode
    @state[keyCode] = off
    @rmap[keyCode] = macro
    @help[key] = macro

  focus: =>
    $(window).on 'keydown', @__dn
    $(window).on 'keyup', @__up

  unfocus: =>
    $(window).off 'keydown', @__dn
    $(window).off 'keyup', @__up

  d10:
    execute:          "Execute something"
    accel:            "Accelerate"
    retro:            "Decellerate"
    steerLeft:        "Turn left"
    steerRight:       "Turn right"
    autopilot:        "Turn to target"
    escape:           "Exit something"
    boost:            "Boost"

Kbd.macro 'debark',    'Sq', 'Leave current vehicle', ->
  NET.json.write switchShip: 'Exosuit' unless VEHICLE and VEHICLE.class is 'Exosuit'

Kbd.macro 'weapNext',    'i', 'Next weapon (primary)', ->
  VEHICLE.nextWeap(NUU.player)

Kbd.macro 'weapPrev',    'o', 'Previous weapon (primary)', ->
  VEHICLE.prevWeap(NUU.player)

Kbd.macro 'weapNextSec', 'Si', 'Next weapon (secondary)', ->
  VEHICLE.nextWeap(NUU.player,'secondary')

Kbd.macro 'weapPrevSec', 'So', 'Previous weapon (secondary)', ->
  VEHICLE.prevWeap(NUU.player,'secondary')

Kbd.macro 'primaryTrigger', ' ', 'Primary trigger',
  dn:-> if f = NUU.player.primary.trigger then do f
  up:-> if f = NUU.player.primary.release then do f

Kbd.macro 'secondaryTrigger', 'x', 'Secondary trigger',
  dn:-> if f = NUU.player.secondary.trigger then do f
  up:-> if f = NUU.player.secondary.release then do f
