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

NET.on 'login', NET.loginFunction = (msg,src) ->
  if msg.match
    unless user = UserDB.get msg
      console.log ':dbg', 'nx:user', msg if debug
      return src.json 'user.login.nx': true
    src.json 'user.login.challenge': salt:user.salt
  else if msg.user? then new User src, msg.user, msg.pass
  null

NET.on 'switchMount', (msg,src) ->
  return unless u = src.handle
  return unless o = u.vehicle
  o.setMount u, parseInt msg
  null

NET.on 'switchShip', (msg,src) ->
  return unless u = src.handle
  return unless o = u.vehicle
  vehicle = u.createVehicle msg
  # o.destructor() if o.mount[0] is u.db.id
  u.enterVehicle vehicle, 0, no
  null

NET.on 'build', (msg,src) ->
  return unless u = src.handle
  return unless v = u.vehicle
  unless s = v.state.S is $orbit
    console.log ':bld', 'not in orbit'
    return
  unless b = Item.byType.station[msg]
    console.log ':bld', 'not a valid Station:', msg
    return
  unless p = v.state.relto.buildRoot
    console.log ':bld', 'no buildRoot: not here!'
    return
  e =
  # checks
  $ = new b state:v.state.toJSON()
  console.log ':bld', b.name, p

NET.on 'jump', (target,src) ->
  return unless o = src.handle.vehicle
  return unless target = $obj.byId[parseInt target]
  # fuel cost
  console.log o.fuel, $dist o, target
  return unless o.fuel > 500
  o.fuel -= 500; NET.health.write o
  # the jump
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

UserDB = Db 'UserDb',
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
    console.log 'user', user, pass if debug
    unless user? and pass?
      return @deny src, pass
    unless @db = UserDB.get user
      return @register src, user, pass
    unless @db? and pass.pass is salted_pass = sha512 [ pass.salt, @db.pass ].join ':'
      return @deny src, pass
    do @upgradeDb
    @sock = src
    src.json 'user.login.success': {user:@db}, sync:add:$obj.list # TODO: inRange & Stellar only
    src.removeListener "message", src.router
    src.on  "message", src.router = NET.route src
    NUU.emit 'user:joined', @
    return handle.rejoin src if handle = User.byId[@db.id]
    @name = @db.nick
    @user = @db.user
    @ping = {}
    @db = @db
    User.byId[@db.id] = src.handle = @
    id = NUU.users.push @; @id = --id
    vehicleType = 'Kestrel'
    vehicleType = @db.vehicle if @db.vehicle?
    v = @createVehicle vehicleType, S:$moving, m:[0.1,0.1], relto: $obj.byId[0]
    @enterVehicle v, 0, yes
    src.authenticated = yes
    console.log 'user', @db.nick.green, 'joined'.green, @db.id, vehicleType
    true

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
  @db = UserDb.create user, nick: user, pass: pass.pass, salt:pass.salt
  rec = UserDB.get user
  src.json 'user.login.register': user
  console.log 'user', 'register'.red, util.inspect rec if debug
  true

User::part = (user) ->
  console.log 'PART'.red, user
  NUU.emit 'user:left', @ unless spawn

User::createVehicle = (id,state)->
  tpl = Ship.byName[id] || Ship.byId[id]
  return console.error 'noship$', id unless tpl?
  if @vehicle
    state = @vehicle.state.toJSON()
  vehicle = new Ship tpl:tpl, state:state, iff:[Math.random()],
    loadout:@db.loadout
  @sock.json sync:add:[vehicle.toJSON()]
  console.log 'user', 'ship', @db.nick.green, vehicle.id
  vehicle

User::enterVehicle = (vehicle,mountId,spawn)->
  @leaveVehicle @vehicle if @vehicle
  @mountId = ( @vehicle = vehicle ).setMount @, mountId, true
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
  dists = $dist o, t.state
  zone  = o.size + t.size / 2
  switch mode
    when 'eva' then if o.name isnt 'Exosuit'
      @enterVehicle @createVehicle('Exosuit'), 0, no
    when 'launch'
      if o.state.S is $orbit and @mountId is 0
        o.locked = no
        debugger
        o.setState S:$moving #, x:o.x, y:o.y, m:o.m.slice()
      else if o.landedAt and @mountId is 0
        NUU.emit 'ship:launch', o, o.landedAt
        o.landedAt = o.locked = no
        o.setState S:$moving #, x:o.x, y:o.y, m:t.m.slice()
      else if @equip? and @equip.type is 'fighter bay'
        @enterVehicle @createVehicle(Item.byName[@equip.stats.ammo.replace(' ','')].stats.ship), 0, no
      else if o.name isnt 'Exosuit'
        @enterVehicle @createVehicle('Exosuit'), 0, no
    when 'capture'
      unless t.constructor.is.Collectable
        console.log t.constructor.name, 'isnt Collectable'
        return
      if dist < max 200, zone
        NUU.emit 'ship:collect', o, t
        console.log 'user', o.id, 'collected', t.id, dist, t.size if debug
        t.destructor()
      else console.log 'user', 'capture', 'too far out', dist, o.size, t.size
    when 'dock' then if dist < zone
      return unless t.mount
      console.log 'user', 'dock', t.id if debug
      # TODO:hook: re-add ammo if fighter
      # else add to inventory
      o.destructor()
      @enterVehicle t, 0, no
    when 'land'
      return if t.mount # cant attach to vehicles
      if dist < zone
        console.log 'user', 'land'.green, t.name if debug
        o.setState S:$fixedTo,relto:t.id,x:(o.x-t.x),y:(o.y-t.y)
        o.locked = yes
        o.fuel = o.fuelMax
        @db.landed = o.landedAt = t.name
        NUU.emit 'ship:land', o.vehicle, t, o
      else console.log 'user', 'land', 'too far', dist, dists, zone, t.state.toJSON()
    when 'orbit'
      if dist < t.size
        console.log 'user', 'orbit', t.id if debug
        o.locked = yes
        o.setState S:$orbit,orb:dist,relto:t
      else console.log 'user', 'orbit', 'too far', dist, dists, zone, t.state.toJSON()
    else console.log 'user', 'orbit/dock/land/enter', 'failed', mode, o.name, t.name
  null

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
