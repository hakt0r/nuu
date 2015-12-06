###

  * c) 2007-2016 Sebastian Glaser <anx@ulzq.de>
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
$obj::m = $v.zero
$obj::state = $voidState
$obj::update = $void

if isServer then $obj::changeState = ->
  # TODO: orbit modifiction (needs elliptical orbits)
  # return console.log 'relto' if @state.relto?
  return console.log 'locked$', @name if @locked
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
  new toConstructor[s.S] @,s.x,s.y,s.d,s.m,s.a,s.t,s.relto
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
    @x = parseInt x || o.x
    @y = parseInt y || o.y
    @d = parseInt d || o.d
    @m = ( m || o.m ).slice()
    @a = a || o.a
    @t = t || TIME
    @relto = $obj.byId[0]
    @relto = relto if relto? and relto.id?
    @relto = relto if relto = $obj.byId[relto]
    @relto.update() if @relto
    o.update = @update.bind @
    @convert ostate if @convert
    @update null
    # console.log 'state$', @S, @o.id
    return unless isServer
    NET.state.write @o

colorDump = (opts={})->
  a = ( (' '+k+' ').red.inverse + '' + (' '+v.toString()+' ').white.inverse.bold for k,v of opts )
  a.join ''

Object.defineProperty State::, 'p',
  get: -> return [ @x, @y ]
  set: (p) -> [ @x, @y ] = p

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
  update: ->
    return null if @lastUpdate is TIME
    @lastUpdate = TIME
    @relto.update()
    @o.x = @relto.x + @x
    @o.y = @relto.y + @y
    @o.m = @relto.m.slice()
    null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,t:@t,relto:@relto.id

State.register 'moving', class moving extends State
  convert: -> @o.m = @m.slice()
  update: ->
    return null if @lastUpdate is TIME
    deltaT = ((@lastUpdate=TIME)-@t)/TICK
    @o.x = @x + @m[0] * deltaT
    @o.y = @y + @m[1] * deltaT
    null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,t:@t,m:@m

State.register 'accelerating', class accelerating extends State
  curm: null
  convert: ->
    @o.m = @curm = @m.slice()
    # tmaxX = ( Speed.max - @m[0] ) / @a * cos(@d/RAD)
    # tmaxY = ( Speed.max - @m[1] ) / @a * sin(@d/RAD)
    # console.log tmaxX, tmaxY
  update: (final) ->
    return null if @lastUpdate is TIME
    deltaT = ((@lastUpdate=TIME)-@t)/TICK
    dir = @d / RAD
    aDeltaT = @a * deltaT
    oFiveDeltaT = .5 * deltaT
    @curm[0] = @m[0] + cosAdeltaT = aDeltaT * cos(dir)
    @curm[1] = @m[1] + sinAdeltaT = aDeltaT * sin(dir)
    @o.x = @x + @m[0] * deltaT + oFiveDeltaT * cosAdeltaT
    @o.y = @y + @m[1] * deltaT + oFiveDeltaT * sinAdeltaT
    null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,a:@a

State.register 'maneuvering', class maneuvering extends State
  convert: ->
    @o.m = @m.slice()
    @turn = @o.turn || 1
    @turn = -@turn if @o.left
  update: ->
    return null if @lastUpdate is TIME
    deltaT = ((@lastUpdate=TIME)-@t)/TICK
    d = ( @d + @turn * deltaT ) % 360
    d = ( 360 + d ) % 360 if d < 0
    dir = d / RAD
    @o.d = d
    @o.x = @x + @m[0] * deltaT
    @o.y = @y + @m[1] * deltaT
    null
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
  update: ->
    return console.log 'update:no_relto' unless @relto
    return null if @lastUpdate is TIME
    @relto.update()
    deltaT = ( TIME - @lastUpdate ) / TICK
    ticks  = ( TIME - @t ) / TICK
    @lastUpdate = TIME
    @dir = ( TAU + @offs + ticks * @step ) % TAU
    @o.x = @relto.x + cos(@dir) * @orbit
    @o.y = @relto.y + sin(@dir) * @orbit
    @tmp = $v.zero.slice()
    @tmp[0] = ( @o.x - @lx ) / deltaT
    @tmp[1] = ( @o.y - @ly ) / deltaT
    @o.m = @tmp.slice()
    @lx = @o.x
    @ly = @o.y
    null
  toJSON: -> S:@S,x:@x,y:@y,d:@d,m:@m,t:@t,relto:@relto.id
