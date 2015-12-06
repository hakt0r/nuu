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

$public class Drone extends Ship
  npc: true
  fire: no
  inRange: no
  primarySlot: null
  primaryWeap: null
  autopilot: null

  constructor: ->
    stel = $obj.byId[ Array.random Object.keys Stellar.byId ]
    stel.update()
    @flags = -1

    super tpl:5, target:false, npc:yes, state:
      S: $moving
      x: floor random() * 1000 - 500 + stel.x
      y: floor random() * 1000 - 500 + stel.y
      d: floor random() * 359

    # console.log 'Drone at', stel.name

    @name = "ai[##{@id}]"
    @primarySlot = @slots.weapon[0]
    @primaryWeap = @slots.weapon[0].equip
    Drone.list.push @

    $worker.push @worker = @autopilot.bind @

  autopilot: ->
    do @update
    if ( not @target or @target.destructing )
      @selectTarget()
    return 1000 unless @target
    if ( @inRange = abs(distance = $dist(@,@target)) < 150 )
      v = NavCom.steer @, @target, 'aim'
      if v.fire and not @fire
        NET.weap.write('ai',0,@primarySlot,@,@target)
      else if @fire and not v.fire
        NET.weap.write('ai',1,@primarySlot,@,@target)
    else v = NavCom.approach @, ( NavCom.steer @, @target, 'pursue' )
    { turn, turnLeft, @accel, @boost, @retro, @fire } = v
    @left = turnLeft
    @right = turn and not turnLeft
    do @changeState if ( @flags isnt v.flags ) or v.setDir
    33

  selectTarget: ->
    @target = null
    return unless NUU.users.length > 0
    closest = null
    closestDist = Infinity
    for p in NUU.users
      if ( closestDist > d = $dist(@,p.vehicle) ) and ( not p.vehicle.destructing ) and ( abs(d) < 1000000 )
        closestDist = d
        closest =  p.vehicle
    return @target = null if closestDist > 5000
    console.log 'Drone SELECTED', closestDist
    @target = closest
    null

  destructor: ->
    Array.remove Drone.list, @
    $worker.remove @worker
    NET.operation.write @, 'remove'
    super
    off

  ###
    Static Members
  ###

  @list: []
  @autospawn: (opts={})-> $worker.push =>
    drones = @list.length
    if drones < opts.max
      dt = opts.max - drones
      new Drone for i in [0...dt]
    1000
