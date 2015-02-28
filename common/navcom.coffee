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

steering = require 'steering'
pursuit = steering.pursuit

class NavCom
  @turnTo: (s,t,limit=5) ->
    dx = s.x - t.x
    dy = s.y - t.y
    dir = 360-((360+floor(atan2(dx,dy)*RAD))%360)
    reldir = dir-((s.d+90)%360)
    return [ true, 180 < reldir or reldir < 0, dir, reldir ] if abs(reldir) >= limit
    return [ false, false, dir, reldir ]

  @autopilot : (s,t) ->
    s.update() unless s.state is manouvering
    t.update() unless t.state is manouvering
    dst = $dist s,t
    [ navTurn, navTurnLeft, dir, reldir ] = NavCom.turnTo s,t,15
    mdx = abs s.mx - t.mx
    mdy = abs s.my - t.my
    intercept = pursuit [t.x,t.y], [s.x,s.y], 10, [s.mx,s.my], [t.mx,t.my]
    navAccel = not navTurn and dst > 100 and mdx + mdy < 10
    navBoost = navAccel and dst > 1000
    return {
      eta       : round( dst / (sqrt( pow(s.mx,2) + pow(s.my,2) ) / 0.04))
      dist      : dst
      accel     : navAccel
      left      : navTurnLeft
      right     : navTurn and not navTurnLeft
      dir       : dir
      reldir    : reldir
      flags     : NET.setFlags [ navAccel, no, navTurn and not navTurnLeft, navTurnLeft, no, no, no, no ] }

$public NavCom