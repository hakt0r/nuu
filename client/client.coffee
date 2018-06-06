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

$static 'NET', {}
$static 'NUU', {}

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

NUU.defaults =
  mouseturn: off
  gfx: hud: off, scanner: off, speedScale: off

NUU.saveSettings = ->
  localStorage.setItem 'config', JSON.stringify NUU.settings
  NUU.emit 'settings'
  NUU.settings

NUU.loadSettings = ->
  try data = NUU.applyDefaults JSON.parse( localStorage.getItem "config" ), NUU.defaults
  catch error then data = NUU.defaults
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

###
  WebGL with Canvas fallback powered by PIXI.js
  # PITFALL: Hack PIXI to use Cache
###

PIXI.BaseTexture.fromImage = (imageUrl, crossorigin, scaleMode, sourceScale) ->
  baseTexture = PIXI.utils.BaseTextureCache[imageUrl]
  if !baseTexture
    image = new Image
    image.crossOrigin = 'anonymous'
    baseTexture = new PIXI.BaseTexture(image, scaleMode)
    baseTexture.imageUrl = imageUrl
    baseTexture.sourceScale = sourceScale if sourceScale
    baseTexture.resolution = PIXI.utils.getResolutionOfUrl(imageUrl)
    Cache.get imageUrl, (cachedUrl) ->
      image.src = cachedUrl
      # Setting this triggers load
      PIXI.BaseTexture.addToCache baseTexture, imageUrl
  baseTexture

console.log ':nuu', 'loading libs'

$ -> NUU.emit 'runtime:ready'

# <center><img class="powered" src="https://camo.githubusercontent.com/eae4496331dc8533db7c7ff8879c0d6a12da2282/687474703a2f2f706978696a732e646f776e6c6f61642f706978696a732d62616e6e65722e706e67"/> <img class="powered" src="https://nodejs.org/static/images/logos/nodejs-new-white.png"/> <img class="powered" src="https://cdn-1.wp.nginx.com/wp-content/uploads/2018/03/icon-NGINX-OSS.svg"/></center>
NUU.on 'gfx:ready', ->
  $static 'vt', new VT100

  $.ajax '/build/objects.json', success: (result) ->
    Item.init result
    vt.write NUU.intro = """
------------------------------------------------------------------------------------------------
<center style="white-space: nowrap;">
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="500" height="180" viewBox="0 0 63.970978 20" version="1.1" id="nuulogo">
<defs id="defs912">
  <clipPath clipPathUnits="userSpaceOnUse" id="clipPath881"><rect id="rect883" width="20" height="20" x="40" y="97" rx="5" ry="5" style="opacity:1;fill:#ff0000;fill-opacity:1;stroke:none;stroke-width:6.01288509;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1" /></clipPath>
  <clipPath clipPathUnits="userSpaceOnUse" id="clipPath905"><rect id="rect903" width="20" height="20" x="40" y="97" rx="5" ry="5" style="opacity:1;fill:#ff0000;fill-opacity:1;stroke:none;stroke-width:6.01288509;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1" /></clipPath>
  <clipPath clipPathUnits="userSpaceOnUse" id="clipPath877"><rect ry="5" rx="5" y="97" x="40" height="20" width="20" id="rect879" style="opacity:1;fill:#ff0000;fill-opacity:1;stroke:none;stroke-width:6.01288509;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1" /></clipPath>
</defs>
<g id="layer1" transform="translate(-184.21689,-303.63095)">
  <path style="fill:#333333;fill-rule:evenodd;stroke:none;stroke-width:0.26499999;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1" d="m 46.5,107 v 10 H 39.999999 V 97 L 46.5,97.000001 53.5,107 V 97.000001 L 60.000001,97 v 20 H 53.5 Z" id="path839" clip-path="url(#clipPath877)" transform="translate(144.21689,206.63095)" />
  <path id="path875" d="M 39.999999,117 V 97 L 46.5,97.000001 V 107 h 7 V 97.000001 L 60.000001,97 v 20 z" style="fill:#333333;fill-rule:evenodd;stroke:none;stroke-width:0.26499999;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1" clip-path="url(#clipPath881)" transform="translate(166.18788,206.63095)" />
  <path transform="translate(188.18787,206.63095)" clip-path="url(#clipPath881)" style="fill:#333333;fill-rule:evenodd;stroke:none;stroke-width:0.26499999;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1" d="M 39.999999,117 V 97 L 46.5,97.000001 V 107 h 7 V 97.000001 L 60.000001,97 v 20 z" id="path891" />
</g>
</svg>
</center>\
--- [ FakeNN ] BREAKING ------------------------------------------------------------------------\
<span class="center news">Earth and Luna have been overrun by the drones our own creation, and now,</span>\
<span class="center news">her Majesty the Kernel is scheming to take Mars and the Jupiter-system!</span>\
------------------------------------------------------------------------------------------------

  ➜ Press alt-R to register
  ➜ Press alt-L to show license screen

    """
    unless debug then NUU.loginPrompt()
    else $timeout 500, => NET.login 'anx', sha512(''), -> vt.hide()
    rules NUU
  null

  NUU.on 'start', -> NUU.emit 'settings'
