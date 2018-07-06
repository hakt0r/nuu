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

Ship::dropLoot = ->
  do @update
  newRandom = (classObj) => new classObj state:
    S: $moving
    x: @x + -@size/2 + Math.random()*@size
    y: @y + -@size/2 + Math.random()*@size
    m: [ @m[0] + Math.random()*2 - 1, @m[1] + Math.random()*2 - 1 ]
  newRandom Cargo  for i in [0...10]
  newRandom Debris for i in [0...10]
  null

Ship::respawn = ->
  do @reset
  @x = Math.random()*100
  @y = Math.random()*100
  @setState S:$moving, x:@x, y:@y, m:[0,0]
  do @update
  NET.mods.write  @, 'spawn'

Ship::hit = (src,wp) ->
  return if @destructing
  dmg = wp.stats
  if @shield > 0
    @shield -= dmg.penetrate
    if @shield < 0
      @shield = 0
      @armour -= dmg.physical
      NUU.emit 'ship:shieldsDown', @, src
  else @armour -= dmg.penetrate + dmg.physical
  if 0 < @armour < 25 and @disabled > 10
    NUU.emit 'ship:disabled', @, src
  else if @armour < 0
    @armour = 0
    @shield = 0
    @destructing = true
    NUU.emit 'ship:destroyed', @, src
    NET.mods.write @, 'destroyed', 0,0
  else
    NUU.emit 'ship:hit', @, src, @shield, @armour
    NET.mods.write @, 'hit', @shield, @armour
  null

Asteroid.autospawn = (opts={})-> $worker.push =>
  roids  = @list.length
  if roids < opts.max
    dt = opts.max - roids
    new Asteroid for i in [0...dt]
  1000

Asteroid::hit = (perp,weapon)->
  return if @destructing
  return unless dmg = weapon.stats.physical
  @hp = max 0, @hp - dmg
  NET.mods.write @, ( if @hp is 0 then 'destroyed' else 'hit' ), 0, @hp
  return unless @hp is 0
  if @resource.length > 1 then for r in @resource
    m = @m.slice(); m[0]+=-6+random()*6; m[1]+=-6+random()*6
    Weapon.hostility perp, new Asteroid
      hostile: []
      resource: r
      size: size = max 10, floor random() * @size / 2
      state: S:$moving, x:@x, y:@y, m:m
  NUU.emit 'asteroid:destroyed', perp, @resource
  @destructor()
  null
