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

###
  this creates the game model, not an instance of a shot
  think of it as a factory
###

lineCircleCollide = (a, b, c, r) ->
  closest = a.slice()
  seg     = b.slice()
  ptr     = c.slice()
  $v.sub seg, a
  $v.sub ptr, a
  segu = $v.normalize seg
  prl  = $v.dot ptr, segu
  if prl > $v.dist a, b then closest = b.slice()
  else if prl > 0 then $v.add closest, $v.mult(segu,prl)
  dist = $v.dist c, closest
  dist < r

Weapon.tracker = -> =>
  return 3000 if not @ship? or @ship.DESTROYED
  unless @target
    @dir = 0
    return null
  if @target.destructing
    @dir = 0
    @target = null
    return null
  td  = NavCom.fixAngle $v.heading(@target.p,@ship.p) * RAD
  tdd = -180 + (((( @ship.d + @dir - td - 90 ) % 360 ) + 360 ) % 360 )
  if @stats.track * 2 < abs tdd
    @dir += ( if tdd > 0 then 1 else -1 ) * @stats.track
  else @dir += tdd
  null

Weapon.Beam = ->
  @lock = false
  @dir = 0
  @ship = d:0, DESTROYED: no # FIXME
  @release  = $void
  @duration = @stats.duration.$t * 100
  @range    = @stats.range || 300
  $worker.push @tracker = Weapon.tracker.call @ if @turret
  @release = =>
    @stop = true; @lock = false
    do @hide if isClient
    delete Weapon.beam[@ship.id]
    off
  @trigger = (src,@ship,slot,@target) =>
    return if @lock; @lock = true; @stop = false
    Weapon.hostility @ship, @target
    do @show if isClient
    Weapon.beam[@ship.id] = @
    @ms = NUU.time()
    @tt = @ms + @duration
    $worker.push (time)=>
      return @release() if @stop or @tt < time
      return null if isClient
      @ship.update()
      dir = NavCom.unfixAngle( @ship.d + @dir ) / RAD
      bend = [ @ship.x + sin(dir) * @range, @ship.y - cos(dir) * @range ]
      for @target in @ship.hostile
        @target.update()
        @target.hit @ship, @ if lineCircleCollide @ship.p, bend, @target.p, @target.size/2
      null
    NUU.emit 'shot', @
    null
  Weapon.Beam.loadAssets.call @ if isClient
  @show = Weapon.Beam.show      if isClient
  @hide = Weapon.Beam.hide      if isClient
  null
