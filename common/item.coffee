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

###
  this creates the game model, not an instance of a shot
  think of it as a factory
###

$public class Item
  @tpl: {}
  @byId: {}
  @byName: {}
  @byType: {}
  @byProp: {}
  @init: (items) ->
    id = 0
    for o in items.ship
      Item.tpl[id] = o
      Ship.byTpl[id] = o.className
      Ship.byName[o.className] = id++
    for o in items.outf
      Item.tpl[o.itemId = id++] = Item.byName[o.className] = o
      size = o.stats.size || 'small'
      t = if (s = o.stats.slot) then (if s.$t then s.$t else s) else 'cargo'
      # unless o.extends is 'Launcher'
      Item.byType[t] = small:{},medium:{},large:{} unless Item.byType[t]
      Item.byType[t][size][o.className] = o
      if s and (t = s.prop)
        Item.byProp[t] = {} unless Item.byProp[t]
        Item.byProp[t][o.className] = o

$public class Outfit
  constructor: (name) ->
    tpl = Item.byName[name]
    @[k] = v for k,v of tpl