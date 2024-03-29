###

  * c) 2007-2022 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2022 flyc0r

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
    v: [ @v[0] + Math.random() * .2 - .1, @v[1] + Math.random()* .2 - .1 ]
  newRandom Cargo  for i in [0...10]
  newRandom Debris for i in [0...10]
  return

Ship::resetHostiles = ->
  h = @hostile; @hostile = []
  return unless h
  Array.remove s.hostile, @ for s in h when s.hostile?
  NUU.jsoncastTo @, hostile:@hostile if @inhabited

Ship::respawn = ->
  @locked = true
  @respawning = yes
  @resetHostiles()
  setTimeout ( =>
    @dropLoot()
  ), 4000
  setTimeout ( =>
    do @reset
    if @user
      opts = @user.spawnState()
      @setState opts.state; delete opts.state
      Object.assign @, opts
    else
      @x = Math.random()*100
      @y = Math.random()*100
      @setState S:$moving, x:@x, y:@y, v:[0,0]
    if @state.S is $moving
      @locked = true
      setTimeout ( => @locked = false ), 3000
    if @landedAt
      NUU.jsoncastTo @, landed: @landedAt.id
    do @update
    NET.mods.write @, 'spawn'
  ), 5000

Ship::hit = (src,wp) ->
  return if @destructing
  switch Weapon.impactLogic.call @, wp
    when Weapon.impactType.hit
      NUU.emit 'ship:hit', @, src, @shield, @armour
      NET.mods.write @, 'hit', @shield, @armour
    when Weapon.impactType.shieldsDown
      NUU.emit 'ship:shieldsDown', @, src
      NET.mods.write @, 'shield', @shield, @armour
    when Weapon.impactType.disabled
      NUU.emit 'ship:disabled', @, src
      NET.mods.write @, 'disabled', @shield, @armour
    when Weapon.impactType.destroyed
      NUU.emit     'ship:destroyed', @, src
      NET.mods.write @, 'destroyed', 0, 0
  return

Station::hit = (src,wp) ->
  return if @destructing
  switch Weapon.impactLogic.call @, wp
    when Weapon.impactType.hit
      NUU.emit 'station:hit', @, src, @shield, @armour
      NET.mods.write @, 'hit', @shield, @armour
    when Weapon.impactType.shieldsDown
      NUU.emit 'station:shieldsDown', @, src
    when Weapon.impactType.disabled
      NUU.emit 'station:disabled', @, src
    when Weapon.impactType.destroyed
      NUU.emit     'station:destroyed', @, src
      NET.mods.write @, 'destroyed', 0, 0
  return
