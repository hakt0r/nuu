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

###
  this creates the game model, not an instance of a shot
  think of it as a factory
###

pointCircleCollide = (point, circle, r) ->
  if r == 0
    return false
  dx = circle[0] - point[0]
  dy = circle[1] - point[1]
  dx * dx + dy * dy <= r * r

lineCircleCollide = (a, b, circle, radius) ->
  return true if pointCircleCollide(a, circle, radius)
  return true if pointCircleCollide(b, circle, radius)
  d  = $v.sub(a,b)
  p  = [ d[0], d[1] ]
  lc = $v.sub circle, a
  dl = d[0] * d[0] + d[1] * d[1]
  if dl > 0
    dp = (lc[0] * d[0] + lc[1] * d[1]) / dl
    p[0] *= dp
    p[1] *= dp
  vec = [ a[0] + p[0],  a[1] + p[1] ]
  pl  =   p[0] * p[0] + p[1] * p[1]
  pointCircleCollide(vec, circle, radius) and pl <= dl and p[0] * d[0] + p[1] * d[1] >= 0

$public class Item
  @tpl: {}
  @byId: {}
  @byName: {}
  @byType: {}
  @byProp: {}
  @init: (items) ->
    id = 0
    for o in items.ship
      Item.tpl[id] = o
      Ship.byTpl[id] = o.className
      Ship.byName[o.className] = id++
    for o in items.outf
      Item.tpl[o.itemId = id++] = Item.byName[o.className] = o
      size = o.general.size || 'small'
      t = if (s = o.general.slot) then (if s.$t then s.$t else s) else 'cargo'
      unless o.extends is 'Launcher'
        Item.byType[t] = small:{},medium:{},large:{} unless Item.byType[t]
        Item.byType[t][size][o.className] = o
      if s and (t = s.prop)
        Item.byProp[t] = {} unless Item.byProp[t]
        Item.byProp[t][o.className] = o

$public class Outfit
  constructor: (name) ->
    tpl = Item.byName[name]
    @[k] = v for k,v of tpl

prjId = 0
$public class Weapon extends Outfit
  @active: []
  @proj  : []
  @beam  : {}
  @count : 0

  turret : no
  color  : 'red'
  sprite : null

  constructor: (name,opts={}) ->
    tpl = Item.byName[name]
    Weapon[tpl.extends].call @
    @[k] = v for k,v of tpl
    @id = Weapon.count++
    Weapon[name] = @
    @[k] = v for k,v of opts

  @Projectile: ->
    @speed    = 30.0
    @decay    = 3000
    @cooldown = 1000
    @trigger = (src,vehicle,slot,target)=>
      slot.timer = setInterval @create(src,vehicle,slot,target), @cooldown
    @release = (src,vehicle,slot)=>
      clearInterval slot.timer
    @create = (src,vehicle,slot,target)=>
      ttl = @specific.range / @specific.speed * 1000
      spt = @specific.speed / TICK
      return =>
        d = vehicle.d / RAD
        cs = cos(d); sn = sin(d)
        sx = floor vehicle.x # + slot.x * cs - slot.x * sn;
        sy = floor vehicle.y # + slot.y * sn + slot.y * cs;
        Weapon.proj.push v =
          id: prjId++
          src: vehicle
          weap: slot.equip
          target: target
          ms: TIME
          tt: TIME + ttl
          m : [ vehicle.m[0] + cs * spt, vehicle.m[1] + sn * spt ]
          x : sx
          y : sy
          sx: sx
          sy: sy
        $worker.push =>
          if v.tt < TIME
            Array.remove Weapon.proj, v
            return off
          ticks = (TIME - v.ms) / TICK
          v.x = floor(v.sx + v.m[0] * ticks)
          v.y = floor(v.sy + v.m[1] * ticks)
          if $dist(v,target) < target.size
            target.hit(vehicle,v.weap) unless isClient
            Array.remove Weapon.proj, v
            return off
          null
        NUU.emit 'shot', v
        return v

  @Launcher: ->
  @Bay: ->

  @Beam: ->
    @duration = 300
    @charge   = 100
    @range    = 150
    turnOff = (src,slot)=>
      slot.active = no
      delete Weapon.beam[src.id]
      off
    @trigger = (src,vehicle,slot,target)=>
      @create src, vehicle, slot, target
      slot.active = yes
    @release = (src,vehicle,slot)=> turnOff vehicle, slot
    @create  = (src,vehicle,slot,target)=>
      NUU.emit 'shot', Weapon.beam[vehicle.id] = v =
        src: vehicle
        weap: slot.equip
        target: target
        ms: TIME
        tt: TIME + @duration
        range: @specific.range
      $worker.push =>
        return turnOff vehicle, slot if v.tt < TIME
        return off unless slot.active
        dir = vehicle.d / RAD
        tpos = [ target.x,  target.y  ]
        vpos = [ vehicle.x, vehicle.y ]
        bend = [ vehicle.x + cos(dir) * @range, vehicle.y + sin(dir) * @range ]
        if not isClient and lineCircleCollide vpos, bend, tpos, target.size
          target.hit(vehicle,v.weap)
        null
      null

_weap_action = ['select','trigger','release']

NET.define 5,'WEAP',
  read:
    client: (msg,src) ->
      mode = msg[1]
      return console.log 'WEAP:missing:vid' unless (vehicle = Ship.byId[msg.readUInt16LE 3])
      return console.log 'WEAP:missing:sid' unless (slot    = vehicle.slots.weapon[msg[2]])
      target = slot.target = $obj.byId[msg.readUInt16LE 5]
      action = if mode is 2 then 'release' else 'trigger'
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
      msg = new Buffer [NET.weapCode,_weap_action.indexOf(action),(if primary then 0 else 1),slotid,0,0]
      msg.writeUInt16LE(tid,4) if tid
      NET.send msg.toString 'binary'
    server: (src,mode,slot,vehicle,target)=>
      return console.log 'no weapon equipped' unless ( equipped = slot.equip )
      return console.log 'no trigger/release' unless ( modeCall = equipped[if mode is 1 then 'trigger' else 'release'] )
      modeCall src, vehicle, slot, target
      msg = new Buffer [NET.weapCode, mode, slot.id, 0,0, 0,0 ]
      msg.writeUInt16LE vehicle.id, 3
      msg.writeUInt16LE target.id,  5
      NUU.bincast msg.toString 'binary'
