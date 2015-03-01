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

dirname  = (p) -> p.replace(/[^\/]+$/,'')
basename = (p) -> p.replace(/^.*\//,'')
download = (url,callback) ->

NO_OPS = {}
CREATE = {create:true}

fetch = (path, write) ->
  $b.add (release) -> 
    x = new XMLHttpRequest
    x.responseType = 'blob'
    x.open 'GET', '/build/' + path, true
    x.onload = ->
      # console.log 'fetch:done', path
      release write x.response
    x.onerror = (e) ->
      console.log 'fetch:error', path, e
    x.send()

class Bottle
  constructor : (@limit) ->
    @stack = []; @active = 0
  next : =>
    if @stack.length is 0 then @active--
    else @stack.shift() @next
  add : (fnc) =>
    if @active < @limit then fnc @next, @active++
    else @stack.push fnc

$b = new Bottle(3)

class FSCache
  constructor : ->
    requestFSSuccess = (@fs) => app.emit 'cache:ready'
    requestStorageSuccess = (@grantedBytes) =>
      window.webkitRequestFileSystem(PERSISTENT,@grantedBytes,requestFSSuccess,@errorHandler)
    navigator.webkitPersistentStorage.requestQuota(500*1024*1024,requestStorageSuccess,@errorHandler)

  get : (path,callback) ->
    # console.log 'cache', 'get', path
    fail = -> callback false, console.log 'cache:fail', path
    fileOpened = (file) -> callback URL.createObjectURL(file)
    Cache.exists path, (file) ->
      if file then file.file(fileOpened,fail)
      else Cache.rmkdir dirname(path), (dir) ->
        dir.getFile( basename(path), CREATE, ( (file) ->
          fetch path, (data) -> file.createWriter (w) ->
            w.onwriteend = -> Cache.get(path,callback)
            w.write data ), fail )

  exists : (path,callback) ->
    Cache.fs.root.getFile path, NO_OPS , callback, (error) ->
      callback false, error unless error.name is "NotFoundError"
      callback false

  ls : (path='/',forEach) =>
    unless forEach
      list = (name) -> (data) -> console.log name, data
      forEach = (a) => a.map (i) => i.getMetadata(list(i.name),@errorHandler)
    gotDir = (dir) => dir.createReader().readEntries forEach, @errorHandler
    @fs.root.getDirectory path, NO_OPS, gotDir, @errorHandler

  purge : -> @ls '/', (list) -> list.map (i) -> Cache.rrm(i.name)

  rm : (path='/',ok,fail,action='rm') =>
    ok = @logSuccess(action,path) unless ok
    fail = @errorHandler          unless fail
    gotFile = (file) => file.remove  ok, fail
    @fs.root.getFile(path,NO_OPS,gotFile,fail)

  mkdir : (path,ok,fail,action='mkdir') =>
    ok = @logSuccess(action,path) unless ok
    fail = @errorHandler unless fail
    path = path.replace(/\/$/,'').split '\/'
    gotResponse = (fileEntry) =>
      return ok(fileEntry) if fileEntry
      @fs.root.getDirectory path, CREATE, ok, fail
    @exists(path,gotResponse,fail)

  rmkdir : (path,ok,fail,action='mkdir') =>
    fail = @errorHandler unless fail
    must = path.replace(/\/$/,'').split '\/'
    dive = (dir) ->
      return ok(dir) if must.length is 0
      dir.getDirectory must.shift(), CREATE, dive, fail
    dive @fs.root

  rrm : (path='/',ok,fail,action='rm -r') =>
    ok = @logSuccess(action,path) unless ok
    fail = @errorHandler          unless fail
    gotDir = (dir) => dir.removeRecursively ok, fail
    @fs.root.getDirectory(path,NO_OPS,gotDir,fail)

  info : (path) =>
    ok = (m) -> console.log path, m
    gotFile = (fileEntry) => fileEntry.getMetadata(ok,@errorHandler)
    @fs.root.getFile(path,NO_OPS,gotFile, (error) =>
      return @errorHandler error unless error.name is "NotFoundError" )

  file : (path='/',ok,fail,action='file') =>
    ok = @logSuccess(action,path) unless ok
    fail = @errorHandler          unless fail
    gotFile = (fileEntry) => fileEntry.file(ok,fail)
    @fs.root.getFile(path,NO_OPS,gotFile,fail)

  getReader : (file,ok,fail) ->
    fail = @errorHandler unless fail
    r = new FileReader()
    r.addEventListener 'loadend', -> ok new Blob([r.result],file.type), file
    r.addEventListener 'error', fail
    debugger
    r.readAsBinaryFile file

  logSuccess : (action,path) =>
    (result) -> console.log action, path, 'success', result

  errorHandler : (e) =>
    console.log "FileSystem Api :Error:", e.name, e.message

$static 'Cache', new FSCache
