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

$public class RTSync extends CommonRTSync
  login : (name, pass, callback) =>
    console.log 'NET.login'
    bind = (s) =>
      @sock = s
      @send = (msg) => s.send msg
      NUU.emit 'connect', s

      NET.on 'join', (vc) ->
        return if Ship.byId[vc.id]
        new Ship vc

      NET.on 'user.login.success', (opts) ->
        log "Login successful."
        NUU.sync opts, ->
          callback true

      NET.on 'user.login.failed', (opts) ->
        log "Login failed."
        callback false

      s.onmessage = (msg) => @route(s)(msg.data)

      s.onopen = (e) ->
        log "Connected. Sending credentials."
        NET.json.write login: user:name, pass:pass

      s.onerror = (e) ->
        console.log "sock:error", e
        NUU.emit 'disconnect'

    loc = window.location.toString()
    addr = loc.replace('http','ws').replace(/#.*/,'').replace(/\/$/,'') + '/nuu'
    console.log 'NET.connect', addr
    bind(if WebSocket? then new WebSocket(addr) else new MozWebSocket(addr))
