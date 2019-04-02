###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
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

NUU.fix_sprites = (o)->
  for k,v of o
    w = v.size
    v.cols   = v.cols   || 1
    v.rows   = v.rows   || 1
    v.width  = v.width  || w
    v.height = v.height || w
    v.radius = v.radius || w / 2
  o

$public class Formula
  @to:   {}
  @from: {}

Formula.define = (k,f)->
  ( Formula.to[k]   || Formula.to[k]   = [] ).push f
  ( Formula.from[c] || Formula.from[c] = [] ).push [k,f] for c in Object.keys f
  return

Formula.init = (k,f)->
  for f in rules.formula
    k = Object.keys(f)[0]
    Formula.define k, f[k]
  console.log Formula.to   if debug
  console.log Formula.from if debug
  return

NUU.init =->
  NUU.mode = NUU.mode || 'dm'
  console.log 'loading game mode', NUU.mode
  Object.assign rules, rules[NUU.mode]
  # Load objects
  fs.writeJSONSync 'build/objects.json', Item.init (
    fs.readJSONSync 'build/objects_naev.json'
    .concat fs.readJSONSync 'build/objects_nuu.json' )
  # Load metadata for sprites for each object
  fs.writeJSONSync 'build/images.json', meta = NUU.fix_sprites Object.assign(
    fs.readJSONSync 'build/imag/sprites_naev.json'
    fs.readJSONSync 'build/imag/sprites_nuu.json' )
  $static '$meta', meta
  do Formula.init
  do Stellar.init
  console.log ':nuu', 'init:rules' if debug
  rules @
  @thread 'group', 1000, ->
    time = NUU.time()
    o.update time for o in $obj.list
    null
  @start()

## Sync - queue object-creation notification
$public class Sync
  @flush: ->
    NUU.jsoncast sync: add:Sync.adds, del:freeIds = Sync.dels.map (i)-> i.id
    Sync.adds = []; Sync.dels = []; Sync.inst = false
    return unless 0 < freeIds.length
    setImmediate -> $obj.freeId = $obj.freeId.concat freeIds
    null
  @adds: []
  @dels: []
  @inst: false

NUU.on '$obj:add', Sync.add = (obj)->
  Sync.inst = setImmediate Sync.flush unless Sync.inst
  Sync.adds.push obj
  obj

NUU.on '$obj:del', Sync.del = (obj)->
  Sync.inst = setImmediate Sync.flush unless Sync.inst
  Sync.dels.push obj
  obj
