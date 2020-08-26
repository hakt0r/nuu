###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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

NET.resolve = {}
NET.VERSION =    $version
NET.COMPATIBLE = "0.4.70"

###
  ████████  ██████   ██████  ██      ███████
     ██    ██    ██ ██    ██ ██      ██
     ██    ██    ██ ██    ██ ██      ███████
     ██    ██    ██ ██    ██ ██           ██
     ██     ██████   ██████  ███████ ███████

  NETWORK PRECISION METHODS / BITMASKS

###

# OPTIMIZE: this does not need to go through a buffer
_floatLE_buffer_  = Buffer.from [0,0,0,0]
_doubleLE_buffer_ = Buffer.from [0,0,0,0,0,0,0,0]

NET.floatLE = (value)->
  _floatLE_buffer_.writeFloatLE value, 0
  _floatLE_buffer_.readFloatLE 0

NET.doubleLE = (value)->
  _doubleLE_buffer_.writeDoubleLE value, 0
  _doubleLE_buffer_.readDoubleLE 0

NET.setFlags = (a) ->
  c = 0
  c += Math.pow(2,k) for k,v of a when v
  c

NET.getFlags = (c) ->
  a = []
  a.push(if c >> i is 1 then (c -= Math.pow(2,i); true) else false) for i in [7..0]
  a.reverse()

###
  ██████  ███████ ███████ ██ ███    ██ ███████
  ██   ██ ██      ██      ██ ████   ██ ██
  ██   ██ █████   █████   ██ ██ ██  ██ █████
  ██   ██ ██      ██      ██ ██  ██ ██ ██
  ██████  ███████ ██      ██ ██   ████ ███████
###

NET.bind = (name,fnc)->
  @resolve[@[name]] = fnc

NET.define = (c,name,opts={}) ->
  console.log ':net', 'define', c, name if debug
  lower = name.toLowerCase()
  unless @[name]?
    @[name] = s = String.fromCharCode c
    @[lower] = {}
    @[lower+'Code'] = c
  for k,v of opts
    @[lower][k] = (
      if v? and (typeof v is 'object') and (v.client? or v.server?)
        if      isClient and v.client then v.client
        else if isServer and v.server then v.server
      else v )
  @resolve[@[lower+'Code']] = @[lower].read if @[lower].read?
NET.define.index = 1

###
  ██████   ██████  ██    ██ ████████ ███████
  ██   ██ ██    ██ ██    ██    ██    ██
  ██████  ██    ██ ██    ██    ██    █████
  ██   ██ ██    ██ ██    ██    ██    ██
  ██   ██  ██████   ██████     ██    ███████
###

if isClient then NET.route = (src,msg)->
  NET.RX++
  NET.RXB += msg.length or msg.byteLength
  msg = new Buffer msg, 'binary' unless msg.readUInt16LE
  fnc = NET.resolve[msg[0]]
  fnc.call NET, msg, src if fnc?
  return

else if isServer then NET.route = (src) ->
  res = NET.resolve
  (msg)->
    msg = Buffer.from msg, 'binary'
    fnc = res[msg[0]]
    fnc.call NET, msg, src if fnc?
    return

###
       ██ ███████  ██████  ███    ██
       ██ ██      ██    ██ ████   ██
       ██ ███████ ██    ██ ██ ██  ██
  ██   ██      ██ ██    ██ ██  ██ ██
   █████  ███████  ██████  ██   ████
###

NET.define 0,'JSON',
  read:
    client:(msg,src) ->
      msg = new Buffer ( new Uint8Array msg ).slice(1)
      msg = JSON.parse msg.toString('utf8')
      NET.emit k, v, src for k, v of msg
    server:(msg,src) ->
      msg = JSON.parse ( msg.slice 1 ).toString('utf8')
      NET.emit k, v, src for k, v of msg
  write: client: (msg) ->
    console.log ':net', 'json', msg if debug
    NET.send NET.JSON + JSON.stringify msg

###
  ██████  ██ ███    ██  ██████
  ██   ██ ██ ████   ██ ██
  ██████  ██ ██ ██  ██ ██   ███
  ██      ██ ██  ██ ██ ██    ██
  ██      ██ ██   ████  ██████
###

NET.define 1,'PING', read:
  client: (msg,src) ->
    Ping.add msg[1], msg.readDoubleLE 2
  server: (msg,src) ->
    b = Buffer.from [NET.pingCode,msg[1],0,0,0,0,0,0,0,0]
    b.writeDoubleLE Date.now(), 2
    src.send b.toString('binary')
    null

###
  ███████ ████████  █████  ████████ ███████
  ██         ██    ██   ██    ██    ██
  ███████    ██    ███████    ██    █████
       ██    ██    ██   ██    ██    ██
  ███████    ██    ██   ██    ██    ███████
###

NET.define 2,'STATE',
  write:
    client:(o,cmd) ->
      thrust = switch cmd
        when "1" then 100 + round o.throttle * 149
        when "2" then       round ( 1 - o.throttle ) * 99
        when "3" then 250 + round o.throttle * 4
        else 0
      msg = Buffer.from [ NET.stateCode, cmd, 0, 0, thrust ]
      o.accel = o.boost = o.retro = o.right = o.left = o.idle = undefined; o[State.controls[msg[1]]] = true
      msg.writeUInt16LE parseInt(o.d), 2
      NET.send msg.toString 'binary'
    server: (s) ->
      NUU.nearcast s._buffer, s.o
      NET.stateSync.add s.o
  read:
    client: State.fromBuffer
    server: (msg,src) ->
      return src.error '_no_vehicle' unless o = src.handle.vehicle
      return src.error '_is_locked'      if o.locked
      return src.error '_not_helm'   unless o.mount[0] is src.handle # only user on helm mount
      o.accel = o.boost = o.retro = o.right = o.left = o.idle = undefined; o[State.controls[msg[1]]] = true
      o.d = msg.readUInt16LE 2
      o.a = o.thrustToAccel msg[4]
      o.applyControlFlags()
      src

###
  ███████ ████████ ███████ ███████ ██████
  ██         ██    ██      ██      ██   ██
  ███████    ██    █████   █████   ██████
       ██    ██    ██      ██      ██   ██
  ███████    ██    ███████ ███████ ██   ██
###

NET.define 10,'STEER',
  write:
    client:(value,x,fromap)->
      value = fromap || value
      msg = Buffer.from [NET.steerCode,0,0]
      msg.writeUInt16LE value, 1
      NET.send msg.toString 'binary'
    server:(o,idx,value)->
      if idx is 0
        return console.log '::st','dir','locked' if o.locked
        if o.state.S is $turnTo
          o.state.changeDir value
        else return o.setState S:$turnTo, D:value
      else if s = o.mountSlot[idx]
           if e = s.equip then e.target = value = ( 360 + value - o.d ) % 360
      else return false
      cast = Buffer.from [NET.steerCode,0,0,0,0,0]
      cast.writeUInt16LE o.id,  1
      cast.writeUInt16LE value, 3
      cast[5] = idx
      NUU.nearcast ( cast.toString 'binary' ), o
  read:
    client:(msg,src)->
      return unless o = $obj.byId[id = msg.readUInt16LE 1]
      idx = msg[5]
      value = msg.readUInt16LE 3
      if idx is 0
        o.state.changeDir value
      else if o.mountType[idx] is 'weap'
        return unless s = o.mountSlot[idx]
        return unless e = s.equip
        e.target = value
    server:(msg,src)->
      return src.error '_no_handle'     unless u = src.handle
      return src.error '_no_vehicle'    unless o = u.vehicle
      return src.error '_no_mounts'     unless m = o.mount
      return src.error '_not_mounted' if -1 is idx = m.indexOf u
      return src.error '_no_steer'    if -1 is ['helm','weap'].indexOf t = o.mountType[idx] # FIXME:cache
      return src.error '_is_locked'         if o.locked
      NET.steer.write o, idx, ( msg.readUInt16LE 1 ) % 360

###
  ██████  ██    ██ ██████  ███    ██
  ██   ██ ██    ██ ██   ██ ████   ██
  ██████  ██    ██ ██████  ██ ██  ██
  ██   ██ ██    ██ ██   ██ ██  ██ ██
  ██████   ██████  ██   ██ ██   ████
###

NET.define 11,'BURN',
  read:server:(msg,src)->
    return src.error '_no_handle'  unless u = src.handle
    return src.error '_no_vehicle' unless o = u.vehicle
    return src.error '_no_mounts'  unless m = o.mount
    return src.error '_not_helm'   unless 0 is idx = m.indexOf u
    return src.error '_is_locked'      if o.locked
    NET.burn.write o, msg.readUInt16LE 1
  write:
    server:(o,value)->
      o.setState S:$burn, a:o.thrustToAccel value
    client:(o,value)->
      value = max 0, min 255, value || THROTTLE || 249
      msg = Buffer.from [NET.burnCode,0,0]
      msg.writeUInt16LE value, 1
      NET.send msg.toString 'binary'

###
  ██     ██ ███████  █████  ██████   ██████  ███    ██
  ██     ██ ██      ██   ██ ██   ██ ██    ██ ████   ██
  ██  █  ██ █████   ███████ ██████  ██    ██ ██ ██  ██
  ██ ███ ██ ██      ██   ██ ██      ██    ██ ██  ██ ██
   ███ ███  ███████ ██   ██ ██       ██████  ██   ████
###

NET.define 3,'WEAP',
  read:
    client: (msg,src) ->
      return console.log 'weap', 'missing:vid' unless vehicle = Shootable.byId[msg.readUInt16LE 3]
      return console.log 'weap', 'missing:sid' unless slot    = vehicle.slots.weapon[msg[2]]
      return console.log 'weap', 'missing:tid' unless target  = slot.target = $obj.byId[msg.readUInt16LE 5]
      action = if 0 is ( mode = msg[1] ) then 'trigger' else 'release'
      slot.equip[action](null,target)
    server: (msg,src)->
      return src.error '_no_vehicle' unless vehicle = src.handle.vehicle
      return src.error '_no_slot'    unless slot = vehicle.slots.weapon[sid = msg[3]]
      return src.error '_no_target'  unless target = slot.target = $obj.byId[msg.readUInt16LE 4]
      return src.error '_disabled'       if vehicle.disabled
      mode = msg[1]
      slot.id = sid # FIXME
      NET.weap.write src, mode, slot, vehicle, target
  write:
    client: (action,primary,slotid,tid)->
      return unless tid
      console.log 'weap', action,primary,slotid,tid if debug
      msg = Buffer.from [NET.weapCode,Weapon.actionKey.indexOf(action),(if primary then 0 else 1),slotid,0,0]
      msg.writeUInt16LE tid, 4
      NET.send msg.toString 'binary'
    server: (src,mode,slot,vehicle,target)->
      return console.log 'weap', 'nothing equipped',slot unless equipped = slot.equip
      return console.log 'weap', 'no trigger/release' unless modeCall = equipped[Weapon.actionKey[mode]]
      modeCall src, target
      msg = Buffer.from [NET.weapCode, mode, slot.id, 0,0, 0,0 ]
      msg.writeUInt16LE vehicle.id, 3
      msg.writeUInt16LE target.id,  5 if target
      NUU.nearcast ( msg.toString 'binary' ), vehicle

###
   █████   ██████ ████████ ██  ██████  ███    ██
  ██   ██ ██         ██    ██ ██    ██ ████   ██
  ███████ ██         ██    ██ ██    ██ ██ ██  ██
  ██   ██ ██         ██    ██ ██    ██ ██  ██ ██
  ██   ██  ██████    ██    ██  ██████  ██   ████
###

$static 'Interact', new Singleton {
  key:['eva','launch','land','orbit','dock','capture','formation','travel'] }

NET.define 4,'ACTION',
  read:server:(msg,src) ->
    return console.log ':net', 'action:nx:t', msg unless t = $obj.byId[msg.readUInt16LE 2]
    src.handle.action t, Interact.key[msg[1]]
  write:client:(t,mode) ->
    console.log mode+'$', t.name, t.id if debug
    msg = Buffer.from [NET.actionCode,Interact.key.indexOf(mode),0,0]
    msg.writeUInt16LE t.id, 2
    NET.send msg.toString 'binary'

###
  ███    ███  ██████  ██████  ███████
  ████  ████ ██    ██ ██   ██ ██
  ██ ████ ██ ██    ██ ██   ██ ███████
  ██  ██  ██ ██    ██ ██   ██      ██
  ██      ██  ██████  ██████  ███████
###

modsKey = ['spawn','destroyed','hit','shield','disabled','stats']
NET.define 5,'MODS',
  read: client: (msg,src) ->
    mode = modsKey[msg[1]]
    vid  = msg.readUInt16LE 2
    return console.log ':net', 'mods', 'missing:vid', vid, mode unless ship = Shootable.byId[vid]
    type = ship.constructor.name.toLowerCase() + ':'
    ship.destructing = yes if mode is 'destroyed'
    ship.disabled    = yes if mode is 'disabled'
    if mode is 'spawn'
      ship.reset()
      $obj.select true if ship is VEHICLE
    NUU.emit '$obj:' + mode, ship, ship.shield = msg.readUInt32LE(4), ship.armour = msg.readUInt32LE(8)
  write: server: (ship,mod,a=0,b=0) ->
    msg = Buffer.from [NET.modsCode, modsKey.indexOf(mod), 0,0, 0,0,0,0, 0,0,0,0]
    msg.writeUInt16LE ship.id, 2
    msg.writeUInt32LE parseInt(a), 4
    msg.writeUInt32LE parseInt(b), 8
    NUU.nearcast ( msg.toString 'binary' ), ship

###
   █████  ██████  ███    ███ ██ ███    ██      ██████  ██████
  ██   ██ ██   ██ ████  ████ ██ ████   ██     ██    ██ ██   ██
  ███████ ██   ██ ██ ████ ██ ██ ██ ██  ██     ██    ██ ██████
  ██   ██ ██   ██ ██  ██  ██ ██ ██  ██ ██     ██    ██ ██
  ██   ██ ██████  ██      ██ ██ ██   ████      ██████  ██
###

operationKey = ['remove','reset']
NET.define 6,'OPERATION',
  write:server: (t,mode) ->
    msg = Buffer.from [NET.operationCode,operationKey.indexOf(mode),0,0]
    msg.writeUInt16LE t.id, 2
    NUU.nearcast ( msg.toString 'binary' ), t
  read:client: (msg) ->
    return unless ( t = $obj.byId[id = msg.readUInt16LE 2] )
    mode = operationKey[msg[1]]
    console.log mode, t.id
    switch mode
      when 'remove' then t.destructor()
      when 'reset'  then t.reset()

###
  ██   ██ ███████  █████  ██   ████████ ██   ██
  ██   ██ ██      ██   ██ ██      ██    ██   ██
  ███████ █████   ███████ ██      ██    ███████
  ██   ██ ██      ██   ██ ██      ██    ██   ██
  ██   ██ ███████ ██   ██ ███████ ██    ██   ██
###

NET.define 8,'HEALTH',
  write:server: (t) ->
    msg = Buffer.from [
      NET.healthCode
      0
      0
      t.shield * ( 255 / t.shieldMax )
      t.energy * ( 255 / t.energyMax )
      t.armour * ( 255 / t.armourMax )
      t.fuel   * ( 255 / t.fuelMax   ) ]
    msg.writeUInt16LE t.id, 1
    NUU.nearcast ( msg.toString 'binary' ), t
  read:client: (msg) ->
    return unless ( t = $obj.byId[id = msg.readUInt16LE 1] )
    t.shield = msg[3] * ( t.shieldMax / 255 )
    t.energy = msg[4] * ( t.energyMax / 255 )
    t.armour = msg[5] * ( t.armourMax / 255 )
    t.fuel   = msg[6] * ( t.fuelMax   / 255 )
    console.log ':net', 'health', t.id, t.shield, t.armour if debug

# ██ ██████   █████   ██████
# ██ ██   ██ ██   ██ ██
# ██ ██████  ███████ ██
# ██ ██   ██ ██   ██ ██
# ██ ██   ██ ██   ██  ██████

if isServer then NUU.on 'extend', ->
  NET.channel = {}
  Object.defineProperty User::, 'channel',
    get:-> @db.channel || 'global'
    set:(v)->
      nc = NET.channel
      return if v is ( cur = @db.channel ) and cur.includes @
      Array.remove     cur, @ if cur
      Array.pushUnique ( nc[@db.channel=v||'global'] || nc[v] = [] ), @
      return v
  User.cleanup.push ->
    Array.remove c, @ if @channel and c = NET.channel[@channel] || NET.channel[@channel] = []
    return

NET.define 12,'AUDIO',
  write:client: (channel,blob)->
    buffer = await new Promise (resolve)->
      r = new FileReader
      r.onload = (event)-> resolve event.target.result
      r.readAsArrayBuffer blob
    channel = Buffer.from ( channel.substring 0, 63 ), 'utf8' # at most 252 bytes
    NET.send Buffer.concat [Buffer.from([NET.audioCode, channel.length ]),channel,Buffer.from buffer]
  read:
    server:(msg,src)->
      src.handle.channel = channel = msg.slice(2,2+chanLength=msg[1]).toString 'utf8'
      dataLength = msg.byteLength - 2 - chanLength
      return if dataLength is 0 or dataLength > 65536
      { nick, id } = src.handle.db
      meta = Buffer.from JSON.stringify c:channel, n:nick, u:id, 'utf8'
      data = msg.slice 2 + chanLength
      pack = Buffer.concat [ Buffer.from([NET.audioCode,0,0]), meta, data ]
      pack.writeUInt16LE meta.byteLength, 1
      NET.channelBincast channel, pack, except:[src]
      console.log "##{channel}@#{nick}: (audio) ", dataLength if debug
    client:(msg)->
      meta = JSON.parse msg.slice(3,3+metaLength=msg.readUInt16LE 1).toString 'utf8'
      dataLength = msg.byteLength - 3 - metaLength
      dataOffset = 3 + metaLength
      Sound.radio.add(
        URL.createObjectURL(new Blob [msg.slice(dataOffset)],type:'audio/webm')
        nick:meta.n, user:meta.u, channel:meta.c)
      console.log "##{meta.c}@#{meta.n}: (audio) ", dataLength # if debug
