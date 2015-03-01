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
  Item.init(JSON.parse fs.readFileSync './build/objects.json')
  for i in rules.stars
    new Stellar id:i[0], name:i[1], sprite:i[2], state: { S:i[4], relto:i[5], orbit:i[3] }
  rules @
  @thread 'group', 1000, =>
    TIME = @time()
    for o in $obj.list
      o.update()
  @start()
