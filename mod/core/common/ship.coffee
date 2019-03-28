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

$obj.register class Ship extends $obj
  @interfaces: [$obj,Ship,Shootable]
  @byName: {}
  @byTpl: {}

  iff:  ''
  name: ''

  thrust:   0.1
  turn:     10.0
  type:     0
  cargo:    10
  throttle: .75

  reactorOut: 10.0
  energy:     100
  energyMax:  100

  armour:      100
  armourMax:   100
  shield:      100
  shieldMax:   100
  shieldRegen: 0.1

  fuel:        100
  fuelMax:     100

  sprite:
    name: 'shuttle'
    cols:  18
    rows:  6
    count: 108
  size: 32

  mount:     null
  inventory: null
  slots:     null

  constructor: (opts) ->
    super opts
    @hostile = []
    @tplName = @name
    @slots = JSON.parse JSON.stringify @slots # FIXME :>
    idx = 0; ( slot.idx = idx++ for slot in @slots.structure )
    idx = 0; ( slot.idx = idx++ for slot in @slots.utility   )
    idx = 0
    @loadSytems opts.loadout
    @updateMods()
    @mount     = [false,false]
    @mountSlot = [false,false]
    @mountWeap = [false,false]
    @mountType = ['helm','passenger']
    @mountName = ['Helm','PassengerSeat']
    for slot in @slots.weapon
      slot.idx = idx++
      continue unless slot and slot.equip
      @mount.push false
      @mountName.push slot.equip.name
      @mountSlot.push slot
      if slot.equip.type is 'fighter bay'
        @mountType.push 'fighter'
      else if slot.equip.turret
        @mountType.push 'weap'
        null
      else @mountType.push 'weaX'
    @fuel = @fuelMax = 200000
    null

Ship.blueprint =
  name: 'Human'
  sprite: 'sprite@suit'
  slots:
    structure: [ size: 'suit', default: 'Human Skin'  ]
    utility:   [ size: 'suit', default: 'Human Heart' ]
    weapon:    [ size: 'suit', default: 'Stock Multitool' ]
  stats: crew:1, mass:1, fuel_consumption:0

Ship::destructor = ->
  $worker.remove @model
  for slot in @slots.weapon when slot and slot.equip
    slot.equip.release()
  $obj::destructor.call @

Ship::reset = ->
  @hostile = []
  @destructing = false
  @energy = @energyMax
  @shield = @shieldMax
  @armour = @armourMax
  @fuel   = @fuelMax

Ship::toJSON = -> {
  id:     @id
  key:    @key
  size:   @size
  state:  @state
  tpl:    @tpl
  name:   @name
  loadout:@loadout }

###
Object.defineProperty Ship::, 'd',
  get:-> @_d || 0
  set:(v)->
    debugger if v is -1
    @_d = v
###

Object.defineProperty Ship::, 'eventHorizon',
  get:-> $v.mag $v.sub @p, ( State.future @state, Date.now() + t ).p

Ship::thrustToAccel = (value)->
  # TODO: frameshift / warp / slipstream :D
  value = max 0, min 255, value
  value = NET.floatLE (
    if      value < 100 then -@thrust * (1/100) * ( 100 - value )
    else if value < 250 then  @thrust * (1/149) * ( value - 100 )
    else                      @thrust *           ( value - 248 ) )
  NET.floatLE value

Ship::burnTime = (v,thurst,origin)->
  a = ship.thrustToAccel thrust
  unless origin
    do @update
    origin = @m
  $v.mag( $v.sub origin.slice(), v ) / a

Ship::turnTime = (dir,origin)->
  origin = @d unless origin
  ddiff = -180 + $v.umod360 -180 + dir - origin
  adiff = abs ddiff
  turnTime = adiff / ( @turn || 1 )

Ship::updateMods = ->

  # gather / calculate mods
  @mods = {}
  @mass = 0
  for type of @slots
    for idx, slot of @slots[type]
      if ( item = slot.equip )
        @mass += item.stats.mass || 0
        unless type is 'weapon'
          for k,v of item.stats when k isnt 'turret'
            if @mods[k] then @[k] += v
            else @[k] = v
            @mods[k] = true
  console.log 'smod', 'mass', @stats.mass - @mass if debug

  # apply mods
  map =
    thrust:      @stats.thrust_mod || 100
    turn:        @stats.turn_mod   || 100
    shield:      @stats.shield_mod || 100
    shieldMax:   @stats.shield_mod || 100
    shieldRegen: @stats.shield_mod || 100
  @[k] += @[k] * ( v / 100 ) for k,v of map

  # scale model values
  @armourMax = @armour = @stats.armour / 1000
  @fuelMax   = @fuel   = @fuel * 10
  @turn      = @turn    / 10
  @thrust    = @thrust  / 100

  # add/exchange model-worker
  @lastUpdate = 0
  ShipModel.remove @
  ShipModel.add @
  null

ShipModel = $worker.ReduceList (time)->
  return false if @destructing
  # return 1000 if @fuel <= 0
  add = null
  @fuel += @fuelRegen || 0.5
  @fuel -= max 0, @state.a if @state.acceleration
  unless @shield is @shieldMax and @energy is @energyMax
    @energy = min @energyMax, @energy + @reactorOut
    @shield += add = min( @shield + min(@shieldRegen,@energy), @shieldMax) - @shield
    @energy -= add
  @fuel = @fuelMax if @fuel > @fuelMax
  @fuel = 0        if @fuel <= 0
  return true unless isServer
  @setState S:$moving if @fuel is 0 and @state.acceleration
  return true unless @mount[0] and @lastUpdate + 3000 < time
  NET.health.write @
  @lastUpdate = time
  true

Ship::save = ->
  loadout = weapon:[], structure:[], utility:[]
  loadout.weapon[k]    = ( slt.equip || name:false ).name for k,slt of @slots.weapon
  loadout.structure[k] = ( slt.equip || name:false ).name for k,slt of @slots.structure
  loadout.utility[k]   = ( slt.equip || name:false ).name for k,slt of @slots.utility
  @user.db.loadout[@tplName] = loadout
  @user.db.vehicle = @tplName
  @user.save()
  console.log 'ship', 'saveFor', @user.db.nick, @tplName, util.inspect loadout
  null

Ship::modSlot = (type,slot,item)->
  console.log 'modSlot', type, slot, item
  old = slot.equip # old.destroy() TODO
  if type is 'weapon'
    i = new Weapon @, Item.byId[item].name, slot:slot
  else i = new Outfit Item.byId[item].name
  slot.equip = i
  @updateMods()
  @save() if isServer

Ship::loadSytems = (loadout)->
  # console.log 'loadSytems', util.inspect loadout
  return do @mockSystems unless loadout
  for k,slt of @slots.weapon
    equip = loadout.weapon[k]
    continue unless slt.default or equip
    try slt.equip = new Weapon @, ( if equip then equip else slt.default ), slot:slt
    catch e then console.error 'weap', e, equip
  for k,slt of @slots.structure
    equip = loadout.structure[k]
    continue unless slt.default or equip
    slt.equip = new Outfit if equip then equip else slt.default
  for k,slt of @slots.utility
    equip = loadout.utility[k]
    continue unless slt.default or equip
    slt.equip = new Outfit if equip then equip else slt.default
  null

Ship::mockSystems = -> # equip fake weapons for development
  MockWeap = ["CheatersLaserCannon","CheatersRagnarokBeam","EnygmaSystemsSpearheadLauncher","HeavyRipperTurret","CheatersDroneFighterBay"]
  Mock =
    utility:
      large: Object.keys Item.byType.utility.large
      medium: Object.keys Item.byType.utility.medium
      small: Object.keys Item.byType.utility.small
    structure:
      large: Object.keys Item.byType.structure.large
      medium: Object.keys Item.byType.structure.medium
      small: Object.keys Item.byType.structure.small
  for k,slt of @slots.weapon when not slt.equip?
    continue if MockWeap.length is 0
    # slt.equip = new Outfit slt.default if slt.default
    slt.equip = new Weapon @, MockWeap.shift(), slot:slt
  for k,slt of @slots.structure when not slt.equip?
    slt.equip = new Outfit slt.default if slt.default
    #else slt.equip = new Outfit(Mock.structure[slt.size].shift())
  for k,slt of @slots.utility when not slt.equip?
    slt.equip = new Outfit slt.default if slt.default
    #else slt.equip = new Outfit(Mock.utility[slt.size].shift())
  null
