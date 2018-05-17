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

NUU.on 'ship:destroyed', (opts) ->
  opts.destructing = yes
  Target.hostile.map (i)->
    Array.remove Target.hostile, i if i.id is opts.id
  do Target.enemy if opts.id is NUU.target.id if NUU.target
  null

NET.on 'hostile', addHostile = (id)->
  if Array.isArray id
    Array.empty Target.hostile
    id.map (i)->
      return console.log 'hostile:unknown', i unless v = $obj.byId[i]
      Target.hostile.push v
  else
    return console.log 'hostile:unknown', id unless v = $obj.byId[id]
    Target.hostile.push v if -1 is Target.hostile.indexOf v
  Target.types[0] = Target.hostile
  do Target.enemy

$public class Target
  @mode: 'land'
  @hostile: h = []
  @typeNames : ['hostile','ship','stellar','all','off']
  @types : [h,Ship.byId,Stellar.byId,$obj.byId,[]]

Target.nextClass = ->
  list = Target.types
  ct = list.length
  NUU.targetId = 0
  NUU.targetClass = ++NUU.targetClass % ct
  Target.prev()
  if NUU.targetClass is 3 then Target.mode = 'land'
  if NUU.targetClass is 2 then Target.mode = 'dock'
  null

Target.prevClass = ->
  list = Target.types
  ct = list.length
  NUU.targetId = 0
  NUU.targetClass = ( ct + --NUU.targetClass ) % ct
  Target.prev()
  if NUU.targetClass is 3 then Target.mode = 'land'
  if NUU.targetClass is 2 then Target.mode = 'dock'
  null

Target.next = ->
  return unless ty = Target.types
  return unless cl = ty[NUU.targetClass]
  return unless ks = Object.keys cl
  ct = ks.length
  NUU.targetId = id = ++NUU.targetId % ct
  NUU.emit 'newTarget', NUU.target = cl[ks[id]]
  null

Target.prev = ->
  return unless ty = Target.types
  return unless cl = ty[NUU.targetClass]
  return unless ks = Object.keys cl
  ct = ks.length
  NUU.targetId = id = ( ct + --NUU.targetId ) % ct
  NUU.emit 'newTarget', NUU.target = cl[ks[id]]
  null

Target.nothing = ->
  NUU.targetId = NUU.target = null
  NUU.targetClass = 4
  NUU.emit 'newTarget', null
  null

Target.closest = (callback) ->
  v = VEHICLE
  list = Target.types
  cl = list[NUU.targetClass]
  closest = null
  closestDist = Infinity
  for k,t of cl when t and t.id isnt v.id and (d = $dist v, t) < closestDist
    continue if t.destructing
    closest = t
    closestDist = d
  return do Target.nothing unless closest?
  NUU.targetId = id = closest.id
  NUU.once 'newTarget', callback if callback? and typeof callback is 'function'
  NUU.emit 'newTarget', NUU.target = closest
  null

Target.enemy = ->
  NUU.targetId = 0
  NUU.targetClass = 0 # hostile
  do Target.closest
  null

Target.toggleMode = ->
  return Target.mode = 'orbit' if Target.mode is 'dock'
  return Target.mode = 'land'  if Target.mode is 'orbit'
  return Target.mode = 'dock'  if Target.mode is 'land'
  Target.mode = 'land'
  null

Target.launch = ->
  NET.action.write(NUU.target||id:0,'launch')
  null

Target.orbit = ->
  Target.mode if NUU.target
  null

Target.jump = ->
  return unless ( t = NUU.target )
  NET.json.write jump: t.id
  null

Target.capture = capture = ->
  NET.action.write(NUU.target,'capture')
  null

Target.captureClosest = ->
  NUU.targetId = 0
  NUU.targetClass = 3 # all
  Target.closest (t)-> capture t if t?
  null

Kbd.macro 'targetClassNext', 'Sy', 'Select next target class',     Target.nextClass
Kbd.macro 'targetClassPrev', 'Sg', 'Select previous target class', Target.prevClass
Kbd.macro 'targetNext',      'y',  'Select next target',           Target.next
Kbd.macro 'targetPrev',      'g',  'Select next target',           Target.prev
Kbd.macro 'targetNothing',   'Se', 'Disable targeting scanners',   Target.nothing
Kbd.macro 'targetClosest',   'u',  'Select closest target',        Target.closest
Kbd.macro 'targetEnemy',     'e',  'Target closest enemy',         Target.enemy
Kbd.macro 'targetMode',      'Sn', 'Toggle Land / Orbit',          Target.toggleMode
Kbd.macro 'launch',          'Sm', 'Launch / Undock',              Target.launch
Kbd.macro 'orbit',           'm',  'Land / Dock / Enter Orbit',    Target.orbit
Kbd.macro 'jump',            'j',  'Jump to target',               Target.jump
Kbd.macro 'capture',         'Sc', 'Capture target',               Target.capture
Kbd.macro 'captureClosest',  'c',  'Capture closest',              Target.captureClosest
