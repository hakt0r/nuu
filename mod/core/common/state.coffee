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

###

$obj::update = $void

if isClient then $public class State
  constructor:(opts) ->
    return if false is opts
    time = NUU.time()
    Object.assign @, opts
    @o = if @o.id? then @o else $obj.byId[@o]
    @o.locked = @lock?
    @o.state = @
    @o.update = @update.bind @
    @relto.update time if @relto? and @relto = $obj.byId[@relto]
    do @cache if @cache
    @update time
    # debugger if @S is $orbit and isClient and @stp is null

if isServer then $public class State
  constructor:(opts) ->
    return if false is opts
    @o = if ( id = opts.o ).id? then id else $obj.byId[id]
    @o.locked = @lock?
    @t = time = NUU.time()
    @o.update time if @o.update
    Object.assign @, opts
    @o.m = @m = @m || @o.m
    @o.x = @x = @x || @o.x
    @o.y = @y = @y || @o.y
    @o.d = @d = @d || @o.d
    @o.a = @a = @a || @o.thrust
    @o.m = @m.slice()
    @m   = @m.slice()
    @o.state  = @
    @o.update = @update.bind @
    if @relto? and ( @relto.id? or @relto = $obj.byId[@relto] )
      @relto.update time
    else @relto = null
    @toBuffer()
    do @translate if @translate
    do @cache     if @cache
    @update time
    NET.state.write @
    # console.log '::st', 'w', @toJSON() if @o.name is 'Kestrel'

State::S = $fixed
State::o = null
State::m = null
State::x = 0
State::y = 0
State::d = 0
State::a = 0
State::t = 0
State::relto = null
State::lastUpdate = 0
State::update = $void
State::translate = false
State::changeDir = ->

Object.defineProperty State::, 'p',
  get: -> return [ @x, @y ]
  set:(p) -> [ @x, @y ] = p

State.toKey = toKey = []
State.byKey = byKey = []
State.register = (constructor) ->
  constructor::name = name = constructor.name
  constructor::S = ( toKey.push name ) - 1
  byKey.push @[name] = constructor
  constructor

State.future = (state,time)->
  o = state.o
  state.update time
  result = p:[o.x,o.y], v:o.m.slice()
  do state.update # let's not confuse anyone
  return result





State::toBuffer = ->
  return @_buffer if @_buffer
  o = @o
  msg =  @_buffer = Buffer.allocUnsafe 90
  msg[0] = NET.stateCode
  msg.writeUInt16LE o.id, 1
  msg[3] = o.flags = NET.setFlags [o.accel,o.retro,o.right,o.left,o.boost,0,0,1]
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ), 4
  msg.writeUInt16LE @S, 6
  msg.writeUInt16LE ( @d = parseInt @d ), 8
  msg.writeDoubleLE ( @x = parseInt @x ), 10
  msg.writeDoubleLE ( @y = parseInt @y ), 26
  msg.writeDoubleLE @m[0],        42; @m[0] = msg.readDoubleLE 42
  msg.writeDoubleLE @m[1],        58; @m[1] = msg.readDoubleLE 58
  msg.writeFloatLE  @a || @a=0.0, 74; @a    = msg.readFloatLE  74
  msg.writeUInt32LE @t % 1000000, 82
  return msg

State.fromBuffer = (msg)->
  return unless o = $obj.byId[id = msg.readUInt16LE 1]
  [ o.accel, o.retro, o.right, o.left, o.boost ] = o.flags = NET.getFlags msg[3]
  new State.byKey[msg[6]]
    o: o
    d: msg.readUInt16LE 8
    x: msg.readDoubleLE 10
    y: msg.readDoubleLE 26
    m: [ msg.readDoubleLE(42), msg.readDoubleLE(58) ]
    a: msg.readFloatLE 74
    t: NUU.timePrefix() + msg.readUInt32LE 82
    relto: msg.readUInt16LE 4
  return o

if isClient then NET.on 'state', (list)->
  new State.byKey[i.S] i for i in list
  null

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
    else if @right or @left then State.turn
    else if @accel or @retro or @boost then State.burn
    else if not ( @m[0] is @m[1] is 0 ) then State.moving
    else State.fixed )
  new ControlState o:@, x:@x, y:@y, x:@x, d:@d, a:@a, m:@m.slice()
  @

$obj::setState = (
  if isClient then (s) ->
    s.o = @
    new byKey[s.S] s
  else (s)->
    @locked = false if @locked
    s.o = @
    new byKey[s.S] s
    @ )






State.register class State.fixed extends State
  constructor:(s)->
    s.m = $v.zero
    super s
    @o.x = @x
    @o.y = @y
  toJSON:-> S:@S,x:@x,y:@y,d:@d
  update: $void

State.register class State.fixedTo extends State
  lock: yes
  update:(time)->
    @relto.update time || time = NUU.time()
    @o.x = @relto.x + @x
    @o.y = @relto.y + @y
    @o.m = @relto.m.slice()
    @lastUpdate = time
    null
  toJSON:-> S:@S,x:@x,y:@y,d:@d,relto:@relto.id

State.register class State.moving extends State
  update:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    dt = ( time - @t ) * TICKi
    @o.x = @x + @m[0] * dt
    @o.y = @y + @m[1] * dt
    null
  toJSON:-> S:@S,x:@x,y:@y,d:@d,t:@t,m:@m


State.register class State.burn extends State
  acceleration: true
  cache:->
    @dir = @d / RAD
    @peak = r = Speed.max
    @cosd = cos @dir
    @sind = sin @dir
    $v.mult $v.normalize(@m), r*.99 if r < $v.mag @m # reset to speed limit
    a = @m.slice()
    b = $v.add @m.slice(), $v.mult [@cosd,@sind], r * 2.5
    d = $v.sub  b.slice(), a
    D = a[0]*b[1] - a[1]*b[0]
    dr = sqrt dr_squared = d[0]**2 + d[1]**2
    sqrt_discr = sqrt discr = r**2 * dr**2 - D**2
    sgn_dx = d[0] * if d[1] < 0 then -1 else 1
    sgn_dy = abs d[1]
    p = if @sind >= 0 then [
      (  D * d[1] + sgn_dx * sqrt_discr ) / dr_squared
      ( -D * d[0] + sgn_dy * sqrt_discr ) / dr_squared
    ] else [
      (  D * d[1] - sgn_dx * sqrt_discr ) / dr_squared
      ( -D * d[0] - sgn_dy * sqrt_discr ) / dr_squared ]
    @dtmax = TICK * $v.dist(p,@m) / @a
  update:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    dtrise = min @dtmax, dtreal = time - @t
    dtpeak = max 0,      dtreal - @dtmax
    dtreal *= TICKi
    dtrise *= TICKi
    dtpeak *= TICKi
    @acceleration = dtpeak is 0
    @o.m[0] = @m[0] + @cosd*@a*dtrise
    @o.m[1] = @m[1] + @sind*@a*dtrise
    @o.x = @x + @m[0]*dtreal + .5*dtrise*@cosd*@a*dtrise + @cosd*@peak*dtpeak
    @o.y = @y + @m[1]*dtreal + .5*dtrise*@sind*@a*dtrise + @sind*@peak*dtpeak
    null
  toJSON:-> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,a:@a

## updateUnlimited:(time)->
##   time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
##   hdt = .5 * ( dt = ( time - @t ) * TICKi )
##   adt = @a * dt
##   @o.m[0] = @m[0] + cosadt = adt * cos @dir
##   @o.m[1] = @m[1] + sinadt = adt * sin @dir
##   @o.x = @x + @m[0] * dt + hdt * cosadt
##   @o.y = @y + @m[1] * dt + hdt * sinadt

State.register class State.turn extends State
  constructor:(s)->
    s.turn = s.o.turn || 1
    s.turn = -s.turn if s.o.left
    super s
  update:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    dt = ( time - @t ) * TICKi
    @o.x = @x + @m[0] * dt
    @o.y = @y + @m[1] * dt
    @o.d = $v.umod360 @d + @turn * dt
    null
  toJSON:-> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t

State.register class State.turnTo extends State
  constructor:(s)->
    s.turn = s.o.turn || 1
    s.turnTime = s.tt = 0
    super s
  changeDir:(dir)->
    @update tt = NUU.time()
    @d = @o.d; @tt = tt
    ddiff = -180 + $v.umod360 -180 + dir - @d
    adiff = abs ddiff
    @turn = @o.turn || 1
    @turnTime = adiff / @turn
    @turn = -@turn if ddiff < 0
  update:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    dt  = ( time - @t  ) * TICKi
    tdt = ( time - @tt ) * TICKi
    @o.x = @x + @m[0] * dt
    @o.y = @y + @m[1] * dt
    @o.d = $v.umod360 360 + @d + @turn * min @turnTime, tdt
    null
  toJSON:-> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t

State.register class State.orbit extends State
  json: yes
  lock: yes
  constructor:(s) ->
    unless s.stp # cloning from JSON
      s.vel = s.orb = s.off = s.stp = null
      super s
    else
      super false
      Object.assign @, s
      @o = if @o.id? then @o else $obj.byId[@o]
      @relto = $obj.byId[@relto] if @relto? and not @relto.id?
      @o.state = @
      @o.locked = yes
      @o.update = @update.bind @
    s.a = s.a || s.o.a || 0
  translate:->
    return console.log '::st', 'orbit', 'set:no-relto' unless @relto
    dx = @o.x - @relto.x
    dy = @o.y - @relto.y
    relm = $v.sub @relto.m.slice(), @o.m
    @orb = round sqrt dx * dx + dy * dy
    @vel = v = max 1, min round(@orb/100), $v.mag relm
    @stp = TAU / (( TAU * @orb ) / v )
    @stp = -@stp if 0 > $v.cross(2) relm, [dx,dy]
    @off = ( TAU + -(PI/2) + atan2 dx, -dy ) % TAU
    # console.log '::st', 'orbit', @o.id, @orb, @off, @stp, @angl if @o.id is 20
  update:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time
    @relto.update time unless @relto.id is 0
    tick = ( time - @t ) * TICKi
    angl = ((( TAU + @off + tick * @stp ) % TAU ) + TAU ) % TAU
    @o.x = @relto.x + @orb * cos angl
    @o.y = @relto.y + @orb * sin angl
    angl += PI/2 if @stp > 0
    angl -= PI/2 if @stp < 0
    angl = (( angl % TAU ) + TAU ) % TAU
    @o.m = [ @relto.m[0] + (@vel * cos angl), @relto.m[1] + (@vel * sin angl) ]
    @o.d = angl * RAD
    @lastUpdate = time; null
  toJSON:->
    S:@S,o:@o.id,relto:@relto.id,t:@t,orb:@orb,stp:@stp,off:@off,vel:@vel

State.register class State.travel extends State
  translate:(old,time)->
    return old unless @to
    old.update time
    unless @from
      @from = {}
      @from.x = o.x; @from.y = o.y; @from.m = o.m.slice()
      @pta = 60 # secs
  update:(time)->
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





###  The mighty collection of Stae debug mocks and tests  ##

if isClient and @o is VEHICLE
@gfx = Sprite.debug || Sprite.layer 'debug', new PIXI.Graphics
@gfx.position.set 100, 100
@gfx.clear()
@gfx.width = @gfx.height = r * 3; h = r * 1.5
ox = h+@m[0]
oy = h+@m[1]
@gfx.lineStyle 1, 0xFFFFFF; @gfx.drawCircle h,h,r
@gfx.lineStyle 1, 0xFF00FF; @gfx.moveTo h,  h;  @gfx.lineTo ox,     oy
@gfx.lineStyle 1, 0x00FF00; @gfx.moveTo ox, oy; @gfx.lineTo ox+d[0],oy+d[1]
@gfx.lineStyle 1, 0xFF0000; @gfx.moveTo ox, oy; @gfx.lineTo h+p[0], h+p[1]
@gfx.lineStyle 1, 0xFF0000; @gfx.drawCircle h+p[0],h+p[1],3
console.log 'this can\'t be happening!', dist1, p, @m

Object.defineProperty $obj::, 'm', get:( -> @_m ), set:(v)->
  debugger if v[1] is -1206
  if @id is 0
    console.log 'proxy m for', @name, v
    v = new Proxy(v,
      apply:(target, thisArg, argumentsList) ->
        thisArg[target].apply this, argumentList
      deleteProperty:(target, property) ->
        console.log 'Deleted %s', property
        true
      set:(target, property, value, receiver) ->
        debugger if value is -1206
        target[property] = value
        console.rlog 'Set %s to %o', property, value
        true )
  @_m = v

Object.debugPropNaN = (o,k)-> Object.defineProperty o,k,
  get: -> @['_'+k]
  set:(v)-> debugger if isNaN v; @['_'+k] = v

Object.debugPropNaN.v2 = (o,k)-> Object.defineProperty o,k,
  set:(v)-> debugger if isNaN v[0] or isNaN v[1]; @['_'+k] = v
  get: -> @['_'+k]

Object.debugPropNaN  $obj::, k for k in ['x','y','d']
Object.debugPropNaN State::, k for k in ['x','y','d']
Object.debugPropNaN.v2  $obj::, 'm'
Object.debugPropNaN.v2 State::, 'm'
Object.defineProperty $obj::, 'state', get:(->@_state), set:(v)->
  debugger if v.void; @_state = v

setTimeout ( ->
  return
  try
    assert = require 'assert'
    states = [$fixed,$fixedTo,$moving,$burn,$turn,$orbit]
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
    # burn state
    s = new State.burn ( o = do mko ), mkst a:2.2
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
    # turn state
    s = new State.turn ( o = do mko ), mkst turn:1.1
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
