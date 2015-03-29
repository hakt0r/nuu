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

pub = $static.list
pub.TIME  = Date.now()
pub.ETIME = Math.floor(TIME/1000000)*1000000

class Worker
  constructor : (interval) ->
    time = Date.now; r = f = null
    lista = []; lista.real = 0; lista.name = 'a'
    listb = []; listb.real = 0; listb.name = 'b'
    flip = no; cur = listb; nxt = lista
    @setTimer = (f) -> time = f
    @push   = push = (f) -> nxt[nxt.real++] = f
    @remove = remove = (f) -> f.stop = true if f
    pushback = (f,t) -> setTimeout (-> push f), t
    callback = =>
      pub.TIME  = time()
      pub.ETIME = Math.floor(TIME/1000000)*1000000
      if (flip = not flip)
        cur = lista; @list = nxt = listb
      else cur = listb; @list = nxt = lista
      c = nxt.real = 0
      for idx in [0...cur.real]
        if typeof (f = cur[idx]) isnt 'function'
        else if f.stop
        else if typeof (r = f()) is 'number'
          pushback f, r; continue
        else if r isnt no
          nxt[nxt.real++] = f
      @count = nxt.real
      @last = time() - TIME
    @setClock = (v) -> time = v
    @timer = setInterval(callback,interval)

$static '$worker', new Worker TICK
