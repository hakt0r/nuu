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

Ship::updateMods = -> # calculate mods
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
  console.log 'mass::', @stats.mass - @mass if debug

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
  @fuelMax   = @fuel   = @fuel * 1000
  @turn      = @turn    / 10
  @thrust    = @thrust  / 100

  # add/exchange model-worker
  add = null
  $worker.remove @model if @model
  lastUpdate = 0
  $worker.push @model = =>
    return 1000 if @destructing
    # return 1000 if @fuel <= 0
    @fuel -= max 0, @state.a if @state.a
    unless @shield is @shieldMax and @energy is @energyMax
      @energy = min @energyMax, @energy + @reactorOut
      @shield += add = min( @shield + min(@shieldRegen,@energy), @shieldMax) - @shield
      @energy -= add
    return unless isServer and @mount[0] and lastUpdate + 3000 < TIME
    NET.health.write @
    lastUpdate = TIME
    return
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
    slt.equip = new Weapon MockWeap.shift()
  for k,slt of @slots.structure when not slt.equip?
    slt.equip = new Outfit slt.default if slt.default
    #else slt.equip = new Outfit(Mock.structure[slt.size].shift())
  for k,slt of @slots.utility when not slt.equip?
    slt.equip = new Outfit slt.default if slt.default
    #else slt.equip = new Outfit(Mock.utility[slt.size].shift())
