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
    @update()
    @m = s.m = s.m || @m
    @a = s.a = s.a || @a
    @x = s.x = s.x || @x
    @y = s.y = s.y || @y
    @d = s.d = s.d || @d
    s.m = @m.slice()
    @m = @m.slice()
    new byKey[s.S] @, s
    console.log '::st:set', s.S, @m if @name is 'Kestrel'
    @ )

if isServer then $public class State
  constructor: (@o,opts={}) ->
    @t = time = NUU.time()
    @o.state = @; @o.update = @update.bind @
    Object.assign @, opts
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
    Object.assign @, opts
    @relto.update time if @relto? and @relto = $obj.byId[@relto]
    @translate @ if @translate and fromBuffer
    @update time
    # debugger if isClient and @o.name is "Kestrel"
    # console.log '::st', 'w', @toJSON()

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
  constructor:(o)->
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
  constructor:(o)->
    super
    o.m = @m.slice()
  update: (time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    deltaT = ( time - @t ) / TICK
    @o.x = @x + @m[0] * deltaT
    @o.y = @y + @m[1] * deltaT
    null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,t:@t,m:@m

State.register class State.accelerating extends State
    #constructor:->
    #  super
    #  tmaxX = ( Speed.max - @m[0] ) / @a * cos(@d/RAD)
    #  tmaxY = ( Speed.max - @m[1] ) / @a * sin(@d/RAD)
    #  console.log '!'.red.inverse, o.m
    #  console.log tmaxX, tmaxY
  acceleration: true
  update: (time) ->
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
    o.m = @m.slice()
  update: (time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    @o.x = @x + @m[0] *   ( deltaT = ( time - @t ) / TICK )
    @o.y = @y + @m[1] *     deltaT
    @o.d = ((( @d + @turn * deltaT ) % 360 ) + 360 ) % 360
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
