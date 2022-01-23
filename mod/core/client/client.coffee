###

  * c) 2007-2022 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2022 flyc0r

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

window.$static   = (name,value) -> window[name] = value
$static.list     = window
window.$public   = (args...) -> window[a.name] = a for a in args
window.$cue      = (f) -> setTimeout 0,f

###
  Client-specific constants / $statics
###

$static 'isClient', yes
$static 'isServer', no
$static 'debug', no

$static 'NET', {}
$static 'NUU', {}

$static 'DUMMY', dummy:yes, id:0, d:0, x:0, y:0, v: [0,0], update: (->), updateSprite: (->), updateScanner:(->), updateShortrange:(->), state:S:'none'
$static 'VEHICLE',    DUMMY
$static 'TARGET',     null
$static 'TTL',        new Set

$static 'WIDTH',  640
$static 'HEIGHT', 480
$static 'WDB2',   320
$static 'HGB2',   240
$static 'WDT2',   1280
$static 'HGT2',   960

NUU.defaults =
  mouseturnoff: off
  gfx: hud: off, scanner: off, speedScale: off

NUU.saveSettings = ->
  localStorage.setItem 'config', JSON.stringify NUU.settings
  NUU.emit 'settings'
  NUU.settings

NUU.loadSettings = ->
  try data = NUU.applyDefaults JSON.parse( localStorage.getItem "config" ), NUU.defaults
  catch error then data = NUU.defaults
  data = new Proxy data, set:(o,k,v)-> NUU.saveSettings o[k] = v
  NUU.settings = data

NUU.applyDefaults = (o={},d={})->
  for k,v of d
    if typeof v is 'object' then o[k] = NUU.applyDefaults o[k] || {}, v
    else if not o[k]? then o[k] = v
  return o

do NUU.loadSettings

###
  Load the more strightforward deps
###

console.log ':nuu', 'loading deps'

for lib in deps.client.require
  if Array.isArray lib
    if lib.length is 3
         $static lib[0], require(lib[1])[lib[2]]
    else $static lib[0], require(lib[1])
  else   $static lib,    require(lib)

# Extend NUU/NET (GLUE OBJECTs:)
NUU[k] = v for k,v of EventEmitter::; EventEmitter.call NUU
NET[k] = v for k,v of EventEmitter::; EventEmitter.call NET

console.log ':nuu', 'loading libs'

$ ->
  NUU.emit 'runtime:ready'
  NUU.emit 'settings:apply'

NUU.on 'start', ->
  Object.assign rules, rules[NUU.mode||'dm']
  rules NUU
  NUU.emit 'settings'

NUU.on 'gfx:ready', ->
  VT100.write """\
<center style="white-space: nowrap">\
<svg viewBox="0 0 62 20"><defs><path id="U" d="M5 0C2.25 0 0 2.25 0 5v10c0 2.75 2.25 5 5 5h10c2.75 0 5-2.25 5-5V5c0-2.75-2.25-5-5-5h-1.5v10h-7V0H5z" style="fill:#333;border:solid red 1px"/></defs><use href="#U" transform="rotate(180 10 10)"/><use href="#U" transform="translate(21)"/><use href="#U" transform="translate(42)"/></svg>\
</center>\
<div style="position:absolute;right: 0;top:0;left: 0;">
  <img class="powered" src="build/imag/nginx.svg">
  <img class="powered" src="build/imag/nodejs.png">
  <img class="powered" src="build/imag/threejs.png">
</div>"""
  vt.write NUU.intro = """
--- [ FakeNN ] BREAKING ------------------------------------------------------------------------\
<span class="center news">Earth and Luna have been overrun by the drones our own creation, and now,</span>\
<span class="center news">her Majesty the Kernel is scheming to take Mars and the Jupiter-system!</span>\
------------------------------------------------------------------------------------------------

➜ Press alt-R to register (we only store <a href="https://en.wikipedia.org/wiki/Salt_(cryptography)">salted</a> <a href="https://en.wikipedia.org/wiki/Hash_function">hashes</a>)
➜ Press alt-L to show license screen
➜ Press alt-C for demo

  """
  NUU.loginPrompt()
  Item.init await new Promise (resolve)-> $.ajax '/build/objects.json', success:resolve
  vt.hide = ->
    $('img.com').remove()
    Window::hide.call @
  a = Item.byClass.com.sort -> Math.random() - .5
  $('body').append $ """<img class="com" src="/build/gfx/#{a.pop().logo}.png"/>"""
  $('body').append $ """<img class="com bottom" src="/build/gfx/#{a.pop().logo}.png"/>"""
  return

NUU.loginComplete = (opts)->
  @player = new User opts
  Sound.radio.init()
  console.log ''
  await GFX.initGame()
  await GFX.start()
  NUU.emit 'start'
  Promise.resolve()
