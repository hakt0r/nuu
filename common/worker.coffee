###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2018 flyc0r

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
    @timer = setInterval callback, interval

$static '$worker', new Worker TICK

$worker.List = (worker)->
  list = c = n = count = null
  listWorker = (time)->
    c = 0; n = 0
    count = listWorker.count
    list  = listWorker.list
    worker.call at, time while ( at = list[c++] )?
    null
  listWorker.worker = worker
  listWorker.list  = []
  listWorker.count = 0
  listWorker.remove = (item)-> Array.remove @list, item
  listWorker.add = (item)->
    @list[@count++] = item
    @count
  listWorker.remove = (item)->
    return false unless @list.includes item
    Array.remove @list, item
    --@count
  listWorker.worker = worker
  $worker.push listWorker

$worker.ReduceList = (worker)->
  swap = []; list = c = n = count = null
  listWorker = (time)->
    c = 0; n = 0
    count = listWorker.count
    list  = listWorker.list
    while ( at = list[c++] )?
      swap[n++] = at if worker.call at, time
    listWorker.list = swap;swap = list
    listWorker.count = n
    null
  listWorker.worker = worker
  listWorker.list  = []
  listWorker.count = 0
  listWorker.add = (item)->
    @list[@count++] = item
    @count
  listWorker.remove = (item)->
    return false unless @list.includes item
    Array.remove @list, item
    --@count
  $worker.push listWorker

$worker.PauseList = (opts,worker)->
  unless worker
    opts = {}
    worker = opts
  listKey = "pause" + $worker.PauseList.key++
  listWorker = (time)->
    list = c = n = count = null
    count = listWorker.count
    list  = listWorker.list
    c = -1; n = 0
    while count > ++c
      at = list[c]
      if -1 is delay = at[listKey]
        delete at[listKey]
        continue
      if time < delay
        list[n++] = at
        continue
      res = worker.call at, time
      if -1 is res or -1 is at[listKey]
        delete at[listKey]
        continue
      at[listKey] = time + res
      list[n++] = at
    listWorker.count = n
    null
  listWorker.worker = worker
  listWorker.list = []
  listWorker.count = 0
  listWorker.add = (at)-> at[listKey] = 0; @list[@count++] = at; Object.assign at, opts
  listWorker.remove = (at)-> at[listKey] = -1
  $worker.push listWorker
$worker.PauseList.key = 0

$worker.DeadLine = (waitFor,deadline,worker)->
  listKey     = "deadline"     + $worker.DeadLine.key
  listKeyLast = "deadlineLast" + $worker.DeadLine.key++
  listWorker = (time)->
    list = c = n = count = null
    count = listWorker.count
    list  = listWorker.list
    c = -1; n = 0
    while count > ++c
      at      = list[c]
      delay   = at[listKey]
      deadlay = at[listKeyLast]
      if delay is false
        delete at[listKey]
        delete at[listKeyLast]
        continue
      if time < delay and time < deadlay
        list[n++] = at
        continue
      worker.call at, time
      at[listKey] = 0
      at[listKeyLast] = time + deadline
    listWorker.count = n
    null
  listWorker.worker = worker
  listWorker.list   = []
  listWorker.count  = 0
  listWorker.add    = (at)->
    at[listKey] = ( time = NUU.time() ) + waitFor
    unless at[listKeyLast]
      at[listKeyLast] = time + deadline
      @list[@count++] = at
  listWorker.remove = (at)->
    at[listKey] = false
  $worker.push listWorker
$worker.DeadLine.key = 0
