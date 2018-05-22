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

$public class RTSync extends EventEmitter
  resolve: {}
  VERSION:    $version
  COMPATIBLE: "0.4.70"

  constructor: -> @define.index = 1

  setFlags: (a) ->
    c = 0
    c += Math.pow(2,k) for k,v of a when v
    c

  getFlags: (c) ->
    a = []
    a.push(if c >> i is 1 then (c -= Math.pow(2,i); true) else false) for i in [7..0]
    a.reverse()

  define: (c,name,opts={}) ->
    # console.log 'NET.define', c, name
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

  bind: (name,fnc) -> @resolve[@[name]] = fnc

$static 'NET', new RTSync

if isClient then RTSync::route = (src,msg)->
  NET.RX++
  msg = new Buffer msg, 'binary'
  fnc = NET.resolve[msg[0]]
  fnc.call NET, msg, src if fnc?

else if isServer then RTSync::route = (src) ->
  res = NET.resolve
  (msg)->
    msg = Buffer.from msg, 'binary'
    fnc = res[msg[0]]
    fnc.call NET, msg, src if fnc?


###
  JSON messages
  TODO: binary json / maybe adaptive key/value compression?
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
    # console.log 'NET.json>', msg
    NET.send NET.JSON + JSON.stringify msg

NET.on 'jump', (target,src) ->
  o = src.handle.vehicle
  if ( target = $obj.byId[parseInt target] )
    o.accel = o.boost = o.retro = o.left = o.right = no
    $static.list.TIME = Date.now()
    target.update()
    o.setState
      S: $moving
      x: parseInt target.x
      y: parseInt target.y
      m: target.m.slice()
      relto: target.id
    NET.state.write o

###
  STATE: Change ships motion and attachment
###

NET.define 2,'STATE',
  write:
    server: (o) -> NUU.bincast ( o.state.toBuffer().toString 'binary' ), o
    client:(o,flags) ->
      msg = Buffer.from [NET.stateCode,( o.flags = NET.setFlags o.flags = flags ),0,0]
      msg.writeUInt16LE parseInt(o.d), 2
      NET.send msg.toString 'binary'
  read:
    client: State.fromBuffer
    server: (msg,src) ->
      o = src.handle.vehicle
      return unless o.mount[0] is src.handle
      [ o.accel, o.retro, o.right, o.left, o.boost ] = NET.getFlags msg[1]
      o.d = msg.readUInt16LE 2
      o.changeState()
      src

NET.define 7,'STEER',
  write:client:(action,value)->
    msg = Buffer.from [NET.steerCode,0,0]
    msg.writeUInt16LE value, 1
    NET.send msg.toString 'binary'
  read:
    client:(msg,src)->
      return unless v = $obj.byId[id = msg.readUInt16LE 1]
      v.d = value = msg.readUInt16LE 3
      v.updateSprite()
    server:(msg,src)->
      return unless o = src.handle.vehicle
      return unless o.mount[0] is src.handle
      o.d = value = msg.readUInt16LE 1
      cast = Buffer.from [NET.steerCode,0,0,0,0]
      cast.writeUInt16LE o.id,  1
      cast.writeUInt16LE value, 3
      NUU.bincast ( cast.toString 'binary' ), o

NET.steer.setDir = 0

###
  WEAPON: trigger / release slots on actors
  mode  slotid vehicleid targetid
  UInt8 UInt8  UInt16    UInt16
###

weaponActionKey = ['trigger','release','reload']
NET.define 3,'WEAP',
  read:
    client: (msg,src) ->
      return console.log 'WEAP:missing:vid' unless vehicle = Ship.byId[msg.readUInt16LE 3]
      return console.log 'WEAP:missing:sid' unless slot    = vehicle.slots.weapon[msg[2]]
      return console.log 'WEAP:missing:tid' unless target  = slot.target = $obj.byId[msg.readUInt16LE 5]
      action = if 0 is ( mode = msg[1] ) then 'trigger' else 'release'
      console.log action, vehicle.id if debug
      slot.equip[action](null,vehicle,slot,target)
    server: (msg,src)->
      mode = msg[1]
      return unless (vehicle = src.handle.vehicle)
      return unless (slot = vehicle.slots.weapon[sid = msg[3]])
      return unless (target = slot.target = $obj.byId[msg.readUInt16LE 4])
      slot.id = sid # FIXME
      NET.weap.write src, mode, slot, vehicle, target

  write:
    client: (action,primary,slotid,tid)->
      return unless tid
      console.log 'weap', action,primary,slotid,tid if debug
      msg = Buffer.from [NET.weapCode,weaponActionKey.indexOf(action),(if primary then 0 else 1),slotid,0,0]
      msg.writeUInt16LE tid, 4
      NET.send msg.toString 'binary'
    server: (src,mode,slot,vehicle,target)->
      return console.log 'no weapon equipped' unless ( equipped = slot.equip )
      return console.log 'no trigger/release' unless ( modeCall = equipped[if mode is 0 then 'trigger' else 'release'] )
      modeCall src, vehicle, slot, target
      msg = Buffer.from [NET.weapCode, mode, slot.id, 0,0, 0,0 ]
      msg.writeUInt16LE vehicle.id, 3
      msg.writeUInt16LE target.id,  5
      NUU.bincast ( msg.toString 'binary' ), vehicle

###
  ACTION: launch, land, orbit, capture
  mode, source, target
  UInt8 UInt16  UInt16
###

action_key = ['launch','land','orbit','dock','capture']
NET.define 4,'ACTION',
  read:server:(msg,src) ->
    return console.log 'nx$obj', t unless t = $obj.byId[msg.readUInt16LE 2]
    src.handle.action src, t, action_key[msg[1]]
  write:client:(t,mode) ->
    console.log mode+'$', t.name, t.id
    msg = Buffer.from [NET.actionCode,action_key.indexOf(mode),0,0]
    msg.writeUInt16LE t.id, 2
    NET.send msg.toString 'binary'

###
  MODS: spawn, destroyed, hit, stats
  source, mod, target, valA, valB
                (UInt16) ^---^
###

modsKey = ['spawn','destroyed','hit','stats']
NET.define 5,'MODS',
  read: client: (msg,src) ->
    mode = modsKey[msg[1]]
    vid  = msg.readUInt16LE 2
    return console.log 'MODS:missing:vid', vid, mode unless ship = Shootable.byId[vid]
    type = ship.constructor.name.toLowerCase() + ':'
    ship.destructing = on if mode is 'destroyed'
    NUU.emit '$obj:' + mode, ship, ship.shield = msg.readUInt16LE(4), ship.armour = msg.readUInt16LE(6)
  write: server: (ship,mod,a=0,b=0) ->
    msg = Buffer.from [NET.modsCode, modsKey.indexOf(mod), 0,0, 0,0, 0,0]
    msg.writeUInt16LE ship.id, 2
    msg.writeUInt16LE parseInt(a), 4
    msg.writeUInt16LE parseInt(b), 6
    NUU.bincast ( msg.toString 'binary' ), ship

###
  REMOVE or RESET actors
  target, operation
###

operationKey = ['remove','reset']
NET.define 6,'OPERATION',
  write:server: (t,mode) ->
    msg = Buffer.from [NET.operationCode,operationKey.indexOf(mode),0,0]
    msg.writeUInt16LE t.id, 2
    NUU.bincast ( msg.toString 'binary' ), t
  read:client: (msg) ->
    return unless ( t = $obj.byId[id = msg.readUInt16LE 2] )
    mode = operationKey[msg[1]]
    console.log mode, t.id
    switch mode
      when 'remove' then t.destructor()
      when 'reset'  then t.reset()

###
  Object Health and Flags
  target, health, armour, fuel
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
    NUU.bincast ( msg.toString 'binary' ), t
  read:client: (msg) ->
    return unless ( t = $obj.byId[id = msg.readUInt16LE 1] )
    t.shield = msg[3] * ( t.shieldMax / 255 )
    t.energy = msg[4] * ( t.energyMax / 255 )
    t.armour = msg[5] * ( t.armourMax / 255 )
    t.fuel   = msg[6] * ( t.fuelMax   / 255 )
    console.log 'health', t.id, t.shield, t.armour if debug
