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

# TODO: orbit modifiction (elliptical orbits?)

# ██ ███    ██ ████████ ███████  ██████  ██████   █████  ████████ ██  ██████  ███    ██
# ██ ████   ██    ██    ██      ██       ██   ██ ██   ██    ██    ██ ██    ██ ████   ██
# ██ ██ ██  ██    ██    █████   ██   ███ ██████  ███████    ██    ██ ██    ██ ██ ██  ██
# ██ ██  ██ ██    ██    ██      ██    ██ ██   ██ ██   ██    ██    ██ ██    ██ ██  ██ ██
# ██ ██   ████    ██    ███████  ██████  ██   ██ ██   ██    ██    ██  ██████  ██   ████

$obj::update = $void

$obj::setState = (s)->
  new byKey[s.S] Object.assign s, o:@

if isServer then $obj::applyControlFlags = (state)->
  @update()
  ControlState = (
    if   @state.S is $orbit            then State.orbit
    else if @right or @left            then State.turn
    else if @accel or @boost or @retro then State.burn
    else                                    State.moving )
  new ControlState o:@, a:@a = if @state.S is $orbit then 0 else @a
  return @

if isClient then NET.on 'state', (list)->
  new State.byKey[i.S] i for i in list
  return

#  ██████ ██      ██ ███████ ███    ██ ████████
# ██      ██      ██ ██      ████   ██    ██
# ██      ██      ██ █████   ██ ██  ██    ██
# ██      ██      ██ ██      ██  ██ ██    ██
#  ██████ ███████ ██ ███████ ██   ████    ██

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
    # console.log @o.name, State.toKey[@S], @p, @v

# ███████ ███████ ██████  ██    ██ ███████ ██████
# ██      ██      ██   ██ ██    ██ ██      ██   ██
# ███████ █████   ██████  ██    ██ █████   ██████
#      ██ ██      ██   ██  ██  ██  ██      ██   ██
# ███████ ███████ ██   ██   ████   ███████ ██   ██

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
    @o.v = @v = @v || @o.v
    @o.x = @x = @x || @o.x
    @o.y = @y = @y || @o.y
    @o.d = @d = @d || @o.d
    @o.a = @a = @a || @o.thrust
    @o.v = @v.slice()
    @v   = @v.slice()
    @o.state  = @
    @o.update = @update.bind @
    do @translate if @translate
    do @cache     if @cache
    @toBuffer()
    @update time
    NET.state.write @
    # console.log @o.name, State.toKey[@S], @p, @v # if @o.name is "Exosuit"

# ███    ███ ███████ ███    ███ ██████  ███████ ██████
# ████  ████ ██      ████  ████ ██   ██ ██      ██   ██
# ██ ████ ██ █████   ██ ████ ██ ██████  █████   ██████
# ██  ██  ██ ██      ██  ██  ██ ██   ██ ██      ██   ██
# ██      ██ ███████ ██      ██ ██████  ███████ ██   ██

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

State::clone = ->
  v = @toJSON()
  v.translate = no
  v

# ███████ ████████  █████  ████████ ██  ██████
# ██         ██    ██   ██    ██    ██ ██
# ███████    ██    ███████    ██    ██ ██
#      ██    ██    ██   ██    ██    ██ ██
# ███████    ██    ██   ██    ██    ██  ██████

State.controls = ["idle","accel","retro","boost","right","left"]
State.toKey = toKey = []
State.byKey = byKey = []

State.register = (constructor) ->
  constructor::name = name = constructor.name
  constructor::S = ( toKey.push name ) - 1
  byKey.push @[name] = constructor
  constructor

State.future = (state,time,now=NUU.time())->
  o = state.o
  state.update time
  result = p:[o.x,o.y], v:o.v.slice()
  state.update now # let's not confuse anyone
  return result

State.fromBuffer = (msg)->
  return unless s = State.byKey[msg[1]]
  return unless o = $obj.byId[msg.readUInt16LE 2]
  s.fromBuffer o, msg
  return o

# ███████ ██ ██   ██ ███████ ██████
# ██      ██  ██ ██  ██      ██   ██
# █████   ██   ███   █████   ██   ██
# ██      ██  ██ ██  ██      ██   ██
# ██      ██ ██   ██ ███████ ██████

State.register class State.fixed extends State
  constructor:(s)->
    s.v = $v.zero
    super s
    @o.x = @x
    @o.y = @y
  toJSON:-> S:@S,x:@x,y:@y,d:@d
  update: $void

State.fixed::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 47; o = @o
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id, 2
  msg.writeUInt16LE ( @d = parseInt @d ), 4
  msg.writeDoubleLE ( @x = parseInt @x ), 6
  msg.writeDoubleLE ( @y = parseInt @y ), 22
  msg.writeUInt32LE ( @t % 1000000     ), 38
  return @_buffer = msg.toString 'binary'

State.fixed.fromBuffer = (o,msg)-> new State.fixed {
  o: o
  d: msg.readUInt16LE 4
  x: msg.readDoubleLE 5
  y: msg.readDoubleLE 22
  t: NUU.timePrefix() + msg.readUInt32LE 38 }

# ███████ ██ ██   ██ ███████ ██████  ████████  ██████
# ██      ██  ██ ██  ██      ██   ██    ██    ██    ██
# █████   ██   ███   █████   ██   ██    ██    ██    ██
# ██      ██  ██ ██  ██      ██   ██    ██    ██    ██
# ██      ██ ██   ██ ███████ ██████     ██     ██████

State.register class State.fixedTo extends State
  lock: yes
  update:(time)->
    return if @lastUpdate is time
    @relto.update @lastUpdate = time || time = NUU.time()
    @o.x = @relto.x + @x
    @o.y = @relto.y + @y
    @o.v[0] = @relto.v[0]
    @o.v[1] = @relto.v[1]
    return
  translate:->
    @relto.update @t
    @x = @o.x - @relto.x
    @y = @o.y - @relto.y
    @o.v = @relto.v.slice()
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,relto:@relto.id

State.fixedTo::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 49; o = @o
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id,                                2
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ), 4
  msg.writeUInt16LE ( @d = parseInt @d ),                6
  msg.writeDoubleLE ( @x = parseInt @x ),                8
  msg.writeDoubleLE ( @y = parseInt @y ),                24
  msg.writeUInt32LE ( @t % 1000000     ),                40
  return @_buffer = msg.toString 'binary'

State.fixedTo.fromBuffer = (o,msg)-> new State.fixedTo {
  o: o
  relto: $obj.byId[msg.readUInt16LE 4]
  d: msg.readUInt16LE 6
  x: msg.readDoubleLE 8
  y: msg.readDoubleLE 24
  t: NUU.timePrefix() + msg.readUInt32LE 40 }

# ███    ███  ██████  ██    ██ ██ ███    ██  ██████
# ████  ████ ██    ██ ██    ██ ██ ████   ██ ██
# ██ ████ ██ ██    ██ ██    ██ ██ ██ ██  ██ ██   ███
# ██  ██  ██ ██    ██  ██  ██  ██ ██  ██ ██ ██    ██
# ██      ██  ██████    ████   ██ ██   ████  ██████

State.register class State.moving extends State
  update:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    dt = time - @t
    @o.x = @x + @v[0] * dt
    @o.y = @y + @v[1] * dt
    return
  translate:->
    return unless @relto
    @relto.update @t
    @o.x    = @x    -= @relto.x
    @o.y    = @y    -= @relto.y
    @o.v[0] = @v[0] -= @relto.v[0]
    @o.v[1] = @v[1] -= @relto.v[1]
  updateRelTo:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    @relto.update time
    dt = time - @t
    @o.x    = @relto.x + @x + @v[0] * dt
    @o.y    = @relto.y + @y + @v[1] * dt
    @o.v[0] = @relto.v[0]   + @v[0]
    @o.v[1] = @relto.v[1]   + @v[1]
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,t:@t,v:@v,relto:(@relto||id:0).id

State.moving::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 81; o = @o
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id,                                2
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ), 4
  msg.writeUInt16LE ( @d = parseInt @d ),                6
  msg.writeDoubleLE ( @x = parseInt @x ),                8
  msg.writeDoubleLE ( @y = parseInt @y ),                24
  msg.writeUInt32LE ( @t % 1000000     ),                40
  msg.writeDoubleLE @v[0], 48;  @v[0] = msg.readDoubleLE 48
  msg.writeDoubleLE @v[1], 64;  @v[1] = msg.readDoubleLE 64
  return @_buffer = msg.toString 'binary'

State.moving.fromBuffer = (o,msg)-> new State.moving {
  o: o
  relto:    $obj.byId[  msg.readUInt16LE 4 ]
  d:                    msg.readUInt16LE 6
  x:                    msg.readDoubleLE 8
  y:                    msg.readDoubleLE 24
  t: NUU.timePrefix() + msg.readUInt32LE 40
  v: [                  msg.readDoubleLE 48
                        msg.readDoubleLE 64 ] }

# ██████  ██    ██ ██████  ███    ██
# ██   ██ ██    ██ ██   ██ ████   ██
# ██████  ██    ██ ██████  ██ ██  ██
# ██   ██ ██    ██ ██   ██ ██  ██ ██
# ██████   ██████  ██   ██ ██   ████

State.register class State.burn extends State
  acceleration: true
  cache:->
    if @a >= 0
         @acc =  @a; @dir = @d * RADi
    else @acc = -@a; @dir = ( @d + 180 ) % 360 * RADi
    @peak = r = Speed.max
    @cosd = cos @dir
    @sind = sin @dir
    $v.mult $v.normalize(@v), r*.99 if r < $v.mag @v # reset to speed limit
    a = @v.slice()
    b = $v.add @v.slice(), $v.mult [@cosd,@sind], r
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
    @dtmax = $v.dist(p,@v) / @acc
  update:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    dtrise  = min @dtmax, dtreal = time - @t; dtrise2 = dtrise*dtrise
    dtpeak  = max 0,      dtreal - @dtmax
    @acceleration = dtpeak is 0
    @o.v[0] = vx = @v[0]        +    @cosd*@acc*dtrise
    @o.v[1] = vy = @v[1]        +    @sind*@acc*dtrise
    @o.x    = @x + @v[0]*dtrise + .5*@cosd*@acc*dtrise2 + dtpeak * vx
    @o.y    = @y + @v[1]*dtrise + .5*@sind*@acc*dtrise2 + dtpeak * vy
    return
  updateRelTo:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    @relto.update time
    dtrise  = min @dtmax, dtreal = time - @t; dtrise2 = dtrise*dtrise
    dtpeak  = max 0,      dtreal - @dtmax
    @acccceleration = dtpeak is 0
    @o.v[0] = vx = @relto.v[0]   + @v[0]        +    @cosd*@acc*dtrise
    @o.v[1] = vy = @relto.v[1]   + @v[1]        +    @sind*@acc*dtrise
    @o.x         = @relto.x + @x + @v[0]*dtrise + .5*@cosd*@acc*dtrise2 + dtpeak * vx
    @o.y         = @relto.y + @y + @v[1]*dtrise + .5*@sind*@acc*dtrise2 + dtpeak * vy
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,v:@v,t:@t,a:@a,relto:(@relto||id:0).id

State.burn::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 85; o = @o
  o.burn = yes; o.left = o.right = undefined
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id,                                          2
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ),           4
  msg.writeUInt16LE ( @d = parseInt @d ),                          6
  msg.writeDoubleLE ( @x = parseInt @x ),                          8
  msg.writeDoubleLE ( @y = parseInt @y ),                          24
  msg.writeUInt32LE ( @t % 1000000     ),                          40
  msg.writeDoubleLE   @v[0],          48; @v[0] = msg.readDoubleLE 48
  msg.writeDoubleLE   @v[1],          64; @v[1] = msg.readDoubleLE 64
  msg.writeFloatLE  ( @a || @a=0.0 ), 80; @a    = msg.readFloatLE  80
  return @_buffer = msg.toString 'binary'

State.burn.fromBuffer = (o,msg)->
  o.burn = yes; o.left = o.right = undefined
  new State.burn {
    o: o
    relto:    $obj.byId[  msg.readUInt16LE 4 ]
    d:                    msg.readUInt16LE 6
    x:                    msg.readDoubleLE 8
    y:                    msg.readDoubleLE 24
    t: NUU.timePrefix() + msg.readUInt32LE 40
    v: [                  msg.readDoubleLE 48
                          msg.readDoubleLE 64 ]
    a:                    msg.readFloatLE  80 }

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
  update:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    dt = time - @t
    @o.x = @x + @v[0] * dt
    @o.y = @y + @v[1] * dt
    @o.d = $v.umod360 @d + @turn * dt
    return
  updateRelTo:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    @relto.update time
    dt = time - @t
    @o.x    = @relto.x + @x + @v[0] * dt
    @o.y    = @relto.y + @y + @v[1] * dt
    @o.v[0] = @relto.v[0]   + @v[0]
    @o.v[1] = @relto.v[1]   + @v[1]
    @o.d = $v.umod360 @d + @turn * dt
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,v:@v,t:@t,relto:(@relto||id:0).id

State.turn::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 81; o = @o
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id,                                      2
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ),       4
  msg.writeUInt16LE ( @d = parseInt @d ),                      6
  msg.writeDoubleLE ( @x = parseInt @x ),                      8
  msg.writeDoubleLE ( @y = parseInt @y ),                      24
  msg.writeUInt32LE ( @t % 1000000     ),                      40
  msg.writeDoubleLE @v[0],        48; @v[0] = msg.readDoubleLE 48
  msg.writeDoubleLE @v[1],        64; @v[1] = msg.readDoubleLE 64
  msg[80] = o.flags = NET.setFlags [0,0,o.right,o.left,0,0,0,0]
  return @_buffer = msg.toString 'binary'

State.turn.fromBuffer = (o,msg)->
  [ o.accel, o.retro, o.right, o.left ] = o.flags = NET.getFlags msg[80]
  new State.turn
    o: o
    relto:    $obj.byId[  msg.readUInt16LE 4 ]
    d:                    msg.readUInt16LE 6
    x:                    msg.readDoubleLE 8
    y:                    msg.readDoubleLE 24
    t: NUU.timePrefix() + msg.readUInt32LE 40
    v: [                  msg.readDoubleLE 48
                          msg.readDoubleLE 64 ]

State.turn::translate = State.moving::translate if isServer

# ████████ ██    ██ ██████  ███    ██ ████████  ██████
#    ██    ██    ██ ██   ██ ████   ██    ██    ██    ██
#    ██    ██    ██ ██████  ██ ██  ██    ██    ██    ██
#    ██    ██    ██ ██   ██ ██  ██ ██    ██    ██    ██
#    ██     ██████  ██   ██ ██   ████    ██     ██████

State.register class State.turnTo extends State
  changeDir:(dir)->
    @update tt = NUU.time()
    @tt = tt
    @D = dir
    do @cache
    return unless isServer
    @_buffer = null; @toBuffer()
  cache:->
    @tt = @tt || @t
    @d = @o.d
    adiff = abs ddiff = (@D-@d+540)%360-180
    return @turn = @turnTime = 0 if adiff is 0
    @turn = @o.turn || 1
    @turnTime = adiff / @turn
    @turn = -@turn if 0 > ddiff
  update:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    dt  = time - @t
    tdt = time - @tt
    @o.x = @x + @v[0] * dt
    @o.y = @y + @v[1] * dt
    @o.d = $v.umod360 360 + @d + @turn * min @turnTime, tdt
    return
  updateRelTo:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    @relto.update time
    dt  = time - @t
    tdt = time - @tt
    @o.x    = @relto.x + @x + @v[0] * dt
    @o.y    = @relto.y + @y + @v[1] * dt
    @o.v[0] = @relto.v[0]   + @v[0]
    @o.v[1] = @relto.v[1]   + @v[1]
    @o.d = $v.umod360 360 + @d + @turn * min @turnTime, tdt
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,D:@D,v:@v,t:@t,relto:(@relto||id:0).id

State.turnTo::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 93; o = @o
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id,                                      2
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ),       4
  msg.writeUInt16LE ( @d = parseInt @d ),                      6
  msg.writeDoubleLE ( @x = parseInt @x ),                      8
  msg.writeDoubleLE ( @y = parseInt @y ),                      24
  msg.writeUInt32LE ( @t  % 1000000    ),                      40
  msg.writeUInt32LE ( @tt % 1000000    ),                      48
  msg.writeDoubleLE @v[0],        64; @v[0] = msg.readDoubleLE 64
  msg.writeDoubleLE @v[1],        80; @v[1] = msg.readDoubleLE 80
  msg.writeUInt16LE ( @D = parseInt @D ),                      88
  return @_buffer = msg.toString 'binary'

State.turnTo.fromBuffer = (o,msg)->
  new State.turnTo
    o: o
    relto:     $obj.byId[  msg.readUInt16LE 4 ]
    d:                     msg.readUInt16LE 6
    x:                     msg.readDoubleLE 8
    y:                     msg.readDoubleLE 24
    t:  NUU.timePrefix() + msg.readUInt32LE 40
    tt: NUU.timePrefix() + msg.readUInt32LE 48
    v:  [                  msg.readDoubleLE 64
                           msg.readDoubleLE 80 ]
    D:                     msg.readUInt16LE 88

State.turnTo::translate = State.moving::translate if isServer

# ███████ ████████ ███████ ███████ ██████
# ██         ██    ██      ██      ██   ██
# ███████    ██    █████   █████   ██████
#      ██    ██    ██      ██      ██   ██
# ███████    ██    ███████ ███████ ██   ██

State.register class State.steer extends State
  constructor:(s)->
    s.turn   = ( s.o.turn || 1 ) / 10
    s.turn   = -s.turn if s.o.left
    super s
  cache:->
    @speed  = $v.mag @v || @o.v
    @radius = @speed / Math.tan @turn * RADi
    @di     = RADi * @d + PI/2
    @rcosdi = @radius * cos @di
    @rsindi = @radius * sin @di
  update:(time=NUU.time())->
    return if @lastUpdate is time; @lastUpdate = time
    dt = time - @t
    dr = RADi * @o.d = $v.umod360 @d + @turn * dt
    dp = RADi *        $v.umod360      @turn * dt
    @o.x = @x + ( @rcosdi ) - @radius * cos dp + @di
    @o.y = @y + ( @rsindi ) - @radius * sin dp + @di
    @o.v[0]   = @speed  * cos dr
    @o.v[1]   = @speed  * sin dr
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,v:@v,t:@t,relto:(@relto||id:0).id

State.steer::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 81; o = @o
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id,                                      2
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ),       4
  msg.writeUInt16LE ( @d = parseInt @d ),                      6
  msg.writeDoubleLE ( @x = parseInt @x ),                      8
  msg.writeDoubleLE ( @y = parseInt @y ),                      24
  msg.writeUInt32LE ( @t % 1000000     ),                      40
  msg.writeDoubleLE @v[0],        48; @v[0] = msg.readDoubleLE 48
  msg.writeDoubleLE @v[1],        64; @v[1] = msg.readDoubleLE 64
  msg[80] = o.flags = NET.setFlags [0,0,o.right,o.left,0,0,0,0]
  return @_buffer = msg.toString 'binary'

State.steer.fromBuffer = (o,msg)->
  [ o.accel, o.retro, o.right, o.left ] = o.flags = NET.getFlags msg[80]
  new State.steer
    o: o
    relto:    $obj.byId[  msg.readUInt16LE 4 ]
    d:                    msg.readUInt16LE 6
    x:                    msg.readDoubleLE 8
    y:                    msg.readDoubleLE 24
    t: NUU.timePrefix() + msg.readUInt32LE 40
    v: [                  msg.readDoubleLE 48
                          msg.readDoubleLE 64 ]

#  ██████  ██████  ██████  ██ ████████
# ██    ██ ██   ██ ██   ██ ██    ██
# ██    ██ ██████  ██████  ██    ██
# ██    ██ ██   ██ ██   ██ ██    ██
#  ██████  ██   ██ ██████  ██    ██

State.register class State.orbit extends State
  lock: yes
  constructor:(s) ->
    unless s.stp # translate
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
      do @cache
      do @update
    s.a = s.a || s.o.a || 0
  translate:->
    return console.log '::st', 'orbit', 'set:no-relto' unless @relto
    dx = @o.x - @relto.x
    dy = @o.y - @relto.y
    relm = $v.sub @relto.v.slice(), @o.v
    @orb = @orb || round sqrt dx * dx + dy * dy
    @vel = v = max 0.02, min 0.01, min $v.mag(relm), @orb / 10000000
    @stp = TAU / (( TAU * @orb ) / v )
    @stp = -@stp if 0 > $v.cross(2) relm, [dx,dy]
    @off = ( TAU + -(PI/2) + atan2 dx, -dy ) % TAU
  cache:->
    @stpangl = if @stp > 0 then PI/2 else -PI/2
  update:(time=NUU.time())->
    return if @lastUpdate is time
    @relto.update time unless @relto.id is 0
    t = time - @t
    angl = ((( TAU + @off + t * @stp ) % TAU ) + TAU ) % TAU
    @o.x = @relto.x + @orb * cos angl
    @o.y = @relto.y + @orb * sin angl
    angl = ( @stpangl + angl + TAU ) % TAU
    @o.v = [ @relto.v[0] + (@vel * cos angl), @relto.v[1] + (@vel * sin angl) ]
    @o.d = angl * RAD
    @lastUpdate = time
    return
  toJSON:->
    S:@S,o:@o.id,relto:@relto.id,t:@t,orb:@orb,stp:@stp,off:@off,vel:@vel

State.orbit::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 79; o = @o
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id,                                2
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ), 4
  msg.writeUInt32LE ( @t % 1000000 ),                    6
  msg.writeDoubleLE @orb, 14;    @orb = msg.readDoubleLE 14
  msg.writeDoubleLE @stp, 30;    @stp = msg.readDoubleLE 30
  msg.writeDoubleLE @off, 46;    @off = msg.readDoubleLE 46
  msg.writeDoubleLE @vel, 62;    @vel = msg.readDoubleLE 62
  return @_buffer = msg.toString 'binary'

State.orbit.fromBuffer = (o,msg)-> o.flags = 0; new State.orbit {
  o: o
  relto:    $obj.byId[  msg.readUInt16LE 4 ]
  t: NUU.timePrefix() + msg.readUInt32LE 6
  orb:                  msg.readDoubleLE 14
  stp:                  msg.readDoubleLE 30
  off:                  msg.readDoubleLE 46
  vel:                  msg.readDoubleLE 62 }

# ███████  ██████  ██████  ███    ███  █████  ████████ ██  ██████  ███    ██
# ██      ██    ██ ██   ██ ████  ████ ██   ██    ██    ██ ██    ██ ████   ██
# █████   ██    ██ ██████  ██ ████ ██ ███████    ██    ██ ██    ██ ██ ██  ██
# ██      ██    ██ ██   ██ ██  ██  ██ ██   ██    ██    ██ ██    ██ ██  ██ ██
# ██       ██████  ██   ██ ██      ██ ██   ██    ██    ██  ██████  ██   ████

State.register class State.formation extends State
  lock: yes
  update:(time)->
    return if @lastUpdate is time
    @relto.update @lastUpdate = time || time = NUU.time()
    @o.x = @relto.x + @x
    @o.y = @relto.y + @y
    @o.v[0] = @relto.v[0]
    @o.v[1] = @relto.v[1]
    @o.d = @relto.d
    @acceleration = @relto.state.acceleration
    return
  translate:->
    @relto.update @t
    @x = @o.x - @relto.x
    @y = @o.y - @relto.y
    @o.v = @relto.v.slice()
    @o.d = @relto.d
    return
  toJSON:-> S:@S,x:@x,y:@y,d:@d,relto:@relto.id

State.formation::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 49; o = @o
  msg[0] = NET.stateCode; msg[1] = @S
  msg.writeUInt16LE o.id,                                2
  msg.writeUInt16LE ( if @relto then @relto.id else 0 ), 4
  msg.writeUInt16LE ( @d = parseInt @d ),                6
  msg.writeDoubleLE ( @x = parseInt @x ),                8
  msg.writeDoubleLE ( @y = parseInt @y ),                24
  msg.writeUInt32LE ( @t % 1000000     ),                40
  return @_buffer = msg.toString 'binary'

State.formation.fromBuffer = (o,msg)-> new State.formation {
  o: o
  relto: $obj.byId[msg.readUInt16LE 4]
  d: msg.readUInt16LE 6
  x: msg.readDoubleLE 8
  y: msg.readDoubleLE 24
  t: NUU.timePrefix() + msg.readUInt32LE 40 }

# ████████ ██████   █████  ██    ██ ███████ ██
#    ██    ██   ██ ██   ██ ██    ██ ██      ██
#    ██    ██████  ███████ ██    ██ █████   ██
#    ██    ██   ██ ██   ██  ██  ██  ██      ██
#    ██    ██   ██ ██   ██   ████   ███████ ███████
$v.div = $v.div 2

State.register class State.travel extends State
  lock:yes
  acceleration:yes
  translate:-> # sometimes I really miss goto
    return if @vec
    s = @o; t = @relto; @vec = v = eta:0
    v.local_pos = [s.x,s.y]
    v.local_vel = @o.v.slice()
    v.local_speed = $v.mag v.local_vel
    v.local_acc = s.thrustToAccel v.thrust = 252
    v.local_aps = 1000 * v.local_acc
    v.top_speed = Speed.max * .5
    t.state.update @t
    $approach = =>
      t.state.update @t + v.eta
      v.target_pos     = [t.x,t.y]
      v.target_vel     = t.v.slice()
      v.target_speed   = $v.mag v.target_vel
      v.approach_path  = $v.sub v.target_pos.slice(), v.local_pos
      v.approach_norm  = $v.normalize v.approach_path.slice()
      v.approach_dist  = $v.mag v.approach_path
      v.approach_head  = $v.heading v.approach_path, $v.zero
      v.approach_r     = $v.mult v.approach_path.slice(), -1
      v.approach_rnorm = $v.normalize v.approach_r.slice()
      v.approach_rhead = $v.heading v.approach_r, $v.zero
      v.travel_vel     = $v.mult v.approach_norm.slice(), v.top_speed
      v.travel_speed   = $v.mag v.travel_vel
      v.steer_vel      = $v.sub v.travel_vel.slice(), v.local_vel
      v.accel_t        = abs ( v.local_vel[0]  - v.travel_vel[0] ) / (v.approach_norm[0]*v.local_acc)
      v.deccel_t       = abs ( v.target_vel[0] - v.travel_vel[0] ) / (v.approach_norm[0]*v.local_acc)
      [ cosd, sind ] = v.approach_norm
      accdt2b2 = .5*(acc = v.local_acc)*(dt2 = (dt = v.accel_t)**2)
      v.accel_dist = $v.mag [
        v.local_vel[0]*dt+cosd*accdt2b2
        v.local_vel[1]*dt+sind*accdt2b2 ]
      [ cosd, sind ] = v.approach_rnorm
      accdt2b2 = .5*(acc = v.local_acc)*(dt2 = (dt = v.deccel_t)**2)
      v.deccel_dist = $v.mag [
        v.travel_vel[0]*dt+cosd*accdt2b2
        v.travel_vel[1]*dt+sind*accdt2b2 ]
      v.glide_dist     = v.approach_dist - v.deccel_dist - v.accel_dist
      v.glide_t        = v.glide_dist / v.top_speed
      v.eta            = v.accel_t + v.deccel_t + v.glide_t
      v.glide_hd       = RAD * v.approach_head
      v.glide_rhd      = RAD * v.approach_rhead
      v.accel_tf       = @t + v.accel_t
      v.glide_tf       = v.accel_tf + v.glide_t
      v.deccel_tf      = v.glide_tf + v.deccel_t
      v.etaf           = @t + v.eta
    eta1 = $approach(); tp0 = v.target_pos.slice()
    console.log 'travel:eta1', htime(v.eta/1000)
    eta2 = $approach()
    console.log 'travel:eta2'.red,
      'eta', htime(v.eta/1000),
      'diff:', htime((eta2-eta1)/1000)
      'tcip:', $v.mag $v.sub tp0.slice(), v.target_pos
    util = require 'util'
    console.log util.inspect(v).bold.inverse
    t.state.update NUU.time()
    return
  update:(time=NUU.time())=>
    return if @lastUpdate is time; v = @vec
    return @toGlide time if time > v.accel_tf
    [ cosd, sind ] = v.approach_norm; acc = v.local_acc
    dt = time - @t; dt2 = dt**2
    @o.x    = @x + @v[0]*dt + .5*cosd*acc*dt2
    @o.y    = @y + @v[1]*dt + .5*sind*acc*dt2
    @o.v[0] =      @v[0]    +    cosd*acc*dt
    @o.v[1] =      @v[1]    +    sind*acc*dt
    @o.d    = v.glide_hd
    @lastUpdate = time
  toGlide:(time)->
    @acceleration = no
    v = @vec; [ cosd, sind ] = v.approach_norm; acc = v.local_acc
    dt = v.accel_t; dt2 = dt**2
    @dx      = @x + @v[0]*dt + .5*cosd*acc*dt2
    @dy      = @y + @v[1]*dt + .5*sind*acc*dt2
    @o.v[0] = @mx = @v[0]    +    cosd*acc*dt
    @o.v[1] = @my = @v[1]    +    sind*acc*dt
    @o.d = v.glide_hd
    ( @update = @o.update = @updateGlide )( time )
  updateGlide:(time=NUU.time())=>
    return if @lastUpdate is time; v = @vec
    return @toDeccel time if time > v.glide_tf
    @o.x = @dx + @mx * dt = time - v.accel_tf
    @o.y = @dy + @my * dt
    @lastUpdate = time
  toDeccel:(time)->
    @acceleration = yes; v = @vec
    @dx  = @dx + @mx * v.glide_t
    @dy  = @dy + @my * v.glide_t
    @o.d = v.glide_rhd
    ( @update = @o.update = @updateDeccel )( time )
  updateDeccel:(time=NUU.time())=>
    return if @lastUpdate is time; v = @vec
    return @toMoving time unless time < v.etaf
    [ cosd, sind ] = v.approach_norm; acc = -v.local_acc
    dt = time - v.glide_tf; dt2 = dt**2;
    @o.x    = @dx + @mx*dt + .5*cosd*acc*dt2
    @o.y    = @dy + @my*dt + .5*sind*acc*dt2
    @o.v[0] =       @mx    +    cosd*acc*dt
    @o.v[1] =       @my    +    sind*acc*dt
    @lastUpdate = time
  toMoving:(time)->
    @acceleration = no; v = @vec; [ cosd, sind ] = v.approach_norm; acc = -v.local_acc
    dt = v.deccel_t; dt2 = dt**2
    @dx = @dx + @mx*dt + .5*cosd*acc*dt2
    @dy = @dy + @my*dt + .5*sind*acc*dt2
    @mx =       @mx    +    cosd*acc*dt
    @my =       @my    +    sind*acc*dt
    @o.d = v.glide_hd
    ( @update = @o.update = @updateMoving )( time )
  updateMoving:(time=NUU.time())=>
    return if @lastUpdate is time; @lastUpdate = time; v = @vec
    @o.x = @dx + @mx * dt = time - v.etaf
    @o.y = @dy + @my * dt
    @lastUpdate = time
  toBuffer:-> @_buffer = NET.JSON + JSON.stringify state:[@toJSON()]
  toJSON:-> S:@S,o:@o.id,x:@x,y:@y,d:@d,t:@t,v:@v,relto:@relto.id,vec:@vec
