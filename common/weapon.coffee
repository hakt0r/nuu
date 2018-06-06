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

$public class Weapon extends Outfit
  @active: []
  @proj  : []
  @beam  : {}
  @count : 0

  turret : no
  color  : 'red'
  sprite : null

  constructor: (name,opts={}) ->
    tpl = Item.byName[name]
    @[k] = v for k,v of tpl
    @id = Weapon.count++
    Weapon[name] = @
    @[k] = v for k,v of opts
    Weapon[tpl.extends].call @

Weapon.hostility = (vehicle,target)->
  if  target.hostile and -1 is  target.hostile.indexOf vehicle
    target.hostile.push vehicle
    NUU.jsoncastTo target, hostile: vehicle.id if target.inhabited
  if vehicle.hostile and -1 is vehicle.hostile.indexOf target
    vehicle.hostile.push target
    NUU.jsoncastTo vehicle, hostile: target.id if vehicle.inhabited

### ████████ ██████   █████   ██████ ██   ██ ███████ ██████
       ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██
       ██    ██████  ███████ ██      █████   █████   ██████
       ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██
       ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██ ###

Weapon.tracker = -> =>
  return 3000 if not @ship? or @ship.DESTROYED
  unless @target
    @dir = 0
    return null
  if not isNaN @target
    @dir = @target
    return null
  else if @target.destructing
    @dir = 0
    @target = null
    return null
  else
    td  = $v.heading(@target.p,@ship.p) * RAD
    tdd = -180 + $v.umod360 @ship.d + @dir - td
  if @stats.track * 2 < abs tdd
    @dir += ( if tdd > 0 then 1 else -1 ) * @stats.track
  else @dir += tdd
  null

### ██████  ███████  █████  ███    ███
    ██   ██ ██      ██   ██ ████  ████
    ██████  █████   ███████ ██ ████ ██
    ██   ██ ██      ██   ██ ██  ██  ██
    ██████  ███████ ██   ██ ██      ██ ###

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
      @ship.update time
      dir = NavCom.unfixAngle( @ship.d + @dir ) / RAD
      bend = [ @ship.x + sin(dir) * @range, @ship.y - cos(dir) * @range ]
      for @target in @ship.hostile
        @target.update time
        @target.hit @ship, @ if lineCircleCollide @ship.p, bend, @target.p, @target.size/2
      null
    NUU.emit 'shot', @
    null
  Weapon.Beam.loadAssets.call @ if isClient
  @show = Weapon.Beam.show      if isClient
  @hide = Weapon.Beam.hide      if isClient
  null


### ██████  ██████   ██████       ██ ███████  ██████ ████████ ██ ██      ███████
    ██   ██ ██   ██ ██    ██      ██ ██      ██         ██    ██ ██      ██
    ██████  ██████  ██    ██      ██ █████   ██         ██    ██ ██      █████
    ██      ██   ██ ██    ██ ██   ██ ██      ██         ██    ██ ██      ██
    ██      ██   ██  ██████   █████  ███████  ██████    ██    ██ ███████ ███████ ###

detector = (perp,weap,ms,tt,sx,sy,mx,my) -> (time)->
  return off if tt < time
  for target in perp.hostile
    ticks = ( time - ms ) * TICKi
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
  @ppt    = @stats.speed * TICKi
  @dir    = 0
  @lock = @stop = false
  $worker.push @tracker = Weapon.tracker.call @ if @turret
  @emitter = (time)=>
    @release() if not @target or @target.destructing
    if @stop then ( @stop = @lock = false; return off )
    @ship.update time
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

### ███    ███ ██ ███████ ███████ ██ ██      ███████
    ████  ████ ██ ██      ██      ██ ██      ██
    ██ ████ ██ ██ ███████ ███████ ██ ██      █████
    ██  ██  ██ ██      ██      ██ ██ ██      ██
    ██      ██ ██ ███████ ███████ ██ ███████ ███████ ###

$abstract 'Missile',
  d: 0
  thrust: 0.1
  turn: 1
  accel: true
  size: 22
  tpl: 175 # Spearhead Missile
  init: $void
  toJSON: -> id:@id,key:@key,state:@state,target:@target.id,ttl:@ttl

# client implements the simple case
return unless isClient

Weapon.Launcher =->
  @release = $void
  @trigger = $void

$obj.register class Missile extends $obj
  @implements: [$Missile]
  @interfaces: [$obj,Debris]
