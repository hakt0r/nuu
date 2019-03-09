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

NUU.server = null
NUU.drone = {}
NUU.userState = {}
NUU.states = []
NUU.players = []

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
  @define: (k,f)->
    ( Formula.to[k]   || Formula.to[k]   = [] ).push f
    ( Formula.from[c] || Formula.from[c] = [] ).push [k,f] for c in Object.keys f
    return

NUU.init =->
  # Load objects
  fs.writeJSONSync 'build/objects.json', Item.init (
    fs.readJSONSync 'build/objects_naev.json'
    .concat fs.readJSONSync 'build/objects_nuu.json' )
  # Load metadata for sprites for each object
  fs.writeJSONSync 'build/images.json', meta = NUU.fix_sprites Object.assign(
    fs.readJSONSync 'build/imag/sprites_naev.json'
    fs.readJSONSync 'build/imag/sprites_nuu.json' )
  $static '$meta', meta
  # Load stellars
  console.log ':nuu', 'init:stars' if debug
  orbits = {}
  now = Date.now()
  rules.lastId = 200
  for f in rules.formula
    k = Object.keys(f)[0]
    Formula.define k, f[k]
  console.log Formula.to
  console.log Formula.from
  for i in rules.stars
    continue unless o = i[7]
    continue unless o.occupiedBy
    rules.seedEconomy i, o
  for i in rules.stars
    [ id, Constructor, name, sprite, orbit, state, relto, args ] = i
    orbits[relto+'_'+orbit] = l = orbits[relto+'_'+orbit] || []
    l.push id
  for i in rules.stars
    [ id, Constructor, name, sprite, orbit, state, relto, args ] = i
    odx = orbits[relto+'_'+orbit].indexOf id
    oct = ( orbits[relto+'_'+orbit] || [] ).length
    relto$ = $obj.byId[relto] || x:0,y:0,update:$void
    relto$.update()
    if oct > 1
      rand  = ( TAU / oct ) * odx
      vel   = 3
      stp   = TAU * 1 / ( TAU * orbit * 1/3 )
      state = S:state, relto:relto$, t:now, orb:orbit, vel:vel, stp:stp, off:rand
    else
      rand = random() * TAU
      m = [0,min 5,   max 1,  orbit % 5]
      if orbit > 100000   then m = [0,min 19,  max 10,  orbit % 19]
      if orbit > 1000000  then m = [0,min 99,  max 20,  orbit % 99]
      if orbit > 10000000 then m = [0,min 199, max 100, orbit % 199]
      state = S:state, relto:relto$, x:relto$.x + cos(rand) * orbit, y:relto$.y + sin(rand) * orbit, m:m
    opts = id:id, name:name, sprite:sprite, state:state
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
