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

functions =
  saveMeta:-> @set '$meta', id: @id
  create: (name,data) ->
    if @fields then for k,v of @fields when not data[k]
      data[k] = (
        if typeof v is 'function' then v.apply @
        else v )
    data.id = @id++
    @set name, data
    do @saveMeta

process.on 'exit',    $tag.closeAll
process.on 'SIGINT',  $tag.closeAll
process.on 'SIGUSR1', $tag.closeAll
process.on 'SIGUSR2', $tag.closeAll

$tag.db = (name,obj={}) ->
  obj.ready = ( -> ) unless obj.ready
  obj.path = path.join 'db', ( obj.name = name ) + '.db'
  obj.needsInit = not fs.existsSync obj.path
  $static name, $tag[name] = db = new $tag.XScale obj.path
  Object.assign db, functions, obj
  if obj.needsInit and db.bootstrap?
    db.set '$meta', id:1
    db.create k,v for k,v of db.bootstrap
  else
    db.id = ( db.get '$meta' ).id
    throw new Error 'db.id is Nan', db if isNaN db.id
  do obj.ready
  console.log '::db', 'register', name, util.inspect db if debug
  db
