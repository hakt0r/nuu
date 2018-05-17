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

class MouseInput
  state: off
  trigger: no
  triggerSec: no
  timer: undefined
  event: x:0, y:0
  accel: no
  destDir: -1
  lastDir: -1
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
    Sprite.hud.widget 'mouse'
    clearInterval @timer
    @timer = null
    document.onmousemove = document.onwheel = document.onmouseup = document.onmousedown = document.oncontextmenu = null
    null

  callback: ->
    v = VEHICLE
    dirChanged = @destDir isnt @lastDir
    accelChanged = @lastAccel isnt @accel
    return unless dirChanged or accelChanged
    return unless NUU.player.mountId is 0
    if dirChanged and not accelChanged
      v.d = @destDir
      NET.steer.write NET.steer.setDir, v.d
    else
      v.d = @destDir
      Kbd.setState 'accel', @accel
    @lastDir = @destDir; @lastAccel = @accel
    null

  oncontextmenu: (evt)->
    # do Kbd.macro.primaryTrigger.dn
    # @trigger = Kbd.macro.primaryTrigger
    false

  onmouseup: (evt)->
    if @trigger
      do @trigger.up
      @trigger = no
    if @triggerSec
      do @triggerSec.up
      @triggerSec = no
    Kbd.setState 'accel', @accel = false
    do evt.stopPropagation
    false

  onmousedown: (evt)->
    switch evt.which
      when 1
        Kbd.setState 'accel', @accel = true
      when 2
        if evt.shiftKey
             Kbd.macro.targetClassNext()
        else Kbd.macro.targetClosest()
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
    return Kbd.macro.targetPrev() if evt.shiftKey and down
    return Kbd.macro.targetNext() if evt.shiftKey
    if down then Kbd.macro.scanMinus() else Kbd.macro.scanPlus()
    do evt.stopPropagation
    false

  macro: -> =>
    @state = not @state
    body = document.querySelector 'body'
    if @state
      document.onmousemove = @update
      document.onwheel = @onwheel
      document.onmouseup = @onmouseup
      document.onmousedown = @onmousedown
      document.oncontextmenu = @oncontextmenu
      @timer = setInterval @callback, TICK
    else @reset()
    null

$static 'Mouse', new MouseInput
Kbd.macro 'mouseturn', 'z', 'Toggle mouseturning', Mouse.macro()
app.on 'settings', -> do Mouse.macro() if app.settings.mouseturn
