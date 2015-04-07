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

    update    = false
    state     = 0
    prevState = 0
    prototype = Item.tpl[@tpl]
    vdiff     = [0,0]

    $worker.push @autopilot = =>

      @selectTarget() if ( not @target or @target.destructing )
      return 1000 unless @target

      @update @target.update()
      dx = parseInt @target.x - @x
      dy = parseInt @target.y - @y
      dst = dx * dx + dy * dy

      # moving target
      if ( spd = $v.mag @m ) > 0
        tfuture = $v.add(@target.p,$v.mult(@target.m.slice(), dst / spd ))
        dx = parseInt tfuture[0] - @x
        dy = parseInt tfuture[1] - @y
        dst = dx * dx + dy * dy
      F  = $v.mult($v.normalize($v.sub(tfuture-@p)),30)
      dF = $v.sub(@m.slice(),F)
      DF = $v.mag dF

      dir = parseInt NavCom.fixAngle( atan2( dx, -dy ) * RAD )
      dif = $v.smod( dir - @d + 180 ) - 180

      state = 1
      @accel = off
      if abs( dif ) is 0
        unless ( @inRange = dst < 300 )
          if DF > 1
            state = 1
            @accel = true
          if @fire
            # console.log 'disengage', @primaryWeap.id
            NET.weap.write('ai',1,@primarySlot,@,@target)
            @fire = off
        else unless @fire
          # console.log 'engage', @primaryWeap.id
          NET.weap.write('ai',0,@primarySlot,@,@target)
          @fire = on
      else if abs( dif ) > 10
        @left  = -180 < dif < 0
        @right = not @left
        state = if @left then 3 else 4
      else if 4 < abs( dif ) < 11
        @left = @right = no
        @d = dir
        state = 5
      @changeState() if state isnt prevState
      prevState = state
      null
    null

  selectTarget: ->
    @target = null
    if NUU.players[0]?
      closest = null
      closestDist = Infinity
      for p in NUU.players
        if closestDist > d = $dist(@,p.vehicle) and not p.vehicle.destructing
          closestDist = d
          closest =  p.vehicle
      @target = closest

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
