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
  @interfaces: [$obj,Ship]
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
    @mockSystems() # fixme
    @updateMods()
    @mount     = [null,null]
    @mountSlot = [null,null]
    @mountType = ['helm','passenger']
    for slot in @slots.weapon when slot and slot.equip
      @mountSlot.push slot
      @mount.push null
      switch slot.equip.type
        when 'fighter bay'
          @mountType.push 'fighter'
        else @mountType.push 'weap'
    null

  destructor: ->
    $worker.remove @model
    for slot in @slots.weapon when slot and slot.equip
      slot.equip.release()
    super

  nextWeap: (player,trigger='primary') ->
    primary = trigger is 'primary'
    ws = player.vehicle.slots.weapon
    ct = ws.length - 1
    tg = player[trigger]
    tg.id   = ++tg.id % ct
    tg.slot = ws[tg.id].equip
    tg.trigger = -> NET.weap.write 'trigger', primary, tg.id, if TARGET then TARGET.id else undefined
    tg.release = -> NET.weap.write 'release', primary, tg.id, if TARGET then TARGET.id else undefined

  prevWeap: (player,trigger='primary') ->
    primary = trigger is 'primary'
    ws = player.vehicle.slots.weapon
    ct = ws.length - 1
    tg = player[trigger]
    tg.id = ( --tg.id + ct ) % ct
    tg.slot = ws[tg.id].equip
    tg.trigger = -> NET.weap.write 'trigger', primary, tg.id, if TARGET then TARGET.id else undefined
    tg.release = -> NET.weap.write 'release', primary, tg.id, if TARGET then TARGET.id else undefined

  hit: (src,wp) ->
    return if @destructing
    dmg = wp.stats
    if @shield > 0
      @shield -= dmg.penetrate
      if @shield < 0
        @shield = 0
        @armour -= dmg.physical
        NUU.emit 'ship:shieldsDown', @, src
    else @armour -= dmg.penetrate + dmg.physical
    if 0 < @armour < 25 and @disabled > 10
      NUU.emit 'ship:disabled', @, src
    else if @armour < 0
      @armour = 0
      @shield = 0
      @destructing = true
      NUU.emit 'ship:destroyed', @, src
    NUU.emit 'ship:hit', @, src, @shield, @armour
    NET.health.write @

  reset: ->
    @hostile = []
    @destructing = false
    @energy = @energyMax
    @shield = @shieldMax
    @armour = @armourMax
    @fuel   = @fuelMax
