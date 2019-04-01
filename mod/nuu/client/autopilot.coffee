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

$public class Autopilot
  @active: no
  @plan:   'land'

Autopilot.widget = (v) ->
  unless VEHICLE.target
    HUD.widget 'autopilot', 'no target', yes
    return v
  s = ''
  s += VEHICLE.target.name + '\n'
  s += v.message + '\n'
  s += v.recommend + '\n'
  s += 'v: ' + parseInt(VEHICLE.target.v[0]) + ':' + parseInt(VEHICLE.target.v[1]) + '\n'
  s += 't: ' + parseInt(v.throttle) + '\n'
  s += 'e: ' + v.error + '\n'
  s += 'z: ' + parseInt(v.target_zone) + '\n'
  s += 'dd:' + parseInt(v.maxSpeed) + '\n'
  s += '\n⚑['
  s += '▲' if v.recommend is 'boost'
  s += '△' if v.recommend is 'burn'
  s += '▽' if v.recommend is 'retro'
  s += '◉' if v.recommend is 'setdir'
  s += '☕' if v.recommend is 'wait'
  s += '⌘' if v.recommend is 'execute'
  s += ']\nFm:' + hdist v.maxSpeed
  HUD.widget 'autopilot', s, yes
  return v

Autopilot.start = ->
  Autopilot.stop() if Autopilot.active
  HUD.widget 'autopilot', 'ap:booting', yes
  VEHICLE.target = TARGET
  VEHICLE.changeStrategy null
  VEHICLE.changeStrategy 'approach'
  Autopilot.active = yes
  Mouse.disableTemp()
  VEHICLE.onTarget = (v)->
    Autopilot.stop()
    Target.orbit()
  return

Autopilot.stop = ->
  HUD.widget 'autopilot', 'ap:off', yes
  VEHICLE.changeStrategy null
  Autopilot.active = no
  Mouse.enableIfWasEnabled()
  return

Autopilot.macro = ->
  unless VEHICLE.hasAP
    VEHICLE.hasAP = yes
    VEHICLE.approachTarget = -> @target = TARGET
    VEHICLE.changeStrategy = AI.prototype.changeStrategy
    VEHICLE.onDecision = Autopilot.widget.bind Autopilot
  unless  Autopilot.active
       do Autopilot.start
  else do Autopilot.stop

Kbd.macro 'autopilot', 'sKeyZ', 'Autopilot', Autopilot.macro
