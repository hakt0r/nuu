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

# ▄▄███▄▄· ██████  ██████       ██
# ██      ██    ██ ██   ██      ██
# ███████ ██    ██ ██████       ██
#      ██ ██    ██ ██   ██ ██   ██
# ███████  ██████  ██████   █████
#   ▀▀▀

$obj::update = $void
$obj::setState = (s)->
  new byKey[s.S] Object.assign s, o:@

if isServer then $obj::applyControlFlags = (state)->
  # TODO: orbit modifiction (elliptical orbits?)
  @update()
  @a = (
    if @state.S is $orbit then 0
    else if @boost then @throttle * @thrust * Speed.boost
    else if @retro then @throttle * @thrust * -.5
    else @throttle * @thrust )
  ControlState = (
    if @state.S is $orbit then State.orbit
    else if @right or @left then State.turn
    else if @accel or @retro or @boost then State.burn
    else State.moving )
  new ControlState o:@, a:@a
  return @

if isClient then NET.on 'state', (list)->
  new State.byKey[i.S] i for i in list
  return

# ███████ ████████  █████  ████████ ███████
# ██         ██    ██   ██    ██    ██
# ███████    ██    ███████    ██    █████
#      ██    ██    ██   ██    ██    ██
# ███████    ██    ██   ██    ██    ███████

if isClient then $public class State
  constructor:(opts) ->
    return if false is opts
    @update = @updateRelTo if opts.relto and @updateRelTo
    time = NUU.time()
    Object.assign @, opts
    @o = if @o.id? then @o else $obj.byId[@o]
    @o.locked = @lock?
    @o.state = @
    @o.update = @update.bind @
    @relto.update time if @relto?.id? or @relto = $obj.byId[@relto]
    do @cache if @cache
    @update time

if isServer then $public class State
  constructor:(opts) ->
    return if false is opts
    @o = if ( id = opts.o ).id? then id else $obj.byId[id]
    @o.locked = @lock?
    @t = time = NUU.time()
    @o.update time if @o.update
    if ( opts.relto?.id? or opts.relto = $obj.byId[opts.relto] )
      opts.relto.update time
    else @findRelTo opts
    opts.update = @updateRelTo if opts.relto and @updateRelTo
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
    do @translate if @translate
    @toBuffer()
    do @cache     if @cache
    @update time
    NET.state.write @

State::findRelTo = (opts) ->
  @o.update()
  if ( r = @o.state?.relto ) and r.bigMass
    if ( 10000 > d = $dist @o, r )
      opts.relto = r
      opts.relto.update @t
    else opts.relto = null
  else
    opts.relto = null
    dist = 10000
    for r in Stellar.list
      continue unless r.bigMass
      r.update @t
      continue if dist < d = $dist @o, r
      dist = d
      opts.relto = r
  return

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

State::clone = ->
  v = @toJSON()
  v.translate = no
  v

# ██████  ██    ██ ███████ ███████ ███████ ██████
# ██   ██ ██    ██ ██      ██      ██      ██   ██
# ██████  ██    ██ █████   █████   █████   ██████
# ██   ██ ██    ██ ██      ██      ██      ██   ██
# ██████   ██████  ██      ██      ███████ ██   ██

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
    relto: $obj.byId[msg.readUInt16LE 4]
  return o

# ███████ ██ ██   ██ ███████ ██████
# ██      ██  ██ ██  ██      ██   ██
# █████   ██   ███   █████   ██   ██
# ██      ██  ██ ██  ██      ██   ██
# ██      ██ ██   ██ ███████ ██████

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
    return if @lastUpdate is time
    @relto.update @lastUpdate = time || time = NUU.time()
    @o.x = @relto.x + @x
    @o.y = @relto.y + @y
    @o.m[0] = @relto.m[0]
    @o.m[1] = @relto.m[1]
    return
  translate:->
    @relto.update @t
    @x = @o.x - @relto.x
    @y = @o.y - @relto.y
    @o.m = @relto.m.slice()
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,relto:@relto.id

# ███    ███  ██████  ██    ██ ██ ███    ██  ██████
# ████  ████ ██    ██ ██    ██ ██ ████   ██ ██
# ██ ████ ██ ██    ██ ██    ██ ██ ██ ██  ██ ██   ███
# ██  ██  ██ ██    ██  ██  ██  ██ ██  ██ ██ ██    ██
# ██      ██  ██████    ████   ██ ██   ████  ██████

State.register class State.moving extends State
  update:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    dt = ( time - @t ) * TICKi
    @o.x = @x + @m[0] * dt
    @o.y = @y + @m[1] * dt
    return
  translate:->
    return unless @relto
    @relto.update @t
    @o.x    = @x    -= @relto.x
    @o.y    = @y    -= @relto.y
    @o.m[0] = @m[0] -= @relto.m[0]
    @o.m[1] = @m[1] -= @relto.m[1]
  updateRelTo:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    @relto.update time
    dt = ( time - @t ) * TICKi
    @o.x    = @relto.x + @x + @m[0] * dt
    @o.y    = @relto.y + @y + @m[1] * dt
    @o.m[0] = @relto.m[0]   + @m[0]
    @o.m[1] = @relto.m[1]   + @m[1]
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,t:@t,m:@m,relto:(@relto||id:0).id

# ██████  ██    ██ ██████  ███    ██
# ██   ██ ██    ██ ██   ██ ████   ██
# ██████  ██    ██ ██████  ██ ██  ██
# ██   ██ ██    ██ ██   ██ ██  ██ ██
# ██████   ██████  ██   ██ ██   ████

State.register class State.burn extends State
  acceleration: true
  cache:->
    if @a >= 0 then @dir = @d * RADi
    else
      @a = -@a
      @dir = ( @d + 180 ) % 360 * RADi
    @peak = r = Speed.max
    @cosd = cos @dir
    @sind = sin @dir
    $v.mult $v.normalize(@m), r*.99 if r < $v.mag @m # reset to speed limit
    a = @m.slice()
    b = $v.add @m.slice(), $v.mult [@cosd,@sind], r
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
    dtrise  = TICKi * min @dtmax, dtreal = time - @t; dtrise2 = dtrise*dtrise
    dtpeak  = TICKi * max 0,      dtreal - @dtmax
    dtreal *= TICKi
    @acceleration = dtpeak is 0
    @o.m[0] = mx = @m[0]        +    @cosd*@a*dtrise
    @o.m[1] = my = @m[1]        +    @sind*@a*dtrise
    @o.x    = @x + @m[0]*dtrise + .5*@cosd*@a*dtrise2 + dtpeak * mx
    @o.y    = @y + @m[1]*dtrise + .5*@sind*@a*dtrise2 + dtpeak * my
    return
  updateRelTo:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    @relto.update time
    dtrise  = TICKi * min @dtmax, dtreal = time - @t; dtrise2 = dtrise*dtrise
    dtpeak  = TICKi * max 0,      dtreal - @dtmax
    dtreal *= TICKi
    @acceleration = dtpeak is 0
    @o.m[0] = mx = @relto.m[0]   + @m[0]        +    @cosd*@a*dtrise
    @o.m[1] = my = @relto.m[1]   + @m[1]        +    @sind*@a*dtrise
    @o.x         = @relto.x + @x + @m[0]*dtrise + .5*@cosd*@a*dtrise2 + dtpeak * mx
    @o.y         = @relto.y + @y + @m[1]*dtrise + .5*@sind*@a*dtrise2 + dtpeak * my
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,a:@a,relto:(@relto||id:0).id

State.burn::translate = State.moving::translate if isServer

# ████████ ██    ██ ██████  ███    ██
#    ██    ██    ██ ██   ██ ████   ██
#    ██    ██    ██ ██████  ██ ██  ██
#    ██    ██    ██ ██   ██ ██  ██ ██
#    ██     ██████  ██   ██ ██   ████

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
    return
  updateRelTo:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    @relto.update time
    dt = ( time - @t ) * TICKi
    @o.x    = @relto.x + @x + @m[0] * dt
    @o.y    = @relto.y + @y + @m[1] * dt
    @o.m[0] = @relto.m[0]   + @m[0]
    @o.m[1] = @relto.m[1]   + @m[1]
    @o.d = $v.umod360 @d + @turn * dt
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,relto:(@relto||id:0).id

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
    return
  updateRelTo:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    @relto.update time
    dt  = ( time - @t  ) * TICKi
    tdt = ( time - @tt ) * TICKi
    @o.x    = @relto.x + @x + @m[0] * dt
    @o.y    = @relto.y + @y + @m[1] * dt
    @o.m[0] = @relto.m[0]   + @m[0]
    @o.m[1] = @relto.m[1]   + @m[1]
    @o.d = $v.umod360 360 + @d + @turn * min @turnTime, tdt
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,relto:(@relto||id:0).id

State.register class State.steer extends State
  constructor:(s)->
    s.turn   = ( s.o.turn || 1 ) / 10
    s.turn   = -s.turn if s.o.left
    super s
  cache:->
    @speed  = $v.mag @m || @o.m
    @radius = @speed / Math.tan @turn * RADi
    @di     = RADi * @d + PI/2
    @rcosdi = @radius * cos @di
    @rsindi = @radius * sin @di
  update:(time)->
    time = NUU.time() unless time; return null if @lastUpdate is time; @lastUpdate = time
    dt = ( time - @t ) * TICKi
    dr = RADi * @o.d = $v.umod360 @d + @turn * dt
    dp = RADi *        $v.umod360      @turn * dt
    @o.x = @x + ( @rcosdi ) - @radius * cos dp + @di
    @o.y = @y + ( @rsindi ) - @radius * sin dp + @di
    @o.m[0]   = @speed  * cos dr
    @o.m[1]   = @speed  * sin dr
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,relto:(@relto||id:0).id

State.turn::translate   = State.moving::translate if isServer
State.turnTo::translate = State.moving::translate if isServer

#  ██████  ██████  ██████  ██ ████████
# ██    ██ ██   ██ ██   ██ ██    ██
# ██    ██ ██████  ██████  ██    ██
# ██    ██ ██   ██ ██   ██ ██    ██
#  ██████  ██   ██ ██████  ██    ██

State.register class State.orbit extends State
  json: yes
  lock: yes
  constructor:(s) ->
    unless s.stp # cloning from JSON
      s.vel = s.off = s.stp = null
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
    @orb = @orb || round sqrt dx * dx + dy * dy
    @vel = v = max 1, min round(@orb/100), $v.mag relm
    @stp = TAU / (( TAU * @orb ) / v )
    @stp = -@stp if 0 > $v.cross(2) relm, [dx,dy]
    @off = ( TAU + -(PI/2) + atan2 dx, -dy ) % TAU
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
