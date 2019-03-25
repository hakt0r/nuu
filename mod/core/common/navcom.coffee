###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
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

$public class NavCom
  @FIX: PI / 2

NavCom.unfixAngle = (d) -> abs ( 360 + 90 + d ) % 360
NavCom.fixAngle   = (d) -> abs ( 270 + d ) % 360
NavCom.absAngle   = (d) -> abs ( 360 + d ) % 360
NavCom.absRad     = (d) -> abs ( TAU + d ) % TAU

NavCom.relAngle = (me,it)->
  ( 360 - (Math.atan2(it.x - me.x, it.y - me.y) * 180 / PI) - 90 ) % 360 / RAD

NavCom.turnTo = (s,t,limit=5)->
  dx = s.x - t.x
  dy = s.y - t.y
  dir = 360 - (( 360 + floor(atan2(dx,dy) * RAD)) % 360 )
  reldir = -180 + $v.umod360 dir - s.d + 90
  return [ true, 180 < reldir or reldir < 0, dir, reldir ] if abs(reldir) >= limit
  return [ false, false, dir, reldir ]

NavCom.maxSpeed = (ship,target,thrust=254)->
  dst = $dist ship, target
  vme = $v.mag ship.m
  vtg = $v.mag target.m
  vdf = $v.mag + $v.sub ship.m.slice(), target.m
  acc = ship.thrustToAccel thrust
  vmx = Speed.max
  dtmatch = ( vme**2 - vtg**2 ) / ( 2*acc )
  ddeccel = ( vmx**2 - vtg**2 ) / ( 2*acc )
  if dst <= dtmatch then vme
  if dst <= ddeccel then vmx
  else max vtg + 3, 0.8 * sqrt abs vtg**2 - ( 2*acc*dst )


NavCom.vectorAddDir = (v,force)->
  angle = PI + $v.heading $v.zero, force
  v.dir = round angle * RAD
  v.dir_diff = $v.reldeg v.current_dir, v.dir
  v.dir_diff_abs = abs v.dir_diff
  v.inRange = v.distance < v.target_zone
  v

NavCom.steer = ( ship, target, context='pursue' )->
  time = NUU.time()
  ship.update time
  target.update time
  v = @[context] ship, target
  v.approach_force = v.force
  v.force = force = $v.sub v.force.slice(), ship.m
  v.error = $v.mag force
  v.error_threshold = max 3,   min 10,  v.distance / 1000
  v.throttle        = max 100, min 254, 101 + v.error/2
  @vectorAddDir v, force
  v.maxSpeed = @maxSpeed ship, target
  return v

NavCom.match = (v)->
  { ship, target } = v
  v.ship_v  = vme = $v.mag ship.m
  v.targ_v  = vtg = $v.mag target.m
  v.diff_v  = $v.mag vdf = $v.sub ship.m.slice(), target.m
  v.ship_a  = acc = ship.thrustToAccel v.thrust
  v.match_d = ( vme**2 - vtg**2 ) / ( 2*v.ship_a )
  v.match_t = ( 2*v.match_d ) / ( vme + vtg )
  [cosd,sind] = $v.normalize vdf.slice()
  [px,py] = ship.p
  [mx,my] = ship.m
  accmatcht2 = acc * ( ticks = v.match_t * TICKi ) * 2
  v.match_p = [ px + mx*ticks + .5*cosd*accmatcht2, py + my*ticks + .5*sind*accmatcht2 ]
  return v

NavCom.pursue = (s,t)->
  # return NavCom.intercept s,t
  v = ship:s, target:t, thrust:254
  NavCom.match v

  local_position     = s.p.slice()
  local_velocity     = s.m.slice()
  local_speed        = $v.mag local_velocity
  target_position    = t.p.slice()
  target_velocity    = t.m.slice()
  target_speed       = $v.mag target_velocity
  shooting_vector    = $v.sub local_position.slice(), target_position
  distance           = $v.mag shooting_vector

  if distance > 10000
    target_future = ( tfs = State.future t.state, NUU.time() + v.match_t ).p
    shooting_vector  = $v.sub local_position.slice(), target_future
    apx_distance     = $v.mag shooting_vector

    if apx_distance < v.match_d
      approximate_time = v.match_t
      max_relative_speed = v.match_d / v.match_t


  unless max_relative_speed
    apx_distance = distance
    max_relative_speed = min Speed.max, sqrt 2 * v.ship_a * ( apx_distance - v.match_d )
    approximate_time = apx_distance / max_relative_speed
    target_future = target_position.slice()

  else target_future = ( tfs = State.future t.state, NUU.time() + approximate_time ).p


  # target_future_velocity = $v.mag tfs.m
  # now we need a vector
  # - towards target_future
  # - at most max_relative_speed
  approach_vector    = $v.sub target_future.slice(), local_position.slice()
  approach_dir       = $v.normalize approach_vector.slice()
  approach_force     = $v.add target_velocity.slice(), $v.mult approach_dir.slice(), max_relative_speed

  return Object.assign(v,
    target_zone: ( t.size + s.size ) * .5
    current_dir: s.d
    eta: approximate_time
    distance: distance
    force: approach_force
    velocity: $v.mag approach_force
    maxSpeed: max_relative_speed )

NavCom.approach = (s,v,d=-1,callback=->)->
  { force, error, distance, dir, dir_diff, dir_diff_abs } = v
  message = 'active'
  if v.inRange and 5 > $v.mag $v.sub s.m.slice(), v.m
    v.recommend = 'execute'
    message += ':exec(' + rdec3(v.dist) + ')'
  else if 0.1 < v.error / $v.mag v.force # v.error_threshold
    if dir_diff_abs > 2
      message += ':setd(' + rdec3(v.dir) + ')'
      v.recommend = 'setdir'
    else
      v.recommend = 'burn'
      v.recommend = 'boost' if 50 < v.error
      message += ':' + v.recommend + '(f' + (rdec3 v.error) + ')'
  else
    v.recommend = 'wait'
    message += ':wait(dF:'+(v.error)+' dD:'+(rdec3 v.dir_diff)+')'
  v.message = message
  v

NavCom.aim = (s,target)->
  s.update time = NUU.time()
  target.update time
  angle = $v.heading(target.p,s.p) * RAD
  v = {}
  v.dir = dir = $v.umod360 angle
  v.dir_diff_abs = abs v.dir_diff = -180 + dir
  v.fire = true # v.dir_diff_abs < 5
  # v.flags = NET.setFlags v.setFlags = [ v.accel, v.retro, v.right||v.left, v.left, v.boost, no, no, no ]
  # if v.dir_diff_abs > 4
  #   v.left  = -180 < v.dir_diff < 0
  #   v.right = not v.left
  # else
  v.setDir = yes
  # s.d = v.dir
  return v
