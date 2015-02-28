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

freeId = []
lastId = 0

class $obj
  @byId : {}

  state : 0
  x : 0
  y : 0
  size : 0
  threads : []
  update : ->

  constructor : (opts={}) ->
    @stateRec = t:null,d:null,x:null,y:null,mx:null,my:null
    if opts.tpl then @[k] = v for k,v of Item.tpl[opts.tpl]
    @[k] = v for k,v of opts
    unless @id?
      @id = if freeId.length is 0 then lastId++ else freeId.shift()
    else lastId = max(lastId,@id+1)
    $obj.byId[@id] = @

  destructor : ->
    delete $obj.byId[@id]
    freeId.push @id
    # delete $obj[stateToKey[@state]][@id]

  dist : (o) -> sqrt(pow(abs(o.x-@x),2)-pow(abs(o.y-@y),2))

class CommonEngine extends EventEmitter
  time : Date.now
  threadList : {}
  players : {}
  constructor : ->
    console.log 'CommonEngine'
    $static 'NUU', @
    $static 'NET', new RTSync
    $worker.push Weapon.projectileDamage
    $worker.push Weapon.beamDamage
  start : ->
    console.log 'engine'.yellow, 'start'.green, @tstart = Date.now()
  stop : -> clearInterval i for k,i of @threadList
  thread : (name,time,fnc) -> @threadList[name] = setInterval fnc, time

$public CommonEngine, $obj