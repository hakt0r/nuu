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

NET.on 'login', NET.loginFunction = (msg,src) ->
  if msg.match
    unless user = UserDB.get msg
      console.log ':dbg', 'nx:user', msg if debug
      return src.json 'user.login.nx': true
    src.json 'user.login.challenge': salt:user.salt
  else if msg.user? then new User src, msg.user, msg.pass
  null

NET.on 'switchMount', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  o.setMount u, parseInt msg
  null

# TODO: mark old ship for autodestruction or sth
# anyways it's cool if it floats around for a bit
# but if it isn't used it will have to go eventually right?
# maybe when the user spawns his next ship up to the (imaginary) ship limit?
# o.destructor() if o.mount[0] is u.db.id

NET.on 'switchShip', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  vehicle = u.createVehicle msg
  u.enterVehicle vehicle, 0, no
  null

NET.on 'modSlot', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  return src.error '_not_the_owner' unless o.user = u
  return src.error '_not_landed'    unless o.landedAt
  return src.error '_no_slot_type'  unless t = o.slots[msg.type]
  return src.error '_no_slot'       unless s = t[msg.slot]
  o.modSlot msg.type, s, msg.item
  NUU.jsoncastTo o, modSlot: type:msg.type, slot:msg.slot, item:msg.item, level:1
  null

NET.on 'build', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  return src.error '_not_in_orbit'  unless s = o.state.S is $orbit
  return src.error '_invalid_item'  unless b = Item.byType.station[msg]
  return src.error '_not_here'      unless p = o.state.relto.buildRoot
  # Create Item and inherit the creator's state
  $ = new b state:o.state.toJSON()
  console.log ':bld', b.name, p     if debug

NET.on 'jump', (target,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  return src.error '_nx_target'     unless target = $obj.byId[parseInt target]
  return src.error '_no_fuel'       unless o.fuel > 500
  o.fuel -= 500; NET.health.write o
  o.accel = o.boost = o.retro = o.left = o.right = no
  target.update()
  o.setState
    S: $moving
    x: parseInt target.x - 1000 + random()*500
    y: parseInt target.y - 1000 + random()*500
    m: target.m.slice()
    relto: target.id
  null

NUU.users = []

$tag.db 'UserDB',
  fields:
    online: no
    nick: ''
    mail: ''
    pass: ''
    regtime: -> NUU.time() / 1000
    credits: 100
  exports: ->
    nick: nick
    mail: mail
    regtime: regtime
    credits: credits
  bootstrap:
   anx:    nick: 'anx',    id:0, mail: 'anx@ulzq.de',      pass: 'e6e81040502d36d3d83a43be4610f1478bdf267b243223ef27da7418a4af3645a6d716f0f926cea22790cb1903227ed2e754ca7f2c40c17d180704ee47f7330f', salt:'', regtime:'2009-11-07'
   flyc0r: nick: 'flyc0r', id:1, mail: 'flyc0r@localhost', pass: 'e6e81040502d36d3d83a43be4610f1478bdf267b243223ef27da7418a4af3645a6d716f0f926cea22790cb1903227ed2e754ca7f2c40c17d180704ee47f7330f', salt:'', regtime:'2009-11-07'

$public class User
  @byId: {}
  constructor: (src, user, pass) ->
    console.log 'user', user, pass # if debug
    unless user? and pass?
      console.log 'user:nopw', user, UserDB.get user
      return @deny src, pass
    console.log 'user', user, UserDB.get user
    unless @db = UserDB.get user
      return @register src, user, pass
    console.log @db
    unless @db? and pass.pass is salted_pass = sha512 [ pass.salt, @db.pass ].join ':'
      return @deny src, pass
    # Login successful #
    @sock = src
    src.authenticated = yes
    src.json 'user.login.success': {user:@db}, sync:add:$obj.list # TODO: inRange & Stellar only
    src.removeListener "message", src.router
    src.on  "message", src.router = NET.route src
    NUU.emit 'user:joined', @
    return handle.rejoin src if handle = User.byId[@db.id]
    User.byId[@db.id] = src.handle = @
    id = NUU.users.push @; @id = --id
    @name = @db.nick
    @user = @db.user
    @ping = {}
    do @upgradeDb
    # Load and enter vehicle #
    vehicleType = 'Kestrel'
    vehicleType = @db.vehicle if @db.vehicle?
    opts = {}
    if @db.landed and relto = $obj.byName[@db.landed]
      opts.state = S:$fixedTo, x:0, y:0, relto: relto
      opts.landedAt = relto
    else if @db.orbit and relto = $obj.byName[@db.orbit[0]]
      opts.state = @db.orbit[1]
      opts.state.relto = relto
    else opts.state = S:$moving, m:[0.1,0.1], relto: $obj.byId[0]
    v = @createVehicle vehicleType, opts
    @enterVehicle v, 0, yes
    console.log 'user', @db.nick.green, 'joined'.green, @db.id, vehicleType
    true

User::save = ->
  UserDB.set @db.nick, @db
  console.log 'save', @db.nick, @db

User::upgradeDb = (src)->
  @db.inventory = {} unless @db.inventory
  @db.unlocks = {} unless @db.unlocks
  @db.loadout = {} unless @db.loadout

User::rejoin = (src)->
  @sock = src
  src.handle = @
  @enterVehicle @vehicle, @mountId, no
  console.log 'user', @db.nick.green, 'rejoined'.yellow, @vehicle?
  true

User::deny = (src, pass)->
  src.json 'user.login.failed':'wrong_credentials'
  console.log 'user', ' login failed '.red.inverse.bold, @db.nick.yellow
  console.log util.inspect(@db).red, pass.red if debug
  false

User::register = (src, user, pass)->
  @db = UserDB.create user, nick: user, pass: pass.pass, salt:pass.salt
  rec = UserDB.get user
  src.json 'user.login.register': user
  console.log 'user', 'register'.red, util.inspect rec if debug
  true

User::part = (user) ->
  console.log 'PART'.red, user
  NUU.emit 'user:left', @ unless spawn

User::createVehicle = (id,opts={})->
  return console.error 'noship$', id          unless tpl = Ship.byName[id]
  opts.user    = @
  opts.tpl     = tpl
  opts.state   = @vehicle.state.toJSON()      unless opts.state or not @vehicle
  opts.loadout = @db.loadout[Ship.byTpl[tpl]] unless opts.loadout
  opts.iff     = [Math.random()]              unless opts.iff
  vehicle      = new Ship opts
  @sock.json sync:add:[vehicle.toJSON()]
  console.log 'user', 'ship', @db.nick.green, vehicle.id
  vehicle

User::enterVehicle = (vehicle,mountId,spawn)->
  @leaveVehicle @vehicle if @vehicle
  @mountId = ( @vehicle = vehicle ).setMount @, mountId, true
  if not @vehicle.user or @vehicle.user.db.id is @db.id
    @vehicle.user = @
    @vehicle.save() # save loadout and ship
  else console.log 'owned-by', @vehicle.user.db.nick
  @sock.json
    switchShip: i:vehicle.id, m:@vehicle.mount.map (i)-> if i then i.db.nick else false
    hostile: vehicle.hostile.map ( (i)-> i.id ) if vehicle.hostile
  NUU.jsoncastTo vehicle, setMount: @vehicle.mount.map (i)-> if i then i.db.nick else false
  console.log 'user', 'enter', @db.nick.green, vehicle.id, @mountId if debug
  null

User::leaveVehicle = ->
  if -1 is idx = @vehicle.mount.indexOf @
    console.log 'user', 'leaveVehicle'.red, @vehicle.name, @db.nick
    return false
  @vehicle.mount[idx] = false; @equip = @mount = undefined
  NUU.jsoncastTo @vehicle, leaveVehicle: @db.nick
  if 0 is @vehicle.mount.filter((i)-> i ).length
    @vehicle.inhabited = no
  console.log 'user', 'leaveVehicle'.green, @vehicle.name, @vehicle.mount
  @vehicle = null
  true

User::action = (t,mode) ->
  o = @vehicle
  if o.locked and not ( mode is 'launch' or mode is 'capture' )
    console.log ':act', 'cannot', mode.red
    return
  console.log 'user', 'action', o.name, mode, t.name if debug
  o.state.update time = NUU.time()
  t.state.update time
  dist  = $dist o, t
  zone  = o.size + t.size / 2
  @[mode] t, o, zone, dist if ['eva','launch','capture','dock','land','orbit'].includes mode
  null

User::eva = (t,o,zone,dist)->
  @enterVehicle @createVehicle('Exosuit'), 0, no if o.name isnt 'Exosuit'
  null

User::launch = (t,o,zone,dist)->
  if o.state.S is $orbit and @mountId is 0
    @save @db.orbit = o.locked = no
    o.setState S:$moving #, x:o.x, y:o.y, m:o.m.slice()
  else if o.landedAt and @mountId is 0
    NUU.emit 'ship:launch', o, o.landedAt
    @save @db.landed = o.landedAt = o.locked = no
    o.setState S:$moving #, x:o.x, y:o.y, m:t.m.slice()
  else if @equip? and @equip.type is 'fighter bay'
    @save @enterVehicle @createVehicle(Item.byName[@equip.stats.ammo.replace(' ','')].stats.ship), 0, no
  else if o.name isnt 'Exosuit'
    @save @enterVehicle @createVehicle('Exosuit'), 0, no
  null

User::capture = (t,o,zone,dist)->
  unless t.constructor.is.Collectable
    console.log t.constructor.name, 'isnt Collectable'
    return
  if dist < max 200, zone
    NUU.emit 'ship:collect', o, t
    console.log 'user', o.id, 'collected', t.id, dist, t.size if debug
    t.destructor()
  else console.log 'user', 'capture', 'too far out', dist, o.size, t.size

User::dock = (t,o,zone,dist)->
  return unless t.mount # needs to be mountable
  return if dist < zone # too far
  console.log 'user', 'dock', t.id if debug
  # TODO:hook: re-add ammo if fighter
  # else add to inventory
  o.destructor()
  @enterVehicle t, 0, no

User::land = (t,o,zone,dist)->
  return false if t.mount # cant attach to vehicles
  return false unless dist < zone # too far
  console.log 'user', 'land'.green, t.name if debug
  o.setState S:$fixedTo,relto:t.id,x:(o.x-t.x),y:(o.y-t.y)
  o.fuel = o.fuelMax
  @db.landed = o.landedAt = t.name
  @save()
  NUU.emit 'ship:land', o.vehicle, t, o
  true

User::orbit = (t,o,zone,dist)->
  return unless dist < t.size
  console.log 'user', 'orbit', t.id if debug
  o.setState S:$orbit,orb:dist,relto:t
  @db.orbit = [t.name,o.state.toJSON()]
  @save()

Ship::setMount = (user,mountId,only=false)->
  @mount[user.mountId] = false if @mount[user.mountId] is user
  mountId = max 0, min @mount.length, mountId
  console.log 'user' ,'setMount', @name.yellow, mountId, @mount.length if debug
  if ( want = @mount[mountId] ) isnt user and want isnt false
    for i in [0...@mount.length-1] when @mount[(mountId+i)%@mount.length] is false
      mountId = ( mountId + i ) % @mount.length
      break
  console.log 'user' ,'setMount', @name.green, mountId, user.db.nick if debug
  @mount[user.mountId = mountId] = user
  user.mount = @mountSlot[mountId]
  user.equip = if user.mount then user.mount.equip else undefined
  @flags = String.fromCharCode 0 if 0 is mountId
  @inhabited = yes
  return mountId if only
  NUU.jsoncastTo @, setMount: @mount.map (i)->
    if i then i.db.nick else false
  mountId
