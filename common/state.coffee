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

$obj::stateFromFlags = ->
  if @right or @left then $maneuvering
  else if @accel or @retro or @boost then $accelerating
  else if abs(@m[0]) + abs(@m[1]) isnt 0 then $moving
  else $fixed

$obj::changeState = (state) ->
  prev = State.toKey[(@state||{S:0}).S]
  @update true
  if typeof state is 'object'
    @state = State.create @, state
  else @state = State.create @,
    S: @stateFromFlags()
    ab: ab = @thrust * Speed.boost
    ar: ar = @thrust * -.5
    a: if @boost then ab else if @retro then ar else @thrust
    t: TIME
    x: @x
    y: @y
    d: @d
    m: @m.slice()
  # console.log @id, prev, '>', State.toKey[@state.S]
  @update = @state.update.bind(@state)
  @

$public class State
  S: $fixed
  lastUpdate: 0
  obj: null
  t: 0
  x: 0
  y: 0
  d: 0
  m: null
  a:  0
  ar: 0
  ab: 0
  relto: null
  update: $void

  constructor: (@obj,opts={}) ->
    @[k] = v for k,v of opts
    @relto = $obj.byId[@relto]
    @m = @obj.m || [0,0] unless @m
    @t = TIME            unless @t
    @lastUpdate = TIME

Object.defineProperty State::, 'p',
  get: -> return [ @x, @y ]
  set: (p) -> [ @x, @y ] = p

State.toKey = []

State.register = (name,value) -> 
  value::S = @toKey.push name
  @[name] = value

State.create = (parent,json) ->
  if ( _super_ = @[@toKey[json.S]] )
    new _super_ parent, json
  else
    console.log 'err', parent.id, json
    null

State.register 'fixed', class fixed extends State
  constuctor: -> @m = $v.zero
  toJSON: -> S:@S,t:@t,x:@x,y:@y,d:@d

State.register 'relative', class relative extends State
  update: ->
    return null if @lastUpdate is TIME
    @lastUpdate = TIME
    @relto.update()
    @obj.x = @relto.x + @x
    @obj.y = @relto.y + @y
    null
  toJSON: -> S:@S,t:@t,x:@x,y:@y,d:@d,relto:@relto.id

State.register 'moving', class moving extends State
  constructor: (opts={})->
    super
    @obj.m = @m
  update: ->
    return null if @lastUpdate is TIME
    @lastUpdate = TIME
    ticks = (TIME - @t) / TICK
    @obj.x = @x + @m[0] * ticks
    @obj.y = @y + @m[1] * ticks
    null
  toJSON: -> S:@S,t:@t,x:@x,y:@y,d:@d,m:@m

State.register 'accelerating', class accelerating extends State
  update: ->
    return null if @lastUpdate is TIME
    @lastUpdate = TIME
    @obj.fuel -= @a
    ticks = (TIME - @t) / TICK
    ticks2 = ticks * ticks
    dir = @obj.d / RAD
    @obj.m[0] = @m[0] + @a * cos(dir) * ticks
    @obj.m[1] = @m[1] + @a * sin(dir) * ticks
    @obj.m = $v.limit @obj.m, Speed.max
    @obj.x = @x + @m[0] * ticks + .5 * @a * cos(dir) * ticks * ticks
    @obj.y = @y + @m[1] * ticks + .5 * @a * sin(dir) * ticks * ticks
    null
  toJSON: -> S:@S,t:@t,x:@x,y:@y,d:@d,m:@m,a:@a,ar:@ar,ab:@ab

State.register 'maneuvering', class maneuvering extends State
  ended: no
  constructor: (@obj,state) ->
    super
    $worker.push => @update()
  update: (final=no) ->
    return off  if @ended
    return null if not final and @lastUpdate is TIME
    @lastUpdate = TIME
    dir = @obj.d
    @obj.turn = @obj.turn || 1
    if @obj.right or @obj.left
      dir = (dir + @obj.turn * if @obj.left then -1 else 1)
      if dir <= -1 then dir = 360 + dir
      else if dir >= 360 then dir = dir - 360
    @obj.d = dir
    if @obj.accel or @obj.retro
      dir = dir / RAD
      @obj.m[0] = @obj.m[0] + @a * cos dir
      @obj.m[1] = @obj.m[1] + @a * sin dir
      @obj.m[0] = @obj.m[1] = 0 if @obj.retro and (abs(@obj.m[0])+abs(@obj.m[1]) < 3)
    @obj.m = $v.limit @obj.m, Speed.max
    @obj.x = @obj.x + @obj.m[0]
    @obj.y = @obj.y + @obj.m[1]
    @ended = final
    return null
  toJSON: -> S:@S,t:@t,x:@x,y:@y,d:@d,m:@m,a:@a,ar:@ar,ab:@ab

State.register 'orbit', class orbit extends State
  rad:  0.0
  offs: 0.0
  dir:  0.0
  step: 0.0
  lx:   0
  ly:   0
  constructor: (@obj,state) ->
    super
    @lastUpdate = @t = TIME
    @orbit = state.orbit || 1000                   #fixme (calculate when not given)
    @step = state.step  || min(10/@orbit*TAU,0.01) #fixme (calculate when not given)
    @offs = state.offs  || Math.random() * TAU     #fixme (calculate when not given)
    @relto.update()
    @obj.x = @x = @relto.x + cos(@offs) * @orbit
    @obj.y = @y = @relto.y + sin(@offs) * @orbit
  update: ->
    return null if @lastUpdate is TIME
    @relto.update()
    deltaT = ( TIME - @lastUpdate ) / TICK 
    ticks  = ( TIME - @t ) / TICK
    @lastUpdate = TIME
    @dir    = @offs + ( ticks * @step ) % TAU
    @obj.x    = @relto.x + cos(@dir) * @orbit
    @obj.y    = @relto.y + sin(@dir) * @orbit
    @obj.m[0] = ( @obj.x - @lx ) / deltaT
    @obj.m[1] = ( @obj.y - @ly ) / deltaT
    @lx = @obj.x
    @ly = @obj.y
    null
  toJSON: -> S:@S,relto:@relto.id,t:@t,orbit:@orbit,offs:@offs,step:@step

NET.on 'jump', (target,src) ->
  o = src.handle.vehicle
  target = $obj.byId[parseInt target]
  if target?
    o.accel = o.boost = o.retro = o.left = o.right = no
    TIME = Date.now(); target.update()
    console.log 'JUMP', target.x, target.y, target.m
    o.x = target.x
    o.y = target.y
    o.m = target.m.slice()
    console.log 'SET', o.x, o.y, o.m
    NET.state.write o, true

NET.define 2,'STATE',
  read:
    server: (msg,src) =>
      o = src.handle.vehicle
      [ o.accel, o.retro, o.right, o.left, o.boost ] = NET.getFlags src.flags = msg[1]
      o.d = msg.readUInt16LE 2
      NET.state.write o
      src
    client: (msg) =>
      o = $obj.byId[id = msg.readUInt16LE 2]
      [ o.accel, o.retro, o.right, o.left, o.boost ] = NET.getFlags o.flags = msg[1]
      o.changeState stateInt = msg[34]
      r = o.state
      o.d  = r.d  = msg.readUInt16LE 4
      o.x  = r.x  = msg.readInt32LE  6
      o.y  = r.y  = msg.readInt32LE  10
      r.t  = Math.floor(Date.now()/1000000)*1000000 + msg.readUInt32LE 14
      o.m[0] = r.m[0] = msg.readDoubleLE 18
      o.m[1] = r.m[1] = msg.readDoubleLE 26
      o
  write:
    server:(o,override=no) =>
      o.flags = NET.setFlags [o.accel,o.retro,o.right,o.left,o.boost,no,no,no]
      o.changeState()
      msg = new Buffer [ NET.stateCode, o.flags,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
      edate = o.state.t % 1000000
      msg.writeUInt16LE o.id,              2
      msg.writeUInt16LE o.d,               4
      msg.writeInt32LE  Math.floor(o.x),   6
      msg.writeInt32LE  Math.floor(o.y),   10
      msg.writeUInt32LE edate,             14
      msg.writeDoubleLE o.m[0],            18
      msg.writeDoubleLE o.m[1],            26
      msg[34] = o.state
      NUU.bincast msg.toString 'binary'
    client:(o,flags) =>
      if typeof flags is 'object'
        o.flags = flags = NET.setFlags(flags)
      else o.flags = flags
      msg = new Buffer [NET.stateCode,flags,0,0,0]
      msg.writeUInt16LE o.d, 2
      NET.send msg.toString 'binary'

action = (o,t,mode) ->
  switch mode
    when 'capture'
      if $dist(o,t) < o.size / 2
        console.log o.id, 'collected', t.id
        t.destructor()
      else console.log 'capture', 'too far out', $dist(o,t)
    when 'launch'
      console.log 'launch', o.id, t.id
      o.changeState S:$relative,relto:o.state.relto
    when 'land', 'dock'
      if $dist(o,t) < t.size / 2
        console.log 'land', t.id
        o.changeState S:$fixed,relto: t
      else console.log 'land/dock', 'too far out'
    when 'orbit'
      if $dist(o,t) < t.size / 2 * 1.5
        console.log 'orbit', t.id
        o.changeState s:$orbit,orbit:$dist(o,t),relto:t
      else console.log 'orbit', 'too far out'
action.key = ['launch','land','orbit','capture']

NET.define 3,'action',
  read:
    server:(msg,src) =>
      o = src.handle.vehicle
      mode = action.key[msg[1]]
      t = msg.readUInt16LE 2
      t = $obj.byId[t]
      console.log 'action', o.id, mode, t.id
      action(o,t,mode)
      r = new Buffer [NET.actionCode,msg[1],0,0,msg[2],msg[3]]
      r.writeUInt16LE o.id, 2
      NUU.bincast r.toString 'binary'
    client: (msg) =>
      mode = action.key[msg[1]]
      o = $obj.byId[id = msg.readUInt16LE 2]
      t = $obj.byId[id = msg.readUInt16LE 4]
      action(o,t,mode)
  write:
    client:(t,mode) =>
      msg = new Buffer [NET.actionCode,action.key.indexOf(mode),0,0]
      msg.writeUInt16LE t.id, 2
      NET.send msg.toString 'binary'
