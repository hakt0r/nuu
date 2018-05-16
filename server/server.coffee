console.log """#######################################################################################
#### NUU ### 0.4.71 ### Gordon Cooper - Astronaut - * 3-6 1927 † 10-4 2004 ############
#######################################################################################

    ``````````````,,',,,,,,++#+;::;;;;;;;:;:::::;;;:::::;;;;;;;:##;;;;,``........,,,.
    `````````````.;';:,:;##';;;;;;;::::;::;'+'''''+##';;;:;:::;;##+;;::```..,,....,,,
    ``````````.,,;';:''##;;;;;;;::;'+'''''':,.,.,,,,'+';;;::;;'####::;.`..,;++;,,,.,,
    ```````..:'';'##;;;;;;+#+''''';;:::,,:,......,.,,.,,@@#@@##@####.,.,:'+++';;:,,,,
    `````..,''''##;;;;;+@##'''''''';::,,,,,.,:,,,,...,,,,'@@########+,,,,:::;::,,,,,,
    ````..:'+'##;;;';####+++''''';;;;;:;:,,,,,,,,,,,,,,,,:,+#########.,...,,,,,,,,,::
    ``...;+'+#;';;;+#####++'''''''';;:::,:,,,,,.,,,,,,,;';;;#@#######+..,,,,,,,,,,,,:
    ..,''+@;;;;'+#####+++++'''''';;;;;;:;::::::::::::;;#'+;;'@@@@@@####,.'''''''''';;
    ..+'##:;;;+@@####+++++''''''';;;;;;;;;;;;;;:::;:;;:';;,:;;@##@@#####..+''''''''''
    ,+'#@++@@@#######++++'''''';';;;;;#++''''';;:,..;::,,,,,.''@#@######+..+++'''''''
    +'+#'@@@@@@####++#+++'+'''''++'''''+++++''';:,,,.:::,,,,;.;#@########'..''+''''''
    ++#@;;'':@#####+#+++++'++''''++';;+#''+''';''';;::,......,,'#@#########..;'''';';
    '+#':;:'';######+++++''''''''+';::::,:''';;'';;;;;:,......,;+##@#######+..++''''+
    ''@;',::;;;'###++''''''''''''';;;;;:::;;;;;;;'';;;;;;,.....,+#######+###'..+'''+#
    ;'#';;,:::;;:##++'''''''''''';;;;:::,:;;;;;;';;;';;;;:,.,,,,,#######'+###:..'''''
    :;'#';;;;'::';,#+'''''';;;;;;;;;;::::;;;;;;'''';;''''''',,;:,,+##+####+:##..,';''
    ;:;#;';;'++.:;;,#+'''''';'';;;;;;;;;;;;;;;;'''''''+'';;,.,,;:,,####,+`,.#'..,;'''
    ;;;'@'';'###.,;;,#++''''''';;;;;;;;;';;;;;';;''+'''';,';,,..,:,###+#+'+;#,.,,;;;;
    ;;;;;@;';;#+#`.;;:##+'''''''''';;'';;;;;;'';;;''''';:,,,,:;;:,'++;###@,+,...;::::
    ,,;;:;;#;;;;;;;+'':@#++''''''''''''';;';;;;;';;''';++';:,;;,`+#:#,,,+.....,`,::;;
    ,,,;:;,;;;'#@@@+#'+'##+''''''''''';''';';'';';;''++''';::,,.,+:##+;.`.... `:,:;'+
    ,,..,::::::'@@@@@@,+@##+'++'''''''''''';;''''''##+';;;;;;;;''##:,,,,,,,````:;,;;'
    ......::::,::'#@#@@@@@###@##@@@##@@@@@@#+'++++';''''''++###;:,,,,,,,,.`````...::,
    `..........:::::::,,:::,;+#@@#::,::::::::::;';;:::,,,,,::,,,::..,..``.``,,,..`:;;
    ```.....,.....,;;::::::::,,::::::::::::::::::::::::::::::...:',.,.., `,.:.,` `;;:

#######################################################################################

    * c) 2007-2016 Sebastian Glaser <anx@ulzq.de>
    * c) 2007-2008 flyc0r

    The nuu project intends to use all the asset files according to
    their respective licenses.

    nuu currently uses the graphics and sound assets of the excellent
    naev project, which in turn are partly attributable to the
    Vega Strike project.

    All assets are downloaded from their source repo to the contrib
    folder during the build process and LICENSE information is copied
    to the build directory as well as being made available in the
    client's about screen and the server splash.

    for more information see:
      build/ARTWORK_LICENSE.txt
      build/SOUND_LICENSE.txt

#######################################################################################"""

global.$static   = (name,value) -> global[name] = value
$static.list     = global
global.$library  = (args...) -> for a in args
  if Array.isArray a then global[a[0]] = require a[1] else global[a] = require a
global.$public   = (args...) -> global[a.name] = a for a in args
global.$cue      = (f) -> setImmediate f

$static 'debug',    no
$static 'isClient', no
$static 'isServer', yes

## Load sources
fs = require 'fs'; deps =
  common : JSON.parse fs.readFileSync './common/build.json'
  client : JSON.parse fs.readFileSync './client/build.json'
  server : JSON.parse fs.readFileSync './server/build.json'

for lib in deps.server.require
  if Array.isArray lib
    if lib.length is 3
      $static lib[0], require(lib[1])[lib[2]]
    else $static lib[0], require(lib[1])
  else $static lib, require lib

for lib in deps.common
  require '../build/common/' + lib

for lib in deps.server.sources
  require '../build/server/' + lib + '.js' if lib isnt 'server'

## Initialize express
$static 'app', app = express()

## Initialize WebSockets
ws = require('express-ws') app
app.ws "/nuu", (c, req) ->
  console.log 'ws'.yellow, 'connection'.grey
  c.json = (msg) -> c.send NET.JSON + JSON.stringify msg
  c.on "message", NET.route c
  c.on "error", (e) -> console.log 'ws'.yellow, 'error'.red, e
  # lag and jitter emulation # c.on "message", (msg) -> setTimeout (-> NET.route(c)(msg)), 100 # + Math.floor Math.random() * 40
wss = ws.getWss '/nuu'

NUU.bincast = (data,origin) ->
  wss.clients.map (c) ->
    try c.send data catch error
      Array.remove wss.clients, c

NUU.nearcast = NUU.bincast = (data,o) -> wss.clients.map (c) ->
  if o? and c.handle? and c.handle.vehicle?
    v = c.handle.vehicle
    return unless ( abs abs(v.x) - abs(o.x) ) < 5000 and ( abs abs(v.y) - abs(o.y) ) < 5000
  try c.send data catch error then Array.remove wss.clients, c

NUU.jsoncast = (data) ->
  data = NET.JSON + JSON.stringify data
  wss.clients.map (c) ->
    try c.send data catch error
      Array.remove wss.clients, c

## Sync - queue object-creation notification
$static 'Sync', class Sync
  @adds: []
  @dels: []
  @inst: false

app.on '$obj:add', Sync.add = (obj)->
  Sync.inst = setImmediate Sync.flush unless Sync.inst
  Sync.adds.push obj
  obj

app.on '$obj:del', Sync.del = (obj)->
  Sync.inst = setImmediate Sync.flush unless Sync.inst
  Sync.dels.push obj
  obj

Sync.flush = ->
  NUU.jsoncast sync: add:Sync.adds, del:freeIds = Sync.dels.map (i)-> i.id
  Sync.adds = []; Sync.dels = []; Sync.inst = false
  return unless 0 < freeIds.length
  setImmediate -> $obj.freeId = $obj.freeId.concat freeIds
  null

## Initialize Engine
console.log 'NUU'.yellow, 'initializing'.yellow
NUU.init()

## Setup Webserver
app.use require('morgan')() if debug
app.use require('body-parser') keepExtensions: true, uploadDir: '/tmp/'
app.use require('compression')()
app.use require('cookie-parser')()
app.use require('express-session') secret: 'what-da-nuu'
app.use '/build', require('serve-static')('build',etag:no)
app.use '/build', require('serve-index' )('build',etag:no)

# Skeleton Page
app.get '/', (req,res) ->
  h = []; for n in deps.client.scripts
    h.push """<script src='build/#{n}'></script>"""
  res.send """
    <html><head>
      <title>nuu (v#{$version} - Gordon Cooper)</title>
      <link rel="shortcut icon" href="build/favicon.ico" />
      <link rel="stylesheet" type="text/css" href="build/imag/gui.css"/>
      <script>
        window.deps = JSON.parse('#{JSON.stringify common:deps.common, client:deps.client}')
      </script>
      #{h.join '\n'}
      <meta name="author" content="anx@ulzq.de"/> <meta name="author" content="flyc0r@ulzq.de"/>
      <meta name="keywords" lang="en-us" content="NUU, Sci-Fi, Space, MMORPG, Game, Online, Browsergame, Trade, Economy Simulation"/>
      <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
    </head><body></body></html>"""

app.chgid  = process.env.CHGID || false
app.port   = process.env.PORT  || 9999
app.addr   = process.env.ADDR  || '127.0.0.1'

console.log 'server'.yellow, 'listen'.yellow, app.addr.red + ':' + app.port.toString().blue
app.listen app.port, app.addr, ->
  console.log 'server'.yellow, 'ready'.green, app.addr.red + ':' + app.port.toString().blue
  return unless app.chgid
  process.setgid app.chgid
  process.setuid app.chgid
