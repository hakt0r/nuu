###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
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

  constructor: (ship,name,opts={}) ->
    super name
    @ship = ship
    @id = Weapon.count++
    Object.assign @, opts
    Weapon[@tpl.extends].call @
  destructor:-> @release()

### ██████   █████  ███    ███  █████   ██████  ███████
    ██   ██ ██   ██ ████  ████ ██   ██ ██       ██
    ██   ██ ███████ ██ ████ ██ ███████ ██   ███ █████
    ██   ██ ██   ██ ██  ██  ██ ██   ██ ██    ██ ██
    ██████  ██   ██ ██      ██ ██   ██  ██████  ███████ ###

Weapon.impactType  =   hit:0,shieldsDown:1,disabled:2,destroyed:3
Weapon.impactTypeKey = ['hit','shieldsDown','disabled','destroyed']
Weapon.impactLogic = (wp)->
  debugger if wp.name is 'CheatersRagnarokBeam'
  dmg = wp.stats
  if @shield > 0
    @shield -= dmg.penetrate
    if @shield < 0
      @shield = 0
      @armour -= dmg.physical
      status = Weapon.impactType.shieldsDown
  else @armour -= dmg.penetrate + dmg.physical
  if 0 < @armour < 25
    status = Weapon.impactType.disabled
  else if @armour < 0
    @armour = 0
    @shield = 0
    @destructing = true
    status = Weapon.impactType.destroyed
  else status = Weapon.impactType.hit
  if wp.name is 'CheatersRagnarokBeam'
    console.log status, @shield, @armor, dmg.penetrate
  status

### ██   ██  ██████  ███████ ████████ ██ ██      ██ ████████ ██    ██
    ██   ██ ██    ██ ██         ██    ██ ██      ██    ██     ██  ██
    ███████ ██    ██ ███████    ██    ██ ██      ██    ██      ████
    ██   ██ ██    ██      ██    ██    ██ ██      ██    ██       ██
    ██   ██  ██████  ███████    ██    ██ ███████ ██    ██       ██    ###

Weapon.hostility = (vehicle,target)->
  # return false unless vehicle.hostile? and target.hostile?
  if  target.hostile and -1 is  target.hostile.indexOf vehicle
    target.hostile.push vehicle
    NUU.jsoncastTo target, hostile: vehicle.id if target.inhabited
  if vehicle.hostile and -1 is vehicle.hostile.indexOf target
    vehicle.hostile.push target
    NUU.jsoncastTo vehicle, hostile: target.id if vehicle.inhabited

### ████████  █████  ██████   ██████  ███████ ████████ ███████
       ██    ██   ██ ██   ██ ██       ██         ██    ██
       ██    ███████ ██████  ██   ███ █████      ██    ███████
       ██    ██   ██ ██   ██ ██    ██ ██         ██         ██
       ██    ██   ██ ██   ██  ██████  ███████    ██    ███████ ###

Weapon.SelectTarget = $worker.ReduceList (time)->
  { ship, target, slot, lock } = @
  closest     = null
  closestDist = Infinity
  ship.update time
  for p in NUU.users
    continue unless v = p.vehicle
    continue     if v.destructing
    v.update time
    if ( closestDist > d = $dist(ship,v) ) and ( 1000000 > abs d )
      closestDist = d
      closest = v
  @target = target = if closestDist > 5000 then null else closest
  if target
    console.log ship.name, 'has target', lock, target.name
    @trigger null, target
    NET.weap.write null, 0, slot, ship, target
    false
  else true

Weapon.Defensive = $worker.ReduceList (time)->
  { ship, target, slot, lock } = @
  unless ship.hostile? and 0 < ship.hostile.length
    return true
  closest     = null
  closestDist = Infinity
  ship.update time
  for v in ship.hostile
    continue if v.destructing
    v.update time
    if ( closestDist > d = $dist(ship,v) ) and ( 1000000 > abs d )
      closestDist = d
      closest = v
  @target = target = if closestDist > 5000 then null else closest
  if target
    console.log ship.name, 'has target', lock, target.name
    @trigger null, target
    NET.weap.write null, 0, slot, ship, target
    false
  else true

### ████████ ██████   █████   ██████ ██   ██ ███████ ██████
       ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██
       ██    ██████  ███████ ██      █████   █████   ██████
       ██    ██   ██ ██   ██ ██      ██  ██  ██      ██   ██
       ██    ██   ██ ██   ██  ██████ ██   ██ ███████ ██   ██ ###

Track = $worker.List (time)->
  if not @ship? or @ship.DESTROYED
    return
  unless @target?
    @dir = 0
    return
  if not isNaN @target
    @dir = @target
    return
  else if @target.destructing
    @dir = 0
    @target = null
    @blur() if @blur
    return
  else
    td  = $v.heading(@target.p,@ship.p) * RAD
    tdd = (@ship.d+@dir-td+360)%360-180
  if @stats.track * 2 < abs tdd
       @dir += ( if tdd > 0 then 1 else -1 ) * @stats.track
  else @dir += tdd
  null

### ██████  ███████  █████  ███    ███
    ██   ██ ██      ██   ██ ████  ████
    ██████  █████   ███████ ██ ████ ██
    ██   ██ ██      ██   ██ ██  ██  ██
    ██████  ███████ ██   ██ ██      ██ ###

Weapon.Beam = ->
  @lock = false
  @dir = 0
  @release  = $void
  @duration = @stats.duration.$t * 100
  @range    = @stats.range || 300
  Track.add @ if @turret
  @destructor = =>
    @release()
    Track.remove @ if @turret
  @release = =>
    @stop = true; @lock = false
    do @hide if isClient
    delete Weapon.beam[@ship.id]
    off
  @trigger = (src,@target) =>
    return if @lock; @lock = true; @stop = false
    return unless @target             if isServer
    return     if @target.destructing
    Weapon.hostility @ship, @target
    do @show if isClient
    Weapon.beam[@ship.id] = @
    @ms = NUU.time()
    @tt = @ms + @duration
    BeamWorker.add @
    NUU.emit 'shot', @
    null
  Weapon.Beam.loadAssets.call @ if isClient
  @show = Weapon.Beam.show      if isClient
  @hide = Weapon.Beam.hide      if isClient
  null

BeamWorker = $worker.ReduceList (time)->
  if @stop or @tt < time
    return do @release
  return true if isClient
  ship = @ship
  ship.update time
  dir = NavCom.unfixAngle( ship.d + @dir ) / RAD
  bgin = ship.p
  bend = [ ship.x + sin(dir) * @range, ship.y - cos(dir) * @range ]
  for target in ship.hostile
    target.update time
    if Math.lineCircleCollide bgin, bend, target.p, target.size/2
      target.hit ship, @
      if target.destructing
        NET.weap.write null, 1, @slot, ship, target, null if isServer
      break
  true

### ██████  ██████   ██████       ██ ███████  ██████ ████████ ██ ██      ███████
    ██   ██ ██   ██ ██    ██      ██ ██      ██         ██    ██ ██      ██
    ██████  ██████  ██    ██      ██ █████   ██         ██    ██ ██      █████
    ██      ██   ██ ██    ██ ██   ██ ██      ██         ██    ██ ██      ██
    ██      ██   ██  ██████   █████  ███████  ██████    ██    ██ ███████ ███████ ###

class ProjectileVector
  constructor:(@perp,@weap,@ms,@tt,@sx,@sy,@vx,@vy)->

Weapon.Projectile = ->
  Weapon.Projectile.loadAssets.call @ if isClient
  @delay  = @stats.delay * 500
  @ttl    = 1000 / @stats.speed * 1000
  @pps    = @stats.speed / 333
  @dir    = 0
  @lock = @stop = false
  Track.add @ if @turret
  @trigger = (src,@target)=>
    return if @lock; @lock = true; @stop = false
    Weapon.hostility @ship, @target
    ProjectileEmitter.add @
    null
  @release = => @stop = true
  null

ProjectileEmitter = $worker.ReduceList (time)->
  @release() if not @target or @target.destructing
  return stop = @lock = false if @stop
  return true if @next > time
  @next = time + @delay
  ship = @ship
  ship.update time
  cs = cos d = (( ship.d + @dir ) % 360 ) * RADi
  sn = sin d
  v = [ ship.v[0] + cs * @pps, ship.v[1] + sn * @pps ]
  x = ship.x # + slot.x * cs
  y = ship.y # + slot.y * sn
  ProjectileDetector.add new ProjectileVector ship, @, time, time + @ttl, x, y, v[0], v[1] if isServer
  new ProjectileAnimation ship, @, time, time + @ttl, x, y, v[0], v[1], d                  if isClient
  NUU.emit 'shot', @                                                                       if isClient
  true

ProjectileDetector = $worker.ReduceList (time)->
  return false if @tt < time
  for target in @perp.hostile
    t = time - @ms
    x = floor @sx + @vx * t
    y = floor @sy + @vy * t
    continue if target.size < $dist (x:x,y:y), target
    target.hit @perp, @weap if isServer
    return false
  true

### ███    ███ ██ ███████ ███████ ██ ██      ███████
    ████  ████ ██ ██      ██      ██ ██      ██
    ██ ████ ██ ██ ███████ ███████ ██ ██      █████
    ██  ██  ██ ██      ██      ██ ██ ██      ██
    ██      ██ ██ ███████ ███████ ██ ███████ ███████ ###

$abstract 'Missile',
  d: 0
  thrust: 0.1
  turn: 1
  size: 22
  tpl: 175 # Spearhead Missile
  init: $void
  toJSON: -> id:@id,key:@key,state:@state,target:@target.id,ttl:@ttl

if isClient # client implements the simple case

  Weapon.Launcher =->
    @release = $void
    @trigger = $void

  $obj.register class Missile extends $obj
    @implements: [$Missile]
    @interfaces: [$obj,Debris]

  return

Weapon.Launcher = ->
  ammo = Item.byName[@stats.ammo]
  @trigger = switch ammo.type
    when 'fighter'
      ship = Item.byName[ammo.stats.ship]
      (src,target)=>
        Weapon.hostility @ship, target
        time = NUU.time()
        new Escort
          escortFor: @ship.id
          state: Missile.ejectState time, @ship, 0.004
          tpl: ship.itemId
    else (src,target)=>
      Weapon.hostility @ship, target
      new Missile source:@ship, target:target
  @release = $void

$obj.register class Missile extends $obj
  @implements: [$Missile]
  @interfaces: [$obj]

  constructor: (opts={})->
    time = NUU.time()
    opts.turn   = 0.4
    src = opts.source
    opts.state  = Missile.ejectState time, src, opts.thrust = 0.0014
    super opts
    @ttl = time + 10000
    @needState = 0
    @prevState = 0
    @hitDist   = pow ( @size + @target.size ) / 2, 2
    @prototype = Item.byId[@tpl]
    setTimeout ( => MissilePilot.add @ ), 500

Missile.ejectState = (time,src,thrust)->
  src.update time
  sv = src.v.slice()
  sd = src.d / RAD
  S: $burn
  a: thrust
  t: time
  d: src.d
  x: src.x
  y: src.y
  v: [ sv[0] + cos(sd) * thrust, sv[1] + sin(sd) * thrust ]

return if isClient

MissilePilot = $worker.ReduceList (time)->
  if time > @ttl
    @destructor()
    return false
  @update time = NUU.time()
  @target.update time
  dist = $v.sub @target.p, @p
  if @hitDist > $v.mag dist
    @target.hit @source, @prototype
    NET.operation.write @, 'remove'
    @destructor()
    return false
  dir = (360+RAD*$v.heading dist, $v.zero)%360
  dif = (dir-@d+540)%360-180
  if abs(dif) < 2
    return true if @prevState is 4; @prevState = 4
    @setState S:$burn, a:@thrust, d:dir
  else
    return true if @prevState is 3 and @prevDir is dir; @prevState = 3; @prevDir = dir
    if @state.S is $turnTo then @state.changeDir dir else @setState S:$turnTo, D:dir
  true
