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

$static 'DUMMY', dummy:yes, id:0, d:0, x:0, y:0, m: [0,0], update: (->), updateSprite: (->), state:S:'none'
$static 'VEHICLE',    DUMMY
$static 'TARGET',     null
$static 'SHORTRANGE', {}

$static 'WIDTH',  640
$static 'HEIGHT', 480
$static 'WDB2',   320
$static 'HGB2',   240
$static 'WDT2',   1280
$static 'HGT2',   960

$static 'app', {}

app.defaults =
  mouseturn: off
  gfx: hud: off, scanner: off, speedScale: off

app.saveSettings = ->
  localStorage.setItem 'config', JSON.stringify app.settings
  app.emit 'settings'
  app.settings
app.loadSettings = ->
  try data = app.applyDefaults JSON.parse( localStorage.getItem "config" ), app.defaults
  catch error then data = app.defaults
  app.settings = data

app.applyDefaults = (o={},d={})->
  for k,v of d
    if typeof v is 'object' then o[k] = app.applyDefaults o[k] || {}, v
    else if not o[k]? then o[k] = v
  return o

do app.loadSettings

###
  Load the more strightforward deps
###

console.log 'NUU.loading.deps'

for lib in deps.client.require
  if Array.isArray lib
    if lib.length is 3
         $static lib[0], require(lib[1])[lib[2]]
    else $static lib[0], require(lib[1])
  else   $static lib,    require(lib)

app[k] = v for k,v of EventEmitter::
EventEmitter.call app

###
  WebGL with Canvas fallback powered by PIXI.js
  # PITFALL: Hack PIXI to use Cache
###

# PIXI.BaseTexture._fromImage = PIXI.BaseTexture.fromImage
# PIXI.BaseTexture.fromImage = (imageUrl, crossorigin, scaleMode, sourceScale) ->
#   return baseTexture if baseTexture = PIXI.utils.BaseTextureCache[imageUrl]
#   Cache.get imageUrl, (cachedUrl) ->
#     return unless baseTexture = PIXI.utils.BaseTextureCache[imageUrl]
#     # baseTexture.updateSourceImage cachedUrl
#   PIXI.BaseTexture._fromImage imageUrl, crossorigin, scaleMode, sourceScale

console.log 'NUU.libs.loading'

$ -> app.emit 'runtime:ready'

app.on 'gfx:ready', ->

  $static 'vt', new VT100

  async.parallel [
    (c) -> $.ajax('/build/objects.json').success (result) ->
      Item.init result
      c null
  ], =>
    unless debug then NUU.loginPrompt()
    else $timeout 500, => NET.login 'anx', sha512(''), -> vt.unfocus()
    rules NUU
  null

  NUU.on 'start', ->
    @time = -> Ping.remoteTime()
    @thread 'ping', 500,  Ping.send
    app.emit 'settings'
