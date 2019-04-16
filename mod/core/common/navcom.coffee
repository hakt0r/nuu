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

NavCom.unfixAngle = (d) -> abs ( 360 + 90 + d ) % 360
NavCom.fixAngle   = (d) -> abs ( 270 + d      ) % 360
NavCom.absAngle   = (d) -> abs ( 360 + d      ) % 360
NavCom.absRad     = (d) -> abs ( TAU + d      ) % TAU

NavCom.relAngle = (me,it)->
  ( 360 - (Math.atan2(it.x - me.x, it.y - me.y) * 180 / PI) - 90 ) % 360 / RAD

NavCom.turnTime = (s,dir)->
  abs( -180 + $v.umod360 -180 + dir - s.d ) / ( s.turn || 1 )


NavCom.vectorAddDir = (v,velocity)->
  angle = PI + $v.head $v.zero, velocity
  v.dir = round angle * RAD
  v.dir_diff = $v.reldeg v.current_dir, v.dir
  v.dir_diff_abs = abs v.dir_diff
  v.inRange = v.approach_d < v.target_zone
  v

NavCom.steer = ( ship, target, context='pursue' )->
  ship  .update time = NUU.time()
  target.update time
  v = @[context] ship, target
  v.steer_v = velocity = $v.sub v.approach_v.slice(), ship.v
  v.error   = $v.mag velocity
  v.error_threshold = min 10,  v.approach_d / 100000
  v.setThrottle = v.thrust
  v.steer_a = acc = ship.thrustToAccel v.setThrottle
  v.steer_d = ( v.ship_v**2 - v.error**2 ) / ( 2*acc )
  angle = RADi * ( PI + v.creep_h )
  v.steer_t = abs NavCom.turnTime(ship,angle) + (2*v.steer_d) / ( v.ship_v+v.error )
  @vectorAddDir v, v.steer_v
  v.creep_s = @creep_s ship, target
  return v

NavCom.pursue = (s,t)->
  v = ship:s, target:t, current_dir:s.d, target_zone:s.size
  v.local_p     = s.p.slice()
  v.local_v     = s.v.slice()
  v.local_s     = $v.mag v.local_v
  v.target_p    = t.p.slice()
  v.target_v    = t.v.slice()
  v.target_s    = $v.mag v.target_v
  v.approach    = $v.sub v.target_p.slice(), v.local_p
  v.approach_d  = $v.mag v.approach
  v.approach_h  = $v.head v.approach, $v.zero
  set_acceleration = (thrust)->
    v.ship_as     = s.thrustToAccel v.thrust = thrust
    v.match       = $v.sub v.local_v.slice(), v.target_v
    v.match_s     = $v.mag v.match
    v.match_h     = $v.head $v.zero, v.match
    v.match_tt    = s.turnTime v.match_h * RADi
    v.match_td    = v.local_s * v.match_tt
    v.match_d     = ( v.target_s**2 - v.local_s**2 ) / 2*v.ship_as
    v.match_t     = ( 2 * v.match_d ) / ( v.local_s + v.target_s ) + v.match_tt
    v.match_d    += v.match_td
    v.glide_d     = max 0, v.approach_d - v.match_d
  set_acceleration if 1000000 < v.approach_d then 255 else 200
  v.creep_s     = min Speed.max, .5 * sqrt abs v.match_s**2 - ( 2 * v.ship_as * ( v.approach_d - v.match_d ) )
  if 1 > v.creep_s / v.match_s
    set_acceleration 150 if v.match_t < 500 # retry with reduced acc
    set_acceleration 101 if v.match_t < 500
    set_acceleration 249 if v.match_t < 500
  else
    # set_acceleration 255 if v.approach_d < v.match_d and 1000000 < v.approach_d # retry with increased acc
  v.creep       = $v.mult $v.norm( v.approach.slice() ), if v.approach_d < v.match_d then -v.creep_s else v.creep_s
  v.creep_h     = $v.head ( $v.mult v.creep.slice(), -1 ), $v.zero
  v.approach_v  = $v.add v.target_v.slice(), v.creep.slice()
  v.approach_vh = $v.head v.approach_v, $v.zero
  v.approach_vs = $v.mag v.approach_v
  v.approach_t  = v.match_t + ( v.glide_d )
  v.wait_t      = v.match_t
  v.wait_t      = v.glide_t if v.approach_d > v.match_t
  return Object.assign v,
    eta:   v.approach_t
    speed: v.creep_s

NavCom.decide = (s,v)->
  message = 'active'
  if v.inRange and 3 > v.match_s
         message += ":#{v.recommend = 'execute'}(#{rdec3 v.dist}"
  else if v.error > v.error_threshold
    if v.dir_diff_abs > 1
         message += ":#{v.recommend = 'setdir'}(d#{rdec3 v.dir})"
    else message += ":#{v.recommend = 'burn'  }(f#{rdec3 v.error})"
  else   message += ":#{v.recommend = 'wait'  }(t#{rdec3 v.wait_t} dF:#{rdec3 v.error} dD:#{rdec3 v.dir_diff})"
  v.message = message
  return v

#
#  ██  ██  ██    ██ ██████  ██████   █████  ████████ ███████
# ████████ ██    ██ ██   ██ ██   ██ ██   ██    ██    ██
#  ██  ██  ██    ██ ██████  ██   ██ ███████    ██    █████
# ████████ ██    ██ ██      ██   ██ ██   ██    ██    ██
#  ██  ██   ██████  ██      ██████  ██   ██    ██    ███████
#

NavCom.turnTo = (s,t,limit=5)->
  dx = s.x - t.x
  dy = s.y - t.y
  dir = 360 - (( 360 + floor(atan2(dx,dy) * RAD)) % 360 )
  reldir = -180 + $v.umod360 dir - s.d + 90
  return [ true, 180 < reldir or reldir < 0, dir, reldir ] if abs(reldir) >= limit
  return [ false, false, dir, reldir ]

NavCom.aim = (s,target)->
  s.update time = NUU.time()
  target.update time
  angle = $v.head(target.p,s.p) * RAD
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

NavCom.match = (v)->
  { ship, target } = v
  v.ship_v  = vme = $v.mag ship.v
  v.targ_v  = vtg = $v.mag target.v
  v.diff_v  = $v.mag v.match_v = vdf = $v.sub ship.v.slice(), target.v
  v.ship_a  = acc = ship.thrustToAccel v.thrust
  v.match_d = ( vme**2 - vtg**2 ) / ( 2*v.ship_a )
  v.match_t = ( 2*v.match_d ) / ( vme + vtg )
  [cosd,sind] = $v.norm vdf.slice()
  [px,py] = ship.p
  [vx,vy] = ship.v
  accmatcht2 = acc * ( t = v.match_t ) * 2
  v.match_p = [ px + vx*t + .5*cosd*accmatcht2, py + vy*t + .5*sind*accmatcht2 ]
  return v

NavCom.creep_s = (ship,target,thrust=254)->
  dst = $dist ship, target
  sme = $v.mag ship.v
  stg = $v.mag target.v
  vdf = $v.mag + $v.sub ship.v.slice(), target.v
  acc = ship.thrustToAccel thrust
  smx = Speed.max
  dtmatch = ( sme**2 - stg**2 ) / ( 2*acc )
  ddeccel = ( smx**2 - stg**2 ) / ( 2*acc )
  if      dst <= dtmatch then max sme, stg
  else if dst >= ddeccel then smx
  else max stg, sqrt abs stg**2 - ( 2*acc*dst )
