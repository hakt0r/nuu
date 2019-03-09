###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
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

$public class Inventory
  constructor: (@key)->
    @data = {}
    do @read if @key?

Inventory::has = (item,count)->
  if count then @data[item]? and @data[item] >= count else @data[item]?
  do @save

Inventory::add = (item,count)->
  @data[item] = ( @data[item] || 0 ) + count
  do @save

Inventory::get = (item,count)->
  if @data[item]? and @data[item] >= count then @data[item] -= count else false
  do @save

$tag.db 'InventoryDB'

Inventory::read = ->
  @data = InventoryDB.get @key
  return if @data
  @data = {}
  do @save

Inventory::save = ->
  InventoryDB.set @key, @data

NET.on "inventory_get", (key)->
