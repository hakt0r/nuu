###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
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

  update: -> (evt) =>
    evt = evt.originalEvent
    @event = e = [ evt.offsetX, evt.offsetY ]
    @dest  = c = [ Sprite.hw, Sprite.hh ]
    @destdir   = parseInt $v.heading(e,c) * RAD
    null

  reset: ->
    Sprite.hud.widget 'mouse'
    clearInterval @timer
    @obj.mousemove = undefined
    @timer = null
    null

  callback: (v) -> =>
    return unless @destdir
    @reldir = $v.reldeg(VEHICLE.d,@destdir)
    [ accel, boost, left, right, retro ] = NET.getFlags v.flags
    if abs(@reldir) > 10
      right = not ( left = @reldir > 0 )
      @status = ( if left then 'left' else 'right' ) + ": " + @reldir
    else if abs(@reldir) > 0
      left = right = no
      v.d = ( v.d - @reldir ) % 360
      @status = 'set:' + v.d
    else
      left = right = no
      @status = 'idle'
      return null
    newFlags = NET.setFlags flags = [ accel, boost, right, left, retro, no, no, no]
    if @lastFlags isnt newFlags
      NET.state.write v, flags
    @lastFlags = newFlags
    Sprite.hud.widget 'mouse', if left then 'left' else if right then right else @destdir
    null

  macro: -> =>
    @state = not @state
    @obj = Sprite.fg
    @obj.interactive = true
    if @state
      @obj.hitArea = new PIXI.Rectangle 0, 0, 2000, 2000
      @obj.click = @update()
      @timer = setInterval @callback(VEHICLE), TICK
    else @reset()
    null

Kbd.macro 'mouseturn', 'z', 'Toggle mouseturning', Mouse.macro()
