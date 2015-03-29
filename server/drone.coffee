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

$public class Drone extends Ship
  npc: true
  fire: no
  inRange: no
  primarySlot: null
  primaryWeap: null
  autopilot: null

  constructor: ->
    super tpl:5,target:false,npc:yes,state:
      S: $relative
      x: floor random() * 1000 - 500
      y: floor random() * 1000 - 500
      d: floor random() * 359
      relto: 0

    @name = "ai[##{@id}]"
    @primarySlot = @slots.weapon[0]
    @primaryWeap = @slots.weapon[0].equip
    Drone.list.push @

    $worker.push @autopilot = =>
      if ( not @target or @target.destructing ) and NUU.players[0]?
        closest = null
        closestDist = Infinity
        for p in NUU.players
          if closestDist > d = $dist(@,p.vehicle) and not p.vehicle.destructing
            closestDist = d
            closest =  p.vehicle
        @target = closest
      return 1000 unless @target
      vec = NavCom.autopilot @, @target
      @inRange = vec.dist < 300
      if not @fire and @inRange
        # console.log 'engage', @primaryWeap.id
        NET.weap.write('ai',0,@primarySlot,@,@target)
        @fire = on
      else if @fire and not @inRange
        # console.log 'disengage', @primaryWeap.id
        NET.weap.write('ai',1,@primarySlot,@,@target)
        @fire = off
      unless vec.flags is @flags
        # console.log 'update', @id, vec.state
        @left  = vec.left
        @right = vec.right
        @accel = vec.accel
        @changeState()
      null
    null

  destructor: ->
    Array.remove Drone.list, @
    $worker.remove @autopilot
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
