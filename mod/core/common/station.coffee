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

  ███████ ████████  █████  ████████ ██  ██████  ███    ██
  ██         ██    ██   ██    ██    ██ ██    ██ ████   ██
  ███████    ██    ███████    ██    ██ ██    ██ ██ ██  ██
       ██    ██    ██   ██    ██    ██ ██    ██ ██  ██ ██
  ███████    ██    ██   ██    ██    ██  ██████  ██   ████ ###

$obj.register class Station extends Stellar
  @interfaces: [$obj,Stellar,Station,Shootable]
  @type:'station'
  level:1
  population:1
  shield:1000
  armour:1000
  weapon:'LaserTurretMK'
  interval:1000
  massMax:100
  orbits:[]
  constructor:(opts)->
    super Economy.defaults opts,
      Station.template[opts.template = opts.template || 'Outpost']
    if @mines and @zone
      @produces[@mines] = @allocates[@mines] = min 100, @zone.availableFor @mines
    @shieldMax = @shield
    @armourMax = @armour
    @access = @access || []
    @hostile = []
    @weapon = new Weapon @, @weapon
    @weapon.slot = id:0, equip:@weapon
    @slots = # Mock items for now
      weapon: [ @weapon.slot ]
      structure: [
        id:0, size:'large', equip:null
        id:0, size:'large', equip:null ]
    if isClient
      @name += " (#{@constructor.name})"
      return
    do @weapon.blur = =>
      return if @destructing
      console.log @name, 'lost target' if debug
      @weapon.release()
      Weapon.Defensive.add @weapon
  destructor:->
    Weapon.Defensive.remove @weapon
    @weapon.destructor()
    @weapon = null
    super()
  toJSON: -> return {
    id:        @id
    key:       @key
    sprite:    @sprite
    state:     @state
    name:      @name
    mines:     @mines
    provides:  @provides
    allocates: @allocates
    produces:  @produces
    consumes:  @consumes
    template:  @template
    owner:     @owner
    access:    @access }

Station.blueprint =
  name:       'Station'
  sprite:     'sprite@station-shipyard'
  weapon:     'LaserTurretMK'
  population: 10
  massMax:    100
  shield:     1000
  armour:     1000
  produces:   {}
  provides:   {}
  consumes:   {}
  allocates:  e:100
  mines:      false
  upgrades:   false
  requires:   false

Station.template =
  Outpost:
    sprite:     'station-sphere'
    population: 5
    shield:     10000
    armour:     10000
    provides:   e:100

  Stronghold:
    upgrades:   'Outpost'
    sprite:     'station-sphere'
    population: 5
    shield:     50000
    armour:     10000
    provides:   e:1000

  Fortress:
    upgrades:   'Stronghold'
    sprite:     'base'
    population: 10
    shield:     100000
    armour:     100000
    weapon:     'GraveBeam'
    allocates:  e:1000

  Powerplant:
    sprite:     'station-powerplant'
    population: 0
    provides:   e:5000

  Farm:
    sprite:     'station-agriculture'
    population: 10
    allocates:  e:100, Farmland:100, H20:10
    produces:   Food:100

  LargeFarm:
    upgrades:   'Farm'
    sprite:     'station-commerce3'
    population: 100
    allocates:  e:10, Farmland:1000
    consumes:   H20:20
    produces:   Food:1000

  Habitat:
    upgrades:   'Farm'
    sprite:     'station-commerce'
    population: 100000
    allocates:  e:10, Executives:10, H20:10000, Food:100000
    provides:   Executives:100, Workers:50000

  Mine:
    sprite:     'station-commerce'
    mines:      'H2O'
    population: 2000
    allocates:  e:200, Food:100

  Trade:
    sprite:     'station-commerce2'
    population: 10000
    massMax:    1000000
    allocates:  e:100, Executives:30, Food:1000

  Factory:
    sprite:     'station-shipyard'
    population: 10
    allocates:  e:100, Executives:10, Food:10
    consumes:   Fe:10
    produces:   Kestrel: 1
