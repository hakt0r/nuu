###

  * c) 2007-2022 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2022 flyc0r

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

  iff:         ''
  name:        ''

  mass:        20
  cargo:       10

  thrust:      0.1
  turn:        10.0
  type:        0
  throttle:    .75
  inventory:   null
  slots:       null
  mount:       null

  reactorOut:  10.0
  energy:      100
  energyMax:   100

  armour:      100
  armourMax:   100
  shield:      100
  shieldMax:   100
  shieldRegen: 0.1
  fuel:        100
  fuelMax:     100
  fuelRegen:   0

  destructing: false
  disabled:    false
  exploding:   false

  sprite:
    name: 'shuttle'
    cols:  18
    rows:  6
    count: 108
  size: 32


  constructor:(opts)->
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
  ShipModel.remove @
  do @reset; @destructing = yes
  for slot in @slots.weapon when slot and slot.equip
    slot.equip.release()
  $obj::destructor.call @

Ship::reset = ->
  for h in @hostile
    h.target = no if h.target is @
    Array.remove h.hostile, @ if h.hostile
  @hostile = []
  @disabled = @respawning = @locked = @destructing = no
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

Ship.formation =
  wing: [
    [150, -40],[-150 ,-40]
    [300, -80],[-300 ,-80]
    [150,-120],[-150,-120]
    [300,-160],[-300,-160]
  ]

#  █████   ██████ ████████ ██  ██████  ███    ██ ███████
# ██   ██ ██         ██    ██ ██    ██ ████   ██ ██
# ███████ ██         ██    ██ ██    ██ ██ ██  ██ ███████
# ██   ██ ██         ██    ██ ██    ██ ██  ██ ██      ██
# ██   ██  ██████    ██    ██  ██████  ██   ████ ███████

Ship::actions = ['travel','formation','dock']
Ship::defaultAction = ->
  d = VEHICLE.dist TARGET
  mode = 'travel'
  mode = 'formation' if d < 2e3
  mode = 'dock'      if d < TARGET.size + VEHICLE.size
  mode

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

Ship::turnTime = (dir,origin=@d)->
  abs(-180 + $v.umod360 -180 + dir - origin) / ( @turn || 1 )

Ship::turnTimeSigned = (dir,origin=@d)->
  ( -180 + $v.umod360 -180 + dir - origin ) / ( @turn || 1 )

# ███    ███  ██████  ██████  ███████
# ████  ████ ██    ██ ██   ██ ██
# ██ ████ ██ ██    ██ ██   ██ ███████
# ██  ██  ██ ██    ██ ██   ██      ██
# ██      ██  ██████  ██████  ███████

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
            if @mods[k] then @stats[k] += v
            else @stats[k] = v
            @mods[k] = true
  console.log 'smod', 'mass', @stats.mass - @mass if debug
  # apply mods
  # map =
  #   thrust:      @stats.thrust || 100
  #   turn:        @stats.turn   || 100
  #   shield:      @stats.shield || 100
  #   shieldRegen: @stats.shield_regen || 100
  # @stats[k] += @stats[k] * ( v / 100 ) for k,v of map

  # get and scale model values
  @shieldMax = @shield  = @stats.shield
  @shieldRegen = @stats.shield_regen
  @armourMax = @armour = @stats.armour
  @fuelMax   = @fuel   = @stats.fuel * 10
  @turn      = @stats.turn   / 500
  @thrust    = @stats.thrust / 10000

  # add/exchange model-worker
  @lastUpdate = 0
  ShipModel.remove @
  ShipModel.add @
  null

# ███    ███  ██████  ██████  ███████ ██
# ████  ████ ██    ██ ██   ██ ██      ██
# ██ ████ ██ ██    ██ ██   ██ █████   ██
# ██  ██  ██ ██    ██ ██   ██ ██      ██
# ██      ██  ██████  ██████  ███████ ███████

ShipModel = $worker.PauseList listkey:'model', Ship::updateModel = (time)->
  return -1 if @destructing
  return 1000  if @disabled
  a = @state.a || 0
  @fuel = max 0, min @fuelMax, @fuel + @fuelRegen - a
  unless @shield is @shieldMax and @energy is @energyMax
    @energy = min @energyMax, @energy + @reactorOut
    @shield += add = min( @shield + min(@shieldRegen,@energy), @shieldMax) - @shield
    @energy -= add
  return 200 if isClient
  @setState S:$moving if @fuel is 0 and @state.acceleration
  return 200 unless @mount[0] and @lastUpdate + 3000 < time
  NET.health.write @
  @lastUpdate = time
  100

# ███████  █████  ██    ██ ███████
# ██      ██   ██ ██    ██ ██
# ███████ ███████ ██    ██ █████
#      ██ ██   ██  ██  ██  ██
# ███████ ██   ██   ████   ███████

Ship::save = ->
  loadout = weapon:[], structure:[], utility:[]
  loadout.weapon[k]    = ( slt.equip || name:false ).name for k,slt of @slots.weapon
  loadout.structure[k] = ( slt.equip || name:false ).name for k,slt of @slots.structure
  loadout.utility[k]   = ( slt.equip || name:false ).name for k,slt of @slots.utility
  @user.db.loadout[@tplName] = loadout
  @user.db.vehicle = @tplName
  @user.save()
  console.log 'ship', 'saveFor', @user.db.nick, @tplName                      if debug
  console.log ' structure:', loadout.structure.join(' ') if loadout.structure if debug
  console.log ' weapon:',    loadout.weapon.join(' ')    if loadout.utility   if debug
  console.log ' utility:',   loadout.utility.join(' ')   if loadout.weapon    if debug
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
