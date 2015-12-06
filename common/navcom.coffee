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

class NavCom
  @FIX: PI / 2 #
  @unfixAngle: (d) -> abs ( 360 + 90 + d ) % 360
  @fixAngle:   (d) -> abs ( 270 + d ) % 360
  @absAngle:   (d) -> abs ( 360 + d ) % 360
  @absRad:     (d) -> abs ( TAU + d ) % TAU

  @relAngle: (me,it) ->
    ( 360 - (Math.atan2(it.x - me.x, it.y - me.y) * 180 / PI) - 90 ) % 360 / RAD

  @turnTo: (s,t,limit=5) ->
    dx = s.x - t.x
    dy = s.y - t.y
    dir = 360-((360+floor(atan2(dx,dy)*RAD))%360)
    reldir = dir-((s.d+90)%360)
    return [ true, 180 < reldir or reldir < 0, dir, reldir ] if abs(reldir) >= limit
    return [ false, false, dir, reldir ]

  @maxSpeed: (ship,target) ->
    # 5 + min( 1, $dist(ship,target) / 80000000 ) * ( Speed.max - 5 )
    td = $dist ship, target
    mx = Speed.max
    if      td > 80000000 then mx
    else if td > 10000000 then mx * 0.2
    else if td > 1000000  then mx * 0.02
    else if td > 100000   then 400
    else if td > 10000    then 150
    else if td > 1000     then 15
    else if td > 100      then 5
    else if td > 10       then 2
    else 1

  @slowingRadius: (ship,target) ->
    a = ship.state.a
    a += ship.state.ab
    t = @maxSpeed(ship,target) / a
    slowingRadius = 0.5 * a * t * t

  @vectorAddDir : (v,force)->
    angle = atan2 force[0], -force[1]
    v.rad = rad = @absRad( @FIX + angle )
    v.dir = dir = parseInt NavCom.fixAngle( angle * RAD )
    v.dir_diff_abs = abs ( v.dir_diff = ( v.dir - v.current_dir ) % 360 )
    v

  @steer: ( ship, target, strategy='seek' ) ->
    ship.update(); target.update()
    v = @[strategy] ship, target, ( maxSpeed = @maxSpeed ship, target )
    v.approach_force = v.force
    v.force = force = $v.sub v.force.slice(), ship.m
    v.error = $v.mag force
    @vectorAddDir v, force
    v.maxSpeed = maxSpeed
    return v

  @pursue: (s,t,max_relative_speed,R)->
    local_position     = s.p.slice()
    local_inertia      = s.m.slice()
    local_speed        = $v.mag local_inertia
    target_position    = t.p.slice()
    target_inertia     = t.m.slice()
    target_speed       = $v.mag target_inertia
    shooting_vector    = $v.sub local_position.slice(), target_position
    distance           = $v.mag shooting_vector
    approximate_time   = distance / max_relative_speed

    if target_speed > 0
      target_future = $v.add( target_position.slice(), $v.mult( target_inertia.slice(), approximate_time ) )
      local_future  = $v.add( local_position.slice(),  $v.mult( target_inertia.slice(), approximate_time ) )
    else
      local_future  = local_position
      target_future = target_position

    # now we need a vector
    # - towards target_future
    # - at most max_relative_speed
    approach_vector    = $v.sub target_future.slice(), local_future
    approach_dir       = $v.normalize approach_vector.slice()
    approach_force     = $v.mult approach_dir.slice(), max_relative_speed
    max_absolute_speed = $v.mag ( $v.add ( $v.mult approach_dir.slice(), max_relative_speed ), target_speed )
    approach_force = $v.add approach_force, target_inertia

    return @vectorAddDir (
      current_dir: s.d
      eta: approximate_time
      distance: distance
      force: approach_force
      velocity: $v.mag approach_force
      maxSpeed: max_relative_speed
    ), approach_force

  @approach : (s,v,d=-1,callback=->) ->
    { force, error, distance, dir, dir_diff, dir_diff_abs } = v
    message = 'active'
    if ( -1 isnt d ) and ( v.dist < d )
      return callback
    v.turn = v.turnLeft = v.accel = v.retro = v.boost = no
    if v.error > 2
      if dir_diff_abs > 15
        v.turn = yes
        v.turnLeft = -180 < dir_diff < 0
        message += ':bear('+(round dir_diff)+'/'+(round dir_diff_abs)+' > '+s.d+'/'+v.dir+')'
      else if dir_diff_abs > 0
        v.setdir = yes
        message += ':setd('+v.dir+')'
      else if 1 < v.error
        v.accel = yes
        v.boost = 100 < v.error
        message += ':accl(f'+(round v.error)+'/d'+dir_diff+' > '+s.d+'/'+v.dir+')'
      # else TODO:
      #   v.retro = yes
      #   message += ':decl('+(round v.error)+')'
    else message += ':wait(dF:'+(round v.error)
    v.message = message
    s.d = v.dir if v.setdir
    v.flags = NET.setFlags v.setFlags = [ v.accel, v.retro, v.turn and not v.turnLeft, v.turnLeft, v.boost, no, no, no ]
    v

  @aim: (s,target)->
    force = $v.sub target.p, s.p
    v = @vectorAddDir (
      left: no
      right: no
      accel: no
      boost: no
      distance: $dist s,target
      velocity: $v.mag force
      current_dir: s.d
      force: force
      maxSpeed: 0
      eta: 0
    ), force
    v.fire = v.dir_diff_abs is 0
    if v.dir_diff_abs > 4
      v.left  = -180 < v.dir_diff < 0
      v.right = not v.left
    else
      v.left = v.right = no
      v.flags = NET.setFlags v.setFlags = [ v.accel, v.retro, v.turn and not v.turnLeft, v.turnLeft, v.boost, no, no, no ]
      v.setDir = yes
      s.d = v.dir
    return v

$public NavCom
