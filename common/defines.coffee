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

$static 'fixed', 0
$static 'moving', 1
$static 'accelerating', 2
$static 'manouvering', 3
$static 'orbit', 4

$static 'PI',  Math.PI
$static 'TAU', Math.PI * 2
$static 'RAD', 180 / Math.PI
$static 'DAR', Math.PI / 180

$static 'floor', Math.floor
$static 'atan2', Math.atan2
$static 'sqrt', Math.sqrt
$static 'min', Math.min
$static 'max', Math.max
$static 'abs', Math.abs
$static 'pow', Math.pow
$static 'sin', Math.sin
$static 'cos', Math.cos
$static 'random', Math.random
$static 'round', Math.round

$static '$dist', (s,o) -> sqrt(pow(s.x-o.x,2)+pow(s.y-o.y,2))
$static '$interval', (i,f) -> setInterval f,i
$static '$timeout', (i,f) -> setTimeout f,i
$static '$cue', (f) -> setTimeout 0,f

$static 'TIME', Date.now()
$static 'TICK', 33
$static 'STICK', 1000/33
$static '$_', require 'underscore'

g = if window? then window else global

class Worker 
  constructor : (interval) ->
    time = Date.now; r = f = null
    lista = []; lista.real = 0; lista.name = 'a'
    listb = []; listb.real = 0; listb.name = 'b'
    flip = no; cur = listb; nxt = lista
    push = (v) ->
      nxt[nxt.real++] = v
    pushback = (f,t) -> setTimeout (-> push f), t
    callback = =>
      g.TIME = time()
      if (flip = not flip)
        cur = lista; nxt = listb
      else cur = listb; nxt = lista
      c = nxt.real = 0
      for idx in [0...cur.real]
        if typeof (f = cur[idx]) isnt 'function'
        else if typeof (r = f()) is 'number' then pushback f, r; continue
        else if r isnt no then nxt[nxt.real++] = f
      #@count = nxt.real
      #@last = time() - TIME
    @push = push
    @setClock = (v) -> time = v
    @timer = setInterval(callback,interval)

$static '$worker', new Worker TICK

# $interval 1000, -> console.log $worker.count, $worker.last
  

