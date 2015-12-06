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
    # console.log 'enterVehicle', v.id
    window.VEHICLE = @_vehicle = v
    v.hide()
    v.layer = 'play'
    v.show()
    Sprite.repositionPlayer()
    @vehicleId = v.id
  get: -> @_vehicle

app.on '$obj:add', (o)->
  # console.log 'yolo', o.id, NUU.player.vehicleId
  NUU.player.vehicle = o if o.id is NUU.player.vehicleId
  null

NET.on 'switchShip', (opts) ->
  # console.log 'switchShip', opts
  NUU.player.vehicleId = opts.i
  NUU.player.mountId = opts.m
  NUU.player.vehicle = Ship.byId[opts.i]

NET.on 'switchMount', (id) ->
  NUU.player.vehicle.mount[NUU.player.mountId] = null
  NUU.player.mountId = id
  NUU.player.vehicle.mount[id] = NUU.player

NUU.frame = 0
NUU.target = null
NUU.targetId = 0
NUU.targetClass = 0
