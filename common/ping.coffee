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

class Mean
  constructor : -> @reset()
  reset : (v) ->
    @last = 0; @total = 0; @count = 0; @avrg = 0
  add : (v) ->
    @count++
    @last = v
    @total += v
    @avrg = @total / @count

$public class CommonRTPing extends Mean
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
    $static 'Ping', @

  reset : ->
    super
    @lag.reset()
    @trip.reset()
    @skew.reset()
    @delta.reset()
    @jitter.reset()
    @error.reset()

app.on 'protocol', -> new RTPing
