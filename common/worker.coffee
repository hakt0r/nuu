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

window.global = window if window?
global.TIME  = NUU.time()

class Worker
  constructor : (interval) ->
    r = f = null
    lista = []; lista.real = 0; lista.name = 'a'
    listb = []; listb.real = 0; listb.name = 'b'
    flip = no; cur = listb; nxt = lista
    @push   = push = (f) -> nxt[nxt.real++] = f
    @remove = remove = (f) -> f.stop = true if f
    pushback = (f,t) -> setTimeout (-> push f), t
    callback = =>
      if (flip = not flip)
        cur = lista; @list = nxt = listb
      else cur = listb; @list = nxt = lista
      c = nxt.real = 0
      began = NUU.time()
      for idx in [0...cur.real]
        global.TIME  = NUU.time()
        global.ETIME = Math.floor(TIME/1000000)*1000000
        if typeof (f = cur[idx]) isnt 'function'
        else if f.stop
        else if typeof (r = f NUU.time() ) is 'number'
          pushback f, r; continue
        else if r isnt no
          nxt[nxt.real++] = f
      @count = nxt.real
      @last = NUU.time() - began
    @timer = setInterval(callback,interval)

$static '$worker', new Worker TICK
