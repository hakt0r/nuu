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
  delete Target.hostile[i] for k,i of Target.hostile when i.id is opts.id
  do Target.enemy          if TARGET? and opts.id is TARGET.id
  null

NET.on 'hostile', addHostile = (id)->
  if Array.isArray id
    Object.empty Target.hostile
    id.map (i)->
      return console.log 'hostile:unknown', i unless v = $obj.byId[i]
      Target.hostile[v.id] = v
  else
    return console.log 'hostile:unknown', id unless v = $obj.byId[id]
    Target.hostile[v.id] = v
  Target.types[0] = Target.hostile
  do Target.enemy

window.TARGET = null

$public class Target
  @id: 0
  @class: 0
  @mode: 'land'
  @hostile: h = {}
  @typeNames : ['hostile','ship','stellar','all','off']
  @types : [h,Ship.byId,Stellar.byId,$obj.byId,[]]

Target.set = (target,callback)->
  window.TARGET = target
  return Target.id = 0 unless target
  if Target.class is 1 then Target.mode = 'dock'
  if Target.class is 2
    if TARGET and TARGET.constructor.name is 'Stellar'
      Target.mode = 'orbit'
    else Target.mode = 'land'
  return console.log '$target:nx:ty' unless ty = Target.types
  return console.log '$target:nx:cl' unless cl = ty[Target.class]
  return console.log '$target:nx:ks' unless ks = Object.keys cl
  Target.id = if -1 is id = ks.indexOf '' + target.id then 0 else id
  NUU.emit 'newTarget', target
  callback TARGET if callback? and typeof callback is 'function'
  return TARGET

Target.mutate = (fnc)-> again = (callback,skipSelf=false)->
  return console.log '$target:nx:ty' unless ty = Target.types
  return console.log '$target:nx:cl' unless cl = ty[Target.class]
  return console.log '$target:nx:ks' unless ks = Object.keys cl
  return console.log '$target:nx:cu' unless cu = TARGET || cl[ks[0]] || null
  ct = ks.length
  ix = ks.indexOf '' + cu.id
  id = ks[fnc ix, ct, cl, ks, skipSelf]
  ta = cl[id]
  if ( skipSelf is false ) and ( ta? and VEHICLE? ) and ( ta.id is VEHICLE.id )
    ta = again callback, VEHICLE.id, window.TARGET = ta
  Target.set ta, callback

Target.prev = Target.mutate (ix,ct)-> ( ct + --ix ) % ct
Target.next = Target.mutate (ix,ct)-> ++ix % ct

Target.closest = Target.mutate (ix,ct,cl,ks,skipSelf) ->
  return console.log '$target:nx:v' unless v = VEHICLE
  dist = Infinity; closest = null
  for k,t of cl when t and t.id isnt v.id and (d = $dist v, t) < dist
    continue if t.destructing
    continue if t.id is skipSelf
    dist = d; closest = t
  return if closest? then ks.indexOf '' + closest.id else 0

Target.nothing = ->
  Target.class = 4
  Target.set null

Target.enemy = ->
  Target.class = 0 # hostile
  do Target.closest

Target.nextClass = ->
  list = Target.types
  ct = list.length
  Target.class = ++Target.class % ct
  do Target.closest
  null

Target.prevClass = ->
  list = Target.types
  ct = list.length
  Target.class = ( ct + --Target.class ) % ct
  do Target.closest
  null

Target.toggleMode = ->
  return Target.mode = 'orbit' if Target.mode is 'dock'
  return Target.mode = 'land'  if Target.mode is 'orbit'
  return Target.mode = 'dock'  if Target.mode is 'land'
  Target.mode = 'land'
  null

Target.launch = ->
  NET.action.write(TARGET||id:0,'launch')
  null

Target.orbit = ->
  Target.mode if TARGET
  null

Target.jump = ->
  return unless ( t = TARGET )
  NET.json.write jump: t.id
  null

Target.capture = capture = ->
  NET.action.write(TARGET,'capture')
  null

Target.captureClosest = ->
  Target.class = 3 # all
  Target.closest (t)-> capture t if t?
  null

Kbd.macro 'targetNothing',   'Sw',   'Disable targeting scanners', Target.nothing
Kbd.macro 'targetNext',      'd',    'Next target',                Target.next
Kbd.macro 'targetClassNext', 'w',    'Next target class',          Target.nextClass
Kbd.macro 'targetPrev',      'a',    'Prev target',                Target.prev
Kbd.macro 'targetClassPrev', 's',    'Previous target class',      Target.prevClass
Kbd.macro 'targetClosest',   'u',    'Closest target',             Target.closest
Kbd.macro 'targetEnemy',     'e',    'Closest enemy',              Target.enemy
Kbd.macro 'targetMode',      'tab',  'Toggle Land / Dock / Orbit', Target.toggleMode
Kbd.macro 'launch',          'Stab', 'Launch / Undock',            Target.launch
Kbd.macro 'orbit',           'q',    'Land / Dock / Enter Orbit',  Target.orbit
Kbd.macro 'jump',            'j',    'Jump to target',             Target.jump
Kbd.macro 'capture',         'Sc',   'Capture target',             Target.capture
Kbd.macro 'captureClosest',  'c',    'Capture closest',            Target.captureClosest
