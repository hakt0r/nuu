###

  * c) 2007-2022 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2022 flyc0r

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

NET.on 'e', (message) -> notice 1000, Error.byId[message]
NET.on 'launch',      -> VEHICLE.landedAt = VEHICLE.orbit = null
NET.on 'landed',  (id)->
  vt.hide()
  new Window.DockingMenu VEHICLE.landedAt = $obj.byId[id]

NET.on 'sync', (opts) -> NUU.sync opts
NUU.sync = (list,callback) ->
  if list.del
    for id in list.del when o = $obj.byId[id]
      do o.destructor
  if todo = list.add
    adds = []; back = []; lastLen = NaN
    while lastLen isnt todo.length
      lastLen = todo.length
      for obj in todo
        if o = $obj.byId[obj.id]
          console.log '$obj', 'exists:replace', obj.id if debug
          o.destructor()
        if obj.id isnt 0 and ( s = obj.state ).relto? and not ( s.relto.id? or r = $obj.byId[s.relto] )
          back.push obj
        else
          s.relto = r if r
          adds.push new $obj.byClass[obj.key] obj
      todo = back; back = []
    $obj.select adds         if adds.length > 0
    SyncRequest.addList back if back.length > 0
  else $obj.select yes
  callback null if callback

NET.queryJSON = (opts,callback)->
  p = new Promise (resolve,reject)->
    key = Object.keys(opts)[0]
    clear = ->
      NET.removeListener 'e', onerror
      NET.removeListener key, ondone
    NET.json.write opts
    NET.on key, ondone  = (data)-> do clear; resolve data
    NET.on 'e', onerror =    (e)-> do clear; if reject then reject e else resolve null
  p.then callback
  return p

class NET.Connection
  constructor: (@name,@pass,callback,@register)->
    NET.Connection._.close() if NET.Connection._
    NET.Connection._ = @
    @addr = window.location
      .toString()
      .replace('http','ws')
      .replace(/start/,'')
      .replace(/#.*/,'')
      .replace(/\?.*$/,'')
      .replace(/\/$/,'') + '/nuu'
    @lsalt = String.random 255 + Math.random @pass.length
    NET.removeAllListeners e for e in [
      'user.login.success','user.login.challenge','user.login.register','user.login.failed','user.login.nx' ]
    NET.on 'user.login.success', (opts) =>
      vt.status 'Login', '<i style="color:green">Success</i> [<i style="color:yellow">' + @name + '</i>]'
      await NUU.loginComplete opts
      callback true
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
    NUU.emit 'disconnect', @

  connect: (@addr) =>
    try @close()
    vt.status 'Connecting', '[<i style="color:yellow">'+ @addr + '</i>]'
    console.log ':net', 'connect', @addr
    try s = if WebSocket? then new WebSocket @addr else new MozWebSocket @addr
    catch e then @onerror e
    s.binaryType = 'arraybuffer'
    @connectTimeout = setTimeout ( ->
      s.close() unless s.readyState is 1
    ), 5000
    NET[k] = @[k] for k in [ 'send' ]
    s[k]   = @[k] for k in [ 'onmessage', 'onopen', 'onerror', 'onclose' ]
    NUU.emit 'connecting', @sock = s

  send: (msg) =>
    NET.TX++
    NET.TXB += msg.length
    return do @reconnect if @sock.readyState > 1
    return unless @sock.readyState is 1
    @sock.send msg

  onopen: (e) => $.ajax url: 'build/hashsums', success: (d) =>
    h = {}; d.trim().split('\n').map (i)-> i = i.split /[ \t]+/; h[i[1]] = i[0]
    unless h['build/client.js'] is NUU.hash['build/client.js']
      return window.location = window.location.pathname + '?hash=' + h['build/client.js']
    vt.status "Connected", '[<i style="color:yellow">' + @addr + '</i>]'
    vt.status "Login", "Getting challenge for " + '[<i style="color:yellow">' + @name + '</i>]'
    NET.json.write login: @name
    do @onReconnectSuccessful

  onmessage: (msg) =>
    NET.route @sock, msg.data

  onclose: (e) =>
    log ':net', 'sock:close', e.code, e.message
    NUU.emit 'disconnect', @
    @reconnect @reconnect.underway = no

  onerror: (e) =>
    @sock.close()
    log ':net', 'sock:error', e

  onReconnectSuccessful: (e) =>
    @reconnect.underway = no
    HUD.widget 'reconnect'

  reconnect: (e) =>
    return console.log 'blocked' if @reconnect.underway
    @reconnect.underway = yes
    HUD.widget 'reconnect', 'wait -----'
    setTimeout ( -> HUD.widget 'reconnect', 'wait ❚----' ), 200
    setTimeout ( -> HUD.widget 'reconnect', 'wait ❚❚---' ), 400
    setTimeout ( -> HUD.widget 'reconnect', 'wait ❚❚❚--' ), 600
    setTimeout ( -> HUD.widget 'reconnect', 'wait ❚❚❚❚-' ), 800
    setTimeout ( =>
      HUD.widget 'reconnect', '[***]'
      @connect @addr
    ), 1000

# Stats
NET.PPS =
  in:     0
  out:    0
  inKb:   0
  outKb:  0
  inAvg:  new Mean
  outAvg: new Mean
  inVol:  new Mean
  outVol: new Mean

NET.TXB = NET.TX = 0
NET.RXB = NET.RX = 0

$interval 1000, ->
  NET.PPS.outAvg.add NET.PPS.out   = NET.TX
  NET.PPS.inAvg.add  NET.PPS.in    = NET.RX
  NET.PPS.inVol.add  NET.PPS.inKb  = NET.RXB / 1024
  NET.PPS.outVol.add NET.PPS.outKb = NET.TXB / 1024
  NET.TX = NET.RX = NET.TXB = NET.RXB = 0
  NET.FPS = HUD.frame
  HUD.frame = 0
