###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
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

$static 'isClient', yes
$static 'isServer', no

console.log 'NUU.loading.deps'
$public require('events').EventEmitter
$public require('buffer').Buffer
$static 'app',   new EventEmitter
$static '$',     require 'jquery'
$static '_',     require('underscore')
$static 'vm',    require('voronoi-map')
$static 'async', require 'async'
$static 'PIXI',  require 'pixi.js'

SHA = require('jssha')
$static 'sha512', (data) ->
  h = new SHA data, 'TEXT'
  h.getHash 'SHA-512', 'HEX'

console.log 'NUU.libs.loading'
require './build/common/' + lib for lib in window.deps.common
require './build/client/' + lib for lib in window.deps.client.sources when lib isnt 'client'
console.log 'NUU.libs.loaded'

$ ->
  console.log 'NUU.runtime.ready'
  app.emit 'runtime:ready'

app.on 'assets:ready', -> NUU.init()
