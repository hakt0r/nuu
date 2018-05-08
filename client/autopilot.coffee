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
    @last = v = NavCom.steer @ship, @target, 'pursue'
    v = NavCom.approach @ship, v
    @widget v
    return @stop(Kbd.macro.orbit()) if v.distance < @target.size / 1.8
    if v.setdir or @ship.flags isnt v.flags
      NET.state.write @ship, [ v.accel, v.retro, v.turn and not v.turnLeft, v.turnLeft, v.boost, no, no, no ]

  widget: (v) ->
    s = ''
    s += @target.name + '\n'
    s += v.message + '\n'
    s += 'm: ' + parseInt(@target.m[0]) + ':' + parseInt(@target.m[1]) + '\n'
    s += 'rad:' + (round v.rad) + ' dir: ' + (round v.dir) + '\n'
    s += 'diff:' + (round v.error) + ' ddiff: ' + (round v.dir_diff) + '\nflags['
    s += 'a' if v.accel
    s += 'b' if v.boost
    s += 'l' if v.left
    s += 'r' if v.right
    s += 's' if v.setdir
    s += ']\nFm:' + hdist v.maxSpeed
    Sprite.hud.widget 'autopilot',  s
    v

  @instance: null
  @macro: =>
    unless ( ap = Autopilot.instance )?
      ap = Autopilot.instance = new Autopilot VEHICLE, NUU.target
    else if ap.active
      console.log 'ap:stop'
      ap.stop()
    else
      Sprite.hud.widget 'autopilot'
      console.log 'ap:start'
      ap.commit(VEHICLE, NUU.target, NUU.targetMode)
      ap.start()

Kbd.macro 'autopilot', 'Sz', 'Autopilot', Autopilot.macro
