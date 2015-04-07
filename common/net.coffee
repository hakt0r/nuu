###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
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

  route: (ctx,src) =>
    res = @resolve
    (msg) =>
      msg = new Buffer msg, 'binary'
      fnc = res[msg[0]]
      fnc.call @, msg, ctx if fnc?

  bind: (name,fnc) -> @resolve[@[name]] = fnc

  constructor: ->
    $static 'NET', @
    @define.index = 1

$static 'NET', new RTSync

###
  JSON messages
  TODO: binary json / maybe adaptive key/value compression?
###

NET.define 0,'JSON',
  read: (msg,src) =>
    msg = JSON.parse msg.slice(1).toString('utf8')
    for k, v of msg
      # console.log 'NET.json[' + k + ']', v
      NET.emit k, v, src
  write: client: (msg) =>
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
    NET.state.write o

###
  STATE: Change ships motion and attachment
###

NET.define 2,'STATE',
  write:
    server: (o) =>
      s = o.state
      msg = new Buffer 42
      msg[0] = NET.stateCode
      msg.writeUInt16LE o.id,          1
      msg[3] = NET.setFlags [o.accel,o.retro,o.right,o.left,o.boost,s.relto?,no,no]
      msg.writeUInt16LE ( if s.relto then s.relto.id else 0 ), 4
      msg.writeUInt16LE s.S,           6
      msg.writeInt32LE  s.x,           8
      msg.writeInt32LE  s.y,           12
      msg.writeUInt16LE s.d,           16
      msg.writeDoubleLE s.m[0],        18
      msg.writeDoubleLE s.m[1],        26
      msg.writeFloatLE  s.a || 0.0,    34
      msg.writeUInt32LE s.t % 1000000, 38
      NUU.bincast msg.toString 'binary'
    client:(o,flags) =>
      msg = new Buffer [NET.stateCode,NET.setFlags(flags),0,0]
      msg.writeUInt16LE parseInt(o.d), 2
      NET.send msg.toString 'binary'
  read:
    server: (msg,src) =>
      o = src.handle.vehicle
      [ o.accel, o.retro, o.right, o.left, o.boost ] = NET.getFlags msg[1]
      o.d = msg.readUInt16LE 2
      o.changeState()
      src
    client: (msg) =>
      id = msg.readUInt16LE 1
      return unless ( o = $obj.byId[id] )
      [ o.accel, o.retro, o.right, o.left, o.boost ] = flags = NET.getFlags msg[3]
      relto = msg.readUInt16LE 4 if flags[5]
      state = State.toConstructor[msg[6]]
      x = msg.readInt32LE 8
      y = msg.readInt32LE 12
      d = msg.readUInt16LE 16
      m = [ msg.readDoubleLE(18), msg.readDoubleLE(26) ]
      a = msg.readFloatLE 34
      t = ETIME + msg.readUInt32LE 38
      new state o,x,y,d,m,a,t,relto
      o

###
  WEAPON: trigger / release slots on actors
  mode  slotid vehicleid targetid
  UInt8 UInt8  UInt16    UInt16
###

weaponActionKey = ['trigger','release','reload']
NET.define 3,'WEAP',
  read:
    client: (msg,src) ->
      mode = msg[1]
      return console.log 'WEAP:missing:vid' unless (vehicle = Ship.byId[msg.readUInt16LE 3])
      return console.log 'WEAP:missing:sid' unless (slot    = vehicle.slots.weapon[msg[2]])
      target = slot.target = $obj.byId[msg.readUInt16LE 5]
      action = if mode is 0 then 'trigger' else 'release'
      debugger unless slot?
      slot.equip[action](null,vehicle,slot,target)
    server: (msg,src)=>
      mode = msg[1]
      return unless (vehicle = src.handle.vehicle)
      return unless (slot = vehicle.slots.weapon[sid = msg[3]])
      return unless (target = slot.target = $obj.byId[msg.readUInt16LE 4])
      slot.id = sid # FIXME
      NET.weap.write src, mode, slot, vehicle, target
  write:
    client: (action,primary,slotid,tid)=>
      msg = new Buffer [NET.weapCode,weaponActionKey.indexOf(action),(if primary then 0 else 1),slotid,0,0]
      msg.writeUInt16LE(tid,4) if tid
      NET.send msg.toString 'binary'
    server: (src,mode,slot,vehicle,target)=>
      return console.log 'no weapon equipped' unless ( equipped = slot.equip )
      return console.log 'no trigger/release' unless ( modeCall = equipped[if mode is 0 then 'trigger' else 'release'] )
      modeCall src, vehicle, slot, target
      msg = new Buffer [NET.weapCode, mode, slot.id, 0,0, 0,0 ]
      msg.writeUInt16LE vehicle.id, 3
      msg.writeUInt16LE target.id,  5
      NUU.bincast msg.toString 'binary'

###
  ACTION: launch, land, orbit, capture
  mode, source, target
  UInt8 UInt16  UInt16
###

action = (o,t,mode) ->
  switch mode
    when 'capture'
      if $dist(o,t) < (o.size + t.size)/2
        console.log o.id, 'collected', t.id
        t.destructor()
      else console.log 'capture', 'too far out', $dist(o,t)
    when 'launch'
      console.log 'launch', o.id, t.id
      # o.setState S:$relative,relto:o.state.relto
    when 'land', 'dock'
      if $dist(o,t) < t.size / 2
        console.log 'land', t.id
        o.setState S:$fixed,relto:t.id
      else console.log 'land/dock', 'too far out'
    when 'orbit'
      if $dist(o,t) < t.size / 2 * 1.5
        console.log 'orbit', t.id
        o.setState S:$orbit,orbit:$dist(o,t),relto:t.id
      else console.log 'orbit', 'too far out'
action.key = ['launch','land','orbit','capture']

NET.define 4,'ACTION',
  read:
    server:(msg,src) =>
      o = src.handle.vehicle
      mode = action.key[msg[1]]
      t = msg.readUInt16LE 2
      return unless ( t = $obj.byId[t] )
      console.log 'action', o.id, mode, t.id
      action(o,t,mode,src)
      r = new Buffer [NET.actionCode,msg[1],0,0,msg[2],msg[3]]
      r.writeUInt16LE o.id, 2
      NUU.bincast r.toString 'binary'
    client: (msg) =>
      mode = action.key[msg[1]]
      return unless ( o = $obj.byId[id = msg.readUInt16LE 2] )
      return unless ( t = $obj.byId[id = msg.readUInt16LE 4] )
      action(o,t,mode)
  write:
    client:(t,mode) =>
      msg = new Buffer [NET.actionCode,action.key.indexOf(mode),0,0]
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
    return console.log 'MODS:missing:vid', mode unless (ship = Ship.byId[vid])
    NUU.emit "ship:" + mode, ship, msg.readUInt16LE(4), msg.readUInt16LE(6)
  write: server: (ship,mod,a=0,b=0) =>
    msg = new Buffer [NET.modsCode, modsKey.indexOf(mod), 0,0, 0,0, 0,0]
    msg.writeUInt16LE ship.id, 2
    msg.writeUInt16LE parseInt(a), 4
    msg.writeUInt16LE parseInt(b), 6
    NUU.bincast msg.toString 'binary'

###
  REMOVE or RESET actors
  target, operation
###

operationKey = ['remove','reset']
NET.define 6,'OPERATION',
  write:server: (t,mode) =>
    msg = new Buffer [NET.operationCode,operationKey.indexOf(mode),0,0]
    msg.writeUInt16LE t.id, 2
    NUU.bincast msg.toString 'binary'
  read:client: (msg) =>
    return unless ( t = $obj.byId[id = msg.readUInt16LE 2] )
    mode = operationKey[msg[1]]
    console.log mode, t.id
    switch mode
      when 'remove' then t.destructor()
      when 'reset'  then t.reset()
