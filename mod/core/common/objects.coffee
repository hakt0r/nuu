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

$public class $obj
  @interfaces: []
  @list:       []
  @byId:       {}
  @byClass:    []

  tpl: null

  x:  0
  y:  0
  vx: 0
  vy: 0
  d:  0
  size: 0

  hit:$void

  constructor: (opts={})->
    # read state if specified
    delete opts.state if state = opts.state
    Object.assign @, Item.byId[opts.tpl] if opts.tpl # apply template
    Object.assign @, opts # apply other keys
    # choose id
    ( if @id? then $id.eternal.take @ else $id.dynamic.get @  ) if isServer
    console.log '$obj', 'constructor$', @id, @name if debug
    # register
    i.list.push i.byId[@id] = @ for i in @constructor.interfaces
    # read or setup velocity
    @v = if v = state.v then v.slice() else [0,0]
    @x = state.x || 0
    @y = state.x || 0
    @d = state.d || 0
    @setState state
    @loadAssets() # loads metadata on server
    TTL .add @ if @ttlFinal
    Sync.add @ unless @virtual if isServer
    Sync.add @ if isClient
    return

  loadAssets: ->
    if ( meta = $meta[ @sprite ] )
      # console.log ':nuu', '$meta', @sprite, $meta[@sprite] if debug
      { @size, @radius } = meta
    else console.log ':nuu', 'no meta for', @ if debug
    return

  destructor: ->
    @destructing = true # might be set already
    @refs.forEach( (fn,k)=> fn.call k, @ ) if @refs
    for i in @constructor.interfaces
      console.log '$obj', @id, 'destructor$'+i.name    if debug
      delete i.byId[@id]
      Array.remove i.list, @
    delete $obj.byName[@name]
    Array.remove @range, @ if @range                   if isClient
    Array.remove VEHICLE.hostile, @ if VEHICLE.hostile if isClient
    @hide()                                            if isClient
    Sync.del @id
    @pool.free @id                                     if isServer
    console.log '$obj', @id, 'destructor$', @name      if debug
    return

  dist: (o)-> sqrt abs(o.x-@x)**2 - abs(o.y-@y)**2
  toJSON: -> id:@id,key:@key,size:@size,state:@state,tpl:@tpl

Object.defineProperty $obj::, 'p',
  get: -> do @update; return [@x,@y]
  set: (@x,@y)->

$obj.create = (opts)->
  new $obj.byClass[opts.key] opts

$obj.register = (blueprint)->
  if blueprint.implements
    list = blueprint.implements
    delete blueprint.implements
    for implement in list
      if typeof implement is 'function'
        implement blueprint
      else console.log 'ERROR:', blueprint::constructor.name
  if blueprint.interfaces then for Interface in blueprint.interfaces
    # console.log blueprint.name, 'is', Interface.name
    blueprint.is = {} unless blueprint.is
    blueprint.is[Interface.name] = true
  blueprint::key = -1 + $obj.byClass.push blueprint
  blueprint.byName = {}
  blueprint.byId = {}
  blueprint.list = []
  $public blueprint

#  █████   ██████ ████████ ██  ██████  ███    ██ ███████
# ██   ██ ██         ██    ██ ██    ██ ████   ██ ██
# ███████ ██         ██    ██ ██    ██ ██ ██  ██ ███████
# ██   ██ ██         ██    ██ ██    ██ ██  ██ ██      ██
# ██   ██  ██████    ██    ██  ██████  ██   ████ ███████


$obj::actions = ['travel','formation']
$obj::defaultAction = ->
  d = VEHICLE.dist TARGET
  return 'formation' if d < 2e3
  'travel'

#    █████   ██████ ████████ ██ ██    ██ ███████    ██████  ███████ ███████
#   ██   ██ ██         ██    ██ ██    ██ ██         ██   ██ ██      ██
#   ███████ ██         ██    ██ ██    ██ █████      ██████  █████   █████
#   ██   ██ ██         ██    ██  ██  ██  ██         ██   ██ ██      ██
#   ██   ██  ██████    ██    ██   ████   ███████    ██   ██ ███████ ██

$obj::ref = (other,callback)->
  { @ref, @unref } = $obj
  @refs = new Map
  @ref other, callback
$obj::unref = -> @

$obj.ref = (other,callback)-> @refs.set other, callback; @
$obj.unref = (other)-> @refs.delete other; @

Object.defineProperty $obj::, 'target',
  set:(v)->
    if @_target then @_target.unref @
    if v        then @_target = v.ref @, (v)=> @targetLost?(v)
    else             @_target = null
  get:-> @_target
  default: null

#  ██████ ██       ██████  ███████ ███████ ███████ ████████
# ██      ██      ██    ██ ██      ██      ██         ██
# ██      ██      ██    ██ ███████ █████   ███████    ██
# ██      ██      ██    ██      ██ ██           ██    ██
#  ██████ ███████  ██████  ███████ ███████ ███████    ██

$obj::closestUser = ->
  return no unless NUU.users.length > 0
  closest = null; dist = Infinity
  for p in NUU.users
    continue unless v = p.vehicle
    continue     if v.destructing or v.respawning
    if ( dist > d = $dist(@,v) ) and ( abs(d) < 1000000 )
      dist = d
      closest =  v
  return no unless closest
  return [closest,dist]

$obj::closestHostile = ->
  return no unless @hostile
  closest = null; dist = Infinity
  for p in @hostile
    continue unless v = p.vehicle
    continue     if v.destructing or v.respawning
    if ( dist > d = $dist(@,v) ) and ( abs(d) < 1000000 )
      dist = d
      closest =  v
  return no unless closest
  return [closest,dist]

$obj::closestBigMass = ->
  dist = Infinity; closest = null
  for r in Stellar.list
    continue unless r.bigMass
    r.update @t
    continue if dist < d = @o r
    dist = d
    closest = r
  return [dist,closest]

# ███████ ██    ██ ███    ██  ██████
# ██       ██  ██  ████   ██ ██
# ███████   ████   ██ ██  ██ ██
#      ██    ██    ██  ██ ██ ██
# ███████    ██    ██   ████  ██████
#
# accumulate object-lifecycle notification

$static 'Sync', new class SyncQ
  constructor:-> @reset()
  reset:->
    @adds = []
    @dels = []
    @inst = false
  flush:=>
    @sendLeaves()                           if isServer
    NUU.emit '$obj:del', @dels          unless 0 is @dels.length
    NUU.emit '$obj:add', @adds          unless 0 is @adds.length
    NUU.jsoncast sync: add:@adds, del:@dels if isServer
    @sendEnters()                           if isServer
    @reset()
    return
  add:(obj)=>
    NUU.player.vehicle = obj if obj.id is NUU.player.vehicleId if isClient
    @inst = setTimeout @flush unless @inst
    @adds.push obj
    obj
  del:(obj)=>
    @inst = setTimeout @flush unless @inst
    @dels.push obj
    obj

if isServer
  Sync.enters = new Set
  Sync.enter = (vehicle,user)->
    ( vehicle.enterList || vehicle.enterList = [] ).push user
    Sync.enters.add vehicle
    return
  Sync.sendEnters = ->
    Sync.enters.forEach (vehicle)->
      if list = vehicle.enterList
        for user in list
          user.sock.json
            switchShip: i:vehicle.id, mount: vehicle.mount.map (i)-> if i then i.db.nick else false
            hostile: vehicle.hostile.map ( (i)-> i.id ) if vehicle.hostile
        NUU.jsoncastTo vehicle, setMount: vehicle.mount.map (i)-> if i then i.db.nick else false
    Sync.enters = new Set
    return

  Sync.leaves = new Set
  Sync.leave = (vehicle,user)->
    ( vehicle.leaveList || vehicle.leaveList = [] ).push user.db.id
    Sync.leaves.add vehicle
    return
  Sync.sendLeaves = ->
    Sync.leaves.forEach (vehicle)->
      return unless list = vehicle.leaveList
      NUU.jsoncastTo vehicle, setMount: vehicle.mount.map (i)-> if i then i.db.nick else false
      delete vehicle.leaveList
    Sync.leaves = new Set
    return

# ████████ ████████ ██
#    ██       ██    ██
#    ██       ██    ██
#    ██       ██    ██
#    ██       ██    ███████

$worker.push NUU.checkTTL = ->
  i = -1; s = null; list = TTL.values(); length = TTL.size
  time = NUU.time()
  while ( r = list.next() ).done is false
    continue if ( s = r.value ).ttl > time
    s.destructor() if s.ttlFinal
    TTL.delete s
  return true

# ███████ ██ ███    ███ ██████  ██      ███████ ████████  ██████  ███    ██ ███████
# ██      ██ ████  ████ ██   ██ ██      ██         ██    ██    ██ ████   ██ ██
# ███████ ██ ██ ████ ██ ██████  ██      █████      ██    ██    ██ ██ ██  ██ ███████
#      ██ ██ ██  ██  ██ ██      ██      ██         ██    ██    ██ ██  ██ ██      ██
# ███████ ██ ██      ██ ██      ███████ ███████    ██     ██████  ██   ████ ███████
##
# Interface-only
#  Objects are just registered here for
#  now, Might be un-stubbed later with
#  some related code.

$obj.register class Collectable extends $obj
  @interface: true

$obj.register class Shootable extends $obj
  @interface: true

$obj.register class Debris extends $obj
  @interfaces: [$obj,Shootable,Collectable,Debris]
  name: 'Debris'
  sprite: 'debris2'
  toJSON: -> id:@id,key:@key,state:@state

$obj.register class Cargo extends $obj
  @interfaces: [$obj,Shootable,Collectable,Debris]
  actions: ['capture']
  sprite: 'cargo'
  name: 'Cargo Box'
  item: null
  ttlFinal: yes
  constructor: (opts={})->
    super opts
    @ttl  = NUU.time() + 30000 unless @ttl
    @item = Item.random() unless @item
    @name = "[#{@item.name}]"
  toJSON: -> id:@id,key:@key,state:@state,item:@item

#  █████  ███████ ████████ ███████ ██████   ██████  ██ ██████
# ██   ██ ██         ██    ██      ██   ██ ██    ██ ██ ██   ██
# ███████ ███████    ██    █████   ██████  ██    ██ ██ ██   ██
# ██   ██      ██    ██    ██      ██   ██ ██    ██ ██ ██   ██
# ██   ██ ███████    ██    ███████ ██   ██  ██████  ██ ██████

$obj.register class Asteroid extends $obj
  @interfaces: [$obj,Shootable,Debris,Asteroid]
  constructor: (opts) ->
    unless opts
      r    = 0.8 + random() / 5
      phi  = random() * TAU
      size = max 10, floor random() * 73
      belt = Array.random [503250000,5.984e+9]
      opts =
        resource: ( Element.random() for i in [0...5] )
        size: size
        state:
          S: $orbit
          x: sqrt(r) * cos(phi) * belt
          y: sqrt(r) * sin(phi) * belt
          relto: Stellar.byId[0]
    img = opts.size - 10
    img = '0' + img if img < 10
    opts.sprite = 'asteroid-D' + img
    super opts
    @name = 'roid-' + @id
    @hp = 100

$obj::closestAsteroid = ->
  return no unless Asteroid.list.length > 0
  closest = null; dist = Infinity
  for p in Asteroid.list
    continue if p.destructing
    if dist > d = abs $dist @,p
      closest = p
      dist = d
  return [closest,dist]

return if isServer

# ██   ██  ██████  ██████  ██ ███████  ██████  ███    ██
# ██   ██ ██    ██ ██   ██ ██    ███  ██    ██ ████   ██
# ███████ ██    ██ ██████  ██   ███   ██    ██ ██ ██  ██
# ██   ██ ██    ██ ██   ██ ██  ███    ██    ██ ██  ██ ██
# ██   ██  ██████  ██   ██ ██ ███████  ██████  ██   ████

$obj.clusterTime   = 100
$obj.clusterLength = round Speed.max * $obj.clusterTime

Object.defineProperty $obj::, 'eventHorizon',
  get:-> $v.mag $v.sub @p, ( State.future @state, Date.now() + t ).p

Object.defineProperty $obj::, 'grid',
  get:->
    [x,y] = @p
    x = round x / $obj.clusterLength
    y = round y / $obj.clusterLength
    [x,y]

$static 'SHORTRANGE', []
$static 'MIDRANGE',   []
$static 'LONGRANGE',  []

$obj.HorizonWeapons =  10e3
$obj.HorizonShort   =  10e6
$obj.HorizonMid     = 200e6
$obj.nextMidrangeUpdate = 0
$obj.nextLongrangeUpdate = 0

$obj.select = (force)->
  S = SHORTRANGE; M = MIDRANGE; L = LONGRANGE
  hS = @HorizonShort; hM = @HorizonMid
  aS = []; aL = []; aM = []; dS = new Set; dM = new Set; dL = new Set
  uM = @nextMidrangeUpdate; uL = @nextLongrangeUpdate
  uM = uL = 0 if force

  VEHICLE.update time = NUU.time()
  { x,y } = VEHICLE

  if time > uL
    @selectFrom LONGRANGE, hS,hM,x,y,time,aS,aM,aL,S,M,L,dL
    @nextLongrangeUpdate = time + 10000
    Scanner.updateLongrange = yes
  if time > uM
    @selectFrom MIDRANGE,  hS,hM,x,y,time,aS,aM,aL,S,M,L,dM
    @nextMidrangeUpdate  = time + 2000
    Scanner.updateMidrange = yes
  @selectFrom SHORTRANGE,hS,hM,x,y,time,aS,aM,aL,S,M,L,dS
  @selectFrom force,     hS,hM,x,y,time,aS,aM,aL,S,M,L,(add:->) if Array.isArray force

  # console.log "<=(horizon)=> " +
  #   "Short(#{SHORTRANGE.length}:#{aS.length}|#{dS.length}) " +
  #   "Mid(#{MIDRANGE.length}:#{aM.length}|#{dM.length}|#{Scanner.updateMidrange}|#{@nextLongrangeUpdate}) " +
  #   "Long(#{LONGRANGE.length}:#{aL.length}|#{dL.length})|#{Scanner.updateLongrange}|#{@nextLongrangeUpdate}"

  @announce 'SHORTRANGE', '$obj:range:short', aS, dS
  @announce 'MIDRANGE',   '$obj:range:mid',   aM, dM
  @announce 'LONGRANGE',  '$obj:range:long',  aL, dL
  return

$obj.selectFrom = (list,hS,hM,x,y,time,aS,aM,aL,S,M,L,del)->
  i = -1; s = null; length = list.length
  while ++i < length
    continue unless s = list[i]
    s.update time; dist = sqrt (x-s.x)**2 + (y-s.y)**2
    if dist < hS
      continue if S.includes s
      aS.push s; del.add s; s.range = S; s.inRange = yes
    else if dist < hM
      continue if M.includes s
      aM.push s; del.add s; s.range = M
    else
      continue if L.includes s
      aL.push s; del.add s; s.range = L
  return

$obj.announce = (key,event,add,del)->
  unless 0 is add.length
    window[key] = window[key]
    .filter (i)-> not del.has i
    .concat add
    NUU.emit event, add
  else window[key] = window[key].filter (i)-> not del.has i
