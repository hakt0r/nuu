###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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

NUU.on 'target:new', (opts)->
  Target.widget()

NUU.on '$obj:destroyed', (v)->
  delete Target.hostile[k] for k,i of Target.hostile when i.id is v.id
  Target.enemy() if Target.hostile.length > 0
  return

NET.on 'hostile', addHostile = (id)->
  count = 1
  doAdd = (i)->
    return console.log ':tgt', 'hostile:unknown', i unless v = $obj.byId[i]
    return if v.destructing
    Target.hostile[v.id] = v
    NUU.emit 'hostile', i
  if Array.isArray id
    Array.empty Target.hostile
    id.map doAdd
    count = id.length
  else doAdd id
  Target.types[0] = Target.hostile
  NUU.emit 'hostiles', Target.hostile
  if Target.hostile.length is 0
       do Target.nothing
  else do Target.enemy
  return

window.TARGET = null

$public class Target
  @id: 0
  @class: 0
  @mode: 'land'
  @hostile: h = []
  @typeNames : ['off','hostile','ship','stellar','roid','all']
  @types : [[],h,Ship.byId,Stellar.byId,Asteroid.byId,$obj.byId]

Target.widget = ->
  HUD.widget 'target', "#{Target.mode}", yes

Target.set = (target,callback)->
  old.unref @ if old = TARGET
  unless window.TARGET = target
    NUU.emit 'target:new', null, old
    return
  target.ref @, (v)->
    Target.enemy()
    NUU.emit 'target:lost', v
    return
  unless ( actions = TARGET.actions ).includes oldMode = Target.mode
     Target.mode = TARGET.defaultAction?() || actions[0] || ''
  return console.log ':tgt', 'nx:ty' unless ty = Target.types
  return console.log ':tgt', 'nx:cl' unless cl = ty[Target.class]
  return console.log ':tgt', 'nx:ks' unless ks = Object.keys cl
  Target.id = if -1 is id = ks.indexOf '' + target.id then 0 else id
  callback? TARGET
  NUU.emit 'target:new', target, old
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
  Target.class = 0
  Target.set null

Target.enemy = ->
  return if TARGET and Target.hostile[TARGET.id]
  Target.class = 1 # hostile
  do Target.closest

Target.nextClass = ->
  ct = ( list = Target.types ).length
  Target.class = ++Target.class % ct
  do Target.closest
  do Target.nextClass if Target.class is 1 and VEHICLE.hostile.length is 0
  return

Target.prevClass = ->
  ct = ( list = Target.types ).length
  Target.class = ( ct + --Target.class ) % ct
  do Target.closest
  do Target.prevClass if Target.class is 1 and VEHICLE.hostile.length is 0
  return

Target.toggleMode = ->
  li = TARGET.actions || ['n/a']
  le = li.length
  ci = li.indexOf Target.mode
  Target.mode = if ci is -1 then ( TARGET.defaultAction?() || li[0] ) else  li[++ci%le]
  Target.widget()
  return

Target.eva = ->
  NET.action.write 0, 'eva'
  return

Target.launch = ->
  NET.action.write 0, 'launch'
  return

Target.orbit = ->
  return unless t = TARGET
  NET.action.write t, Target.mode
  return

Target.jump = ->
  return unless t = TARGET
  NET.json.write jump: t.id
  return

Target.capture = capture = ->
  return unless t = TARGET
  NET.action.write t, 'capture'
  return

Target.roid = ->
  Target.class = 4
  do Target.closest

Target.captureClosest = ->
  Target.class = 5 # all
  Target.closest (t)-> capture t if t?
  return

Target.prompt = ->
  vt.prompt "target#", (
    (seek)->
      return if seek.trim() is ''
      seek = seek.toLowerCase()
      t = Object
      .keys($obj.byName)
      .filter (i)-> null != i.toLowerCase().match seek
      .map    (i)-> $obj.byName[i]
      Target.set t[0] if t[0]
  ), yes

Kbd.macro 'targetSearch',    'KeyG', 'Target search',             Target.prompt
Kbd.macro 'targetNothing',  'sKeyW', 'Target nothing',            Target.nothing
Kbd.macro 'targetNext',      'KeyD', 'Target next',               Target.next
Kbd.macro 'targetClassNext', 'KeyW', 'Target next class',         Target.nextClass
Kbd.macro 'targetPrev',      'KeyA', 'Target prev',               Target.prev
Kbd.macro 'targetClassPrev', 'KeyS', 'Target prev class',         Target.prevClass
Kbd.macro 'targetClosest',   'KeyU', 'Target closest target',     Target.closest
Kbd.macro 'targetEnemy',     'KeyE', 'Target closest enemy',      Target.enemy
Kbd.macro 'targetRoid',      'KeyR', 'Target closest asteroid',   Target.roid
Kbd.macro 'targetMode',      'KeyQ', 'Toggle Land/Dock/Orbit',    Target.toggleMode
Kbd.macro 'orbit',            'Tab', 'Land / Dock / Enter Orbit', Target.orbit
Kbd.macro 'launch',         'aKeyQ', 'Launch / Undock',           Target.launch
Kbd.macro 'eva',           'saKeyQ', 'EVA',                       Target.eva
Kbd.macro 'jump',            'KeyJ', 'Jump to target',            Target.jump
Kbd.macro 'capture',        'sKeyC', 'Capture target',            Target.capture
Kbd.macro 'captureClosest',  'KeyC', 'Capture closest',           Target.captureClosest
