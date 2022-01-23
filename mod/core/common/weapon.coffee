
###

  * c) 2007-2022 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2022 flyc0r

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

Weapon.actionKey  = ['trigger','release','reload','aim']
Weapon.actionCode =   trigger:0,release:1,reload:2,aim:3

### ██████   █████  ███    ███  █████   ██████  ███████
    ██   ██ ██   ██ ████  ████ ██   ██ ██       ██
    ██   ██ ███████ ██ ████ ██ ███████ ██   ███ █████
    ██   ██ ██   ██ ██  ██  ██ ██   ██ ██    ██ ██
    ██████  ██   ██ ██      ██ ██   ██  ██████  ███████ ###

Weapon.impactType  =   hit:0,shieldsDown:1,disabled:2,destroyed:3
Weapon.impactTypeKey = ['hit','shieldsDown','disabled','destroyed']
Weapon.impactLogic = (wp)->
  dmg = wp.stats
  if @shield > 0
    @shield -= dmg.penetrate
    if @shield < 0
      @shield = 0
      @armour -= dmg.physical
      status = Weapon.impactType.shieldsDown
  else
    @shield = 0
    @armour -= dmg.penetrate + dmg.physical
  if 0 < @armour and @armour < 25
    status = Weapon.impactType.disabled
    @update()
    @setState S:$moving, lock:yes
    @disabled = @locked = yes
    @releaseAll()
  else if @armour < 0
    @armour = 0
    @shield = 0
    @destructing = yes
    status = Weapon.impactType.destroyed
  else status = Weapon.impactType.hit
  console.log @name, 'hitFor', dmg.penetrate, @shield+'/'+@shieldMax, @armour+'/'+@armourMax if debug
  status

Station::releaseAll = ->
  releaseCode = Weapon.actionCode.release
  @slots.weapon.forEach (w)=> if e = w.equip
    e.release null, null
    NET.weap.write null, releaseCode, w, @, null
  return

Ship::releaseAll = ->
  releaseCode = Weapon.actionCode.release
  @slots.weapon.forEach (w)=> if e = w.equip
    e.release null, null
    NET.weap.write null, releaseCode, w, @, null
  return

### ██   ██  ██████  ███████ ████████ ██ ██      ██ ████████ ██    ██
    ██   ██ ██    ██ ██         ██    ██ ██      ██    ██     ██  ██
    ███████ ██    ██ ███████    ██    ██ ██      ██    ██      ████
    ██   ██ ██    ██      ██    ██    ██ ██      ██    ██       ██
    ██   ██  ██████  ███████    ██    ██ ███████ ██    ██       ██    ###

Weapon.hostility = (perp,target)->
  if ( h = target.hostile ) and -1 is h.indexOf perp
    h.push perp
    target.onHostility() if target.onHostility
    Sync.hostile.add target if target.inhabited
  if ( h = perp.hostile ) and -1 is h.indexOf target
    h.push target
    Sync.hostile.add perp if perp.inhabited

Sync.hostile = new class HostileSync
  inst:no
  set:null
  constructor:->
    @set = new Set
  add:(s)->
    @set.add s
    @inst = setTimeout @flush, TICK unless @inst
    return
  flush:=>
    @set.forEach (s)->
      console.log 'sync:hostiles', s.name if debug
      NUU.jsoncastTo s, hostile:s.hostile.map $id$
    @set = new Set
    @inst = no
    return

### ████████  █████  ██████   ██████  ███████ ████████ ███████
       ██    ██   ██ ██   ██ ██       ██         ██    ██
       ██    ███████ ██████  ██   ███ █████      ██    ███████
       ██    ██   ██ ██   ██ ██    ██ ██         ██         ██
       ██    ██   ██ ██   ██  ██████  ███████    ██    ███████ ###

Weapon.SelectPlayer = $worker.ReduceList (time)->
  { ship, target, slot, lock } = @
  return false     if ship.disabled
  return false unless u = ship.closestUser()
  [closest,dist] = u
  if dist > 5000
    console.log ship.name, 'has target', lock, closest.name
    @trigger null, @target = closest
    NET.weap.write null, 0, slot, ship, closest
    false
  else true

Weapon.Defensive = $worker.ReduceList (time)->
  { ship, target, slot, lock } = @
  return true     if ship.disabled
  return true unless ship.hostile? and 0 < ship.hostile.length
  return true unless h = ship.closestHostile()
  [closest,dist] = h
  if dist > 5000
    console.log ship.name, 'has target', lock, closest.name if debug
    @trigger null, @target = closest
    NET.weap.write null, 0, slot, ship, closest
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
    td  = $v.head(@target.p,@ship.p) * RAD
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
    @stop = true
    @lock = false
    do @hide if isClient
    @ship.beam = false
    off
  @trigger = (src,@target) =>
    return if @lock; @lock = true; @stop = false
    return unless @target       if isServer
    return     if @target.destructing
    Weapon.hostility @ship, @target
    @ship.beam = @
    do @show if isClient
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
    do @release
    return false
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
      NET.weap.write null, 1, @slot, ship, target, null if target.destructing if isServer
      break
  true

### ██████  ██████   ██████       ██ ███████  ██████ ████████ ██ ██      ███████
    ██   ██ ██   ██ ██    ██      ██ ██      ██         ██    ██ ██      ██
    ██████  ██████  ██    ██      ██ █████   ██         ██    ██ ██      █████
    ██      ██   ██ ██    ██ ██   ██ ██      ██         ██    ██ ██      ██
    ██      ██   ██  ██████   █████  ███████  ██████    ██    ██ ███████ ███████ ###

class ProjectileVector
  constructor:(@perp,@weap,@ms,@tt,@sx,@sy,@vx,@vy,@a)->
    @pp = [@x,@y]

Weapon.Projectile = ->
  Weapon.Projectile.loadAssets.call @ if isClient
  @delay = @stats.delay * 500
  @ttl   = 1000 / @stats.speed * 1000
  @pps   = @stats.speed / 333
  @dir   = 0
  @lock  = @stop = false
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
  d = (( ship.d + @dir + 360 ) % 360 ) * RADi
  cs = cos d
  sn = sin d
  vx = ship.v[0] + cs * @pps
  vy = ship.v[1] + sn * @pps
  x = ship.x # + slot.x * cs
  y = ship.y # + slot.y * sn
  a =                    new ProjectileAnimation ship, @, time, time + @ttl, x, y, vx, vy, d if isClient
  ProjectileDetector.add new ProjectileVector    ship, @, time, time + @ttl, x, y, vx, vy, a
  NUU.emit 'shot', @                                                                         if isClient
  true

ProjectileDetector = $worker.ReduceList (time)->
  return false if @tt < time
  t = time - @ms
  x = @sx + @vx * t
  y = @sy + @vy * t
  pos = [x,y]
  pp  = @pp
  for target in @perp.hostile
    target.update time
    continue unless Math.lineCircleCollide pp, pos, target.p, target.size
    target.hit @perp, @weap if isServer
    @a.destroy()            if isClient
    return false
  @pp = pos
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
    constructor:(opts)->
      opts.target = $obj.byId[opts.target]
      super opts
    @implements: [$Missile]
    @interfaces: [$obj,Debris]

if isServer

  Weapon.Launcher = ->
    ammo = Item.byName[@stats.ammo]
    @trigger = switch ammo.type
      when 'fighter'
        ship = Item.byName[ammo.stats.ship]
        (src,target)=>
          ship.formationSlots = Ship.formation.wing.slice() unless ship.formationSlots
          Weapon.hostility @ship, target
          time = NUU.time()
          new Escort
            escortFor: @ship.id
            formVec: ship.formationSlots.shift()
            state: Missile.ejectState time, @ship, 0.002
            tpl: ship.itemId
            iff: ship.iff
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
    dir = (360+RAD*$v.head dist, $v.zero)%360
    dif = (dir-@d+540)%360-180
    if abs(dif) < 2
      return true if @prevState is 4; @prevState = 4
      @setState S:$burn, a:@thrust, d:dir
    else
      return true if @prevState is 3 and @prevDir is dir; @prevState = 3; @prevDir = dir
      if @state.S is $turnTo then @state.changeDir dir else @setState S:$turnTo, D:dir
    true
