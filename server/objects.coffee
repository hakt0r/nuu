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

Ship::dropLoot = ->
  newRandom = (classObj) =>
    o = new classObj state:
      S: $moving
      x: @x + -@size/2 + Math.random()*@size
      y: @y + -@size/2 + Math.random()*@size
      m: [ @m[0] + Math.random()*2 - 1, @m[1] + Math.random()*2 - 1 ]
    o
  newRandom Cargo  for i in [0...10]
  newRandom Debris for i in [0...10]
  null

Ship::respawn = ->
  @x = Math.random()*100
  @y = Math.random()*100
  @reset()
  NET.state.write @
  NET.mods.write  @, 'spawn'
