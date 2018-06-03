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

$static '$voidState', S:0,update:$void,x:0,y:0,m:$v.zero,a:0,void:yes

$obj::_x = 0
$obj::_y = 0
$obj::_d = 0
$obj::_a = 0
$obj::_m = $v.zero
# $obj::_state = $voidState
$obj::update = $void

if isServer then $obj::applyControlFlags = (state)->
  # TODO: orbit modifiction (needs elliptical orbits)
  # return console.log '::st', 'applyControlFlags' 'relto' if @state.relto?
  # return @setState state if state
  return console.log '::st', 'locked', @name if @locked or @state.S is $orbit
  @update()
  @a = (
    if @state.S is $orbit then 0
    else if @boost then @thrust * Speed.boost
    else if @retro then @thrust * -.5
    else @thrust )
  ControlState = (
    if @state.S is $orbit then State.orbit
    else if @right or @left then State.maneuvering
    else if @accel or @retro or @boost then State.accelerating
    else if not ( @m[0] is @m[1] is 0 ) then State.moving
    else State.fixed )
  new ControlState @, x:@x, y:@y, x:@x, d:@d, a:@a, m:@m.slice()
  @

$obj::setState = (
  if isClient then (s) ->
    new byKey[s.S] @, s
  else (s)->
    @locked = false if @locked
    new byKey[s.S] @, s
    console.log '::st:set', s.S, @m if @name is 'Kestrel'
    @ )

if isServer then $public class State
  constructor: (@o,opts={}) ->
    @t = time = NUU.time()
    @o.update time if @o.update
    Object.assign @, opts
    @o.m = @m = @m || @o.m
    @o.a = @a = @a || @o.a
    @o.x = @x = @x || @o.x
    @o.y = @y = @y || @o.y
    @o.d = @d = @d || @o.d
    @o.m = @m.slice()
    @m   = @m.slice()
    @o.state  = @
    @o.update = @update.bind @
    if @relto? and ( @relto.id? or @relto = $obj.byId[@relto] )
      @relto.update time
    else @relto = null
    @toBuffer()
    do @translate if @translate
    @update time
    NET.state.write @
    # console.log '::st', 'w', @toJSON() if @o.name is 'Kestrel'

if isClient then $public class State
  constructor: (@o,opts={},fromBuffer) ->
    @o.state = @; @o.update = @update.bind @
    time = NUU.time()
    Object.assign @,  opts
    Object.assign @o, opts; @o.m = @m.slice()
    @relto.update time if @relto? and @relto = $obj.byId[@relto]
    @translate @ if @translate and fromBuffer
    @update time
    if isClient and 100 < ( @o.ttl - time )
      VEHICLE.update time
      debugger if 5 < abs VEHICLE.x - @o.x
    # console.log '::st', 'w', Object.keys @o.rr

State::S = $fixed
State::o = null
State::x = 0
State::y = 0
State::d = 0
State::m = $v.zero
State::a = 0
State::t = 0
State::relto = null
State::lastUpdate = 0
State::update = $void
State::translate = false

###
Object.debugPropNaN = (o,k)-> Object.defineProperty o,k,
  get: -> @['_'+k]
  set: (v)-> debugger if isNaN v; @['_'+k] = v

Object.debugPropNaN.v2 = (o,k)-> Object.defineProperty o,k,
  set: (v)-> debugger if isNaN v[0] or isNaN v[1]; @['_'+k] = v
  get: -> @['_'+k]

Object.debugPropNaN  $obj::, k for k in ['x','y','d']
Object.debugPropNaN State::, k for k in ['x','y','d']
Object.debugPropNaN.v2  $obj::, 'm'
Object.debugPropNaN.v2 State::, 'm'
Object.defineProperty $obj::, 'state', get:(->@_state), set:(v)->
  debugger if v.void; @_state = v
###

Object.defineProperty State::, 'p',
  get: -> return [ @x, @y ]
  set: (p) -> [ @x, @y ] = p

State::toBuffer = ->
  return @_buffer if @_buffer
  msg =  @_buffer = Buffer.alloc 90
  msg[0] = NET.stateCode
  msg.writeUInt16LE @o.id,          1
  msg[3] = @o.flags = NET.setFlags [@o.accel,@o.retro,@o.right,@o.left,@o.boost,0,0,1]
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ), 4
  msg.writeUInt16LE @S,           6
  # return console.log @ if @d < 0 or @d > 359 #if debug
  msg.writeUInt16LE ( @d = parseInt @d ), 8
  msg.writeDoubleLE ( @x = parseInt @x ), 10
  msg.writeDoubleLE ( @y = parseInt @y ), 26
  msg.writeDoubleLE @m[0],        42; @m[0] = msg.readDoubleLE 42
  msg.writeDoubleLE @m[1],        58; @m[1] = msg.readDoubleLE 58
  msg.writeFloatLE  @a || @a=0.0, 74; @a    = msg.readFloatLE  74
  msg.writeUInt32LE @t % 1000000, 82
  # console.log 'w'.red.inverse, @toJSON() if @o.name is 'Kestrel'
  return msg

State.fromBuffer = (msg)->
  return unless o = $obj.byId[id = msg.readUInt16LE 1]
  new State.byKey[msg[6]] o, (
    d: msg.readUInt16LE 8
    x: msg.readDoubleLE 10
    y: msg.readDoubleLE 26
    m: [ msg.readDoubleLE(42), msg.readDoubleLE(58) ]
    a: msg.readFloatLE 74
    t: NUU.timePrefix() + msg.readUInt32LE 82
    relto: msg.readUInt16LE 4 ), true
  o

State.toKey = toKey = []
State.byKey = byKey = []

State.register = (constructor) ->
  constructor::name = name = constructor.name
  constructor::S = ( toKey.push name ) - 1
  byKey.push @[name] = constructor
  constructor

State.register class State.fixed extends State
  t: 0
  constructor:(o,p)->
    p.m = [0,0]
    super
    o.x = @x
    o.y = @y
  toJSON: -> S:@S,x:@x,y:@y,d:@d
  update: ->

State.register class State.relative extends State
  update: (time)->
    time = NUU.time() unless time
    @relto.update time
    @o.x = @relto.x + @x
    @o.y = @relto.y + @y
    @o.m = @relto.m.slice()
    @lastUpdate = time; null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,t:@t,relto:@relto.id

State.register class State.moving extends State
  update: (time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    dt = ( time - @t ) * ITICK
    @o.x = @x + @m[0] * dt
    @o.y = @y + @m[1] * dt
    null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,t:@t,m:@m

State.register class State.accelerating extends State
  acceleration: true
  update: (time) ->
    #  tmaxX = ( Speed.max - @m[0] ) / @a * cos(@d/RAD)
    #  tmaxY = ( Speed.max - @m[1] ) / @a * sin(@d/RAD)
    # debugger
    @dir = @d / RAD
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    hdt = .5 * ( dt = ( time - @t ) * ITICK )
    adt = @a * dt
    @o.m[0] = @m[0] + cosadt = adt * cos @dir
    @o.m[1] = @m[1] + sinadt = adt * sin @dir
    @o.x = @x + @m[0] * dt + hdt * cosadt
    @o.y = @y + @m[1] * dt + hdt * sinadt
    null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,a:@a

State.register class State.maneuvering extends State
  constructor: (o)->
    @turn = o.turn || 1
    @turn = -@turn if o.left
    super
  update: (time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    dt = ( time - @t ) * ITICK
    @o.x = @x + @m[0] * dt
    @o.y = @y + @m[1] * dt
    @o.d = $v.umod360 @d + @turn * dt
    null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,a:@a

State.register class State.orbit extends State
  orbt: 0.0
  offs: 0.0
  angl: 0.0
  step: 0.0
  lstx: 0.0
  lsty: 0.0
  constructor:(o,s) ->
    return super unless s and s.step
    return unless s.relto? and ( s.relto.id? or relto = $obj.byId[s.relto] )
    console.log 'JSON-orbit', s if debug
    @o = o; @relto = relto; { @a, @t, @m, @orbt, @offs, @step } = s
    o.state = @; o.update = @update.bind @
    @d = parseInt s.d || o.d
    @a = 0 unless @a
    ticks = ( ( time = NUU.time() ) - @t ) / TICK
    @relto.update time if @relto
    @angl = ( TAU + @offs + ticks * @step ) % TAU
    @lstx = o.x = @relto.x + @orbt * cos @angl
    @lsty = o.y = @relto.y + @orbt * sin @angl
  toJSON: ->
    S:@S,d:@d,m:@m,t:@t,relto:@relto.id,orbt:@orbt,step:@step,dir:@angl,offs:@offs
  translate: ->
    return console.log '::st', 'orbit', 'set:no-relto' unless @relto
    # return console.log '::st', 'orbit', 'noop:no-need-to-translate' if @step? and @orbt?
    dx = @o.x - @relto.x
    dy = @o.y - @relto.y
    [ rx, ry ] = @relto.m
    [ mx, my ] = @o.m
    r = sqrt rx * rx + ry * ry
    t = sqrt mx * mx + my * my
    t = abs r - t
    @offs = ( TAU + -(PI/2) + atan2 dx, -dy ) % TAU
    @orbt = sqrt dx * dx + dy * dy
    @step  = TAU * ( t / @orbt )
    @lstx = @o.x = @relto.x + cos(@offs) * @orbt
    @lsty = @o.y = @relto.y + sin(@offs) * @orbt
    # console.log '::st', 'orbit', @o.id, @orbt, @offs, @step, @angl if @o.id is 20
  update: (time)->
    return console.log '::st', 'orbit', 'set:no-relto' unless @relto
    time = NUU.time() unless time; return null if @lastUpdate is time
    @relto.update time unless @relto.id is 0
    ticks = ( time - @t ) * ITICK
    @angl = ( TAU  + @offs + ticks * @step ) % TAU
    @o.x = @relto.x + @orbt * cos @angl
    @o.y = @relto.y + @orbt * sin @angl
    @o.m = m = [0,0]
    dt   = ( time - @lastUpdate ) * ITICK
    m[0] = ( @o.x - @lstx ) / dt; @lstx = @o.x
    m[1] = ( @o.y - @lsty ) / dt; @lsty = @o.y
    @lastUpdate = time; null

# State.orbit::translate.force = yes

State.register class State.travel extends State
  translate:(old,time)->
    return old unless @to
    old.update time
    unless @from
      @from = {}
      @from.x = o.x; @from.y = o.y; @from.m = o.m.slice()
      @pta = 60 # secs
  update: (time)->
    time = NUU.time() unless time; return null if @lastUpdate is time
    deltaT = ( time - @lastUpdate ) / TICK
    time_passed  = time - @from.t
    @to.state.update time
    @o.x = @from.x + time_passed * ( @from.x - @to.x )
    @o.y = @from.y + time_passed * ( @from.y - @to.y )
    @o.m = m = $v.zero.slice()
    m[0] = ( @o.x - @lstx ) / deltaT; @lstx = @o.x
    m[1] = ( @o.y - @ly ) / deltaT; @ly = @o.y
    @lastUpdate = time; null
  toJSON:-> S:@S, from:from.toJSON(), to:@to.id

###
setTimeout ( ->
  return
  try
    assert = require 'assert'
    states = [$fixed,$relative,$moving,$accelerating,$maneuvering,$orbit]
    NUU._time = NUU.time
    NUU.time = -> 2342
    mko = (opts={})-> Object.assign {a:2.2, turn:1.2}, opts
    mkst= (opts={})->
      s = x:10, y:11, m:[1,1], d:42
      s.t = NUU.time() if isClient
      Object.assign s, opts
    # Fixed state
    s = new State.fixed ( o = do mko ), mkst()
    test = "fixed:pre:x"; assert.equal o.x, 10
    test = "fixed:pre:y"; assert.equal o.y, 11
    test = "fixed:pre:d"; assert.equal o.d, 42
    test = "fixed:pre:m"; assert.deepEqual o.m, [0,0]
    s.update 2342 + TICK
    test = "move:tick:x"; assert.equal o.x, 10
    test = "move:tick:y"; assert.equal o.y, 11
    test = "move:tick:d"; assert.equal o.d, 42
    test = "move:tick:m"; assert.deepEqual o.m, [0,0]
    # Moving state
    s = new State.moving ( o = do mko ), mkst()
    test = "move:pre:x"; assert.equal o.x, 10
    test = "move:pre:y"; assert.equal o.y, 11
    test = "move:pre:d"; assert.equal o.d, 42
    test = "move:pre:m"; assert.deepEqual o.m, [1,1]
    s.update 2342 + TICK
    test = "move:tick:x"; assert.equal round(o.x), 11
    test = "move:tick:y"; assert.equal round(o.y), 12
    test = "move:tick:d"; assert.equal round(o.d), 42
    test = "move:tick:m"; assert.deepEqual o.m, [1,1]
    # Accelerating state
    s = new State.accelerating ( o = do mko ), mkst a:2.2
    test = "accel:plain:x"; assert.equal o.x, 10
    test = "accel:plain:y"; assert.equal o.y, 11
    test = "accel:plain:d"; assert.equal o.d, 42
    test = "accel:plain:m"; assert.deepEqual o.m, [1,1]
    s.update 2342 + TICK
    test = "accel:tick:x"; assert.equal true, o.x > 11
    test = "accel:tick:y"; assert.equal true, o.y > 12
    test = "accel:tick:d"; assert.equal o.d, 42
    test = "accel:tick:X"; assert.equal true, 2.63 < o.m[0] < 2.7
    test = "accel:tick:Y"; assert.equal true, 2.45 < o.m[1] < 2.5
    # Maneuvering state
    s = new State.maneuvering ( o = do mko ), mkst turn:1.1
    test = "turn:plain:x"; assert.equal o.x, 10
    test = "turn:plain:y"; assert.equal o.y, 11
    test = "turn:plain:d"; assert.equal o.d, 42
    test = "turn:plain:m"; assert.deepEqual o.m, [1,1]
    s.update 2342 + TICK
    test = "turn:tick:x"; assert.equal round(o.x),    11
    test = "turn:tick:y"; assert.equal round(o.y),    12
    test = "turn:tick:d"; assert.equal round(o.d*10), 431
    test = "turn:tick:m"; assert.deepEqual o.m, [1,1]
    # Orbit state
    suns = new State.fixed ( sun = mko id: 0 ), x:0, y:0
    s = new State.orbit ( o = do mko ), mkst relto: sun
    test = "orbt:plain:x"; assert.equal o.x, 10
    test = "orbt:plain:y"; assert.equal o.y, 11
    test = "orbt:plain:d"; assert.equal o.d, 42
    test = "orbt:plain:m"; assert.deepEqual o.m, [1,1]
    s.update 2342 + TICK
    test = "orbt:tick:x"; assert.equal round(o.x),    11
    test = "orbt:tick:y"; assert.equal round(o.y),    12
    test = "orbt:tick:d"; assert.equal round(o.d*10), 431
    test = "orbt:tick:m"; assert.deepEqual o.m, [1,1]
    NUU.time = NUU._time
  catch e
    console.log 'test', 'state', test, e.message
    console.log require('util').inspect s
    console.log require('util').inspect o
), 0
###
