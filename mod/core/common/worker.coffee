###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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

$static '$worker', new class TickWorker
  constructor:(interval=TICK)->
    @list   = []
    @remove = @remove.bind @
    @tick   = @tick.bind @
    @push   = @push.bind @
    @timer  = setInterval @tick, interval
  tick:->
    list = @list.filter @notStopped
    while f = list.shift()
      continue if f.notBefore > time = NUU.time()
      global.TIME  = time
      global.ETIME = Math.floor(TIME/1000000)*1000000
      if typeof f isnt 'function'
      else if f.stop
      else if not isNaN r = f time
           f.notBefore = NUU.time() + r
      else f.stop = r isnt false
    @list = @list.filter @notStopped
  push:(f)-> f.stop = false; @list.push f; f
  remove:(f)-> f.stop = true
  notStopped:(f)-> f.stop isnt true

class $worker.InlineThread
  constructor:(init=@init)->
    source =  [ '( async function(self){' ]
    source.push @workerInit.toInlineCode() if @workerInit
    source.push @worker    .toInlineCode() if @worker
    source.push '} ).call(this,self)'
    if source.length isnt 2
      @thread = new Worker URL.createObjectURL new Blob [source.join '\n'],type:'text/javascript'
      @thread.onmessage = (m)=>
        @[k]? v for k,v of m.data
        return
    @init?()

$worker.List = (worker)->
  list = c = n = count = null
  listWorker = (time)->
    { count, list } = listWorker
    c = n = 0
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
    { count, list } = listWorker
    c = n = 0
    while c < count and ( at = list[c++] )?
      unless false is worker.call at, time
        swap[n++] = at
    listWorker.list = swap; swap = list
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
  listKey = opts.listKey || "pause" + $worker.PauseList.key++
  if debug then setInterval ( ->
    console.log '$PauseWorker', listKey, listWorker.count
  ), 5000
  listWorker = (time)->
    { count, list } = listWorker
    c = -1; n = 0
    while count > ++c
      item  = list[c]
      delay = item[listKey]
      if -1 is delay
        delete item[listKey]
        continue
      if time < delay
        list[n++] = item
        continue
      res = worker.call item, time
      if -1 is res or -1 is item[listKey]
        delete item[listKey]
        continue
      item[listKey] = time + res
      list[n++] = item
    listWorker.count = n
    return true
  listWorker.worker = worker
  listWorker.list   = []
  listWorker.count  = 0
  listWorker.add    = (item)->
    item[listKey] = 0
    @list[@count++] = item
    Object.assign item, opts
  listWorker.remove = (item)->
    item[listKey] = -1
  $worker.push listWorker
$worker.PauseList.key = 0

$worker.DeadLine = (waitFor,deadline,worker)->
  listKey     = "deadline"     + $worker.DeadLine.key
  listKeyLast = "deadlineLast" + $worker.DeadLine.key++
  listWorker = (time)->
    { count, list } = listWorker
    c = -1; n = 0
    while count > ++c
      item    = list[c]
      delay   = item[listKey]
      deadlay = item[listKeyLast]
      if delay is false
        delete item[listKey]
        delete item[listKeyLast]
        continue
      if time < delay and time < deadlay
        list[n++] = item
        continue
      worker.call item, time
      delete item[listKey]
      delete item[listKeyLast]
    listWorker.count = n
    return
  listWorker.worker = worker
  listWorker.list   = []
  listWorker.count  = 0
  listWorker.add    = (item)->
    item[listKey] = waitFor + time = NUU.time()
    unless item[listKeyLast]
      item[listKeyLast] = deadline + time
      @list[@count++] = item
  listWorker.remove = (item)->
    item[listKey] = false
  $worker.push listWorker
$worker.DeadLine.key = 0
