###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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
    Mouse.disable()
    @active = yes
    @interval = setInterval @tick(), 20

  stop: -> if @active
    @active = no
    clearInterval @interval
    @interval = null
    Mouse.enable()
    HUD.widget 'autopilot', null

  tick: -> =>
    @last = v = NavCom.steer @ship, @target, 'pursue'
    v = NavCom.approach @ship, v
    @widget v
    return @stop(Target.orbit()) if v.distance < @target.size / 1.8
    if v.setdir or @ship.flags isnt v.flags
      NET.state.write @ship, [ v.accel, v.retro, v.turn and not v.turnLeft, v.turnLeft, v.boost, no, no, no ]

  widget: (v) ->
    s = ''
    s += @target.name + '\n'
    s += v.message + '\n'
    s += 'm: ' + parseInt(@target.m[0]) + ':' + parseInt(@target.m[1]) + '\n'
    s += 'vdiff:' + (rdec3 v.error) + '\n'
    s += 'rad:' + (round v.rad) + ' dir: ' + (rdec3 v.dir) + '\n'
    s += 'ddiff: ' + (rdec3 v.dir_diff) + '\n'
    s += '\n⚑['
    s += '▲' if v.boost
    s += '△' if v.accel
    s += '▽' if v.retro
    s += '◀' if v.left
    s += '▶' if v.right
    s += '◉' if v.setdir
    s += ']\nFm:' + hdist v.maxSpeed
    HUD.widget 'autopilot', s, yes
    v

  @instance: null
  @macro: =>
    unless ap = Autopilot.instance
      Autopilot.instance = new Autopilot VEHICLE, TARGET
    else if not ap.active
      console.log '::ap', 'start'
      ap.commit(VEHICLE, TARGET, Target.mode)
      ap.start()
    else
      console.log '::ap', 'stop'
      ap.stop()

Kbd.macro 'autopilot', 'sKeyZ', 'Autopilot', Autopilot.macro
