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

detector = (perp,weap,ms,tt,sx,sy,mx,my) -> (time)->
  return off if tt < time
  for target in perp.hostile
    ticks = ( time - ms ) / TICK
    x = floor sx + mx * ticks
    y = floor sy + my * ticks
    continue if target.size < $dist (x:x,y:y), target
    target.hit perp, weap if isServer
    return off
  return null

Weapon.Projectile = ->
  Weapon.Projectile.loadAssets.call @  if isClient
  @delay  = @stats.delay * 500
  @ttl    = 1000 / @stats.speed * 1000
  @ppt    = @stats.speed / TICK
  @dir    = 0
  @lock = @stop = false
  $worker.push @tracker = Weapon.tracker.call @ if @turret
  @emitter = (time)=>
    @release() if not @target or @target.destructing
    if @stop then ( @stop = @lock = false; return off )
    @ship.update()
    cs = cos d = (( @ship.d + @dir ) % 360 ) / RAD
    sn = sin d
    m = [ @ship.m[0] + cs * @ppt, @ship.m[1] + sn * @ppt ]
    x = @ship.x # + slot.x * cs
    y = @ship.y # + slot.y * sn
    $worker.push detector   @ship, @, time, time + @ttl, x, y, m[0], m[1]    if isServer
    new ProjectileAnimation @ship, @, time, time + @ttl, x, y, m[0], m[1], d if isClient
    NUU.emit 'shot', @
    @delay
  @trigger = (src,@ship,slot,@target)=>
    return if @lock; @lock = true; @stop = false
    Weapon.hostility @ship, @target
    $worker.push @emitter
    null
  @release = => @stop = true
  null
