###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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
    Object.assign @, opts
    unless @o.id?
      console.error '$state:object not resolved', @o if debug
      return false
    console.error  '$state:relto not resolved', @relto unless @relto.id? if debug
    @update = @updateRelTo if @updateRelTo and @relto?
    @o.update = @update.bind @
    @o.locked = @lock?
    @o.state = @
    t = NUU.time()
    @relto.update t if @relto
    @cache()        if @cache
    @update t
    # console.log @o.name, State.toKey[@S], @p, @v

# ███████ ███████ ██████  ██    ██ ███████ ██████
# ██      ██      ██   ██ ██    ██ ██      ██   ██
# ███████ █████   ██████  ██    ██ █████   ██████
#      ██ ██      ██   ██  ██  ██  ██      ██   ██
# ███████ ███████ ██   ██   ████   ███████ ██   ██

if isServer then $public class State
  constructor:(opts) ->
    return if false is opts
    opts.o = o = if ( id = opts.o ).id? then id else $obj.byId[id]
    opts.t = opts.t || NUU.time()
    if oldState = opts.o.state
      oldState.update()
      oldState.cleanup()
    { @x,@y,@d,@a,@v } = o
    opts.a = if opts.a? then opts.a else ( if o.thrustToAccel then o.thrustToAccel o.thrust else 0 )
    Object.assign @, opts
    Object.assign o, x:@x,y:@y,d:@d,a:@a,v:@v
    o.v = ( @v = @v.slice() ).slice()
    o.state  = @
    o.locked = @lock is true
    if ( @relto?.id? ) or ( @relto = $obj.byId[@relto] ) # or @findRelTo opts
      @update = @updateRelTo || @update
      @relto.ref @, @reltoLost
      @relto.update @t
    o.update = @update.bind @
    @translate oldState if @translate
    @cache()            if @cache
    @toBuffer()
    @update @t
    NET.state.write @
  reltoLost:->
    console.log @o.name, 'lost relto', @relto.name
    @o.setState S:$moving, relto:$obj.byId[0]
  cleanup:-> @relto.unref @ if @relto
    # console.log @o.name, State.toKey[@S], @p, @v # if @o.name is "Exosuit"

if isServer then NET.stateSync = $worker.DeadLine 1000, 5000,
  -> NUU.bincast @state._buffer, @ unless @destructing

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

State::findRelTo = (oldState) ->
  @o.update() if @o.update
  if ( r = oldState?.relto ) and r.bigMass
    if ( 10000 > d = $dist @o, r )
      @relto = r
      @relto.update @t
    else @relto = null
  else
    [dist,closest] = @o.closestBigMass()
    relto  = closest if dist < 10000
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

State.moving.shader = """
uniform float Object[0xFFFF*8];
const int px     = 0;
const int py     = 1;
const int vx     = 2;
const int vy     = 3;
const int symbol = 4;
const int tint   = 5;
const int relto  = 6;
vec2 moving(float t, int objId){
  int offset = objId * fields;
  rel = moving(t, Object[offset+relto])
  vec2 pos = vec2( Object[offset+px], Object[offset+px] );
  vec2 vel = vec2( Object[offset+px], Object[offset+px] );
  return rel + pos + vel * dt  );
}
"""

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
    $v.mult $v.norm(@v), r*.99 if r < $v.mag @v # reset to speed limit
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
    @vel = v = max 0.1, min 0.01, min $v.mag(relm), @orb / 1e7
    @stp = TAU / (( TAU * @orb ) / v )
    @stp = -@stp if 0 > $v.cross relm, [dx,dy]
    @off = ( TAU + -(PI/2) + atan2 dx, -dy ) % TAU
  cache:->
    @stpangl = if @stp > 0 then PI/2 else -PI/2
  update:(time=NUU.time())->
    return if @lastUpdate is time
    @relto.update time unless @relto.id is 0
    t = time - @t
    angl = ((( TAU + @off + t * @stp ) % TAU ) + TAU ) % TAU
    cosa = cos angl; sina = sin angl
    @o.x = @relto.x + @orb * cosa
    @o.y = @relto.y + @orb * sina
    angl = ( @stpangl + angl + TAU ) % TAU
    @o.v[0] = @relto.v[0] + (@vel * cosa)
    @o.v[1] = @relto.v[1] + (@vel * sina)
    @o.d = angl * RAD
    @lastUpdate = time
    return
  toJSON:->
    S:@S,o:@o.id,relto:@relto.id,t:@t,orb:@orb,stp:@stp,off:@off,vel:@vel

State.orbit.shader = """
const TAU = 6.283185307179586;
vec4 orbit(vec4 obj, vec4 rel){
  float angl =
  vec4 cur =

}
"""

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

State.orbit.relto = (relto,orbit,speed,offset)->
  return
    S:     $orbit
    orb:   orbit
    vel:   v = speed || orbit / 1e7
    stp:   TAU / (( TAU * orbit ) / v )
    off:   offset || 0.0
    relto: relto

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

State.register class State.travel extends State
  lock:yes
  acceleration:yes
  constructor:(opts)->
    super opts

  cache:->
    @vec = new NavComVector @o, @relto, @
    @px = @x; @py = @y; [ @vx, @vy ] = @v
    @o.d = @vec.mathdd
    if isNaN @vec.absETA
      console.log "@@@", @o.name, '=>', @relto.name, ( round @o.dist(@relto))
      console.log @o.p
      console.log @relto.p
      console.log @vec
    return

  update:(time=NUU.time())->
    return if @lastUpdate is time; v = @vec
    return @toAccel time if time > v.matfti
    [ cosd, sind ] = v.matnrm; acc = v.locacc
    dt = time - @t; dt2 = dt**2
    accdt2b2 = acc*dt2*.5; @o.x=@px+@vx*dt+cosd*accdt2b2; @o.y=@py+@vy*dt+sind*accdt2b2
    accdt = acc*dt; @o.v[0]=@vx+cosd*accdt; @o.v[1]=@vy+sind*accdt
    @lastUpdate = time

  toAccel:(time)->
    v = @vec; acc = v.locacc; [ cosd, sind ] = v.matnrm; dt = v.mattim; dt2 = dt**2
    @px=@px+@vx*dt+.5*cosd*acc*dt2; @py=@py+@vy*dt+.5*sind*acc*dt2
    @vx=@vx+cosd*acc*dt; @vy=@vy+sind*acc*dt
    console.log 'match=>accel:v', $v.mag $v.sub [@vx,@vy], v.pmavel if debug
    console.log 'match=>accel:p', $v.mag $v.sub [@px,@py], v.pmapos if debug
    [@vx,@vy] = v.pmavel; [@px,@py] = v.pmapos
    @o.d = v.glihdd
    ( @update = @o.update = @updateAccel.bind @ )( time )
    return

  updateAccel:(time=NUU.time())->
    return if @lastUpdate is time; v = @vec
    return @toGlide time if time > v.accfti
    [ cosd, sind ] = v.appnrm; acc = v.locacc
    dt = time - v.matfti; dt2 = dt**2
    accdt2b2 = acc*dt2*.5; @o.x=@px+@vx*dt+cosd*accdt2b2; @o.y=@py+@vy*dt+sind*accdt2b2
    accdt = acc*dt; @o.v[0]=@vx+cosd*accdt; @o.v[1]=@vy+sind*accdt
    @lastUpdate = time

  toGlide:(time)->
    v = @vec; acc = v.locacc; [ cosd, sind ] = v.appnrm; dt = v.acctim; dt2 = dt**2
    @px=@px+@vx*dt+.5*cosd*acc*dt2; @py=@py+@vy*dt+.5*sind*acc*dt2
    @vx=@vx+cosd*acc*dt; @vy=@vy+sind*acc*dt
    console.log 'accel=>glide:v', $v.mag $v.sub [@vx,@vy], v.pacvel if debug
    console.log 'accel=>glide:p', $v.mag $v.sub [@px,@py], v.pacpos if debug
    # [@vx,@vy] = v.pacvel; [@px,@py] = v.pacpos
    @o.d = v.glihdd; @acceleration = no
    ( @update = @o.update = @updateGlide.bind @ )( time )
    return

  updateGlide:(time=NUU.time())->
    return if @lastUpdate is time; v = @vec
    return @toDeccel time if time > v.glifti
    dt = time - v.accfti
    @o.x=@px+@vx*dt; @o.y=@py+@vy*dt
    @o.d = $v.umod360 360 + v.glihdd + v.glitrn * min v.glitrt, dt
    @lastUpdate = time

  toDeccel:(time)->
    v = @vec; dt = v.glitim
    @px=@px+@vx*dt; @py=@py+@vy*dt
    console.log 'glide=>deccel:v', $v.mag $v.sub [@vx,@vy], v.pglvel if debug
    console.log 'glide=>deccel:p', $v.mag $v.sub [@px,@py], v.pglpos if debug
    # [@vx,@vy] = v.pglvel; [@px,@py] = v.pglpos
    @o.d = v.glirhd; @acceleration = yes
    ( @update = @o.update = @updateDeccel.bind @ )( time )
    return

  updateDeccel:(time=NUU.time())->
    return if @lastUpdate is time; v = @vec
    return @toMoving time if time > v.decfti
    [ cosd, sind ] = v.decnrm; acc = v.locacc
    dt = time - v.glifti; dt2 = dt**2
    accdt2b2 = acc*dt2*.5; @o.x=@px+@vx*dt+cosd*accdt2b2; @o.y=@py+@vy*dt+sind*accdt2b2
    accdt = acc*dt; @o.v[0]=@vx+cosd*accdt; @o.v[1]=@vy+sind*accdt
    @lastUpdate = time

  toMoving:(time)->
    @lock = @o.locked = @acceleration = no
    v = @vec; acc = v.locacc; [ cosd, sind ] = v.decnrm; dt = v.dectim; dt2 = dt**2
    @px=@px+@vx*dt+.5*cosd*acc*dt2; @py=@py+@vy*dt+.5*sind*acc*dt2
    @vx=@vx+cosd*acc*dt; @vy=@vy+sind*acc*dt
    console.log 'deccel=>glide:v', $v.mag $v.sub [@vx,@vy], v.pdevel if debug
    console.log 'deccel=>glide:p', $v.mag $v.sub [@px,@py], v.pdepos if debug
    @relto.update v.absETA
    console.log 'deccel=>glide:tp', $v.mag $v.sub [@relto.x,@relto.y], v.tgtpos if debug
    [@o.x,@o.y] = v.pdepos; [ @o.v[0], @o.v[1] ] = v.pdevel
    # [@o.x,@o.y] = [@px,@py]; [ @o.v[0], @o.v[1] ] = [@vx,@vy]
    @update = @o.update = ->
    if isServer
      # @o.setState S:$moving
      @relto.update v.decfti
      @o.setState S:$moving,t:v.decfti,relto:@relto
      @relto.update()
    # new State.moving o:@o,t:v.decfti,x:@px,y:@py,v:[@vx,@vy],relto:@relto
    return

State.travel::toJSON =-> S:@S,o:@o.id,x:@x,y:@y,d:@d,t:@t,v:@v,relto:@relto.id
State.travel::toBuffer = ->
  return @_buffer if @_buffer; msg = Buffer.allocUnsafe 85; o = @o
  o.burn = o.left = o.right = undefined
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

State.travel.fromBuffer = (o,msg)->
  o.burn = o.left = o.right = undefined
  new State.travel {
    o: o
    relto:    $obj.byId[  msg.readUInt16LE 4 ]
    d:                    msg.readUInt16LE 6
    x:                    msg.readDoubleLE 8
    y:                    msg.readDoubleLE 24
    t: NUU.timePrefix() + msg.readUInt32LE 40
    v: [                  msg.readDoubleLE 48
                          msg.readDoubleLE 64 ]
    a:                    msg.readFloatLE  80 }
