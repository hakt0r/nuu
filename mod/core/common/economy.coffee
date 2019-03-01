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

  ███████  ██████  ██████  ███    ██  ██████  ███    ███ ██    ██
  ██      ██      ██    ██ ████   ██ ██    ██ ████  ████  ██  ██
  █████   ██      ██    ██ ██ ██  ██ ██    ██ ██ ████ ██   ████
  ██      ██      ██    ██ ██  ██ ██ ██    ██ ██  ██  ██    ██
  ███████  ██████  ██████  ██   ████  ██████  ██      ██    ██ ###

$public class Economy
  @objects: new Set
  @timer:   null
  @queue:   []
  @byName:  {}
  constructor: (root) ->
    @allocations = {}
    @offline = []
    @list    = []
    @list.push @root = root
    @inventory = new Inventory 'zone', root.name
    Economy.byName[@name = root.name] = @

Economy.defaults = (o,d)->
  console.log o.template unless d?
  filter = ['allocates','provides','produces','consumes']
  # for k in filter
  o.allocates = Object.assign e:10, d?.allocates || {}, o?.allocates || {}
  o.provides  = Object.assign {},   d?.provides  || {}, o?.provides  || {}
  o.produces  = Object.assign {},   d?.produces  || {}, o?.produces  || {}
  o.consumes  = Object.assign {},   d?.consumes  || {}, o?.consumes  || {}
  for k,v of d when -1 is filter.indexOf k
    o[k] = d[k]
  o

Economy.for = (stellar)->
  unless root = stellar.buildRoot
    console.log 'no buildRoot', stellar.name if debug
    return undefined
  Economy.byName[name = root.name] || Economy.byName[name] = new Economy root

Economy.attach = (stellar)->
  return undefined unless stellar.produces or stellar.consumes
  return unless zone = Economy.for stellar
  stellar.zone = zone
  zone.list.push stellar if -1 is zone.list.indexOf stellar
  Economy.objects.add stellar
  if stellar.active = zone.tryAllocate stellar
    Array.remove zone.offline, stellar
    zone.offline.map Economy.attach
  else
    zone.offline.push stellar
    zone.offline = Array.uniq zone.offline

Economy::detach = (stellar)->
  Array.remove @list, stellar
  Array.remove stellar.zone.offline, stellar
  Economy.objects.delete stellar

Economy::tryAllocate = (stellar)->
  return true unless stellar.allocates
  failed = no
  for item, count of stellar.allocates
    if not @allocate stellar, item, count
      failed = yes
      console.log stellar.name, 'needs', item, count  if debug
      break
    else
      console.log stellar.name, 'has', item, count  if debug
  return true unless failed
  @disallocate stellar
  false

Economy::allocate = (stellar,item,count)->
  need  = stellar.allocates[item]
  total = @provides item
  list  = @allocations[item] || @allocations[item] = []
  sum   = list.reduce ( (v,p)-> v = v + p.allocates[item] ), 0
  return false unless total - sum >= need
  list.push stellar
  true

Economy::provides = (key)->
  @list
  .map (o)-> o.provides?[key] || 0
  .reduce ( (v,t)-> t + v ), 0

Economy::disallocate = (stellar)->
  for item, count of stellar.allocates when @allocations[item]?
    Array.remove @allocations[item], stellar
  null

Economy.produce = ->
  now = Date.now()
  Object.values(Economy.byName).map (zone)->
    unless 1 < zone.list.length
      console.log '$p : no zones'  if debug
      return
    produce = zone.list
    .filter (stellar)->
      return false unless stellar.nextCyle is 0 and stellar.produces?
      return true  unless stellar.consumes?
      for item, count of stellar.consumes
        unless stellar.zone.inventory.has item, count
          console.log '$p', stellar.name, 'needs', item, count  if debug
          return false
      for item, count of stellar.consumes
        stellar.zone.inventory.get item, count
      true
    .map    (stellar)-> stellar.nextCyle = now + stellar.interval; stellar
    Economy.queue = Economy.queue.concat produce
    console.log zone.inventory.data  if debug
  Economy.queue = Economy.queue.sort (a,b)-> a.nextCyle - b.nextCyle
  Economy.queueNext()
  null

setInterval Economy.produce, 1000 if isServer

Economy.queueNext = ->
  now = Date.now()
  clearTimeout Economy.timer
  q = Economy.queue
  return unless q[0]?
  Economy.timer = setTimeout ( ->
    while q[0]?.nextCyle <= now
      stellar = q.pop()
      stellar.nextCyle = 0
      for item, count of stellar.produces
        console.log stellar.name, '$p', item, count  if debug
        stellar.zone.inventory.add item, count
    Economy.queueNext()
    return
  ), max 0, q[0].nextCyle - Date.now()

Economy::totalFor = (key)->
  @list
    .map (v)->
      if v.produces and e = v.produces[key]
        if e == true then Infinity else e
      else 0
    .reduce (v,t)-> t + v
Object.defineProperty Economy::, 'energyTotal',   get:-> @totalFor 'e'
Object.defineProperty Economy::, 'farmlandTotal', get:-> @totalFor 'Farmland'

Economy::availableFor = (key)->
  return 0 if 0 is have = @totalFor key
  have - @list
    .map (v)-> if v.consumes and e = v.consumes[key] then e else 0
    .reduce (v,t)-> t + v
Object.defineProperty Economy::, 'energyAvailable',   get:-> @availableFor 'e'
Object.defineProperty Economy::, 'farmlandAvailable', get:-> @availableFor 'Farmland'

Object.defineProperty Economy::, 'nextCyle', get:(key)-> @list.reduce (v,t)->
  if (e = v.nextCyle) isnt 0 and e > t then e else t || 0

Object.defineProperty Economy::, 'stalled', get:(key)-> @list.filter (i)->
  i.nextCyle is 0
