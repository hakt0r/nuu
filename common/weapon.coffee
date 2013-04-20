###
  this creates the game model, not an instance of a shot
  think of it as a factory
###

class Item
  @tpl : {}
  @byId : {}
  @byName : {}
  @byType : {}
  @byProp : {}
  @init : (items) ->
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

class Outfit
  constructor : (name) ->
    tpl = Item.byName[name]
    # console.log 'item'.grey, tpl.name, tpl.extends
    @[k] = v for k,v of tpl

prjId = 0
class Weapon extends Outfit
  @active : []
  @proj   : {}
  @beam   : {}
  @count  : 0

  turret  : no
  color   : 'red'
  sprite  : null

  constructor : (name,opts={}) ->
    tpl = Item.byName[name]
    # console.log 'weapon'.grey, tpl.name, tpl.extends
    Weapon[tpl.extends].call @
    @[k] = v for k,v of tpl
    @id = Weapon.count++
    Weapon[name] = @
    @[k] = v for k,v of opts

  @Projectile : ->
    @speed    = 30.0
    @decay    = 3000
    @cooldown = 1000
    @trigger = (src,vehicle,slot,target) =>
      # console.log 'trigger'
      slot.timer = setInterval @create(src,vehicle,slot,target), @cooldown
    @release = (src,vehicle,slot) =>
      # console.log 'release'
      clearInterval slot.timer
    @create = (src,vehicle,slot,target) =>
      # console.log 'create'
      ttl = @specific.range / @specific.speed * 1000
      spt = @specific.speed / TICK
      return =>
        $worker.push =>
          if v.tt < TIME
            delete Weapon.proj[v.id]
            return off
          ticks = (TIME - v.ms) / TICK
          v.x = floor(v.sx + v.mx * ticks)
          v.y = floor(v.sy + v.my * ticks)
          if $dist(v,target) < target.size
            target.hit(vehicle,v.weap)
            delete Weapon.proj[v.id]
            return off
          null
        d = vehicle.d / RAD
        cs = cos(d); sn = sin(d)
        sx = floor vehicle.x + slot.x * cs - slot.x * sn;
        sy = floor vehicle.y + slot.y * sn + slot.y * cs;
        NUU.emit 'shot', Weapon.proj[prjId] = v =
          id : prjId++
          src : vehicle
          weap : slot.equip
          target : target
          ms : TIME
          tt : TIME + ttl
          mx : vehicle.mx + cs * spt
          my : vehicle.my + sn * spt
          x  : sx
          y  : sy
          sx : sx
          sy : sy
        v

  @Launcher : ->
  @Bay : ->
  @Beam : ->
    @duration = 300
    @charge   = 100
    @create = (src,s,slot,target,_reset) => =>
      console.log 'beam:create', slot.timer
      now = NUU.time()
      shot = src : s, ms : now, ttl : now + @duration, reset:_reset, range : @specific.range, target : target
      NUU.emit 'shot', shot
      Weapon.beam[s.id] = shot
      shot
    @trigger = (src,vehicle,slot,target) =>
      console.log 'beam:trigger', slot.timer
      Ton = Toff = null
      d = @duration
      c = @charge
      x = c + d
      create = @create src, vehicle, slot, target, =>
        delete Weapon.beam[vehicle.id]
        clearInterval Ton
        clearInterval Toff
      $timeout c, =>
        create()
        Ton =  $interval x, create
        Toff = $interval d, =>
          delete Weapon.beam[vehicle.id]
    @release = (src,vehicle,slot) => if Weapon.beam[vehicle.id]
      console.log 'beam:release', slot.timer
      Weapon.beam[vehicle.id].reset()

  @projectileDamage : =>
    now = NUU.time()
    Weapon.proj = $_.filter Weapon.proj, (v) ->
      return false if not v.target or v.ttl < now
      ticks = (now - v.ms)/TICK
      v.x = floor(v.msx + v.mx * ticks)
      v.y = floor(v.msy + v.my * ticks)
      t = v.target
      # console.log $dist(v,t)
      if $dist(v,t) < t.size
        t.hit v, v.src
        console.log 'projectile hit'
        dealDamageVehicle t, v.weap
        return false
      true

  @beamDamage : =>
      now = NUU.time()    
      for k,v of Weapon.beam
        t = v.target
        if $dist(v,t) < t.size
          console.log 'beam hit'

_weap_action = ['select','trigger','release']

app.on 'protocol', -> NET.define 'WEAP',
  read :
    client : (msg,src) ->
      mode = msg[1]
      return unless (vehicle = Ship.byId[msg.readUInt16LE 3])
      return unless (slot    = vehicle.slots.weapon[msg[2]])
      target = slot.target = $obj.byId[msg.readUInt16LE 5]
      action = if mode is 2 then 'release' else 'trigger'
      slot.equip[action](null,vehicle,slot,target)
    server : (msg,src) =>
      mode = msg[1]
      return unless (vehicle = src.handle.vehicle)
      return unless (slot = vehicle.slots.weapon[msg[3]])
      return unless (target = slot.target = $obj.byId[msg.readUInt16LE 4])
      NET.weap.write src, mode, slot, vehicle, target
  write :
    client : (action,primary,slotid,tid) =>
      msg = new Buffer [NET.weapCode,_weap_action.indexOf(action),(if primary then 0 else 1),slotid,0,0]
      msg.writeUInt16LE(tid,4) if tid
      NET.send msg.toString 'binary'
    server : (src,mode,slot,vehicle,target) =>
      return console.log 'no weapon equipped' unless ( slot = slot.equip )
      return console.log 'no trigger/release' unless ( slot = slot[if mode is 1 then 'trigger' else 'release'] )
      slot(src,vehicle,slot,target)
      msg = new Buffer [NET.weapCode, mode, slot.id, 0,0, 0,0 ]
      msg.writeUInt16LE vehicle.id, 3
      msg.writeUInt16LE target.id,  5
      NUU.bincast msg.toString 'binary'


$public Weapon, Outfit, Item