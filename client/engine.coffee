###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
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

debug = off

$public class Player
  _vehicle: null
  primary: id: 0
  secondary: id: 0
  constructor: (@vehicle)->

Object.defineProperty Player::, 'vehicle',
  set: (v) ->
    # console.log 'enterVehicle', v.id
    NUU.vehicle = @_vehicle = v
    v.hide()
    v.layer = 'play'
    v.show()
    Sprite.repositionPlayer()
  get: -> @_vehicle

NUU.frame = 0
NUU.target = null
NUU.targetId = 0
NUU.targetClass = 0

NUU.init = (callback)->
  async.parallel [
    (c) -> $.ajax('/build/objects.json').success (result) ->
      Item.init result
      c null
  ], =>
    if debug then $timeout 500, => NET.login 'anx', sha512(''), =>
      vt.unfocus()
      callback null if callback
    else @loginPrompt()
    rules @
    callback null if callback
  null

NUU.on 'start', ->
  @time = -> Ping.remoteTime()
  @thread 'ping', 500,  Ping.send
