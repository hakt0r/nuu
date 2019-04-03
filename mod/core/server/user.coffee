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

NET.on 'login', NET.loginFunction = (msg,src) ->
  if msg.match
    if msg is 'test'
      user = User.testUser
    else unless user = UserDB.get msg
      console.log ':dbg', 'nx:user', msg if debug
      return src.json 'user.login.nx': true
    src.json 'user.login.challenge': salt:user.salt
  else if msg.user? then new User src, msg.user, msg.pass
  return

NET.on 'logout', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  u.logout()
  return

NET.on 'debug', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_admin'      unless u.db.isAdmin or u.db.nick is 'anx'
  NUU.emit 'debug:start'

NET.on 'switchMount', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  o.setMount u, parseInt msg
  return

# TODO: mark old ship for autodestruction or sth
# anyways it's cool if it floats around for a bit
# but if it isn't used it will have to go eventually right?
# maybe when the user spawns his next ship up to the (imaginary) ship limit?

NET.on 'switchShip', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  return src.error '_not_landed'    unless o.landedAt
  vehicle = u.createVehicle msg
  vehicle.landedAt = o.landedAt
  u.enterVehicle vehicle, 0, no
  o.destructor()
  return

NET.on 'modSlot', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  return src.error '_not_the_owner' unless o.user = u
  return src.error '_not_landed'    unless o.landedAt
  return src.error '_no_slot_type'  unless t = o.slots[msg.type]
  return src.error '_no_slot'       unless s = t[msg.slot]
  o.modSlot msg.type, s, msg.item
  NUU.jsoncastTo o, modSlot: type:msg.type, slot:msg.slot, item:msg.item, level:1
  return

NET.on 'build', (msg,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  return src.error '_not_in_orbit'  unless s = o.state.S is $orbit
  return src.error '_invalid_item'  unless b = Item.byType.station[msg]
  return src.error '_not_here'      unless p = o.state.relto.buildRoot
  # Create Item and inherit the creator's state
  $ = new Station template:msg, state:o.state.toJSON(), owner:u.db.id
  console.log ':bld', b.name, p     if debug
  return

NET.on 'jump', (target,src) ->
  return src.error '_no_handle'     unless u = src.handle
  return src.error '_no_vehicle'    unless o = u.vehicle
  return src.error '_nx_target'     unless target = $obj.byId[parseInt target]
  return src.error '_no_fuel'       unless o.fuel > 500
  o.fuel -= 500; NET.health.write o
  o.accel = o.left = o.right = no
  src.json jump:1
  setTimeout ( ->
    target.update()
    o.setState {
      S: $moving
      x: parseInt target.x - 500 + random()*1000
      y: parseInt target.y - 500 + random()*1000
      v: target.v.slice()
      relto: if target.bigMass then target else undefined }
    src.json jump:2
  ), 1000
  return

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
  @cleanup: []
  constructor: (src, user, pass) ->
    console.log 'user', user, pass # if debug
    if user? and user is 'test'
      @db = JSON.parse JSON.stringify User.testUser
      @db.nick += Date.now()
      @db.id = Date.now()
    else
      unless user? and pass?
        console.log 'user:nopw', user, UserDB.get user
        return @deny src, pass
      unless @db = UserDB.get user
        return @register src, user, pass
      unless @db? and pass.pass is salted_pass = sha512 [ pass.salt, @db.pass ].join ':'
        console.log salted_pass.red
        return @deny src, pass
    # Login successful #
    @sock = src
    src.authenticated = yes
    src.removeListener "message", src.router
    src.on  "message", src.router = NET.route src
    src.json 'user.login.success': {user:@db}, sync:add:$obj.list # TODO: inRange & Stellar only
    NUU.emit 'user:joined', @
    if existingUser = User.byId[@db.id]
      return existingUser.rejoin src
    else @firstJoin src

User::firstJoin = (src)->
  User.byId[@db.id] = src.handle = @
  id = NUU.users.push @; @id = --id
  @name = @db.nick
  @user = @db.user
  @ping = {}
  do @upgradeDb
  do @loadShip
  @sock.json landed: @vehicle.landedAt.id if @vehicle.landedAt
  console.log 'user', @db.nick.green, 'joined'.green, @db.id, @vehicleType
  return

User::rejoin = (src)->
  @sock = src; src.handle = @
  if @vehicle then @enterVehicle @vehicle, @mountId, no else do @loadShip
  @sock.json landed: @vehicle.landedAt.id if @vehicle.landedAt
  console.log 'user', @db.nick.green, 'rejoined'.yellow, ( @vehicle.landedAt || 'space' ).red
  true

User::logout = ->
  if o = @vehicle
    mounties = o.mount.reduce (v,c=0)-> if v? then ++c else c
    console.log 'logout', @name, mounties, o.mount[0] if debug
    o.destructor() if 1 is mounties
  @sock = @vehicle = undefined
  setTimeout => @destructor()
  return

User::destructor = ->
  return false if @sock
  do @save
  @channel = null
  delete User.byId[@db.id]
  f.call @ for f in User.cleanup
  true

User::loadShip = ->
  @vehicleType = 'Kestrel'
  @vehicleType = @db.vehicle if @db.vehicle?
  opts = {}
  if @db.landed and relto = $obj.byId[@db.landed]
    opts.state = S:$fixedTo, x:0, y:0, relto:relto, translate:no
    opts.landedAt = relto
  else if @db.orbit and relto = $obj.byName[@db.orbit[0]]
    opts.state = @db.orbit[1]
    opts.state.relto = relto
  else opts.state = S:$moving, v:[0.1,0.1], relto: $obj.byId[0]
  v = @createVehicle @vehicleType, opts
  @enterVehicle v, 0, yes
  return

User.testUser =
  id:0
  salt:'notRly'
  mountId:0
  nick:'test'
  mail:'anx@ulzq.de'
  regtime:'2009-11-07'
  online:false
  credits:1000
  inventory:{}

User::save = ->
  return if @db.nick.match /^test[0-9]+$/
  UserDB.set @db.nick, @db
  # console.log 'save', @db.nick, @db if debug
  return

User::upgradeDb = (src)->
  @db.inventory = {} unless @db.inventory
  @db.unlocks   = {} unless @db.unlocks
  @db.loadout   = {} unless @db.loadout
  return

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

User::part = (spawn) ->
  console.log 'PART'.red, @db.nick
  NUU.emit 'user:left', @ unless spawn
  return

User::createVehicle = (id,opts={})->
  return console.error 'noship$', id          unless tpl = Ship.byName[id]
  opts.user    = @
  opts.tpl     = tpl
  opts.state   = @vehicle.state.clone()       unless opts.state or not @vehicle
  opts.loadout = @db.loadout[Ship.byTpl[tpl]] unless opts.loadout
  opts.iff     = [Math.random()]              unless opts.iff
  vehicle      = new Ship opts
  console.log 'user', 'ship', @db.nick.green, vehicle.id
  vehicle

User::enterVehicle = (vehicle,mountId,spawn)->
  @leaveVehicle @vehicle if @vehicle
  @mountId = ( @vehicle = vehicle ).setMount @, mountId, true
  if not @vehicle.user or @vehicle.user.db.id is @db.id
    @vehicle.user = @
    @vehicle.save() # save loadout and ship
  else console.log 'owned-by', @vehicle.user.db.nick
  Sync.enter vehicle, @
  console.log 'user', 'enter', @db.nick.green, vehicle.id, @mountId if debug
  return

User::leaveVehicle = ->
  if -1 is idx = @vehicle.mount.indexOf @
    console.log 'user', 'leaveVehicle'.red, @vehicle.name, @db.nick
    return false
  @vehicle.mount[idx] = false; @equip = @mount = undefined
  Sync.leave @vehicle, @
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
  o.update time = NUU.time()
  t.update time
  dist  = $dist o, t
  zone  = ( o.size + t.size ) * .5
  @[mode] t, o, zone, dist if ['eva','launch','capture','dock','land','orbit'].includes mode
  return

User::eva = (t,o,zone,dist)->
  @enterVehicle @createVehicle('Exosuit'), 0, no if o.name isnt 'Exosuit'
  return

$obj::launch = ->
  @locked = no
  @setState S:$moving

User::launch = (t,o,zone,dist)->
  if ( o.state.S is $orbit or o.landedAt ) and @mountId is 0
    o.launch o.landedAt = no
    @save()
    NUU.jsoncastTo o, launch:yes
  else if @equip? and @equip.type is 'fighter bay'
    @save @enterVehicle @createVehicle(Item.byName[@equip.stats.ammo.replace(' ','')].stats.ship), 0, no
  else if o.name isnt 'Exosuit'
    @save @enterVehicle @createVehicle('Exosuit'), 0, no
  return

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
  return false unless t.mount # needs to be mountable
  return false unless dist < zone # too far
  console.log 'user', 'dock', t.id if debug
  # TODO:hook: re-add ammo if fighter
  # else add to inventory
  o.destructor()
  @enterVehicle t, 0, no

# ██       █████  ███    ██ ██████
# ██      ██   ██ ████   ██ ██   ██
# ██      ███████ ██ ██  ██ ██   ██
# ██      ██   ██ ██  ██ ██ ██   ██
# ███████ ██   ██ ██   ████ ██████

$obj::land = (t,zone=@size,dist=$dist(t,@))->
  return false if t.mount # cant attach to vehicles
  return false unless dist < zone # too far
  console.log 'land'.green, @name, 'on', t.name if debug
  @setState S:$fixedTo, relto:t
  @fuel     = @fuelMax
  @landedAt = t
  true

User::land = (t,o,zone,dist)->
  return false unless o.land t,zone,dist
  @save @db.landed = t.id
  @sock.json landed: t.id
  NUU.emit 'ship:land', @db.nick, o.name, t.name
  true

#  ██████  ██████  ██████  ██ ████████
# ██    ██ ██   ██ ██   ██ ██    ██
# ██    ██ ██████  ██████  ██    ██
# ██    ██ ██   ██ ██   ██ ██    ██
#  ██████  ██   ██ ██████  ██    ██

User::orbit = (t,o,zone,dist)->
  return unless ob = t.orbits
  return     if 0 is ob.length
  return     if o.nextOrbit and o.nextOrbit > TIME = Date.now()
  o.nextOrbit = TIME + 1000
  for oo in ob when 50 > abs( abs(oo) - abs(dist) )
    console.log 'user', 'orbit', t.id, oo, dist if debug
    o.setState S:$orbit,orb:oo,relto:t
    @db.orbit = [t.name,o.state.toJSON()]
    @save()
    break
  return

# ███    ███  ██████  ██    ██ ███    ██ ████████
# ████  ████ ██    ██ ██    ██ ████   ██    ██
# ██ ████ ██ ██    ██ ██    ██ ██ ██  ██    ██
# ██  ██  ██ ██    ██ ██    ██ ██  ██ ██    ██
# ██      ██  ██████   ██████  ██   ████    ██

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
  @accel = @left = @right = no if 0 is mountId
  @inhabited = yes
  return mountId if only
  console.log ' => ', @mount.map (i)-> if i then i.db.nick else false # if debug
  NUU.jsoncastTo @, setMount: @mount.map (i)-> if i then i.db.nick else false
  # Sync.enter @, user
  mountId
