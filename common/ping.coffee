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

$public class RTPing extends Mean
  INTERVAL : 500
  lag    : new Mean
  trip   : new Mean
  skew   : new Mean
  delta  : new Mean
  error  : new Mean
  jitter : new Mean
  ringId : 0
  ringBf : [null,null,null,null,null,null,null,null,null,null]

  lastLocalTime : Date.now()
  lastRemoteTime : Date.now()

  constructor : ->
    super
    NET.define 1,'PING', read:
      client: (msg,src) =>
        prediction = NUU.time() - @avrg
        remote = @lastRemoteTime = msg.readDoubleLE 2
        local  = @lastLocalTime  = Date.now()
        return console.log ':net', 'ping-error', msg[1], 'is not a ping id'     unless @ringBf[msg[1]]
        @trip  .add trip  = local - @ringBf[msg[1]]                             # time it took from ping to response
        @delta .add delta = local - (trip/2) - remote                           # raw current time delta to remote
        @add trip / 2
        @lastError = remote - prediction
        return unless @trip.count > 10
        @error.add @lastError
        if abs(@error.avrg) / abs(@avrg) > 0.3
          console.log "resetting ping due to", @lastError, @error.avrg, @avrg, abs(@error.avrg) / abs(@avrg)
          @reset()
          @error.reset()
        null
      server: (msg,src) =>
        b = Buffer.from [NET.pingCode,msg[1],0,0,0,0,0,0,0,0]
        b.writeDoubleLE Date.now(), 2
        src.send b.toString('binary')
        null
    return if isServer
    @ringId = 0
    @ringBf = []
    timer = null
    NUU.on 'connect', => timer = $interval @INTERVAL, =>
      @ringBf[id = ++@ringId % 32] = Date.now()
      msg = Buffer.from [NET.pingCode,id]
      NET.send msg.toString 'binary'
    NUU.on 'disconnect', -> clearInterval timer
    null

  reset : ->
    super
    @lag.reset()
    @trip.reset()
    @skew.reset()
    @delta.reset()
    @jitter.reset()
    @error.reset()

$static 'Ping', new RTPing

return if isServer

NUU.time = ->
  now = Date.now()
  # skew = (now - Ping.lastLocalTime) / Ping.INTERVAL * Ping.skew.avrg # total skew since last sync
  return now - Ping.delta.avrg # + skew                        # now - delta to server + clock skew

NUU.on 'start', ->
  NUU.thread 'ping', 500, Ping.send
