###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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

$public class Outfit
  constructor: (name) ->
    @tpl = Item.byName[name]
    Object.assign @, @tpl

$public class Item
  @byId: {}
  @byName: {}
  @byType: ship:{}, station:{}
  @byProp: {}
  @byClass: ship:[],outfit:[],gov:[],skill:[],com:[],stellar:[],station:[]

Item.random = (opts={})->
  item = Array.random Object.values Item.byId
  return item unless opts.not
  while opts.not.includes item.type
    item = Array.random Object.values Item.byId
  return item

Item.init = (seed) ->
  items = seed
  console.log ':nuu', 'init:items' if debug
  Item.db = items
  NUU.emit 'init:items:pre', items
  id = 0
  for k,o of Station.template
    o.class = "station"
    o.name  = o.name || k
    Item.byClass.station.push Item.byType.station[o.name] = Item.byId[o.itemId = id] = Item.byName[o.name] = o
    console.log 'item', 'Station', id, o.name if debug
    id++
  NUU.emit 'init:items', items
  for o in items
    Item.byClass[o.class].push o
    if o.class is 'ship'
      Item.byType['ship'][o.name] = Item.byId[o.itemId = id] = Item.byName[o.name] = o
      Ship.byTpl[id] = o.name
      Ship.byName[o.name] = id
      id++
    else if o.class is 'outfit'
      Item.byId[o.itemId = id] = Item.byName[o.name] = o
      size = o.size || 'small'
      t = (
        if (s = o.slot) then (if s.$t then s.$t else s)
        else if o.extends is 'Ammo' then 'ammo'
        else 'cargo' )
      Item.byType[t] = {}       unless Item.byType[t]
      Item.byType[t][size] = {} unless Item.byType[t][size]
      Item.byType[t][size][o.name] = o
      if o.type
        t = o.type.split(' ').pop()
        Item.byType[t] = {} unless Item.byType[t]
        Item.byType[t][o.name] = o
      if s and (t = s.prop)
        Item.byProp[t] = {} unless Item.byProp[t]
        Item.byProp[t][o.name] = o
      id++
    else if o.class is 'com'
    else if o.class is 'gov'
    else console.log 'x', o

  for type, items of Item.byType when items.medium?
    if Object.keys(items.medium).length is 0 and Object.keys(items.large).length is 0
      Item.byType[type] = items.small
  Item.byName.CheatersRagnarokBeam.turret = yes
  Item.byName.CheatersRagnarokBeam.stats.track = 1.6
  NUU.emit 'init:items:done', items
  return seed
