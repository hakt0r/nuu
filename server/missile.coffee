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

Weapon.Launcher =->
  @release = $void
  @trigger = (src,vehicle,slot,target)=>
    new Missile source:vehicle, target:target

$obj.register class Missile extends $obj
  @implements: [$Missile]
  @interfaces: [$obj]

  constructor: (opts={})->
    source = opts.source
    opts.d = source.d
    opts.m = source.m.slice()
    opts.state =
      S: $moving
      x: source.x
      y: source.y

    super opts
    @turn = 1.0
    @thrust = 0.5

    @ttl = TIME + 3000
    update    = false
    state     = 0
    prevState = 0
    hitDist   = pow ( @size + @target.size ) / 2, 2
    prototype = Item.tpl[@tpl]
    vdiff     = [0,0]
    $worker.push @autopilot = =>
      if TIME > @ttl
        @destructor()
        return false
      @update @target.update()
      dx = parseInt @target.x - @x
      dy = parseInt @target.y - @y
      dst = dx * dx + dy * dy
      if hitDist > dst
        @target.hit source, prototype
        NET.operation.write(@,'remove')
        @destructor()
        return false
      dir = parseInt NavCom.fixAngle( atan2( dx, -dy ) * RAD )
      dif = $v.smod( dir - @d + 180 ) - 180
      if abs( dif ) > 10
        @left  = -180 < dif < 0
        @right = not @left
        state = if @left then 1 else 2
      else if 4 < abs( dif ) < 11
        @left = @right = no
        @d = dir
        state = 3
      else state = 4
      @changeState() if state isnt prevState
      prevState = state
      null

  destructor: ->
    @autopilot.stop = true
    super
