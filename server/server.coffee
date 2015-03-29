console.log """
  ###
    ## NUU # drake
  ###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2008 flyc0r

  The nuu project intends to use all the asset files according to
  their respective licenses.

  nuu currently uses the graphics and sound assets of the excellent
  naev project, which in turn are partly attributable to the
  Vega Strike project.

  All assets are downloaded from their source repo to the contrib
  folder during the build process and LICENSE information is copied
  to the build directory as well as bein made available in the
  client's about screen and the server splash.

  for more information see:
    build/ARTWORK_LICENSE.txt
    build/SOUND_LICENSE.txt
"""

global.$static   = (name,value) -> global[name] = value
$static.list     = global
global.$library  = (args...) -> for a in args
  if Array.isArray a then global[a[0]] = require a[1] else global[a] = require a
global.$public   = (args...) -> global[a.name] = a for a in args
global.$cue      = (f) -> setImmediate f

$static 'isClient', no
$static 'isServer', yes

$library 'colors', 'fs', 'crypto', 'express', ['_','underscore'], ['UglifyJS',"uglify-js"]
$static 'browserify',   require('browserify')()
$static 'EventEmitter', require('events').EventEmitter
$static 'sha512', (str) -> crypto.createHash('sha512').update(str).digest 'hex'

## Initialize express
$static 'app', app = express()

## Load sources

app.deps =
  common : JSON.parse fs.readFileSync './common/build.json'
  client : JSON.parse fs.readFileSync './client/build.json'
  server : JSON.parse fs.readFileSync './server/build.json'

require '../build/common/' + lib          for lib in app.deps.common
require '../build/server/'  + lib + '.js' for lib in app.deps.server.sources when lib isnt 'server'

## Initialize WebSockets

ws = require('express-ws') app
app.ws "/nuu", (c, req) ->
  console.log 'ws'.yellow, 'connection'.grey
  c.json = (msg) -> c.send NET.JSON + JSON.stringify msg
  c.on "message", NET.route(c)
  c.on "error", (e) -> console.log 'ws'.yellow, 'error'.red, e
  # lag and jitter emulation # c.on "message", (msg) -> setTimeout (-> NET.route(c)(msg)), 100 # + Math.floor Math.random() * 40
wss = ws.getWss '/nuu'

NUU.bincast = (data,origin) ->
  c.send data for c in wss.clients

NUU.nearcast  = (data,o) ->
  wss.clients.map (c) -> if Math.abs(c.x) - Math.abs(o.x) < 5000 and Math.abs(c.y) - Math.abs(o.y) < 5000
    c.send data

NUU.jsoncast = (data) ->
  data = NET.JSON + JSON.stringify data
  c.send data for c in wss.clients

## Sync - queue object-creation notification

$static 'Sync', ( ->
  list = []
  inst = false
  cue = (obj)->
    list.push obj
    inst = setImmediate flush unless inst
    obj
  flush =->
    NUU.jsoncast sync: list
    list = []
    inst = false
  cue.flush = flush
  return cue )()

app.on '$obj:add', (o)->
  #console.log 'sync::', o.id, o.constructor.name, o.name
  Sync o

## Initialize Engine

console.log 'NUU'.yellow, 'initializing'.yellow
NUU.init()

## Setup Webserver

app.use require('morgan')()
app.use require('body-parser') keepExtensions: true, uploadDir: '/tmp/'
app.use require('compression')()
app.use require('cookie-parser')()
app.use require('express-session') secret: 'what-da-nuu'

app.use '/build', require('serve-static')('build',etag:no)
app.use '/build', require('serve-index' )('build',etag:no)

## Skeleton Page

app.bundle  = (module) -> browserify.require module, expose : module
app.include = (path)   -> app.deps.client.scripts.push path

app.get '/', (req,res) ->
  h = []; for n in app.deps.client.scripts
    h.push """<script src='build/#{n}'></script>"""
  res.send """
    <html><head>
      <title>nuu v#{$version} (drake, francis)</title>
      <link rel="shortcut icon" href="build/favicon.ico" />
      <link rel="stylesheet" type="text/css" href="build/imag/gui.css"/>
      <script>
        window.deps = JSON.parse('#{JSON.stringify common:app.deps.common, client:app.deps.client}')
      </script>
      #{h.join '\n'}
      <meta name="author" content="anx@ulzq.de"/> <meta name="author" content="flyc0r@ulzq.de"/>
      <meta name="keywords" lang="en-us" content="NUU, Sci-Fi, Space, MMORPG, Game, Online, Browsergame, Trade, Economy Simulation"/>
      <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
    </head><body></body></html>"""

console.log 'server'.yellow, 'ready'.green
app.listen 9999
