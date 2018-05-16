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
      NET.login user, pass, (success) =>
        return @login user, pass  if typeof success is 'object'
        return @loginPrompt() unless success

String.random = (length) ->
  text = ''; i = 0
  text += String.fromCharCode floor 80 + 36 * random() while i++ < length
  text

class NET.Connection
  constructor: (@name,@pass,callback)->
    @addr = window.location.toString().replace('http','ws').
      replace(/#.*/,'').replace(/\/$/,'') + '/nuu'
    @lsalt = String.random 255 + Math.random @pass.length
    NET.on 'user.login.success', (opts) =>
      log "Login successful."
      $worker.setTimer => Ping.remoteTime()
      NUU.firstSync opts, => callback true
      NUU.emit 'connect', @
    NET.once 'user.login.failed', (opts) =>
      log "Login failed."
      callback false
    NET.on 'user.login.nx', (opts) =>
      @rsalt = String.random 255 + Math.random @pass.length
      pass = sha512 [ @rsalt, @pass ].join ':'
      log "User unexistant. Registering credentials for", @name
      NET.json.write login: user:@name, pass: pass:pass,salt:@rsalt
    NET.on 'user.login.challenge', (opts) =>
      pass = sha512 [ @lsalt, sha512 [ opts.salt, @pass ].join ':' ].join ':'
      NET.json.write login: user:@name, pass: pass:pass,salt:@lsalt
    NET.on 'user.login.register', (opts) =>
      log "Registered. Re-sending credentials for", @name
      @lsalt = String.random 255 + Math.random @pass.length
      pass = sha512 [ @lsalt, sha512 [ @rsalt, @pass ].join ':' ].join ':'
      NET.json.write login: user:@name, pass: pass:pass,salt:@lsalt
    @connect @addr
  connect: (@addr) =>
    console.log 'NET.connect', @addr
    s = if WebSocket? then new WebSocket @addr else new MozWebSocket @addr
    NET[k] = @[k] for k in [ 'send' ]
    s[k]   = @[k] for k in [ 'onmessage', 'onopen', 'onerror' ]
    NUU.emit 'connecting', @sock = s
  send: (msg) =>
    NET.TX++
    return @connect @addr if @sock.readyState >= @sock.CLOSING
    return if @sock.readyState isnt @sock.OPEN
    @sock.send msg
  onopen: (e) =>
    log "Connected. Getting challenge for #{@name}"
    NET.json.write login: @name
  onmessage: (msg) =>
    NET.route @sock, msg.data
  onerror: (e) =>
    console.log "NET.sock:error", e
    NUU.emit 'disconnect'
    setTimeout ( => @connect @addr ), 1000

NET.login = (name, pass, callback) ->
  return console.log 'NOT IMPLEMENTED' if NET.Connection._?
  console.log 'NET.login', name
  NET.Connection._ = new NET.Connection name, pass, callback

# Stats
NET.PPS = in:0,out:0,inAvg:new Mean,outAvg:new Mean
NET.TX = 0
NET.RX = 0
$interval 1000, ->
  NET.PPS.outAvg.add NET.PPS.out = NET.TX
  NET.PPS.inAvg.add  NET.PPS.in  = NET.RX
  NET.TX = NET.RX = 0
