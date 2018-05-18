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

    if isClient
      @ringId = 0
      @ringBf = []
      timer = null
      NUU.on 'connect', =>
        timer = $interval @INTERVAL, =>
          id = ++@ringId % 32
          local = @ringBf[id] = Date.now()
          msg = Buffer.from [NET.pingCode,id,0,0,0,0,0,0,0,0]
          msg.writeDoubleLE local, 2
          NET.send msg.toString('binary')
      NUU.on 'disconnect', =>
        clearInterval timer

    NET.define 1,'PING', read:
      client: (msg,src) =>
        prediction = @remoteTime()
        remote = @lastRemoteTime = msg.readDoubleLE 2
        local  = @lastLocalTime  = Date.now()
        unless @ringBf[msg[1]]
          console.log 'ERROR', msg[1], 'is not a ping id'
        trip   = local - @ringBf[msg[1]]   # time it took from ping to response
        delta  = local - (trip/2) - remote # raw current time delta to remote
        @trip.add trip
        if @trip.count > 1                # delta to last delta
          @skew.add skew = @delta.last - delta
        @delta.add delta
        @add trip / 2
        @lastError = remote - prediction
        if @trip.count > 10
          @error.add @lastError
          if abs(@error.avrg) / abs(@avrg) > 0.3
            @reset()
            @error.reset()
        null
      server: (msg,src) =>
        b = Buffer.from [NET.pingCode,msg[1],0,0,0,0,0,0,0,0]
        b.writeDoubleLE(Date.now(),2)
        src.send b.toString('binary')
        null
    null

  reset : ->
    super
    @lag.reset()
    @trip.reset()
    @skew.reset()
    @delta.reset()
    @jitter.reset()
    @error.reset()

if isClient
  RTPing::remoteTime = ->
    now = Date.now()
    skew = (now - @lastLocalTime) / @INTERVAL * @skew.avrg # total skew since last sync
    return now - @delta.avrg + skew                        # now - delta to server + clock skew

$static 'Ping', new RTPing
