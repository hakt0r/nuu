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

NUU.server = null
NUU.drone = {}
NUU.userState = {}
NUU.states = []
NUU.players = []

NUU.loadMeta = (obj) ->
  if ( meta = $meta[ obj.sprite ] )
    # console.log ':nuu', '$meta', obj.sprite, $meta[obj.sprite] if debug
    obj.size = meta.size
    obj.radius = meta.radius
  else console.log ':nuu', 'no meta for', obj if debug

NUU.fix_sprites = (o)->
  for k,v of o
    w = v.size
    v.cols   = v.cols   || 1
    v.rows   = v.rows   || 1
    v.width  = v.width  || w
    v.height = v.height || w
    v.radius = v.radius || w / 2
  o

NUU.init =->
  console.log ':nuu', 'init:items' if debug
  # Load objects
  items = JSON.parse fs.readFileSync './build/objects_naev.json'
  nuu_i = JSON.parse fs.readFileSync './build/imag/objects_nuu.json'
  items.ship = items.ship.concat nuu_i.ship
  items.outf = items.outf.concat nuu_i.outf
  Item.init items
  fs.writeFileSync 'build/objects.json', JSON.stringify items
  # Load metadata for sprites for each object
  meta =                     JSON.parse fs.readFileSync 'build/imag/sprites_naev.json'
  meta = Object.assign meta, JSON.parse fs.readFileSync 'build/imag/sprites_nuu.json'
  meta = NUU.fix_sprites meta
  fs.writeFileSync 'build/images.json', JSON.stringify meta
  $static '$meta', meta
  NUU.on '$obj:add', NUU.loadMeta
  # Load stellars
  console.log ':nuu', 'init:stars' if debug
  for i in rules.stars
    [ id, Constructor, name, sprite, orbit, state, relto, args ] = i
    rand  = random() * TAU
    relto = $obj.byId[relto] || x:0,y:0,update:$void
    relto.update()
    m = [0,min 5,   max 1,  orbit % 5]
    if orbit > 100000   then m = [0,min 19,  max 10,  orbit % 19]
    if orbit > 1000000  then m = [0,min 99,  max 20,  orbit % 99]
    if orbit > 10000000 then m = [0,min 199, max 100, orbit % 199]
    opts = id:id, name:name, sprite:sprite, state:
      S:state
      relto:relto
      x:relto.x + cos(rand) * orbit
      y:relto.y + sin(rand) * orbit
      m:m
    opts[k] = v for k,v of args
    new Constructor opts
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
