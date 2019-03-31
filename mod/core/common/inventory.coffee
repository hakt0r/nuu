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

NUU.on "server:db", ( -> $tag.db 'InventoryDB' ) if isServer

$public class Inventory
  @byKey: {}
  create: yes
  constructor: (opts)->
    { @key, @create, @data } = opts
    return existing if existing = Inventory.byKey[@key]
    ( @[k] = v for k,v of EventEmitter::; EventEmitter.call @ ) if isClient
    Inventory.byKey[@key] = @
    do @read  if @key
    do @tally if @data

Inventory::close = -> delete Inventory.byKey[@key]

Inventory::tally = ->
  @types = Object.keys(@data).length
  @total = Object.values(@data).reduce ( (v,i)-> v += i ), 0
  return

Inventory::read = NUU.$target
  server: ->
    @exists = false isnt @data = InventoryDB.get @key
    return if @data or not @create
    @write @data = {}
    return
  client: ->
    NET.json inventory_read: @key
    return

Inventory::write = NUU.$target
  server: ->
    do @tally
    InventoryDB.set @key, @data if @key
    return
  client: ->

Inventory::has = (item,count=1)->
  return false unless d  = @data[item]
  return false unless d >= count
  return d

Inventory::add = (item,count=1)->
  @data[item] = ( @data[item] || 0 ) + count
  do @write
  return

Inventory::give = (other,item,count=1)->
  return false unless @get item, count
  other.add item, count
  do @write
  true

Inventory::get = (item,count=1)->
  return false unless @data[item]? and @data[item] >= count
  @data[item] -= count
  do @write
  true

NET.on "inventory_read", (msg,src)->
  return src.error '_no_handle' unless u = src.handle
  i = new Inventory Object.assign msg, create:no
  src.json inventory_write: key:msg.key, data: i.data
  i.close()
  return

NET.register "inventory_write",
  server: (msg,src)->
    i = new Inventory msg
    src.json inventory_write: key:msg.key, data: i.data
    i.close()
  client: (msg)->
    return unless i = Inventory.byKey[msg.key]
    i.data = msg.data
    i.emit 'read', i
    return
