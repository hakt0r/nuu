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

$static '$voidState', S:0,update:$void,x:0,y:0,m:$v.zero,a:0

$obj::x = 0
$obj::y = 0
$obj::d = 0
$obj::a = 0
$obj::m = $v.zero
$obj::state = $voidState
$obj::update = $void

if isServer then $obj::changeState = (state)->
  # TODO: orbit modifiction (needs elliptical orbits)
  # return console.log 'relto' if @state.relto?
  # return @setState state if state
  return console.log 'locked$', @name if @locked or @state.S is $orbit
  @state.update true
  @a = (
    if @state.S is $orbit then 0
    else if @boost then @thrust * Speed.boost
    else if @retro then @thrust * -.5
    else @thrust )
  state = (
    if @state.S is $orbit then State.orbit
    else if @right or @left then State.maneuvering
    else if @accel or @retro or @boost then State.accelerating
    else if not ( @m[0] is @m[1] is 0 ) then State.moving
    else State.fixed )
  # console.log ' changeState '.white.inverse, @name, @state.name, '>', state.name if @name is 'Kestrel'
  new state @, @x, @y, @d, @m, @a, @t, @relto
  @

$obj::setState = (s) ->
  @locked = false if @locked
  new toConstructor[s.S] @, s.x, s.y, s.d, s.m, s.a, s.t, s.relto
  @

$public class State
  S: $fixed
  o: null
  x: 0
  y: 0
  d: 0
  m: $v.zero
  a: 0
  t: 0
  relto: null
  update: $void
  lastUpdate: 0
  convert: false
  constructor: (o,x,y,d,m,a,t,relto) ->
    ostate = o.state; @o = o; @o.state = @
    o.update = @update.bind @
    @x = parseInt x || o.x
    @y = parseInt y || o.y
    @d = parseInt d || o.d
    @m = ( m || o.m ).slice()
    @a = a || o.a
    @t = t || TIME
    @relto = $obj.byId[0]
    @relto = relto  if relto? and ( relto.id? or relto = $obj.byId[relto] )
    @relto.update() if @relto
    @toBuffer()     if isServer
    @convert ostate if @convert
    @update null
    # console.log 'state$', @S, @o.id
    return if isClient
    NET.state.write @o

Object.defineProperty State::, 'p',
  get: -> return [ @x, @y ]
  set: (p) -> [ @x, @y ] = p

State::toBuffer = ->
  return @_buffer if @_buffer
  msg =  @_buffer = Buffer.alloc 90
  msg[0] = NET.stateCode
  msg.writeUInt16LE @o.id,          1
  msg[3] = @o.flags = NET.setFlags [@o.accel,@o.retro,@o.right,@o.left,@o.boost,@relto?,0,1]
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ), 4
  msg.writeUInt16LE @S,           6
  # return console.log @ if @d < 0 or @d > 359 #if debug
  msg.writeUInt16LE @d,           8
  msg.writeDoubleLE @x,           10
  msg.writeDoubleLE @y,           26
  msg.writeDoubleLE @m[0],        42
  msg.writeDoubleLE @m[1],        58
  msg.writeFloatLE  @a || @a=0.0, 74; @a = msg.readFloatLE 74
  msg.writeUInt32LE @t % 1000000, 82
  return msg

State.fromBuffer = (msg)->
  id = msg.readUInt16LE 1
  return unless o = $obj.byId[id]
  [ o.accel, o.retro, o.right, o.left, o.boost ] = flags = NET.getFlags msg[3]
  relto = msg.readUInt16LE 4 if flags[5]
  state = State.toConstructor[msg[6]]
  d = msg.readUInt16LE 8
  x = msg.readDoubleLE 10
  y = msg.readDoubleLE 26
  m = [ msg.readDoubleLE(42), msg.readDoubleLE(58) ]
  a = msg.readFloatLE 74
  t = ETIME + msg.readUInt32LE 82
  new state o,x,y,d,m,a,t,relto
  o

State.toKey = toKey = []
State.toConstructor = toConstructor = []

State.register = (name,value) ->
  value::name = name
  value::S = ( toKey.push name ) - 1
  toConstructor.push @[name] = value
  value

State.register 'fixed', class fixed extends State
  convert: -> @o.m = $v.zero
  toJSON: -> S:@S,x:@x,y:@y,d:@d

State.register 'relative', class relative extends State
  constructor: State
  update: (time)->
    if not time and @lastUpdate is TIME then return null else time = TIME
    @relto.update()
    @o.x = @relto.x + @x
    @o.y = @relto.y + @y
    @o.m = @relto.m.slice()
    @lastUpdate = TIME; null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,t:@t,relto:@relto.id

State.register 'moving', class moving extends State
  convert: -> @o.m = @m.slice()
  update: (time)->
    if not time and @lastUpdate is TIME then return null else time = TIME
    deltaT = ( time - @t ) / TICK
    @o.x = @x + @m[0] * deltaT
    @o.y = @y + @m[1] * deltaT
    @lastUpdate = TIME; null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,t:@t,m:@m

State.register 'accelerating', class accelerating extends State
  acceleration: true
  curm: null
  convert: ->
    @o.m = @curm = @m.slice() || []
    @dir = @d / RAD
    # tmaxX = ( Speed.max - @m[0] ) / @a * cos(@d/RAD)
    # tmaxY = ( Speed.max - @m[1] ) / @a * sin(@d/RAD)
    # console.log tmaxX, tmaxY
  update: (time) ->
    if not time and @lastUpdate is TIME then return null else time = TIME
    deltaTb2 = .5 * ( deltaT = ( time - @t ) / TICK )
    aDeltaT = @a * deltaT
    @curm[0] = @m[0] + cosaDeltaT = aDeltaT * cos @dir
    @curm[1] = @m[1] + sinaDeltaT = aDeltaT * sin @dir
    @o.x = @x + @m[0] * deltaT + deltaTb2 * cosaDeltaT
    @o.y = @y + @m[1] * deltaT + deltaTb2 * sinaDeltaT
    @lastUpdate = TIME; null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,a:@a

State.register 'maneuvering', class maneuvering extends State
  convert: ->
    @o.m = @m.slice()
    @turn = @o.turn || 1
    @turn = -@turn if @o.left
  update: (time)->
    if not time and @lastUpdate is TIME then return null else time = TIME
    @o.x = @x + @m[0] *   ( deltaT = ( time - @t ) / TICK )
    @o.y = @y + @m[1] *     deltaT
    @o.d = ((( @d + @turn * deltaT ) % 360 ) + 360 ) % 360
    @lastUpdate = TIME; null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,a:@a

State.register 'orbit', class orbit extends State
  offs: 0.0
  dir:  0.0
  step: 0.0
  lx:   0
  ly:   0
  tmp:  null
  convert: (o)->
    return console.log 'set:no_relto' unless @relto
    dx = @x - @relto.x
    dy = @y - @relto.y
    @offs = ( TAU + -(PI/2) + atan2 dx, -dy ) % TAU
    @orbit = sqrt dx * dx + dy * dy
    [ rx, ry ] = @relto.m
    [ mx, my ] = @m
    r = sqrt rx * rx + ry * ry
    t = sqrt mx * mx + my * my
    t = abs r - t
    @step  = TAU * ( t / @orbit )
    @lx = @o.x = @relto.x + cos(@offs) * @orbit
    @ly = @o.y = @relto.y + sin(@offs) * @orbit
    # console.log '$orbit', @o.id, @orbit, @offs, @step, @dir if @o.id is 20
  update: (time)->
    return console.log 'update:no_relto' unless @relto
    if not time and @lastUpdate is TIME then return null else time = TIME
    deltaT = ( time - @lastUpdate ) / TICK
    @relto.update()
    ticks  = ( time - @t ) / TICK
    @dir = ( TAU + @offs + ticks * @step ) % TAU
    @o.x = @relto.x + cos(@dir) * @orbit
    @o.y = @relto.y + sin(@dir) * @orbit
    @tmp = $v.zero.slice()
    @tmp[0] = ( @o.x - @lx ) / deltaT
    @tmp[1] = ( @o.y - @ly ) / deltaT
    @o.m = @tmp.slice()
    @lx = @o.x
    @ly = @o.y
    @lastUpdate = TIME; null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,relto:@relto.id

State.register 'travel', class travel extends State
  convert:(old)->
    return old unless @to
    old.update()
    unless @from
      @from = {}
      @from.x = o.x; @from.y = o.y; @from.m = o.m.slice()
      @pta = 60 # secs
  update: (time)->
    unless time
      if @lastUpdate is TIME then return null else time = TIME
      deltaT = ( time - @lastUpdate ) / TICK
      time_passed  = time - @from.t
      @lastUpdate = time
    @to.state.update()
    @o.x = @from.x + time_passed * ( @from.x - @to.x )
    @o.y = @from.y + time_passed * ( @from.y - @to.y )
    @o.m = m = $v.zero.slice()
    m[0] = ( @o.x - @lx ) / deltaT; @lx = @o.x
    m[1] = ( @o.y - @ly ) / deltaT; @ly = @o.y
    @lastUpdate = TIME; null
  toJSON:-> S:@S, from:from.toJSON(), to:@to.id
