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

                            ▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▒▒▒
                        ▒▒▒▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓▓▒▒▒
                     ▒▒▒▒▓▓▓▓▓▓▓▓▓▓███▓█▓▓▓▓▓▓▓▓▓▓▒▒▒▒
                   ▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒
                 ▒▒▒▒▒▒▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒ ▒▒
                 ▓▓▓▒▒▒▒▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒
                ▒▓▓▓▓▓▓▒▒▒▒▒▒▒▓▓▒▒       ▒▒▓▓▓▒▒
                 ▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒           ▒▓▓▒
                 ▒▒▒▒▒  ▒▒▒▒▒            ▒  ▒▓▓▓ ▒▒    ▒
                  ▒▒▒                ▒▒▓▓▓▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒
                  ▒▒▒▒▒▒  ▒▒▓▓▓▒▒▒▒▒▓▓▓▓▒▒▒▓▒▒▓▓▓▓▒▒▒▓▒▒
                     ▒     ▒▒▓▓▒▒▒▒▒▓▓▓▓▒▒           ▒▒▒
                 ▒▒▒        ▒▒▒▒▒▒▒▒▓▓▓▒▓▓▒▒▒▒    ▒▒▒▒▒▒▒▒
                  ▒▓▓▓▒   ▒   ▒▒▒▒▒▒▒▒▒▓▒▒ ▒          ▒▒▒▒▒▒
                    ▓▒▓▒   ▒▒▒▒▒▓▓▓▓▓▒▒▒           ▒  ▒▓▓▒▒▒
                     ▒▓▓▒   ▒▒▒▒▒▒▒▒▓▓▓▒▒▒   ▒▒▒▒    ▒▒▒▒
                                ▒▒▒▒▒▒▒▓▓▒▒▒▒    ▒▒▒▒▓▓▒
                                  ▒▒▒  ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒
                                           ▒▒
                            ▒
                              ▒
                                 ▒▒▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒

██████   ██████  ███    ██   ██████   █████   ██████  ██       ██████  ██     ██
██   ██ ██    ██ ████   ██   ██   ██ ██   ██ ██       ██      ██    ██ ██     ██
██   ██ ██    ██ ██ ██  ██   ██   ██ ███████ ██   ███ ██      ██    ██ ██  █  ██
██   ██ ██    ██ ██  ██ ██   ██   ██ ██   ██ ██    ██ ██      ██    ██ ██ ███ ██
██████   ██████  ██   ████   ██████  ██   ██  ██████  ███████  ██████   ███ ███
                                    https://en.wikipedia.org/wiki/Don_Daglow ###

# ███████ ████████ ███████ ██      ██       █████  ██████
# ██         ██    ██      ██      ██      ██   ██ ██   ██
# ███████    ██    █████   ██      ██      ███████ ██████
#      ██    ██    ██      ██      ██      ██   ██ ██   ██
# ███████    ██    ███████ ███████ ███████ ██   ██ ██   ██

$obj.byName = {}
$obj.register class Stellar extends $obj
  interval: 1000
  @interfaces: [$obj,Stellar]
  constructor:(opts)->
    super opts
    unless @orbits then @orbits = (
      if      @size > 500 then [500,1000,1500,2000]
      else if @size > 300 then [500,1000,1500]
      else if @size > 100 then [500,1000]
      else                     [500] )
    @lastCycle = @nextCyle = 0
    @name = "#{@constructor.name} [#{@id}]" unless @name
    $obj.byName[@name] = @
    console.log @constructor.name.yellow, @name, ( @buildRoot?.name || '' ).red,( @state?.relto?.name || '' ).bold if debug
    Economy.attach @ if isServer
  destructor:->
    @zone.detach @ if @zone
    super()
  toJSON: -> return {
    id:       @id
    key:      @key
    sprite:   @sprite
    state:    @state
    name:     @name
    orbits:   if @orbits[0] is 500 then undefined else @orbits
    produces: @produces
    consumes: @consumes }
  produce:-> e:@produces.e * @level

Stellar.init = ->
  console.log ':nuu', 'init:stars' if debug
  orbits = {}
  now = Date.now()
  rules.lastId = 256
  for i in rules.stars
    continue unless o = i[7]
    continue unless o.occupiedBy
    rules.seedEconomy i, o
  for i in rules.stars
    [ id, Constructor, name, sprite, orbit, state, relto, args ] = i
    orbits[relto+'_'+orbit] = l = orbits[relto+'_'+orbit] || []
    l.push id
  for i in rules.stars
    [ id, Constructor, name, sprite, orbit, state, relto, args ] = i
    args   = {} unless args
    odx    = orbits[relto+'_'+orbit].indexOf id
    oct    = ( orbits[relto+'_'+orbit] || [] ).length
    relto$ = $obj.byId[relto] || x:0,y:0,update:$void
    relto$.update()
    rand = if oct is 1 then TAU * random() else ( TAU / oct ) * odx
    vel   = 0.05
    if 0 < hrs = args.t
      vel = ( TAU * orbit ) / ( hrs * 360000 ) # ten times faster
    stp   = TAU / ( ( TAU * orbit ) / vel )
    state = S:state, relto:relto$, t:now, orb:orbit, vel:vel, stp:stp, off:rand
    opts = Object.assign args||{}, id:id, name:name, sprite:sprite, state:state
    new Constructor opts
  return

Object.defineProperty Stellar::, 'buildRoot', get:->
  p = @; u = {}; u[p.id] = true
  console.log '-', @name, @state.relto.name if @state.relto if debug
  p.state.update time = NUU.time()
  while r = p.state.relto
    console.log '|', p.name if debug
    r.state.update time
    if 150000 < d = $dist(p,r)
      console.log 'x:dist', d if debug
      break
    if u[r.id]
      console.log 'x:uniq', r.name if debug
      break
    u[(p = r).id] = true
  console.log '->', p.name, p.constructor.name if debug
  switch p.constructor.name
    when 'Star','Planet','Moon' then p
    else null

$obj.register class Star extends Stellar
  @interfaces: [$obj,Stellar]
  provides: e:1000
  bigMass:yes

$obj.register class Planet extends Stellar
  @interfaces: [$obj,Stellar]
  bigMass:yes

$obj.register class Moon extends Stellar
  @interfaces: [$obj,Stellar]
  bigMass:yes
