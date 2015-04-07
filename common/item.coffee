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
  @byType: ship:{}
  @byProp: {}
  @init: (items) ->
    id = 0
    for o in items.ship
      Item.tpl[id] = o
      Ship.byTpl[id] = o.name
      Ship.byName[o.name] = id++
      Item.byName[o.name] = o
      Item.byType['ship'][o.name] = o
    for o in items.outf
      Item.tpl[o.itemId = id++] = Item.byName[o.name] = o
      size = o.size || 'small'
      t = (
        if (s = o.slot) then (if s.$t then s.$t else s)
        else if o.extends is 'Ammo' then 'ammo'
        else 'cargo' )
      Item.byType[t] = small:{},medium:{},large:{} unless Item.byType[t]
      Item.byType[t][size][o.name] = o
      if o.type
        t = o.type.split(' ').pop()
        Item.byType[t] = {} unless Item.byType[t]
        Item.byType[t][o.name] = o
      if s and (t = s.prop)
        Item.byProp[t] = {} unless Item.byProp[t]
        Item.byProp[t][o.name] = o

    for type, items of Item.byType when items.medium?
      if Object.keys(items.medium).length is 0 and Object.keys(items.large).length is 0
        Item.byType[type] = items.small

$public class Outfit
  constructor: (name) ->
    tpl = Item.byName[name]
    @[k] = v for k,v of tpl