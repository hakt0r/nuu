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

Array.empty = (a)->
  a.pop() while a.length > 0
  a

Object.empty = (o)->
  delete o[k] for k of o
  o

class Engine extends EventEmitter
  time: Date.now
  threadList: {}
  players: {}
  init: $void
  thread: (name,time,fnc) -> @threadList[name] = setInterval fnc, time
  start: (callback) ->
    console.log 'NUU.engine.start', @tstart = Date.now()
    @emit 'start'
    callback null if callback
    null
  stop: ->
    clearInterval i for k,i of @threadList
    null

$static 'NUU', new Engine
