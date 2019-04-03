
NUU.emit 'extend'

# ██     ██ ███████ ██████  ███████ ███████ ██████  ██    ██ ███████ ██████
# ██     ██ ██      ██   ██ ██      ██      ██   ██ ██    ██ ██      ██   ██
# ██  █  ██ █████   ██████  ███████ █████   ██████  ██    ██ █████   ██████
# ██ ███ ██ ██      ██   ██      ██ ██      ██   ██  ██  ██  ██      ██   ██
#  ███ ███  ███████ ██████  ███████ ███████ ██   ██   ████   ███████ ██   ██

## Initialize express / setup WebSockets
$websocket NUU.web = express()
## Setup Webserver
NUU.web.use require('morgan')() if debug
# NUU.web.use require('body-parser') keepExtensions: true, uploadDir: '/tmp/'
NUU.web.use require('compression')()
NUU.web.use require('cookie-parser')()
NUU.web.use require('express-session') secret: 'what-da-nuu', saveUninitialized:no, resave:no
NUU.web.use '/build', require('serve-static')('build',etag:no)
NUU.web.use '/build', require('serve-index' )('build',etag:no) if debug
NUU.web.get '/excuse', NUU.splashPage false, true
NUU.web.get '/',       NUU.splashPage false, false
NUU.web.get '/intro',  NUU.splashPage true,  false
NUU.web.get '/start',  NUU.startPage()

# ███████ ███    ██  ██████  ██ ███    ██ ███████
# ██      ████   ██ ██       ██ ████   ██ ██
# █████   ██ ██  ██ ██   ███ ██ ██ ██  ██ █████
# ██      ██  ██ ██ ██    ██ ██ ██  ██ ██ ██
# ███████ ██   ████  ██████  ██ ██   ████ ███████

$static '$release', fs.readJSONSync './build/release.json'
$release.banner = $release.v.green + $release.git.red

NUU.chgid  = process.env.CHGID   || false
NUU.port   = process.env.PORT    || 9999
NUU.addr   = process.env.ADDR    || '127.0.0.1'
BROWSER    = process.env.BROWSER || 'chromium'

console.log ':nuu', 'initializing'.yellow
NUU.init()

console.log 'http', 'listen'.yellow, NUU.addr.red + ':' + NUU.port.toString().magenta
NUU.web.listen NUU.port, NUU.addr, ->
  console.log 'http', 'online'.green, NUU.addr.red + ':' + NUU.port.toString().magenta
  console.log ':nuu', $release.banner
  if process.env.CLIENT
    if BROWSER.match /^chrom[ei]/
      ARGS = ["-app=http://#{NUU.addr}:#{NUU.port}/start"]
    if BROWSER.match /^firefox/
      ARGS = ["http://#{NUU.addr}:#{NUU.port}/start"]
    try cp.spawn BROWSER, ARGS
  if NUU.chgid
    console.log 'http', 'dropping privileges'.green
    process.setgid NUU.chgid
    process.setuid NUU.chgid
  null
