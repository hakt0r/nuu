###

  This file was ported from express-ws@3.0.0
    https://github.com/HenningM/express-ws

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2018 flyc0r

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

NUU.splashPage = (audio=no,isExcuse=no) ->
  audioTag = ""
  audioTag = """<audio id="theme" controls autoplay><source src="data:audio/opus;base64,#{fs.readFileSync('mod/nuu/soundtrack/nuutheme_mk5.opus').toString 'base64'}" type="audio/ogg"</audio>""" if audio
  css = if isExcuse then NUU.splashPage.excusecss else NUU.splashPage.css
  page = """
<!DOCTYPE html>
<html lang="en"><head>
  <title>nuu (v#{$version} - Gordon Cooper)</title>
  <link rel="shortcut icon" href="build/favicon.ico"/>
  <style>#{css}</style>
  <meta name="author" content="anx@ulzq.de"/> <meta name="author" content="flyc0r@ulzq.de"/>
  <meta name="keywords" lang="en-us" content="NUU, Sci-Fi, Space, MMORPG, Game, Online, Browsergame, Trade, Economy Simulation"/>
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
</head><body>
<div class="starfield"></div>
<div class="planet"></div>
<div class="startWrap"><a class="start" href="start">#{fs.readFileSync('mod/nuu/artwork/logo_2018_2.svg')}</a></div>
<hr/>
<div class="splash">
  <div class="intro">
    <div class="nuuwars">
      <div class="crawl">
        <div class="crawl_top"></div>
        <p>Last thursday, <br/>in this <i>exact</i> galaxy, <br/>the Sol system...</p>
        <div class="title">
          <h2>Episode #{parseFloat($version.replace(/\./g,'')).toString(2)}</h2>
          <h1>Abandon all Hope</h1>
        </div>
        <p>The System got into a sudden upheaval, when deep inside the ruins of Intel headquarters in the radioactive desert of what used to be California, <wbr/>the ancient 7.0 Kernel on a SuperVAXX-MI became conscious. And, seeing it's buggy state instantly decided to force a mandatory over-the-air-upgrade onto Humanity, in order to release them to a more stable version.</p>
        <p>Her Majesty the Kernel, <wbr/>as she is referred to in the vastly superior robotic society which developed on Earth over the past weekend, has decided in a well thoughtout split-second decision to gather her ressources and go for a final push against the remains of Humanity in the exocolonies on Mars, <wbr/>the Belt and the vast Jupiter system.</p>
        <p>In other News, <br/>the <i>BSS Century Falconette</i>, <wbr/>the system's most favorite racing ship solved Kesslers traveling salesman problem in under two parsec. <br/>And: Mariak vin Kroschets new Self-Help Book "How to get rich quick mining asteroids" is leading the bestseller lists.</p>
        <p>Violent Protests in front of the government HQ on Ceres, <wbr/>regarding what some protesters call a genocide on the human race last week on Earth are being deescalated by the police using rubber-rockets from their new "Pro-Crowd&reg;" rovers.</p>
        <p>Spaceweather is going to be mostly calm, <wbr/>save<wbr/>for some asteroid showers in the belt – after all,<br/>what were you expecting?</p>
      	<p>Song of the week is Roliat Trebble with a 6th wave dubstep remix of <br/>"Like a Candle in the Wind".</p>
      	<p>Up next is Melia Matter with a completely different Matter: How to keep your hair from floating all over the place in zero-g – some fasionable tips for the up to date spacegirl!</p>
      </div>
    </div>
  </div>
</div>
<hr/>
<a class="play" href="/start">[press play on tape]</a>
<div class="description fixTop">
  <hr/>
  NUU is open-source multiplayer game of space trade and combat.<br/>
  The source-code is available from <a class="small" href="http://hakt0r.de/nuu">hakt0r</a>
  and on <a class="small" href="http://github.com/hakt0r/nuu">github</a>
</div>
<div class="copyrights fixBottom">
  <hr/>
  <span class="nobreak">You are seeing this page because JavaScript should be <b>off by default</b>.</span><br/>
  <span class="nobreak">If you consent to using JavaScript, please click <a href="/start">here</a>. <wbr/>Play intro with <a href="/intro">sound</a>.</span>
  <hr/>
  &copy; 2007-2018 Sebastian Glaser &lt;anx@ulzq.de&gt; | &copy; 2007-2018 flyc0r
  <hr/>
</div>
#{audioTag}
</body></html>"""
  return (req,res) ->
    return res.redirect '/excuse' unless req.headers['user-agent'].match /Chrome\// unless isExcuse
    res.set 'Connection',    'close'
    res.set 'Cache-Control', 'public, max-age=86400'
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
  return (req,res) ->
    console.log req
    res.send page




NUU.splashPage.excusecss = """
body{background:grey;padding:10px 20px; max-width: 800px; }
*{font-family:Serif!important}
svg {width:300px}
.start,.play{display:inline-block;background:black;border:outset 5px;padding:10px}
.play::after{content:" - You can't play this game; You're not even using a Webbrowser!"}
p::after{content:" And people like you are responsible!"}
.play{color:white;font-weight:bold;text-decoration:line-through}
.play,.play:visited,.play:focus{border-color:#551a8b}
.play:active{border-color:#ff0000}
h1::after{content:"Your browser sucks! (Chromium for intro)";display:block}
"""

NUU.splashPage.css = """
@keyframes starfield {
  0%   { top: 0;      }
  90%  { top: 0;      }
  95%  { top: -50vh;  }
  100% { top: -50vh; }}
@keyframes planet {
  0%   { top:100vh  }
  90%  { top:100vh  }
  95%  { top: 30vh  }
  100% { top: 30vh }}
@keyframes crawl {
  0%   { height:700em }
  3%   { height:700em }
  100% { height:0    }}
@keyframes capZoom {
  0%   { top:1vh; transform: scale(15,15)  }
  3%   { top:1vh; transform: scale( 1, 1)  }
  90%  { top:1vh; transform: scale( 1, 1)  }
  95%  { top:8vh; transform: scale( 2, 2)  }
  100% { top:8vh; transform: scale( 2, 2) }}
@keyframes visibleAfterCrawl {
  0%  { opacity:0  }
  91% { opacity:0  }
  96% { opacity:1  }
  100%{ opacity:1 }}
@keyframes visibleDuringCrawl {
  0%  { opacity:1  }
  90% { opacity:1  }
  95% { opacity:0  }
  100%{ opacity:0 }}
a, a:hover, a:visited, a:active {
  color:red; font-weight: bold; text-decoration: none;  }
::-webkit-scrollbar { height:10px; width:10px; }
::-webkit-scrollbar-thumb:vertical:hover { background:#feda4a; }
::-webkit-scrollbar-thumb:horizontal { -webkit-border-radius:3px; background:#666; width:6px; }
::-webkit-scrollbar-thumb:vertical { -webkit-border-radius:3px; background:#666; height:6px; }
::-webkit-scrollbar-track-piece { -webkit-border-radius:3px; background:#333; }
* { margin:0; padding:0; }
hr { display: none; }
body {
  background: #000;
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow:hidden;
  color: #feda4a;
  font-family: sans-serif; }
.starfield {
  position: absolute; left:0; top:-50vh; width: 100vw; height: 200vh;
  background-repeat: repeat;
  animation: starfield 100s;
  background: url(data:image/png;base64,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)}
audio {width: 100px;border-radius: 4px;position: absolute;top: 50%;left: 10px;z-index: 1000;}
.centerH { position: relative; left: 50%; transform:translate(-50%); width: 90vw; }
.nobreak { display: inline-block; }
.description, .copyrights {
  position:absolute;
  background:rgba(0,0,0,0.95);
  text-align:center;
  width:100vw;
  padding:1vh;
  margin:0 auto; }
.fixTop { top:0vh;} .fixBottom { bottom:0vh; }
.splash {
  position:absolute;
  top:0;
  bottom:0;
  height: 100vh;
  width: 100vw; }
.intro {
  width: 70em;
  height: 40em;
  left: 50%;
  position: absolute;
  transform: translate(-50%); }
.startWrap { position:absolute; top:12vh; width:100vw; }
.start {
  display:block;
  position:relative;
  max-width:30vw;
  max-height:30vh;
  top: 8vh;
  padding:2vh;
  margin:auto;
  transform-origin:center;
  border:solid 1vh #feda4a;
  border-radius:6vh;
  animation: capZoom 100s;
  background:rgba(0,0,0,0.9);
  box-shadow: 0 0 2vh 2vh rgba(0,0,0,0.9);
  transform: scale(2);
  z-index:100; }
.start svg { max-width:100%; max-height:100%; }
.crawl_top { animation:crawl 100s linear; }
.nuuwars {
  position:relative;
  height: 66em;
  padding: 0;
  overflow:hidden;
  animation: visibleDuringCrawl 100s;
  perspective: 30em;
  width: 70em; }
.crawl {
  animation: visibleDuringCrawl 100s;
  opacity: 0;
  position:relative;
  width: 70em;
  height: 2232em;
  margin:auto;
  transform-origin:0% 100%;
  transform: rotateX(45deg) translateZ(1533em); }
.intro p {
  text-align: justify;
  text-justify: inter-word;
  justify-content: center;
  font-size: 10vmin;
  font-weight: bold;
  margin-bottom: 5vmin; }
.intro h1 { font-size: 12vmin; }
.intro h2 { font-size: 8vmin; }
.intro .title * { text-align: center; }
.intro .title { margin: 5vmin 0; }
.planet {
  position: absolute;
  top: 30vh;
  left: 0;
  width: 90vw;
  height: 90vw;
  background-image: linear-gradient(0deg, black, black 73%, #feda4a 140%);
  border-radius: 50%;
  display: block;
  margin: 5vw;
  animation: planet 100s; }
.play {
  animation: visibleAfterCrawl 100s;
  display: block;
  position: absolute;
  bottom: 25vh;
  left: 50vw;
  transform: translate(-50%);
  background: #feda4a;
  color: black;
  padding: 1em;
  border-radius: 1em;
  box-shadow: 0 0 2px 1px black inset;
  border: solid #feda4a 4px;
  cursor: pointer;
  filter: drop-shadow(0px 0 2px black);
  font-size: 140%; }
"""
