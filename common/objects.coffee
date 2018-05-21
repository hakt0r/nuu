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

freeId = []
lastId = 0

$public class $obj
  @freeId: freeId
  @interfaces: [$obj]
  tpl: null
  size: 0
  hit: $void

  constructor: (opts={})->

    # read or setup momentum vector
    @m = opts.m || [0,0]
    delete opts.m

    # read state if specified
    delete opts.state if ( state = opts.state )

    # apply template
    @[k] = v for k,v of Item.tpl[opts.tpl] if opts.tpl

    # apply other keys
    @[k] = v for k,v of opts
    # console.log 'constructor$', @id, @name

    # choose id
    unless @id?
      @id = if freeId.length is 0 then lastId++ else freeId.shift()
    else lastId = max(lastId,@id+1)

    # register
    i.list.push i.byId[@id] = @ for i in @constructor.interfaces

    # apply state
    @setState state
    do @loadAssets if @loadAssets
    app.emit '$obj:add', @

  destructor: ->
    console.log 'destructor$', @id, @name if debug
    for i in @constructor.interfaces
      console.log 'destructor$', 'object', i.name if debug
      delete i.byId[@id]
      Array.remove i.list, @
    app.emit '$obj:del', @

  dist: (o)-> sqrt(pow(abs(o.x-@x),2)-pow(abs(o.y-@y),2))

  toJSON: -> id:@id,key:@key,size:@size,state:@state,tpl:@tpl

Object.defineProperty $obj::, 'p',
  get: -> @update(); return [@x,@y]
  set: (@x,@y)->

$obj.byId = {}
$obj.list = []
$obj.byClass = []

$obj.create = (opts)-> new $obj.byClass[opts.key] opts

$obj.register = (blueprint)->
  if blueprint.implements
    list = blueprint.implements
    delete blueprint.implements
    for implement in list
      if typeof implement is 'function'
        implement blueprint
      else console.log 'ERROR:', blueprint::constructor.name
  blueprint::key = ( $obj.byClass.push blueprint ) - 1
  blueprint.byId = {}
  blueprint.list = []
  $public blueprint

###
  Interface-only
   Objects are just registered here for
   now, Might be un-stubbed later with
   some related code.
###

$obj.register class Collectable extends $obj
  @interface: true

$obj.register class Shootable extends $obj
  @interface: true

###
  Some simple objects
###

$obj.register class Debris extends $obj
  @interfaces: [$obj,Collectable,Debris]
  name: 'Debris'
  toJSON: -> id:@id,key:@key,state:@state

$obj.register class Cargo extends $obj
  @interfaces: [$obj,Collectable,Debris]
  name: 'Cargo Box'
  item: null
  ttlFinal: yes
  constructor: (opts={})->
    super opts
    @ttl  = NUU.time() + 30000 unless @ttl
    @item = Element.random()   unless @item
  toJSON: -> id:@id,key:@key,state:@state,item:@item

$obj.register class Stellar extends $obj
  @interfaces: [$obj,Stellar]
  toJSON: -> id:@id,key:@key,sprite:@sprite,state:@state,name:@name

$obj.register class Star extends Stellar
  @interfaces: [$obj,Stellar]

$obj.register class Planet extends Stellar
  @interfaces: [$obj,Stellar]

$obj.register class Moon extends Stellar
  @interfaces: [$obj,Stellar]

$obj.register class Station extends Stellar
  @interfaces: [$obj,Stellar]
