###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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

                            ▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▒▒▒
                        ▒▒▒▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓▓▒▒▒
                     ▒▒▒▒▓▓▓▓▓▓▓▓▓▓███▓█▓▓▓▓▓▓▓▓▓▓▒▒▒▒
                   ▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒
                 ▒▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒ ▒▒
                 ▓▓▓▒▒▒▒▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒
                ▒▓▓▓▓▓▓▒▒▒▒▒▒▒▓▓▒▒       ▒▒▓▓▓▒▒
                 ▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒           ▒▓▓▒
                 ▒▒▒▒▒  ▒▒▒▒▒            ▒  ▒▓▓▓ ▒▒    ▒
                  ▒▒▒                ▒▒▓▓▓▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒
                  ▒▒▒▒▒▒  ▒▒▓▓▓▒▒▒▒▒▓▓▓▓▒▒▒▓▒▒▓▓▓▓▒▒▒▓▒▒
                     ▒     ▒▒▓▓▒▒▒▒▒▓▓▓▓▒▒           ▒▒▒
                 ▒▒▒        ▒▒▒▒▒▒▒▒▓▓▓▒▓▓▒▒▒▒    ▒▒▒▒▒▒▒▒
                  ▒▓▓▓▒   ▒   ▒▒▒▒▒▒▒▒▒▓▒▒ ▒          ▒▒▒▒▒▒
                    ▓▒▓▒   ▒▒▒▒▒▓▓▓▓▓▒▒▒           ▒  ▒▓▓▒▒▒
                     ▒▓▓▒   ▒▒▒▒▒▒▒▒▓▓▓▒▒▒   ▒▒▒▒    ▒▒▒▒
                                ▒▒▒▒▒▒▒▓▓▒▒▒▒    ▒▒▒▒▓▓▒
                                  ▒▒▒  ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒
                                           ▒▒
                            ▒
                              ▒
                                 ▒▒▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒

██████   ██████  ███    ██   ██████   █████   ██████  ██       ██████  ██     ██
██   ██ ██    ██ ████   ██   ██   ██ ██   ██ ██       ██      ██    ██ ██     ██
██   ██ ██    ██ ██ ██  ██   ██   ██ ███████ ██   ███ ██      ██    ██ ██  █  ██
██   ██ ██    ██ ██  ██ ██   ██   ██ ██   ██ ██    ██ ██      ██    ██ ██ ███ ██
██████   ██████  ██   ████   ██████  ██   ██  ██████  ███████  ██████   ███ ███
                                    https://en.wikipedia.org/wiki/Don_Daglow ###

$public class Production
  @all: new Set
  @zone: {}

Production.Zone = class Zone
  constructor: (root) ->
    @list = new Array
    @list.push @root = root
    Production.zone[@name = root.name] = @

Zone::totalFor = (key)->
  @list
    .map (v)->
      if v.produces and e = v.produces[key]
        if e == true then Infinity else e
      else 0
    .reduce (v,t)-> t + v
Object.defineProperty Zone::, 'energyTotal',   get:-> @totalFor 'e'
Object.defineProperty Zone::, 'farmlandTotal', get:-> @totalFor 'farmland'

Zone::availableFor = (key)->
  return 0 if 0 is have = @totalFor key
  have - @list
    .map (v)-> if v.consumes and e = v.consumes[key] then e else 0
    .reduce (v,t)-> t + v
Object.defineProperty Zone::, 'energyAvailable',   get:-> @availableFor 'e'
Object.defineProperty Zone::, 'farmlandAvailable', get:-> @availableFor 'farmland'

Object.defineProperty Zone::, 'nextCyle', get:(key)-> @list.reduce (v,t)->
  if (e = v.nextCyle) isnt 0 and e > t then e else t || 0

Object.defineProperty Zone::, 'stalled', get:(key)-> @list.filter (i)->
  i.nextCyle is 0

Zone::detach = (stellar)->
  Array.remove @list, stellar
  Production.all.delete stellar

Production.zoneFor = (stellar)->
  return undefined unless root = stellar.buildRoot
  return z if z = Production.zone[name = root.name]
  Production.zone[name] = new Production.Zone root

Production.attach = (stellar)->
  return undefined unless stellar.produces or stellar.consumes
  return unless zone = Production.zoneFor stellar
  zone.list.push stellar if -1 is zone.list.indexOf stellar
  Production.all.add stellar
  stellar.zone = zone

$obj.byName = {}
$obj.register class Stellar extends $obj
  @interfaces: [$obj,Stellar]
  constructor:(opts)->
    super opts
    @lastCycle = @nextCyle = 0
    @name = "#{@constructor.name} [#{@id}]" unless @name
    $obj.byName[@name] = @
    Production.attach @
  destructor:->
    @zone.detach @ if @zone
    super()
  toJSON: -> return {
    id:@id
    key:@key
    sprite:@sprite
    state:@state
    name:@name
    produces:@produces
    consumes:@consumes }
  produce:-> e:@produces.e * @level

Object.defineProperty Stellar::, 'buildRoot', get:->
  p = @; u = {}; u[p.id] = true
  console.log '-', @name if debug
  p.state.update time = NUU.time()
  while r = p.state.relto
    r.state.update time
    if 1500 < d = $dist(p,r)
      console.log 'x:dist', d if debug
      break
    if u[r.id]
      console.log 'x:uniq', r.name if debug
      break
    u[(p = r).id] = true
    console.log '--', p.name if debug
  switch p.constructor.name
    when 'Star','Planet','Moon' then p
    else null

$obj.register class Star extends Stellar
  @interfaces: [$obj,Stellar]
  produces:e:1000

$obj.register class Planet extends Stellar
  @interfaces: [$obj,Stellar]

$obj.register class Moon extends Stellar
  @interfaces: [$obj,Stellar]

$obj.register class Station extends Stellar
  @interfaces: [$obj,Stellar,Station,Shootable]
  @type:'station'
  level:1
  population:1
  shield:1000
  armour:1000
  weapon:'LaserTurretMK'
  constructor:(opts)->
    super opts
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
    return unless isServer
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
    id:       @id
    key:      @key
    sprite:   @sprite
    state:    @state
    name:     @name
    produces: @produces
    consumes: @consumes
    owner:    @owner
    access:   @access }

$obj.register class Station.Powerplant extends Station
  @interfaces: [$obj,Stellar,Station,Shootable]
  sprite: 'station-powerplant'
  population:0
  consumes:r:H2:10,Pu:1

$obj.register class Station.Farm extends Station
  @interfaces: [$obj,Stellar,Station,Shootable]
  sprite:'station-agriculture'
  population:10
  consumes:e:1,H20:10,farmland:1
  produces:Food:1

$obj.register class Station.LargeFarm extends Station
  @interfaces: [$obj,Stellar,Station,Shootable]
  sprite:'station-commerce3'
  upgrades:Station.Farm
  population:100
  consumes:e:10,H20:20,farmland:10
  produces:Food:10

$obj.register class Station.Habitat extends Station
  @interfaces: [$obj,Stellar,Station,Shootable]
  sprite:'station-commerce'
  upgrades:Station.Farm
  population:100
  consumes:e:10,H20:10,Food:10
  produces:Executive:1,Workers:10

$obj.register class Station.Mine extends Station
  @interfaces: [$obj,Stellar,Station,Shootable]
  sprite:'station-commerce2'
  population:10
  consumes:e:1,Food:10
  # produces whater is mined

$obj.register class Station.Factory extends Station
  @interfaces: [$obj,Stellar,Station,Shootable]
  sprite:'station-shipyard'
  upgrades:Station.Mine
  produces:Kestrel:1
  consumes:e:1,Fe:10,Food:10
  population:10

$obj.register class Station.Fortress extends Station
  @interfaces: [$obj,Stellar,Station,Shootable]
  sprite:'base'
  population:10
  consumes:e:1000
  produces:{}
  constructor:(opts)->
    opts.shield = opts.shield || 10000
    opts.armour = opts.armour || 10000
    opts.weapon = opts.weapon || 'GraveBeam'
    super opts
