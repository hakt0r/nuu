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

$obj.register class Ship extends $obj
  @interfaces: [$obj,Ship]
  @byName: {}
  @byTpl: {}

  d: 0
  m: [0,0]
  iff: ''
  name: ''
  accel: no
  retro: no
  right: no
  left: no

  thrust: 0.1
  turn: 10.0
  type: 0
  cargo: 10

  reactorOut: 10.0
  energy: 100
  energyMax: 100

  armor: 100
  armorMax: 100
  shield: 100
  shieldMax: 100
  shieldRegen: 0.1

  fuel: 100
  fuelMax: 100

  sprite: 'shuttle'
  size: 32
  cols: 18
  rows: 6
  count: 108

  mount: []
  inventory: []
  slot: []

  invisible: no

  constructor: (opts) ->
    super opts
    @slots = _.clone @slots
    @mockSystems() # fixme
    @updateMods()
    $worker.push Ship.model @

  mockSystems: -> # equip fake waepons for development
    Mock = 
      weapon:
        large: Object.keys Item.byType.weapon.small
        medium: Object.keys Item.byType.weapon.medium
        small: Object.keys Item.byType.weapon.small
      utility:
        large: Object.keys Item.byType.utility.large
        medium: Object.keys Item.byType.utility.medium
        small: Object.keys Item.byType.utility.small
      structure:
        large: Object.keys Item.byType.structure.large
        medium: Object.keys Item.byType.structure.medium
        small: Object.keys Item.byType.structure.small
    for k,slt of @slots.weapon when not slt.equip?
      slt.equip = new Weapon(Mock.weapon[slt.size].shift())
    for k,slt of @slots.structure when not slt.equip?
      if slt.default then slt.equip = new Outfit(slt.default)
      #else slt.equip = new Outfit(Mock.structure[slt.size].shift())
    for k,slt of @slots.utility when not slt.equip?
      if slt.default then slt.equip = new Outfit(slt.default)
      #else slt.equip = new Outfit(Mock.utility[slt.size].shift())

  updateMods: -> # calculate mods
    @mods = {}
    @mass = 0
    for type of @slots
      for idx of @slots[type]
        slot = @slots[type][idx]
        item = slot.equip
        if item
          @mass += item.general.mass
          unless type is 'weapon'
            for k,v of item.specific when k isnt 'turret'
              if @mods[k] then @[k] += v
              else @[k] = v
              @mods[k] = true

    # apply mods
    map =
      thrust:      @thrust_mod || 100
      turn:        @turn_mod   || 100
      shield:      @shield_mod || 100
      shieldMax:   @shield_mod || 100
      shieldRegen: @shield_mod || 100
    @[k] += @[k] * ( v / 100 ) for k,v of map

    # scale model values
    @fuelMax = @fuel = @fuel * 1000
    @turn   = @turn    / 10
    @thrust = @thrust  / 100
    null

  nextWeap: (player,trigger='primary') ->
    primary = trigger is 'primary'
    ws = player.vehicle.slots.weapon
    tg = player[trigger]
    tg.id   = min ++tg.id, ws.length-1
    tg.slot = ws[tg.id].equip
    tg.trigger = -> NET.weap.write 'trigger', primary, tg.id, NUU.target.id
    tg.release = -> NET.weap.write 'release', primary, tg.id, NUU.target.id

  prevWeap: (player,trigger='primary') ->
    primary = trigger is 'primary'
    ws = player.vehicle.slots.weapon
    tg = player[trigger]
    tg.id = max 0, --tg.id
    tg.slot = ws[tg.id].equip
    tg.trigger = -> NET.weap.write 'trigger', primary, tg.id, NUU.target.id
    tg.release = -> NET.weap.write 'release', primary, tg.id, NUU.target.id

  hit: (src,wp) ->
    return if @destructing
    NUU.emit 'ship:hit', @, src
    dmg = wp.specific.damage
    if @shield > 0
      @shield -= dmg.penetrate * 4
      if @shield < 0
        @armor += @shield
        @shield = 0
        @armor -= dmg.physical
        NUU.emit 'ship:shieldsDown', @, src
      else if @armor > 75
        @armor -= dmg.physical
      console.log 'hit', @shield, @armor
    else
      @armor -= dmg.penetrate
      @armor -= dmg.physical
    if @armor < 25 and @disabled > 10
      NUU.emit 'ship:disabled', @, src
    else if @armor < 0
      @armor = 0
      @shield = 0
      @shieldRegen = 0
      @destructing = true
      NUU.emit 'ship:destroyed', @, src

  reset: ->
    @destructing = false
    @shield = @shieldMax
    @armor  = @armorMax
    @fuel   = @fuelMax

  dropLoot: ->
    newRandom = (classObj) =>
      o = new classObj state:
        S: $moving
        x: @x + -@size/2 + Math.random()*@size
        y: @y + -@size/2 + Math.random()*@size
        m: [ @m[0] + Math.random()*2 - 1, @m[1] + Math.random()*2 - 1 ]
      o
    newRandom Cargo  for i in [0...10]
    newRandom Debris for i in [0...10]
    null

  respawn: ->
    @x = Math.random()*100
    @y = Math.random()*100
    @reset()
    NET.state.write @
    NET.mods.write  @, 'spawn'

  @model: (s) ->
    add = null
    return ->
      s.energy = min(s.energy + s.reactorOut,s.energyMax)
      add = min(s.shield+min(s.shieldRegen,s.energy),s.shieldMax) - s.shield
      s.shield += add; s.energy -= add
      null

# Special states / mods
_mods = ['spawn','destroyed']

if isClient
  NUU.on 'ship:destroyed', (ship) ->
    ship.reset()
  NUU.on 'ship:spawn', (ship) ->
    ship.invisible = no

else
  NUU.on 'ship:destroyed', (ship) ->
    NET.mods.write ship, 'destroyed'

NET.define 4,'MODS',
  read: client: (msg,src) ->
    return console.log 'MODS:missing:vid' unless (ship = Ship.byId[msg.readUInt16LE 2])
    mode = _mods[msg[1]]
    console.log 'ship:' + mode
    NUU.emit "ship:" + mode, ship
  write: server: (ship,mod) =>
    msg = new Buffer [NET.modsCode, _mods.indexOf(mod), 0,0]
    msg.writeUInt16LE ship.id, 2
    NUU.bincast msg.toString 'binary'
