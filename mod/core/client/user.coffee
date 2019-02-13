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

###

$public class User
  _vehicle: null
  primary: id: 0
  secondary: id: 0
  constructor: (opts)->
    @[k] = v for k,v of opts
    console.log 'user', @

Object.defineProperty User::, 'vehicle',
  set: (v) ->
    return unless v
    window.VEHICLE = @_vehicle = v
    v.hide()
    v.layer = 'play'
    v.show()
    Sprite.repositionPlayer()
    @vehicleId = v.id
    NUU.emit 'enterVehicle', v
    switchWeap(-1) NUU.player, 'primary'
    switchWeap(-1) NUU.player, 'secondary'
    console.log 'user', 'enterVehicle', v.id if debug
  get: -> @_vehicle

switchWeap = (mutate)-> (player,trigger='primary') ->
  primary = trigger is 'primary'
  ws = player.vehicle.slots.weapon
  ct = ws.length
  tg = player[trigger]
  unless mutate is -1
    id = 0 if isNaN id = parseInt tg.id
    id = max 0, min ct, id
    tg.id = id = mutate id, ct
    if ct is id
      tg.slot = weap = null
      tg.trigger = tg.release = ->
    else
      tg.slot = weap = ws[id].equip
      tg.trigger = -> NET.weap.write 'trigger', primary, id, if TARGET then TARGET.id else undefined
      tg.release = -> NET.weap.write 'release', primary, id, if TARGET then TARGET.id else undefined
  NUU.emit 'switchWeapon', trigger, weap
Ship::setWeap  = (idx,trigger='primary')-> switchWeap( -> idx )(NUU.player,'primary')
Ship::nextWeap = switchWeap (id,ct)-> if ct < 1 then 0 else ++id % (ct + 1 )
Ship::prevWeap = switchWeap (id,ct)-> if ct < 1 then 0 else ( --id + ct ) % (ct + 1 )

NUU.on '$obj:add', (o)->
  # console.log 'yolo', o.id, NUU.player.vehicleId
  NUU.player.vehicle = o if o.id is NUU.player.vehicleId
  null

NET.on 'switchShip', (opts) ->
  console.log 'user', 'switchShip', opts if debug
  NUU.player.vehicle = Ship.byId[opts.i]
  NET.emit 'setMount', opts.m

NET.on 'setMount', (list) ->
  VEHICLE.mount = list
  NUU.player.mountId = id = list.indexOf NUU.player.user.nick
  console.log 'user', 'setMount', id if debug
  NUU.player.mount = VEHICLE.mountSlot[id]
  NUU.player.equip = VEHICLE.mountSlot[id].equip if NUU.player.mount
  VEHICLE.name + '['+ id + ':' + VEHICLE.mountType[id] + ']\n' + VEHICLE.mount
    .map (i,k)-> if i then "[#{k}]i" else false
    .filter (i)-> i
    .join ' '

NUU.frame = 0
