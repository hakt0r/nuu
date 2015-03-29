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


NUU.server = null
NUU.drone = {}
NUU.userState = {}
NUU.states = []
NUU.players = []

NUU.init =->
  console.log 'init:items'
  Item.init(JSON.parse fs.readFileSync './build/objects.json')
  console.log 'init:stars'
  for i in rules.stars
    rand  = random() * TAU
    relto = $obj.byId[i[5]] || x:0,y:0,update:$void
    relto.update()
    new Stellar id:i[0], name:i[1], sprite:i[2], state:
      S:i[4]
      relto:i[5]
      x:relto.x+cos(rand)*i[3]
      y:relto.y+sin(rand)*i[3]
  console.log 'init:rules'
  rules @
  now = Date.now
  @thread 'group', 1000, =>
    TIME  = now()
    ETIME = Math.floor(TIME/1000000)*1000000
    o.update() for o in $obj.list
  @start()
