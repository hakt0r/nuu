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

$public class Player
  _vehicle: null
  primary: id: 0
  secondary: id: 0
  constructor: (opts)->
    @[k] = k for k,v of opts
    console.log 'player$', @

Object.defineProperty Player::, 'vehicle',
  set: (v) ->
    return unless v
    window.VEHICLE = @_vehicle = v
    v.hide()
    v.layer = 'play'
    v.show()
    Sprite.repositionPlayer()
    @vehicleId = v.id
    NUU.emit 'enterVehicle', v
    console.log 'enterVehicle', v.id if debug
  get: -> @_vehicle

Player::FighterBaySlotHook = ->
  return false unless NUU.player.equip and NUU.player.equip.type is 'fighter bay'
  NET.json.write switchShip: Item.byName[NUU.player.equip.stats.ammo.replace(' ','')].stats.ship
  true

app.on '$obj:add', (o)->
  # console.log 'yolo', o.id, NUU.player.vehicleId
  NUU.player.vehicle = o if o.id is NUU.player.vehicleId
  null

NET.on 'switchShip', (opts) ->
  console.log 'switchShip', opts if debug
  NUU.player.mountId = parseInt opts.m
  NUU.player.vehicle = Ship.byId[opts.i]
  NET.emit 'switchMount', opts.m

NET.on 'switchMount', (id) ->
  console.log 'NET:switchMount', id if debug
  id = parseInt id
  VEHICLE.mount[NUU.player.mountId] = null
  VEHICLE.mount[id] = NUU.player
  NUU.player.mountId = id
  NUU.player.mount = VEHICLE.mountSlot[id]
  NUU.player.equip = VEHICLE.mountSlot[id].equip if NUU.player.mount
  HUD.widget 'mount', VEHICLE.name + '['+ id + ':' + VEHICLE.mountType[id] + ']', true

NUU.frame = 0
