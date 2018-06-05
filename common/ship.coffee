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

$obj.register class Ship extends $obj
  @interfaces: [$obj,Ship,Shootable]
  @byName: {}
  @byTpl: {}

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

  armour: 100
  armourMax: 100
  shield: 100
  shieldMax: 100
  shieldRegen: 0.1

  fuel: 100
  fuelMax: 100

  sprite:
    name: 'shuttle'
    cols:  18
    rows:  6
    count: 108
  size: 32

  mount: null
  inventory: null
  slots: null

  constructor: (opts) ->
    @hostile = []
    super opts
    @slots = _.clone @slots
    @tplName = @name
    @mockSystems() # fixme
    @updateMods()
    @mount     = [false,false]; idx = 0
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
  destructor: ->
    $worker.remove @model
    for slot in @slots.weapon when slot and slot.equip
      slot.equip.release()
    super

  reset: ->
    @hostile = []
    @destructing = false
    @energy = @energyMax
    @shield = @shieldMax
    @armour = @armourMax
    @fuel   = @fuelMax

  toJSON: -> id:@id,key:@key,size:@size,state:@state,tpl:@tpl,name:@name

Object.defineProperty Ship::, 'd',
  get:-> @_d || 0
  set:(v)->
    debugger if v is -1
    @_d = v
