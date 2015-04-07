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

class NavCom
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

  @seek: (ship, target, maxSpeed, slowingRadius) ->
    maxSpeed      = @maxSpeed      ship, target unless maxSpeed
    slowingRadius = @slowingRadius ship, target unless slowingRadius
    Pship         = ship.p   # getter function anyways
    Ptarget       = target.p # getter function anyways
    Fship         = ship.m.slice()
    Ftarget       = target.m.slice()
    deltaP        = $v.mag desired = $v.sub(Ptarget,Pship)
    desired       = $v.normalize desired
    if deltaP <= slowingRadius
         $v.mult desired, maxSpeed * deltaP / slowingRadius
    else $v.mult desired, maxSpeed
    force = $v.sub desired, Fship

  @pursuit: (ship, target, maxSpeed, slowingRadius) ->
    maxSpeed      = @maxSpeed      ship, target unless maxSpeed
    slowingRadius = @slowingRadius ship, target unless slowingRadius
    Pship         = ship.p   # getter function anyways
    Ptarget       = target.p # getter function anyways
    Fship         = ship.m.slice()
    Ftarget       = target.m.slice()
    deltaP        = $v.sub Ptarget, Pship
    updatesNeeded = $v.mag(deltaP) / maxSpeed
    tv            = $v.mult Ftarget.slice(), updatesNeeded
    prediction    = $v.add  Ftarget.slice(), tv
    return @seek ship, { p:prediction, m: Ftarget }, maxSpeed, slowingRadius

  @maxSpeed: (ship,target) ->
    td = $dist ship, target
    tm = abs(target.m[0]) + abs(target.m[1])
    mx = Speed.max

  @slowingRadius: (ship,target) ->
    a = ship.state.a
    a += ship.state.ab
    t = @maxSpeed(ship,target) / a
    slowingRadius = 0.5 * a * t * t

  @FIX: PI / 2
  @steer: (ship,target,strategy='seek') ->
    ship.update()
    target.update()
    maxSpeed = @maxSpeed ship, target
    slowingRadius = @slowingRadius ship, target
    force = @[strategy] ship, target, maxSpeed, slowingRadius
    rad = @absRad( @FIX + atan2(-force[0],force[1]) )
    dir = @absAngle parseInt(rad * RAD)
    force[0] = -force[0]
    force[1] = -force[1]
    return force: force, dir: dir, rad: rad, slowingRadius: slowingRadius, maxSpeed: maxSpeed

  @autopilot : (s,t) ->
    dst = $dist s,t
    setdir = turn = turnLeft = accel = retro = boost = dir = no
    state = 'undecided'
    if dst > t.size * 1.5 # approach
      state = 'approach'
      vec = NavCom.steer s,t,'seek'
      dir = vec.dir
      diff = parseInt $v.dist($v.zero,vec.force)
      ddiff = $v.smod( s.d - dir + 180 ) - 180
      if diff > 10
        if abs( ddiff ) > 15
          turn = yes
          turnLeft = 180 > ddiff > 0
          state += ':bear('+diff+","+ddiff+','+s.d+','+dir+')'
        else if 0 < abs( ddiff ) <= 10
          state += ':setd('+dir+')'
          setdir = yes
        else if 0 < diff
          accel = yes
          boost = yes if 10 < diff
          state += ':accl('+diff+')'
        else
          retro = yes
          state += ':decl('+diff+')'
      else # travel
        state += ':wait(dF:'+diff+' sR:'+hdist(parseInt(vec.slowingRadius))+')'
    else
      s.update()
      t.update()
      [ turn, turnLeft, dir, reldir ] = NavCom.turnTo s,t,15
      state = 'finalApproach:' + dir
    return {
      state:  state
      eta:    round( dst / (sqrt( pow(s.m[0],2) + pow(s.m[1],2) ) / 0.04))
      dist:   dst
      accel:  accel
      retro:  retro
      boost:  boost
      left:   turnLeft
      right:  turn and not turnLeft
      setdir: setdir
      dir:    dir
      reldir: reldir
      flags:  NET.setFlags [ accel, retro, turn and not turnLeft, turnLeft, boost, no, no, no ] }

$public NavCom