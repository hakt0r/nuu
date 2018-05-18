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

$abstract 'Missile',
  d: 0
  thrust: 0.1
  turn: 1
  accel: true
  size: 22
  tpl: 175 # Spearhead Missile
  init: $void
  toJSON: -> id:@id,key:@key,state:@state,target:@target.id,ttl:@ttl

# client implements the simple case
return unless isClient

Weapon.Launcher =->
  @release = $void
  @trigger = $void

$obj.register class Missile extends $obj
  @implements: [$Missile]
  @interfaces: [$obj,Debris]
