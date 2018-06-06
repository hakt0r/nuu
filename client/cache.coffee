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

class Bottle
  constructor: (@limit) ->
    @stack = []; @active = 0
  next: =>
    if @stack.length is 0 then @active--
    else @stack.shift() @next
  add: (fnc) =>
    if @active < @limit then fnc @next, @active++
    else @stack.push fnc

$b        = new Bottle(3)
URL       = window.URL or window.webkitURL
indexedDB = window.indexedDB or window.webkitIndexedDB or window.mozIndexedDB or window.OIndexedDB or window.msIndexedDB
iDBtx     = window.IDBTransaction or window.webkitIDBTransaction or window.OIDBTransaction or window.msIDBTransaction

$static 'Cache', new class BlobCacheIndexedDB
  constructor: ->
    dbVersion = 1.0
    createObjectStore = (dataBase) => dataBase.createObjectStore 'nuu'
    req = indexedDB.open 'nuucache', dbVersion
    req.onerror = (event) => console.log 'data', 'Error creating/accessing IndexedDB database'
    req.onupgradeneeded = (event) => createObjectStore event.target.result
    req.onsuccess = (event) =>
      console.log 'data', 'Success creating/accessing IndexedDB database' if debug
      @db = req.result
      @db.onerror = (event) => console.log 'data','Error creating/accessing IndexedDB database'
      if @db.setVersion # Interim solution for Google Chrome to create an objectStore. Will be deprecated
        if @db.version isnt dbVersion
          setVersion = @db.setVersion dbVersion
          setVersion.onsuccess = => ready createObjectStore @db
        else do ready
      else do ready
      null
    @get_ = @get; queue = {}
    @get = (path,callback) =>
      l = queue[path] || queue[path] = []
      l.push callback if -1 is l.indexOf callback
    ready = =>
      @get = @get_
      @get k, c for c in v for k, v of queue
      NUU.emit 'cache:ready'
    null

  get: (path,callback) ->
    path = path.replace(/^\//,'')
    tx = @db.transaction([ 'nuu' ], "readonly")
    q = tx.objectStore('nuu').get(path)
    q.onerror = (event) => console.log event
    q.onsuccess = (event) =>
      if ( imgFile = event.target.result )
        imgURL = URL.createObjectURL imgFile
        callback imgURL
        # URL.revokeObjectURL imgURL
      else @fetch path, (blob)=>
        imgURL = URL.createObjectURL blob
        callback imgURL
        # URL.revokeObjectURL imgURL
        null
      null
    null

  fetch: (path, callback) ->
    $b.add (release) =>
      x = new XMLHttpRequest
      x.responseType = 'blob'
      x.open 'GET', path, true
      x.addEventListener 'error', (e) => console.log 'data', 'fetch-error', path, e
      x.addEventListener 'load', => if x.status == 200
        tx = @db.transaction [ 'nuu' ], "readwrite"
        put = tx.objectStore('nuu').put x.response, path
        callback x.response
        release()
        null
      x.send()
      null
    null

  drop:->
    indexedDB.deleteDatabase 'nuucache'
    window.location.reload()
