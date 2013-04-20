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

$public class RTPing extends CommonRTPing
  constructor : ->
    super
    timer = null
    NET.define 'PING', read : (msg,src) =>
      prediction = @remoteTime()
      remote = @lastRemoteTime = parseInt msg.readUInt32LE('utf8',2)
      local = @lastLocalTime = Date.now()
      trip = local - @ringBf[msg[1]]    # time it took from ping to response
      delta = local - (trip/2) - remote # raw current time delta to remote
      @trip.add trip
      if @trip.count > 1           # delta to last delta
        @skew.add skew = @delta.last - delta
      @delta.add delta
      @add trip / 2
      @lastError = remote - prediction
      @error.add @lastError if @trip.count > 10
      @reset() if @trip.count > 2 and Math.abs(@error.avrg) > 100000
    NUU.on 'connect', =>
      timer = $interval @INTERVAL, =>
        id = @ringId++; local = @ringBf[id] = Date.now() 
        msg = new Buffer [NET.pingCode,id,0,0,0,0,0,0,0,0]
        msg.writeDoubleLE local, 2
        NET.send msg.toString('binary')
    NUU.on 'disconnect', =>
      clearInterval timer

  remoteTime : =>
    now = Date.now()
    skew = (now - @lastLocalTime) / @INTERVAL * @skew.avrg # total skew since last sync 
    return now - @delta.avrg + skew                 # now - delta to server + clock skew
