
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

NUU.on 'settings', ->
  do Mouse.macro() unless NUU.settings.mouseturnoff

$static 'Mouse', new class MouseInput
  state: off
  trigger: no
  triggerSec: no
  timer: undefined
  event: x:0, y:0
  accel: no
  destDir: 0
  lastDir: 0
  lastAccel: no

  constructor:->
    @[k] = @[k].bind @ for k in ['update','reset','callback','oncontextmenu','onwheel','onmouseup','onmousedown']
    null

  update: (evt) ->
    evt = evt
    @event = e = [ evt.offsetX, evt.offsetY ]
    @dest  = c = [ WDB2, HGB2 ]
    @destDir   = ( 360 + parseInt $v.heading(e,c) * RAD ) % 360
    null

  reset: ->
    do @trigger.dn if @trigger
    @trigger = no
    do @triggerSec.dn if @triggerSec
    @triggerSec = no
    @state = off
    HUD.widget 'mouse', null
    clearInterval @timer
    @timer = null
    document.onmousemove = document.onwheel = document.onmouseup = document.onmousedown = document.oncontextmenu = null
    null

  callback: ->
    v = VEHICLE
    dirChanged = @destDir isnt @lastDir
    accelChanged = @lastAccel isnt @accel
    return if VEHICLE.locked and 0 is NUU.player.mountId
    return if VEHICLE.locked and 0 is NUU.player.mountId
    return unless dirChanged or accelChanged
    return if -1 is ['helm','weap'].indexOf
    switch VEHICLE.mountType[NUU.player.mountId]
      when 'helm'
        # v.d = @destDir if NUU.settings.trueInstantWorld
        if dirChanged and not accelChanged
          NET.steer.write @destDir
        else do Kbd.setState 'accel', @accel
      when 'weap'
        NET.steer.write @destDir
    @lastDir = @destDir; @lastAccel = @accel
    null

  oncontextmenu: (evt)-> false

  onmouseup: (evt)->
    switch evt.which
      when 1
        do Kbd.setState 'accel', @accel = false if @accel
        do Kbd.setState 'boost', @boost = false if @boost
        do Kbd.setState 'retro', @retro = false if @retro
      when 3
        if @trigger
          do @trigger.up
          @trigger = no
        if @triggerSec
          do @triggerSec.up
          @triggerSec = no
    do evt.stopPropagation
    false

  onmousedown: (evt)->
    switch evt.which
      when 1
        s = if evt.shiftKey then 'boost' else if evt.ctrlKey then 'retro' else 'accel'
        do Kbd.setState s, @[s] = true
      when 2
        if evt.altKey
             Scanner.toggle()
        else if evt.shiftKey
             Target.nextClass()
        else Target.closest()
      when 3
        if evt.shiftKey
          do Kbd.macro.weapNext
        if evt.altKey
          do Kbd.macro.weapNextSec
        if evt.ctrlKey
          @triggerSec = Kbd.macro.secondaryTrigger
          do Kbd.macro.secondaryTrigger.dn
        if Kbd.macro.primaryTrigger? and not ( evt.altKey or evt.shiftKey or evt.ctrlKey )
          @trigger = Kbd.macro.primaryTrigger
          do Kbd.macro.primaryTrigger.dn
    do evt.stopPropagation
    false

  onwheel: (evt) ->
    down = evt.wheelDeltaY >= 0
    if evt.altKey # alt: set throttle
      return unless NUU.player.mountId is 0
      if down
           VEHICLE.throttle = max 0.01, VEHICLE.throttle - 0.05
      else VEHICLE.throttle = min    1, VEHICLE.throttle + 0.05
    else if evt.ctrlKey # ctrl: zoom screen
      if down
           Sprite.scale = max 0.33, Sprite.scale - 0.02
      else Sprite.scale = min    1, Sprite.scale + 0.02
    else if evt.shiftKey # shift: select target
      if down
           Target.prev()
      else Target.next()
    else # zoom scanne without modifiers
      if down
           Scanner.zoomOut()
      else Scanner.zoomIn()
    do evt.stopPropagation
    false

  enable: ->  @state = off; do @macro()
  disable: -> @state = on;  do @macro()
  macro: -> =>
    @state = not @state
    body = document.querySelector 'body'
    if @state
      HUD.widget 'mouse', 'mouse', true
      document.onmousemove = @update
      document.onwheel = @onwheel
      document.onmouseup = @onmouseup
      document.onmousedown = @onmousedown
      document.oncontextmenu = @oncontextmenu
      @timer = setInterval @callback, TICK
    else @reset()
    null

Object.assign Kbd.defaultMap,
  boost:      'sArrowUp'
  accel:      'ArrowUp'
  retro:      'ArrowDown'
  steerLeft:  'ArrowLeft'
  steerRight: 'ArrowRight'

Object.assign Kbd.d10,
  execute:    "Execute something"
  accel:      "Accelerate"
  retro:      "Decelerate"
  steerLeft:  "Turn left"
  steerRight: "Turn right"
  autopilot:  "Turn to target"
  escape:     "Exit something"
  boost:      "Boost"

Kbd.setState = (key,value)-> =>
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

Kbd.macro 'mouseturn', 'KeyZ', 'Toggle mouseturning', Mouse.macro()

for a in ["accel","retro","steerRight","steerLeft","boost"]
  Kbd.macro a, Kbd.defaultMap[a], Kbd.d10[a],
    up: Kbd.setState(a,false)
    dn: Kbd.setState(a,true)

Kbd.macro 'primaryTrigger', 'Space', 'Primary trigger',
  dn:-> if f = NUU.player.primary.trigger then do f
  up:-> if f = NUU.player.primary.release then do f

Kbd.macro 'weapNext',         'F1', 'Next primary',       -> VEHICLE.nextWeap NUU.player
Kbd.macro 'weapPrev',         'F2', 'Previous primary',   -> VEHICLE.prevWeap NUU.player
Kbd.macro 'weapLock',     'Digit0', 'Primary lock',       -> VEHICLE.setWeap -1
Kbd.macro 'weapPri1',     'Digit1', 'Primary #1',         -> VEHICLE.setWeap  0
Kbd.macro 'weapPri2',     'Digit2', 'Primary #2',         -> VEHICLE.setWeap  1
Kbd.macro 'weapPri3',     'Digit3', 'Primary #3',         -> VEHICLE.setWeap  2
Kbd.macro 'weapPri4',     'Digit4', 'Primary #4',         -> VEHICLE.setWeap  3
Kbd.macro 'weapPri5',     'Digit5', 'Primary #5',         -> VEHICLE.setWeap  4
Kbd.macro 'weapPri6',     'Digit6', 'Primary #6',         -> VEHICLE.setWeap  5
Kbd.macro 'weapPri7',     'Digit7', 'Primary #7',         -> VEHICLE.setWeap  6
Kbd.macro 'weapPri8',     'Digit8', 'Primary #8',         -> VEHICLE.setWeap  7

Kbd.macro 'secondaryTrigger', 'KeyX', 'Secondary trigger',
  dn:-> if f = NUU.player.secondary.trigger then do f
  up:-> if f = NUU.player.secondary.release then do f

Kbd.macro 'weapNextSec',      'F3', 'Next secondary',     -> VEHICLE.nextWeap NUU.player, 'secondary'
Kbd.macro 'weapPrevSec',      'F4', 'Previous secondary', -> VEHICLE.prevWeap NUU.player, 'secondary'
Kbd.macro 'weapLockSec', 'sDigit0', 'Secondary lock',     -> VEHICLE.setWeap -1,          'secondary'
Kbd.macro 'weapSec1',    'sDigit1', 'Secondary #1',       -> VEHICLE.setWeap  0,          'secondary'
Kbd.macro 'weapSec2',    'sDigit2', 'Secondary #2',       -> VEHICLE.setWeap  1,          'secondary'
Kbd.macro 'weapSec3',    'sDigit3', 'Secondary #3',       -> VEHICLE.setWeap  2,          'secondary'
Kbd.macro 'weapSec4',    'sDigit4', 'Secondary #4',       -> VEHICLE.setWeap  3,          'secondary'
Kbd.macro 'weapSec5',    'sDigit5', 'Secondary #5',       -> VEHICLE.setWeap  4,          'secondary'
Kbd.macro 'weapSec6',    'sDigit6', 'Secondary #6',       -> VEHICLE.setWeap  5,          'secondary'
Kbd.macro 'weapSec7',    'sDigit7', 'Secondary #7',       -> VEHICLE.setWeap  6,          'secondary'
Kbd.macro 'weapSec8',    'sDigit8', 'Secondary #8',       -> VEHICLE.setWeap  7,          'secondary'

Kbd.macro 'mountNext',   'KeyM', 'Next mount', ->
  m = ++NUU.player.mountId % VEHICLE.mount.length
  NET.json.write switchMount: m

Kbd.macro 'debug', 'sBackquote', 'Debug', ->
  window.debug = not debug
  NUU.emit 'debug' if debug
