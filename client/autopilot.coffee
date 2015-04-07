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

$public class Autopilot

  active:   no
  plan:     'land'
  strategy: 'seek'
  ship:      null
  target:    null
  interval:  null

  constructor: (ship, target, plan='land')->
    @commit.apply @, arguments
    @start()

  commit: (@ship, @target, @plan='land')->

  start: ->
    @stop() if @active
    @active = yes
    @interval = setInterval @tick(), 20

  stop: -> if @active
    @active = no
    clearInterval @interval
    @interval = null

  tick: -> =>
    old = @ship.flags
    message = 'approach'
    v = NavCom.steer @ship, @target, @strategy
    v.turn = v.turnLeft = v.accel = v.retro = v.boost = no
    if ( v.diff = parseInt $v.dist($v.zero,v.force) ) > 10
      if abs( v.ddiff = $v.smod( @ship.d - v.dir + 180 ) - 180 ) > 15
        v.turn = yes
        v.turnLeft = 180 > v.ddiff > 0
        message += ':bear('+v.diff+","+v.ddiff+','+@ship.d+','+v.dir+')'
      else if 0 < v.diff
        v.accel = yes
        v.boost = yes if 100 < v.diff
        message += ':accl('+v.diff+')'
      else
        v.retro = yes
        message += ':decl('+v.diff+')'
      if 0 < abs( v.ddiff ) <= 10
        message += ':setd('+v.dir+')'
        v.setdir = yes
    else message += ':wait(dF:'+v.diff+' sR:'+hdist(parseInt(v.slowingRadius))+')'
    v.message = message
    @ship.d = v.dir if v.setdir
    if v.setdir or old isnt v.flags
      NET.state.write @ship, v.flags = NET.setFlags [ v.accel, v.retro, v.turn and not v.turnLeft, v.turnLeft, v.boost, no, no, no ]
    @widget v

  widget: (v) ->
    s = '\n'
    s += @target.name + '\n'
    s += v.message + '\n'
    s += 'm: ' + parseInt(@target.m[0]) + ':' + parseInt(@target.m[1]) + '\n'
    s += 'rad:' + v.rad + ' dir: ' + v.dir + '\n'
    s += 'diff:' + v.diff + ' ddiff: ' + v.ddiff + '\nflags['
    s += 'a' if v.accel
    s += 'b' if v.boost
    s += 'l' if v.left
    s += 'r' if v.right
    s += 's' if v.setdir
    s += ']\nRs:' + hdist v.slowingRadius
    s += '\nFm:' + hdist v.maxSpeed
    Sprite.hud.widget 'autopilot',  s
    v

  @instance: null
  @macro: =>
    unless ( ap = Autopilot.instance )?
      ap = Autopilot.instance = new Autopilot VEHICLE, NUU.target
    if ap.active
      console.log 'ap:stop'
      ap.stop()
    else
      Sprite.hud.widget 'autopilot'
      console.log 'ap:start'
      ap.commit(VEHICLE, NUU.target, NUU.targetMode)
      ap.start()

Kbd.macro 'autopilot', 'Sz', 'Autopilot', Autopilot.macro
