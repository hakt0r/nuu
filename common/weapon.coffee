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

###
  this creates the game model, not an instance of a shot
  think of it as a factory
###

$public class Weapon extends Outfit
  @active: []
  @proj  : []
  @beam  : {}
  @count : 0

  turret : no
  color  : 'red'
  sprite : null

  constructor: (name,opts={}) ->
    tpl = Item.byName[name]
    # console.log name, tpl.extends
    @[k] = v for k,v of tpl
    @id = Weapon.count++
    Weapon[name] = @
    @[k] = v for k,v of opts
    Weapon[tpl.extends].call @

Weapon.hostility = (vehicle,target)->
  if  target.hostile and -1 is  target.hostile.indexOf vehicle
    target.hostile.push vehicle
    NUU.jsoncastTo target, hostile: vehicle.id if target.inhabited
  if vehicle.hostile and -1 is vehicle.hostile.indexOf target
    vehicle.hostile.push target
    NUU.jsoncastTo vehicle, hostile: target.id if vehicle.inhabited

Weapon.Bay =->
