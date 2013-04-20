require 'colors'
fs = require 'fs'
cp = require 'child_process'
path = require 'path'
async = require 'async'
touch = require 'touch'
coffee = require 'coffee-script'
request = require 'request'

####################################################################################################

targets =
  common : JSON.parse fs.readFileSync './common/build.json'
  server : JSON.parse fs.readFileSync './server/build.json'
  client : JSON.parse fs.readFileSync './client/build.json'

make = 

  clean: clean = (c) -> exec """
    rm -rf build
    mkdir -p build contrib
  """, c

  dist_clean: dist_clean = (c) -> clean -> exec """
    rm -rf node_modules contrib
    mkdir -p contrib
  """, c

  naev: naev = (c) -> exec """
    test -f contrib/naev.zip ||
      wget -cO contrib/naev.zip 'https://github.com/bobbens/naev/archive/master.zip'
    test -d contrib/naev-master || {
      sh -c "cd contrib; unzip naev.zip"
    }
    mkdir -p build/stel
    test -f build/ARTWORK_LICENSE.txt || ln -sf ../contrib/naev-master/dat/gfx/ARTWORK_LICENSE build/ARTWORK_LICENSE.txt
    test -f build/SOUND_LICENSE.txt   || ln -sf ../contrib/naev-master/dat/snd/SOUND_LICENSE   build/SOUND_LICENSE.txt
    test -d build/spfx                || ln -sf ../contrib/naev-master/dat/gfx/spfx            build/
    test -d build/ship                || ln -sf ../contrib/naev-master/dat/gfx/ship            build/
    test -d build/outfit              || ln -sf ../contrib/naev-master/dat/gfx/outfit          build/

    find \
      contrib/naev-master/dat/gfx/planet/space \
      contrib/naev-master/dat/gfx/bkg \
      -type f | while read file; do
        ln -sf "../../$file" build/stel/
      done

    test -d build/sounds          || ln -sf ../contrib/naev-master/dat/snd/sounds              build/
    test -f build/objects.json ||
      coffee tools/import_naev.coffee > build/objects.json
  """, c

  node: node = (c) ->
    o = '<ul class="libs">'
    d = JSON.parse fs.readFileSync 'package.json', 'utf8'
    for lib, data of targets.client.contrib
      o += """
        <li><a target="_new" href="#{data.homepage}">#{data.name} (build/#{lib})</a><span class="version">master/git<span></li>
      """
    for k in fs.readdirSync 'node_modules'
      if fs.existsSync 'node_modules/' + k + '/package.json'
        rec = JSON.parse fs.readFileSync 'node_modules/' + k + '/package.json'
        v = rec.version
      else if d.dependencies[k] then v = d.dependencies[k]
      else continue
      o += """<li><a target="_new" href="https://www.npmjs.com/package/#{k}">#{k}</a>"""
      o += """<span class="version">#{v}</span>"""
      # o += """<span class="description">#{rec.description}</span>""" if rec.description
      o += "</li>"
    o += '</ul>'
    fs.writeFileSync 'build/node_packages.html', o
    c null

  contrib: contrib = (c) -> node -> naev ->
    list = []
    list.push fetch data.url, 'build/'+lib for lib, data of targets.client.contrib
    async.parallel list, c

  sources: sources = (c) ->
    exec """
      mkdir -p build/client
      mkdir -p build/server
    """, ->
      list = []
      list.push compile 'common/'+lib+'.coffee', 'build/'+lib+'.js'        for lib in targets.common
      list.push compile 'client/'+lib+'.coffee', 'build/client/'+lib+'.js' for lib in targets.client.sources
      list.push compile 'server/'+lib+'.coffee', 'build/server/'+lib+'.js' for lib in targets.server.sources
      async.parallel list, c

  deps: deps = (c) -> contrib -> sources -> exec """
    mkdir -p build/imag
    find client/gfx -type f | while read file; do
      ln -sf "../../$file" build/imag/
    done
    rm build/imag/gui.css
      ln -sf "../client/gfx/gui.css" build/
  """, c

  run: run = (c) -> deps -> exec """
    coffee server/server.coffee
  """, c

  debug: debug = (c) -> deps -> exec """
    coffee --nodejs debug server/server.coffee
  """, c

  all: all = (c) -> run -> console.log 'DONE'

####################################################################################################

process.chdir path.dirname __dirname

fetch = (src,dst) -> (c) ->
  if not fs.existsSync dst
    console.log 'fetch', dst, dst, src
    request.get(src).pipe(fs.createWriteStream dst)
  else console.log 'ok'.green, dst
  c null

compile = (src,dst) -> (c) ->
  return c null unless src.match /\.coffee$/
  return c null if ( stat = fs.statSync(src) ).isDirectory()
  if fs.existsSync(dst)
    if ( dstat = fs.statSync(dst) )
      if stat.mtime.toString().trim() is dstat.mtime.toString().trim()
        console.log 'up-todate:'.green, src.yellow, ( dstat || mtime: null ).mtime
        return c null
  console.log 'compile:'.red, src.yellow, stat.mtime, ( dstat || mtime: null ).mtime
  fs.writeFileSync dst, coffee.compile fs.readFileSync( src, 'utf8')
  touch.sync dst, ref: src
  c null

exec = (cmd,c) ->
  console.log cmd.grey
  cp.spawn( 'sh', [ '-c', cmd ], stdio: 'inherit' ).on 'close', ->
    c null

process.argv.shift()
process.argv.shift()
make[process.argv[0] || 'all'] ->
