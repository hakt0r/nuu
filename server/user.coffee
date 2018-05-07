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

NET.on 'login', (msg,src) ->
  new User src, msg.user, msg.pass

NET.on 'switchShip', (msg,src) ->
  u = src.handle
  o = u.vehicle
  vehicle = u.createVehicle src,msg
  # o.destructor() if o.mount[0] is u.db.id
  u.enterVehicle src, vehicle, 0, no

NUU.users = []

UserDB = Db 'UserDb',
  fields:
    online: no
    nick: ''
    mail: ''
    pass: ''
    regtime: -> Date.now()/1000
    credits: 100
  exports: ->
    nick: nick
    mail: mail
    regtime: regtime
    credits: credits
  bootstrap:
   anx:    nick: 'anx',    id:0, mail: 'anx@ulzq.de',      pass: 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e', regtime:'2009-11-07', state:3, credits: 47553836
   flyc0r: nick: 'flyc0r', id:1, mail: 'flyc0r@localhost', pass: 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e', regtime:'2009-11-07', state:1, credits: 15091366

$public class User
  @byId: {}
  constructor: (src, user, pass) ->
    return @deny           src, pass       unless user? and pass?
    return @register       src, user, pass unless @db = UserDB.get user
    return @deny           src, pass       unless @db? and pass is @db.pass
    src.json 'user.login.success': {user:@db}, sync:add:$obj.list
    return handle.rejoin   src                 if handle = User.byId[@db.id]
    @name = @db.nick; @user = @db.user; @ping = {}; @db = @db
    User.byId[@db.id] = src.handle = @
    id = NUU.users.push @; @id = --id
    vehicleType = 'Kestrel'
    vehicleType = @db.vehicle if @db.vehicle?
    @enterVehicle src, (
      @createVehicle src, vehicleType, S:$moving, m:[0.1,0.1], relto: $obj.byId[0]
    ), 0, yes
    console.log @db.nick, 'joined'.green, @db.id, vehicleType
    true

User::rejoin = (src)->
  src.handle = @
  @enterVehicle src, @vehicle, @mountId, no
  console.log @db.nick, 'rejoined', @vehicle?
  true

User::deny = (src, pass)->
  src.json 'user.login.failed':'wrong_credentials'
  console.log 'ws'.yellow, 'login'.red, util.inspect(@db).red, pass.red
  false

User::register = (src, user, pass)->
  @db = UserDb.create user, nick: user, pass: pass
  rec = UserDB.get user
  src.json 'user.login.register': user
  console.log 'User'.yellow, 'register'.red, util.inspect rec if debug
  true

User::part = (user) ->
  console.log 'PART'.red, user

User::createVehicle = (src,id,state)->
  tpl = Ship.byName[id] || Ship.byId[id]
  return console.error 'noship$', id unless tpl?
  state = @vehicle.state if @vehicle
  vehicle = new Ship tpl:tpl, state:state, iff:['@'+@nick]
  NUU.jsoncast 'join': vehicle
  console.log 'user$ship', @db.nick, vehicle.id
  vehicle

User::enterVehicle = (src,vehicle,mountId,spawn)->
  @vehicle = vehicle; @mountId = mountId
  while vehicle.mount[mountId]? and vehicle.mount[mountId] isnt @
    console.log 'already mounted', vehicle.name, mountId
    mountId++
  vehicle.mount[mountId] = @
  vehicle.flags = String.fromCharCode 0 if 0 is mountId
  NUU.emit 'userLeft', src.handle unless spawn
  NUU.emit 'userJoined', src.handle
  src.json 'switchShip': i:vehicle.id, m:mountId
  console.log 'user$enter', @db.nick, vehicle.id, mountId
  null

User::action = (src,t,mode) ->
  o = @vehicle
  unless mode is 'launch' or mode is 'capture'
    return if o.locked
  # console.log 'action$', o.name, mode, t.name
  TIME = Date.now(); o.update(); t.update()
  dist = $dist(o,t)
  dists = $dist(o,t.state)
  zone = o.size + t.size / 2
  switch mode
    when 'launch'
      if o.state.S is $orbit
        o.setState S:$moving, x:o.x, y:o.y, m:o.m.slice()
      else o.setState S:$moving, x:o.x, y:o.y, m:t.m.slice()
      NUU.emit 'ship:launch', o.vehicle, o
      o.locked = no
    when 'capture'
      if dist < zone
        NUU.emit 'ship:collect', o.vehicle, t, o
        console.log o.id, 'collected', t.id, dist, t.size
        t.destructor()
      else console.log 'capture', 'too far out', dist, o.size, t.size
    when 'dock' then if dist < zone
      return unless t.mount
      console.log 'dock', t.id
      o.destructor() if o.size < t.size / 2
      @enterVehicle src, t, 0, no
    when 'land'
      return if t.mount # cant attach to vehicles
      if dist < zone
        console.log 'land', t.id
        o.setState S:$relative,relto:t.id,x:(o.x-t.x),y:(o.y-t.y)
        o.locked = yes
        NUU.emit 'ship:land', o.vehicle, t, o
      else console.log 'land$', 'too far', dist, dists, zone, t.state.toJSON()
    when 'orbit' then if dist < t.size
      console.log 'orbit', t.id
      o.locked = yes
      o.setState S:$orbit,orbit:dist,relto:t.id
    else console.log 'orbit/dock/land/enter', 'failed', mode, o.name, t.name
  null
