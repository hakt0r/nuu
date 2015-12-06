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

NET.on 'join', (vc) ->
  return if Ship.byId[vc.id]
  new Ship vc

NET.on '$obj:del', (opts) ->
  # freeId.push opts.id
  # try $obj.byId[opts.id].destructor()

NET.on 'sync', (opts) -> NUU.sync opts

NUU.sync = (list,callback) ->
  if list.del
    do o.destructor for id in list.del when o = $obj.byId[id]
  if list.add then for obj in list.add
    o.destructor console.log '$obj:exists:replace', obj.id if o = $obj.byId[obj.id]
    new $obj.byClass[obj.key] obj
  callback null if callback

NUU.firstSync = (opts,callback)->
  @player = new Player opts
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
    $worker.setTimer -> Ping.remoteTime()
    NUU.firstSync opts, -> callback true

  NET.once 'user.login.failed', (opts) ->
    log "Login failed."
    callback false
  connect = (addr) =>
    console.log 'NET.connect', addr
    s = if WebSocket? then new WebSocket addr else new MozWebSocket addr
    @sock = s
    @send = (msg) =>
      NET.TX++ # DEBUG
      s.send msg
    NUU.emit 'connect', s
    s.onmessage = (msg) =>
      NET.RX++ # DEBUG
      @route(s) msg.data
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

# DEBUG
NET.PPS = in:0,out:0,inAvg:new Mean,outAvg:new Mean
NET.TX = 0
NET.RX = 0
$interval 1000, ->
  NET.PPS.outAvg.add NET.PPS.out = NET.TX
  NET.PPS.inAvg.add  NET.PPS.in  = NET.RX
  NET.TX = NET.RX = 0
# DEBUG
