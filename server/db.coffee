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

functions =
  create: (name,data) ->
    if @fields then for k,v of @fields when not data[k]
      data[k] = (
        if typeof v is 'function' then v.apply @
        else v )
    @put name, data

Db = (name,obj={}) ->
  console.log 'db', 'register', name # util.inspect obj
  ( obj.ready = -> ) unless obj.ready
  dbPath = path.join 'db',name + '.db'
  initialize = fs.existsSync dbPath
  Db[obj.name] = db = flatfile dbPath
  _.defaults db, functions
  _.defaults db, obj
  db.on 'open', ->
    if initialize
      if db.bootstrap? then for k,v of db.bootstrap
        db.put k,v
      db.put 'db.init', true, -> obj.ready null
    else obj.ready null
    null
    $static name, db
  db

$static 'Db', Db