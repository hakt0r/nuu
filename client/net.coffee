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

NET.login = (name, pass, callback, register=no) ->
  console.log ':net', 'login', name if debug
  new NET.Connection name, pass, callback, register
NET.register = (name, pass, callback) -> NET.login name, pass, callback, yes

NET.on 'sync', (opts) -> NUU.sync opts

NUU.sync = (list,callback) ->
  if list.del
    do o.destructor for id in list.del when o = $obj.byId[id]
  if list.add then for obj in list.add
    if o = $obj.byId[obj.id]
      console.log '$obj', 'exists:replace', obj.id if debug
      o.destructor()
    new $obj.byClass[obj.key] obj
  callback null if callback

NUU.firstSync = (opts,callback)->
  @player = new User opts
  Sprite.start => @start callback

class NET.Connection
  constructor: (@name,@pass,callback,@register)->
    NET.Connection._.close() if NET.Connection._
    NET.Connection._ = @
    @addr = window.location.toString().replace('http','ws').
      replace(/#.*/,'').replace(/\/$/,'') + '/nuu'
    @lsalt = String.random 255 + Math.random @pass.length
    NET.removeAllListeners 'user.login.success'
    NET.removeAllListeners 'user.login.challenge'
    NET.removeAllListeners 'user.login.register'
    NET.removeAllListeners 'user.login.failed'
    NET.removeAllListeners 'user.login.nx'
    NET.on 'user.login.success', (opts) =>
      vt.status 'Login', '<i style="color:green">Success</i> [<i style="color:yellow">' + @name + '</i>]'
      NUU.firstSync opts, => callback true
      NUU.emit 'connect', @
    NET.once 'user.login.failed', (opts) =>
      vt.status 'Login', '<b style="color:red">Failed</b> [<i style="color:yellow">' + @name + '</i>]'
      callback false
    NET.on 'user.login.nx', (opts) =>
      if @register
        vt.status 'Register', '<i style="color:green">Name is free</i> [<i style="color:yellow">' + @name + '</i>] :)'
        @rsalt = String.random 255 + Math.random @pass.length
        pass = sha512 [ @rsalt, @pass ].join ':'
        NET.json.write login: user:@name, pass: pass:pass,salt:@rsalt
      else
        vt.status 'Login failed', '<b style="color:red">Wrong name / password.</b>'
        callback false
    NET.on 'user.login.challenge', (opts) =>
      vt.status 'Login', 'Got challenge, sending response.'
      pass = sha512 [ @lsalt, sha512 [ opts.salt, @pass ].join ':' ].join ':'
      NET.json.write login: user:@name, pass: pass:pass,salt:@lsalt
    NET.on 'user.login.register', (opts) =>
      vt.status 'Register', 'Success.'
      @lsalt = String.random 255 + Math.random @pass.length
      pass = sha512 [ @lsalt, sha512 [ @rsalt, @pass ].join ':' ].join ':'
      NET.json.write login: user:@name, pass: pass:pass,salt:@lsalt
    @connect @addr

  close: =>
    try @sock.close()
    NUU.emit 'disconnected', @

  connect: (@addr) =>
    vt.status 'Connecting', '[<i style="color:yellow">'+ @addr + '</i>]'
    console.log ':net', 'connect', @addr
    s = if WebSocket? then new WebSocket @addr else new MozWebSocket @addr
    NET[k] = @[k] for k in [ 'send' ]
    s[k]   = @[k] for k in [ 'onmessage', 'onopen', 'onerror' ]
    NUU.emit 'connecting', @sock = s

  send: (msg) =>
    NET.TX++
    return do @reconnect if @sock.readyState >= @sock.CLOSING
    return if @sock.readyState isnt @sock.OPEN
    @sock.send msg

  onopen: (e) =>
    vt.status "Connected", '[<i style="color:yellow">' + @addr + '</i>]'
    vt.status "Login", "Getting challenge for " + '[<i style="color:yellow">' + @name + '</i>]'
    NET.json.write login: @name

  onmessage: (msg) =>
    NET.route @sock, msg.data

  onerror: (e) =>
    console.log ':net', 'sock:error', e
    NUU.emit 'disconnect'

  reconnect: (e) =>
    setTimeout ( => @connect @addr ), 5000

# Stats
NET.PPS = in:0,out:0,inAvg:new Mean,outAvg:new Mean
NET.TX = 0
NET.RX = 0
$interval 1000, ->
  NET.PPS.outAvg.add NET.PPS.out = NET.TX
  NET.PPS.inAvg.add  NET.PPS.in  = NET.RX
  NET.TX = NET.RX = 0
