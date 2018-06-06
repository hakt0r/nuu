###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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

NUU.on 'newTarget', (opts) -> Target.widget()

NUU.on '$obj:destroyed', (v) ->
  delete Target.hostile[k] for k,i of Target.hostile when i.id is v.id
  do Target.enemy          if TARGET? and v.id is TARGET.id
  null

NET.on 'hostile', addHostile = (id)->
  doAdd = (i)->
    return console.log ':tgt', 'hostile:unknown', i unless v = $obj.byId[i]
    return if v.destructing
    Target.hostile[v.id] = v
    NUU.emit 'hostile', i
  if Array.isArray id
    Object.empty Target.hostile
    id.map doAdd
  else doAdd id
  Target.types[0] = Target.hostile
  NUU.emit 'hostiles', Target.hostile
  do Target.enemy

window.TARGET = null

$public class Target
  @id: 0
  @class: 0
  @mode: 'land'
  @hostile: h = {}
  @typeNames : ['hostile','ship','stellar','all','roid','off']
  @types : [h,Ship.byId,Stellar.byId,$obj.byId,Asteroid.byId,[]]

Target.widget = ->
  HUD.widget 'target', "#{Target.mode}", yes

Target.set = (target,callback,old=TARGET)->
  return NUU.emit 'newTarget', null, old unless window.TARGET = target
  if Target.class is 1 then Target.mode = 'dock'
  if Target.class is 2
    if TARGET and TARGET.constructor.name is 'Stellar'
      Target.mode = 'orbit'
    else Target.mode = 'land'
  return console.log ':tgt', 'nx:ty' unless ty = Target.types
  return console.log ':tgt', 'nx:cl' unless cl = ty[Target.class]
  return console.log ':tgt', 'nx:ks' unless ks = Object.keys cl
  Target.id = if -1 is id = ks.indexOf '' + target.id then 0 else id
  callback TARGET if callback? and typeof callback is 'function'
  NUU.emit 'newTarget', target, old
  return TARGET

Target.mutate = (fnc)-> again = (callback,skipSelf=false)->
  return console.log ':tgt', 'nx:ty' unless ty = Target.types
  return console.log ':tgt', 'nx:cl' unless cl = ty[Target.class]
  return console.log ':tgt', 'nx:ks' unless ks = Object.keys cl
  ct = ks.length
  ix = if ( cu = TARGET || cl[ks[0]] || null ) then ks.indexOf '' + cu.id else 0
  id = ks[fnc ix, ct, cl, ks, skipSelf]
  ta = cl[id]
  if ( skipSelf is false ) and ( ta? and VEHICLE? ) and ( ta.id is VEHICLE.id )
    ta = again callback, VEHICLE.id, window.TARGET = ta
  Target.set ta, callback

Target.prev = Target.mutate (ix,ct)-> ( ct + --ix ) % ct
Target.next = Target.mutate (ix,ct)-> ++ix % ct

Target.closest = Target.mutate (ix,ct,cl,ks,skipSelf) ->
  return console.log ':tgt', 'nx:v' unless v = VEHICLE
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
  if TARGET and Target.hostile[TARGET.id]
    HUD.targetSprite.tint = 0xFF0000
  else do Target.closest

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
  Target.mode = switch Target.mode
    when 'orbit' then 'dock'
    when 'land'  then 'orbit'
    when 'dock'  then 'land'
    else              'land'
  Target.widget()
  null

Target.eva = ->
  NET.action.write 0, 'eva'
  null

Target.launch = ->
  NET.action.write 0, 'launch'
  null

Target.orbit = ->
  return unless t = TARGET
  NET.action.write t, Target.mode
  null

Target.jump = ->
  return unless t = TARGET
  NET.json.write jump: t.id
  null

Target.capture = capture = ->
  return unless t = TARGET
  NET.action.write t, 'capture'
  null

Target.roid = ->
  Target.class = 4
  do Target.closest

Target.captureClosest = ->
  Target.class = 3 # all
  Target.closest (t)-> capture t if t?
  null

Kbd.macro 'targetNothing',  'sKeyW', 'Target nothing',            Target.nothing
Kbd.macro 'targetNext',      'KeyD', 'Target next',               Target.next
Kbd.macro 'targetClassNext', 'KeyW', 'Target next class',         Target.nextClass
Kbd.macro 'targetPrev',      'KeyA', 'Target prev',               Target.prev
Kbd.macro 'targetClassPrev', 'KeyS', 'Target prev class',         Target.prevClass
Kbd.macro 'targetClosest',   'KeyU', 'Target closest target',     Target.closest
Kbd.macro 'targetEnemy',     'KeyE', 'Target closest enemy',      Target.enemy
Kbd.macro 'targetRoid',      'KeyR', 'Target closest asteroid',   Target.roid
Kbd.macro 'targetMode',      'sTab', 'Toggle Land/Dock/Orbit',    Target.toggleMode
Kbd.macro 'orbit',            'Tab', 'Land / Dock / Enter Orbit', Target.orbit
Kbd.macro 'launch',         'aKeyQ', 'Launch / Undock',           Target.launch
Kbd.macro 'eva',           'saKeyQ', 'EVA',                       Target.eva
Kbd.macro 'jump',            'KeyJ', 'Jump to target',            Target.jump
Kbd.macro 'capture',        'sKeyC', 'Capture target',            Target.capture
Kbd.macro 'captureClosest',  'KeyC', 'Capture closest',           Target.captureClosest
