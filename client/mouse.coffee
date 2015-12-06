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

$static 'Mouse', new class MouseInput
  state: off
  timer: undefined
  event: x:0, y:0
  accel: no
  destDir: -1
  lastDir: -1
  lastAccel: no

  update: -> (evt) =>
    evt = evt.data.originalEvent
    @event = e = [ evt.offsetX, evt.offsetY ]
    @dest  = c = [ WDB2, HGB2 ]
    @destDir   = ( 360 + parseInt $v.heading(e,c) * RAD ) % 360
    null

  reset: ->
    Sprite.hud.widget 'mouse'
    clearInterval @timer
    @obj.interactive = no
    @obj.mousemove = undefined
    @obj.mousedown = undefined
    @timer = null
    null

  callback: -> =>
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

  macro: -> =>
    @state = not @state
    @obj = Sprite.fg
    @obj.interactive = true
    body = document.querySelector 'body'
    if @state
      trigger = no
      @obj.hitArea = new PIXI.Rectangle 0, 0, 2000, 2000
      @obj.mousemove = @update()
      body.onwheel = (evt) =>
        down = evt.wheelDeltaY >= 0
        return Kbd.macro.targetPrev() if evt.shiftKey and down
        return Kbd.macro.targetNext() if evt.shiftKey
        if down then Kbd.macro.scanMinus() else Kbd.macro.scanPlus()
      @obj.mousedown = (evt) =>
        if 2 is evt.data.originalEvent.which
          return Kbd.macro.targetClassNext() if evt.data.originalEvent.shiftKey
          return Kbd.macro.targetClosest()
        trigger = evt.data.originalEvent.shiftKey
        if trigger and Kbd.macro.primaryTrigger? then do Kbd.macro.primaryTrigger.dn
        else Kbd.setState 'accel', @accel = true
        do evt.stopPropagation
      body.oncontextmenu = (evt) =>
        do Kbd.macro.primaryTrigger.dn
        do evt.stopPropagation
        false
      @obj.mouseup = (evt) =>
        if trigger and Kbd.macro.primaryTrigger? then do Kbd.macro.primaryTrigger.up
        Kbd.setState 'accel', @accel = false
        do evt.stopPropagation
      @timer = setInterval @callback(), TICK
    else @reset()
    null

Kbd.macro 'mouseturn', 'z', 'Toggle mouseturning', Mouse.macro()
app.on 'settings', -> do Mouse.macro() if app.settings.mouseturn
