
global.$static   = (name,value) -> global[name] = value
$static.list     = global
global.$library  = (args...) -> for a in args
  if Array.isArray a then global[a[0]] = require a[1] else global[a] = require a
global.$public   = (args...) -> global[a.name] = a for a in args
global.$cue      = (f) -> setImmediate f

$static 'debug',    no
$static 'isClient', no
$static 'isServer', yes
BROWSER = process.env.BROWSER || 'chromium'

## Load sources
$cp = require 'child_process'
$fs = require 'fs'

deps =
  common : JSON.parse $fs.readFileSync './common/build.json'
  client : JSON.parse $fs.readFileSync './client/build.json'
  server : JSON.parse $fs.readFileSync './server/build.json'

for lib in deps.server.require
  if Array.isArray lib
    if lib.length is 3
      $static lib[0], require(lib[1])[lib[2]]
    else $static lib[0], require(lib[1])
  else $static lib, require lib

## Initialize express
$static 'app', app = express()
$static 'coffee', coffee = require 'coffeescript'

## Setup Webserver
app.use require('morgan')('combined',{})
app.use require('body-parser').urlencoded keepExtensions: true, uploadDir: '/tmp/', limit: '1mb', extended:true
app.use require('compression')()
app.use require('cookie-parser')()
app.use '/shader', express.static('mod/nuu/shader',etag:yes)

express.static.mime.define({'text/html': ['frag','vert']});

app.post '/upload/:name', (req,res)->
  out = $fs.createWriteStream 'build/imag/' + req.params.name
  req.pipe out
  req.on 'end', ->
    console.log 'upload'.green, req.params.name
    # $cp.spawn 'feh', ['build/imag/' + req.params.name]
    res.end()

app.get '/', (req,res) ->
  res.set 'Content-Type', 'text/html'
  res.send $fs.readFileSync 'mod/nuu/render.html'

scriptfile = (n)-> app.get '/'+n+'.js', (req,res) ->
  res.set 'Content-Type', 'text/javascript'
  if $fs.existsSync 'mod/nuu/'+n+'.coffee'
       res.send coffee.compile( $fs.readFileSync('mod/nuu/'+n+'.coffee').toString 'utf8' )
  else res.send $fs.readFileSync 'mod/nuu/'+n+'.js'

pngfile = (n)-> app.get '/'+n+'.png', (req,res) ->
  res.set 'Content-Type', 'image/png'
  res.send $fs.readFileSync 'mod/nuu/'+n+'.png'

scriptfile n for n in ['stargen','three','spritegen']
pngfile    n for n in ['star_spectrum']

app.get '/quit', (req,res)->
  $cp.spawnSync 'pkill', ['-f','Xephyr']
  res.end()

app.listen 9998, ->
  console.log 'sysgen-server:9998'.yellow, 'ready'.green
  return
  p = $cp.spawnSync 'rm',['-f','/tmp/.X84-lock'], stdio:'inherit'
  p = $cp.spawn 'Xephyr',['-screen','820x820',':84'], stdio:'inherit'
  setTimeout ( ->
    p = $cp.spawn BROWSER,['--temp-profile','--app=http://localhost:9998/'], stdio:'inherit', env: DISPLAY:':84'
    p.on 'close', -> process.exit 0
  ), 1000
