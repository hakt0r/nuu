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

stateToKey = [ 'fixed', 'moving', 'accelerating', 'manouvering', 'orbit' ]

class State
  @change : (s,state) =>
    # debugger
    unless state?
      if s.accel or s.retro or s.boost
        if s.right or s.left then state = manouvering
        else state = accelerating
      else if s.right or s.left then state = manouvering
      else if abs(s.mx) + abs(s.my) isnt 0 then state = moving
      else state = fixed
    s.update()
    r = s.stateRec
    r.a  = if s.boost then s.thrust * 2 else if s.retro then s.thrust * -.5 else s.thrust
    r.t  = TIME; r.d  = s.d
    r.x  = s.x;   r.y  = s.y
    r.mx = s.mx;  r.my = s.my
    # console.log 'changeState', s.id, s.state, state
    s.update = State[stateToKey[s.state = state]](s)
    s

  # object state callback factories
  @fixed : (s) -> ->

  @moving : (s) ->
    r = s.stateRec; update = TIME
    return ->
      return null if update is TIME; update = TIME
      ticks = (TIME - r.t) / TICK
      s.x = r.x + s.mx * ticks
      s.y = r.y + s.my * ticks
      null

  @accelerating : (s) ->
    r = s.stateRec; update = TIME
    return ->
      return null if update is TIME; update = TIME
      s.fuel -= r.a
      ticks = (TIME - r.t) / TICK
      ticks2 = ticks * ticks
      dir = s.d / RAD
      s.mx = r.mx + r.a * cos(dir) * ticks
      s.my = r.my + r.a * sin(dir) * ticks
      s.x  = r.x + r.mx * ticks + .5 * r.a * cos(dir) * ticks * ticks
      s.y  = r.y + r.my * ticks + .5 * r.a * sin(dir) * ticks * ticks
      null

  @manouvering : (s) -> 
    r = s.stateRec; update = TIME
    $worker.push ->
      return off  if ended
      return null if update is TIME
      update = TIME; dir = s.d
      s.turn = s.turn || 1
      if s.right or s.left
        dir = (dir + s.turn * if s.left then -1 else 1)
        if dir <= -1 then dir = 360 + dir
        else if dir >= 360 then dir = dir - 360
      s.d = dir
      if s.accel or s.retro
        dir = dir / RAD
        s.mx = s.mx + r.a * cos dir
        s.my = s.my + r.a * sin dir
        s.mx = s.my = 0 if s.retro and (abs(s.mx)+abs(s.my) < 3)
      s.x = s.x + s.mx
      s.y = s.y + s.my
      return null
    ended = no; return (noend) ->
      ended = yes unless noend

  @orbit : (s) ->
    lx = ly = 0
    offs = Math.random() * TAU 
    rad = s.orbit
    s.x = s.orbit; s.y = 0
    r = s.stateRec; update = TIME
    p = s.relto
    step = min(10/rad*TAU,0.01)
    if p then return ->
      return null if update is TIME
      p.update()  if p.update
      ticks = (TIME - r.t) / TICK
      dir  = offs + (ticks * step) % TAU
      s.x = p.x + cos(dir) * rad
      s.y = p.y + sin(dir) * rad
      s.mx = s.x - lx
      s.my = s.y - ly
      lx = s.x; ly = s.y
      null
    else return ->
      return null if update is TIME
      ticks = (TIME - r.t) / TICK
      dir  = offs + (ticks * step) % TAU
      s.x  = cos(dir) * rad
      s.y  = sin(dir) * rad
      null

app.on 'protocol', ->

  NET.define 'STATE',
    read :
      server : (msg,src) =>
        o = src.handle.vehicle
        [ o.accel, o.retro, o.right, o.left, o.boost
        ] = NET.getFlags(src.flags = msg[1])
        o.d = msg.readUInt16LE 2
        NET.state.write(o)
        src
      client : (msg) =>
        o = $obj.byId[id = msg.readUInt16LE 2]
        [ o.accel, o.retro, o.right, o.left, o.boost
        ] = NET.getFlags(o.flags = msg[1])
        State.change o, msg[34]
        r = o.stateRec
        o.d  = r.d  = msg.readUInt16LE 4
        o.x  = r.x  = msg.readInt32LE  6
        o.y  = r.y  = msg.readInt32LE  10
        r.t  = Math.floor(Date.now()/1000000)*1000000 + msg.readUInt32LE 14
        o.mx = r.mx = msg.readDoubleLE 18
        o.my = r.my = msg.readDoubleLE 26
        o
    write :
      server :(o) =>
        o.flags = NET.setFlags([o.accel,o.retro,o.right,o.left,o.boost,no,no,no])
        State.change o
        msg = new Buffer [ NET.stateCode, o.flags,
          0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        edate = o.stateRec.t % 1000000
        msg.writeUInt16LE o.id,             2
        msg.writeUInt16LE o.d,              4
        try
          msg.writeInt32LE  Math.floor(o.x),  6
          msg.writeInt32LE  Math.floor(o.y),  10
        catch e
          console.log o.x, o.y, edate
        msg.writeUInt32LE edate,            14
        msg.writeDoubleLE(o.mx,             18)
        msg.writeDoubleLE(o.my,             26)
        msg[34] = o.state
        NUU.bincast msg.toString 'binary'
      client :(o,flags) =>
        if typeof flags is 'object'
          o.flags = flags = NET.setFlags(flags)
        else o.flags = flags
        msg = new Buffer [NET.stateCode,flags,0,0,0]
        msg.writeUInt16LE o.d, 2
        NET.send msg.toString 'binary'

  dock = (o,t,mode) ->
    switch mode
      when 'launch'
        console.log 'launch'
        t = o.relto
        State.change o, moving
        delete o.relto
        delete o.orbit
      when 'land'
        console.log 'land'
      when 'orbit'
        console.log 'orbit'
        o.relto = t
        o.orbit = $dist o,t
        State.change o, orbit
  dock.key = ['launch','land','orbit']

  NET.define 'DOCK',
    read :
      server :(msg,src) =>
        o = src.handle.vehicle
        mode = dock.key[msg[1]]
        t = msg.readUInt16LE 2
        dock(o,t,mode)
        r = new Buffer [NET.dockCode,msg[1],0,0,msg[2],msg[3]]
        r.writeUInt16LE o.id, 2
        NUU.bincast r.toString 'binary'
      client : (msg) =>
        mode = dock.key[msg[1]]
        o = $obj.byId[id = msg.readUInt16LE 2]
        t = $obj.byId[id = msg.readUInt16LE 4]
        dock(o,t,mode)
    write :
      client :(t,mode) =>
        msg = new Buffer [NET.dockCode,dock.key.indexOf(mode),0,0]
        msg.writeUInt16LE t.id, 2
        NET.send msg.toString 'binary'

$public State