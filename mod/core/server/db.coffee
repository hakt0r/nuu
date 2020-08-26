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

unless fs.existsSync 'db'
  fs.mkdirSync 'db'

$tag.db = (name,obj={}) ->
  obj.ready = ( -> ) unless obj.ready
  db = new $tag.XScale obj.path = path.join 'db', ( obj.name = name ) + '.db'
  meta = db.get '$meta'
  console.log '::db$meta', name, meta if debug
  Object.assign db, functions, obj, meta
  if db.id?
    console.log name, ':open'.green, db.id?
    throw new Error 'db.id is Nan', db if isNaN db.id
  else
    console.log name, ':bootstrap'.red, db.id? if debug
    db.id = 1
    db.create k,v for k,v of db.bootstrap
  global[name] = db
  do obj.ready
  console.log '::db', 'register', name, util.inspect db if debug
  db

functions =
  saveMeta:->
    @set '$meta', id: @id
    console.log '_save:$meta', id: @id
  create: (name,data) ->
    if @fields then for k,v of @fields when not data[k]
      data[k] = (
        if typeof v is 'function' then v.apply @
        else v )
    data.id = @id++
    @set name, data
    do @saveMeta
    console.log '_create:', id: @id

setInterval ( ->
  $tag.flushAll()
), 1000

NUU.emit "server:db"
