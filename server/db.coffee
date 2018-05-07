###

  * c) 2007-2016 Sebastian Glaser <anx@ulzq.de>
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

functions =
  create: (name,data) ->
    if @fields then for k,v of @fields when not data[k]
      data[k] = (
        if typeof v is 'function' then v.apply @
        else v )
    data.id = @keys().length
    @put name, data

Db = (name,obj={}) ->
  obj.ready = ( -> ) unless obj.ready
  obj.path = path.join 'db', ( obj.name = name ) + '.db'
  obj.init = fs.existsSync obj.path
  $static name, Db[name] = db = flatfile obj.path
  _.defaults db, functions
  _.defaults db, obj
  db.on 'open', ->
    if obj.init
      db.put k,v for k,v of db.bootstrap if db.bootstrap?
      db.put 'db.init', true, -> obj.ready null
    else do obj.ready
    null
  console.log 'db', 'register', name, util.inspect db
  db

$static 'Db', Db
