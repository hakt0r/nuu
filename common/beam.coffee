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

###
  this creates the game model, not an instance of a shot
  think of it as a factory
###

lineCircleCollide = (a, b, c, r) ->
  closest = a.slice()
  seg     = b.slice()
  ptr     = c.slice()
  $v.sub seg, a
  $v.sub ptr, a
  segu = $v.normalize seg
  prl  = $v.dot ptr, segu
  if prl > $v.dist a, b then closest = b.slice()
  else if prl > 0 then $v.add closest, $v.mult(segu,prl)
  dist = $v.dist c, closest
  dist < r

class BeamInstance
  src: null
  weap: null
  target: null
  ms: null
  tt: null
  range: null
  constructor: (@src,@weap,@range,@target,@ms,@tt)->

Weapon.Beam =->
  @release = $void
  @trigger = (src,vehicle,slot,target)=>
    if @release isnt $void
      # console.log 'emergency-release trigger'
      do @release
    @duration = @stats.duration.$t * 100
    @range = @stats.range || 300
    # TODO: implement recharge
    @release = =>
      @release = $void
      detector.stop = true
      delete Weapon.beam[vehicle.id]
      off
    detector = =>
      return @release() if v.tt < TIME
      dir = NavCom.unfixAngle(vehicle.d) / RAD
      tpos = target.p
      vpos = vehicle.p
      bend = [
        vehicle.x + sin(dir) * @range
        vehicle.y - cos(dir) * @range ]
      if lineCircleCollide vpos, bend, tpos, target.size
        target.hit(vehicle,v.weap) unless isClient
      null
    NUU.emit 'shot', Weapon.beam[vehicle.id] = v =
      new BeamInstance vehicle, slot.equip, @range, target, TIME, TIME + @duration
    $worker.push slot.worker = detector
    Weapon.hostility vehicle, target
    null
