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
    if evt.ctrlKey
      if down
           Sprite.scale = max 0.1, Sprite.scale - 0.05
      else Sprite.scale = min   1, Sprite.scale + 0.05
    if evt.shiftKey
      if down
           Target.prev()
      else Target.next()
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

NUU.on 'settings', -> do Mouse.macro() unless NUU.settings.mouseturnoff
Kbd.macro 'mouseturn', 'KeyZ', 'Toggle mouseturning', Mouse.macro()
