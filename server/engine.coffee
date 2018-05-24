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
  else console.log ':nuu', 'no meta for', obj

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
  app.on '$obj:add', NUU.loadMeta
  # Load stellars
  console.log ':nuu', 'init:stars' if debug
  for i in rules.stars
    # [ id, Constructor, name, sprite, orbit, state, relto, orbitEcc ] = i
    rand  = random() * TAU
    relto = $obj.byId[i[6]] || x:0,y:0,update:$void
    relto.update()
    m = [0,min 5,   max 1,  i[4] % 5]
    if i[4] > 100000   then m = [0,min 19,  max 10,  i[4] % 19]
    if i[4] > 1000000  then m = [0,min 99,  max 20,  i[4] % 99]
    if i[4] > 10000000 then m = [0,min 199, max 100, i[4] % 199]
    Constructor = i[1]
    new Constructor id:i[0], name:i[2], sprite:i[3], state:
      S:i[5]
      relto:relto# i[5]
      x:relto.x + cos(rand) * i[4]
      y:relto.y + sin(rand) * i[4]
      m:m
  console.log ':nuu', 'init:rules' if debug
  rules @
  now = Date.now
  @thread 'group', 1000, =>
    global.TIME  = now()
    global.ETIME = Math.floor(TIME/1000000)*1000000
    o.update() for o in $obj.list
  @start()
