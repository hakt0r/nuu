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

fs    = require 'fs'
path  = require 'path'
cp    = require 'child_process'
async = require 'async'
_     = require 'underscore'

Array.prototype.uniq = ->
  b = {}; c = []; for k,v of @ when b[v] isnt true
   b[v] = true;c.push v
  c

readDir  = (dir,call) -> call f, dir for f in fs.readdirSync dir

root = path.dirname __dirname
server = null
client = null
watch = {}
rebuildFiles = []
timeout = null
rebuildLock = no

addFile = (f,dir) ->
  path = dir + f
  watch[f+dir] = fs.watch path,{persistent:on}, changeFile(path,f)

changeFile = (path,name) -> ->
  if rebuildLock is on
    console.log ':dev', '[locked]', path
    return
  clearTimeout timeout
  rebuildFiles.push path
  timeout = setTimeout rebuild, 100

rebuild = ->
  rebuildLock = on
  console.log  'coffee',['-co',root+'/build/'].concat rebuildFiles.uniq()
  i = cp.spawn 'coffee',['-co',root+'/build/'].concat rebuildFiles.uniq()
  i.on 'close', (status) ->
    console.log 'done'
    rebuildFiles = []
    rebuildLock = off
    server.kill('SIGHUP') if server?
    client.kill('SIGHUP') if client?
    server = cp.spawn 'coffee', ['server/server.coffee']
    server.stdout.setEncoding 'utf8'
    server.stderr.setEncoding 'utf8'
    server.stdout.on 'data', console.log
    server.stderr.on 'data', console.log
    setTimeout ( ->
      client = cp.spawn 'chromium-browser', ["-app=http://localhost:9999"]
      client.stdout.setEncoding 'utf8'
      client.stderr.setEncoding 'utf8'
      client.stdout.on 'data', console.log
      client.stderr.on 'data', console.log
    ), 500

readDir root + '/common/', addFile
readDir root + '/client/', addFile
console.log ':dev', 'watching', Object.keys(watch).length
