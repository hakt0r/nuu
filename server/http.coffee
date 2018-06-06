###

  This file was ported from express-ws@3.0.0
    https://github.com/HenningM/express-ws

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2008 flyc0r

  Port for NUU:
    Sebastian Glaser <anx@ulzq.de>

  Original Author:
    Henning Morud <henning@morud.org>

  Contributors:
    Jesús Leganés Combarro <piranna@gmail.com>
    Sven Slootweg <admin@cryto.net>
    Andrew Phillips <theasp@gmail.com>
    Nicholas Schell <nschell@gmail.com>
    Max Truxa <dev@maxtruxa.com>
    Kræn Hansen <mail@kraenhansen.dk>

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

ws = require 'ws'
http = require 'http'
express = require 'express'

addWsMethod = (target) ->
  target.ws = addWsRoute unless target.ws?
  return target

addWsRoute = (route, middlewares...) ->
  wrappedMiddlewares = middlewares.map wrapMiddleware
  wsRoute = websocketUrl route
  this.get.apply this, [wsRoute].concat wrappedMiddlewares
  return @

trailingSlash = (string) ->
  string += '/' if '/' isnt string.charAt string.length - 1
  string

wrapMiddleware = (middleware) -> (req, res, next) ->
  if req.ws != null and req.ws != undefined
    req.wsHandled = true
    try middleware req.ws, req, next
    catch err then next err
  else next()

websocketUrl = (url)->
  return "#{trailingSlash(url)}.websocket" if -1 is url.indexOf '?'
  [baseUrl, query] = url.split '?'
  return "#{trailingSlash(baseUrl)}.websocket?#{query}"

wsServer = null
$static '$websocket', (app,options={}) ->
  server = http.createServer app
  app.listen = server.listen.bind server
  addWsMethod app
  addWsMethod express.Router unless options.leaveRouterUntouched
  wsOptions = options.wsOptions || {}
  wsOptions.server = server
  wsServer = $websocket.server = new ws.Server wsOptions
  wsServer.on 'connection', (socket,request)->
    request = socket.upgradeReq if socket.updateReq?
    request.ws = socket
    request.wsHandled = false
    request.url = websocketUrl request.url
    dummyResponse = new http.ServerResponse request
    dummyResponse.writeHead = writeHead = (statusCode) ->
      socket.close() if statusCode > 200
    console.log '::ws', 'connection:pre'.yellow, request.url.yellow if debug
    app.handle request, dummyResponse, -> socket.close() unless request.wsHandled
    null
  app.ws "/nuu", (src, req) ->
    src.json = (msg) -> src.send (NET.JSON + JSON.stringify msg), $websocket.error(src)
    src.on "message", src.router = NET.awaitLogin(src)
    src.on "error", $websocket.error(src)
    # lag and jitter emulation # src.on "message", (msg) -> setTimeout (-> NET.route(src)(msg)), 100 # + Math.floor Math.random() * 40
    console.log '::ws', 'connection'.yellow
    null
  app

$websocket.error = (src)-> (error)-> if error
  console.log '::ws'.red, error
  wsServer.clients.delete src

NET.awaitLogin = (src)-> (msg)->
  unless typeof msg is 'string' and msg[1] is '{'
    console.log ':net', 'pre-login'.red, msg, typeof msg, msg[1]
    return src.close()
  try msg = JSON.parse msg.substr(1) catch e
    console.log ':net', 'pre-login'.red, msg, e.message
    src.close()
  return src.close() unless msg.login?
  console.log ':net', 'pre-login'.yellow, msg if debug
  NET.loginFunction msg.login, src

NUU.bincast = (data,o) ->  wsServer.clients.forEach (src) ->
  src.send data, $websocket.error(src)
  null

NUU.nearcast = NUU.bincast = (data,o) -> wsServer.clients.forEach (src) ->
  if o? and src.handle? and src.handle.vehicle? and o isnt src.handle.vehicle
    v = src.handle.vehicle
    return unless ( abs abs(v.x) - abs(o.x) ) < 5000 and ( abs abs(v.y) - abs(o.y) ) < 5000
  src.send data, $websocket.error(src)
  null

NUU.jsoncast = (data) ->
  data = NET.JSON + JSON.stringify data
  wsServer.clients.forEach (src)-> src.send data, $websocket.error(src)
  null

NUU.jsoncastTo = (v,data) ->
  return unless v.inhabited
  data = NET.JSON + JSON.stringify data
  v.mount.map (user)-> if user and src = user.sock
    console.log '::ws', 'jsoncastTo', v.id, data
    src.send data, $websocket.error(src)
  null

NUU.splashPage = ->
  page = """
<html><head>
  <title>nuu (v#{$version} - Gordon Cooper)</title>
  <link rel="shortcut icon" href="build/favicon.ico" />
  <style>
    @keyframes fadein { 0% { padding: 40px 20px;} 50% { padding: 50px 30px; } 100% { padding: 40px 20px; } }
    @keyframes fadein2 { 0% { box-shadow: 0 0 1px 1px red; } 50% { box-shadow: 0 0 4px 2px red; } 100% { box-shadow: 0 0 1px 1px red; } }
    body { background: #060606; position: relative; }
    * { user-select: none; margin:0; padding:0; color:white; font-size:10px; line-height:16px; font-family:"monospace" !important; }
    p { padding: 10px 0px; }
    .window {
      position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
      overflow-y:auto; overflow-x:hidden; margin:auto; padding:10px 20px; min-width: 50em;
      box-shadow: 0 0 1px 1px #b400ff; background:rgba(0, 0, 0, 0.9); border:solid gray 1px; border-radius:5px; text-align:center; }
    img { user-drag:none; -webkit-user-drag: none; }
    a, a:visited { display:inline-block; padding:5px; color:white; background:rgb(3,3,3); border-radius:4px; font-size:30px; font-weight:bolder; text-decoration:none; }
    a.start,  a.start:visited { box-shadow: 0 0 1px 1px red; display:block;line-height: 30px;border: solid 1px #4d4c4c; width: 465px;margin: auto;transition: 0.1s;animation: fadein2 0.3s; padding: 40px 0px; }
    a.small,  a.small:visited { padding: 4px 7px; width: unset; font-size: 10px; animation: fadein2 0.2s; }
    a:hover,  a.small:hover  { background:rgb(4,12,6); transition: 0.1s; }
    a:active, a.small:active { background:rgba(150,255,150,0.6); color:black; transition: 0.1s; }
            img { user-drag:none; -webkit-user-drag: none; }
    a:hover img { filter: hue-rotate(10deg); transition: 3s; }
  </style>
  <meta name="author" content="anx@ulzq.de"/> <meta name="author" content="flyc0r@ulzq.de"/>
  <meta name="keywords" lang="en-us" content="NUU, Sci-Fi, Space, MMORPG, Game, Online, Browsergame, Trade, Economy Simulation"/>
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
</head><body>
<div class="window full splash" id="splash"><p>
  -------------------------------------------------------------------------------<br/>
  NUU is open-source multiplayer game of space trade and combat.<br/>
  The source-code is available from <a class="small" href="http://hakt0r.de/nuu">hakt0r</a>
  and on <a class="small" href="http://github.com/hakt0r/nuu">github</a><br/>
  -------------------------------------------------------------------------------
</p><p>
  <a class="start" href="start">#{fs.readFileSync('mod/nuu/artwork/logo_2018.svg')}</a>
</p><p>
  -------------------------------------------------------------------------------<br/><br/>
  If you consent to using JavaScript and WebGL, please click the link above.<br/>
  NUU stores no personal data except hashes of your username and password.
</p><p>
  You are seeing this page because <i>-IMHO-</i> JavaScript should be <b>off by default</b>.<br/>
  Just bookmark the link above if you don't want to do this everytime.
</p><p>
  -------------------------------------------------------------------------------<br/>
  &copy; 2007-2018 Sebastian Glaser &lt;anx@ulzq.de&gt; | &copy; 2007-2008 flyc0r<br/>
  -------------------------------------------------------------------------------
</p></div></body></html>"""
  return (req,res) ->
    res.set('Connection', 'close');
    res.set('Cache-Control', 'public, max-age=86400');
    res.send page

NUU.startPage = ->
  page = """<html><head>
  <title>nuu (v#{$version} - Gordon Cooper)</title>
  <link rel="shortcut icon" href="build/favicon.ico" />
  <link rel="stylesheet" type="text/css" href="build/imag/gui.css"/>
  <script>
    window.deps = JSON.parse('#{JSON.stringify common:NUU.deps.common, client:NUU.deps.client}')
  </script>
  #{( """<script src='build/#{n}'></script>""" for n in NUU.deps.client.scripts ).join '\n'}
  <meta name="author" content="anx@ulzq.de"/> <meta name="author" content="flyc0r@ulzq.de"/>
  <meta name="keywords" lang="en-us" content="NUU, Sci-Fi, Space, MMORPG, Game, Online, Browsergame, Trade, Economy Simulation"/>
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
</head><body></body></html>"""
  return (req,res) -> res.send page
