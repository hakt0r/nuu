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

NUU.sync = (list,callback) ->
  new $obj.byClass[obj.key] obj for obj in list when not $obj.byId[obj.id]
  callback null if callback

NUU.firstSync = (opts,callback)->
  @sync opts.objects
  @player = new Player $obj.byId[opts.ship.id]
  Sprite.start => @start callback

NUU.loginPrompt = ->
  vt.prompt 'Login', (user) =>
    return @loginPrompt() if user is null
    vt.prompt 'Password', (pass) =>
      return @loginPrompt() if pass is null
      NET.login user, sha512(pass), (success) =>
        return @loginPrompt() unless success

NET.login = (name, pass, callback) ->
  console.log 'NET.login'
  NET.once 'user.login.success', (opts) ->
    log "Login successful."
    NUU.firstSync opts, -> callback true

  NET.once 'user.login.failed', (opts) ->
    log "Login failed."
    callback false
  connect = (addr) =>
    console.log 'NET.connect', addr
    s = if WebSocket? then new WebSocket addr else new MozWebSocket addr
    @sock = s
    @send = (msg) => s.send msg
    NUU.emit 'connect', s
    s.onmessage = (msg) => @route(s) msg.data
    s.onopen = (e) ->
      log "Connected. Sending credentials."
      NET.json.write login: user:name, pass:pass
    s.onerror = (e) ->
      console.log "NET.sock:error", e
      NUU.emit 'disconnect'
  loc = window.location.toString()
  addr = loc.
    replace('http','ws').
    replace(/#.*/,'').
    replace(/\/$/,'') + '/nuu'
  connect addr

NET.on 'join', (vc) ->
  return if Ship.byId[vc.id]
  new Ship vc

NET.on 'sync', (opts) ->
  NUU.sync opts
