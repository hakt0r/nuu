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