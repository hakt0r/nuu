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

window.isClient  = yes
window.$public   = (args...) -> window[a.name] = a for a in args
window.$static   = (name,value) -> window[name] = value

$public class EventEmitter
  __subcribers : {}
  on : (event, callback) ->
    @__subcribers[event] = [] unless @__subcribers[event]?
    @__subcribers[event].push callback
  emit : (event, args...) -> if @__subcribers[event]?
    i.apply this, args for i in @__subcribers[event]
    null
  off : (event, callback) -> if @__subcribers[event]?
    callbacks.splice i, 1 while i = @__subcribers.indexOf(callback)
    null

$static 'app', new EventEmitter
$static '$',   require 'jquery'

console.log 'NUU.loading.libs'
$static '_',     require('underscore')
$static 'vm',    require('voronoi-map')
$static 'async', require 'async'
$public          require('buffer').Buffer

SHA = require('jssha')
$static 'sha512', (data) ->
  h = new SHA data, 'TEXT'
  h.getHash 'SHA-512', 'HEX'

require './build/'        + lib for lib in window.deps.common
require './build/client/' + lib for lib in window.deps.client.sources when lib isnt 'client'

$ ->
  console.log 'NUU.initializing'
  new Engine
  app.emit 'ready'