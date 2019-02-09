###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2018 flyc0r

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

require('./csmake.coffee')( global.STAGES =

  init: (done) ->
    home = require('os').userInfo().homedir
    global.GAME_DIR  = path.join path.dirname __dirname
    global.MODS_AVAILABLE = fs.readdirSync('mod').sort()

    global.CONF_FILE = (
      if      fs.existsSync p = '/etc/nuu.json'                       then p
      else if fs.existsSync p = path.join home, '.config', 'nuu.json' then p
      else                      path.join GAME_DIR, 'nuu.json' )

    global.CONFIG = JSON.parse fs.readFileSync CONF_FILE
    CONFIG.mod.unshift 'core'
    CONFIG.mod.map (m)-> unless fs.existsSync path.join GAME_DIR, 'mod', m
      console.log m, 'does not exist.'
      process.exit 1

    global.SCRIPTS = {}
    for m in CONFIG.mod when fs.existsSync f = path.join GAME_DIR, 'mod', m, 'build.coffee'
      SCRIPTS[m] = require f

    global.TARGETS = common:{}, server:{}, client:{}, compile:[]

    merge_recursive = (o,merge)-> for k,v of merge
      if ( a = Array.isArray v ) and o[k]? then o[k] = o[k].concat v
      else if not a and typeof v is 'object' and o[k]? then merge_recursive o[k], v
      else o[k] = v
    CONFIG.mod.map (m)->
      return unless fs.existsSync p = path.join GAME_DIR, 'mod', m, 'build.json'
      merge_recursive TARGETS, v = JSON.parse fs.readFileSync p
      for tgt, step of v when step.sources
        for src in step.sources
          TARGETS.compile.push [ path.join(GAME_DIR,'mod',m,tgt,src), tgt ]
      null

    console.log " builds ".yellow.inverse, CONFIG.mod.map( (i)-> i.green ).join ' '
    for tgt, step of TARGETS
      continue if tgt is 'compile'
      for name, values of step
        if Array.isArray values
          console.log " #{tgt} ".yellow.bold, "#{name}".bold, values.map(
            (i)-> if Array.isArray i then i[1].yellow + ":" + i[0].green else i.green
          ).join ' '
        else if name is 'contrib' then for lib, opts of values
             console.log " #{tgt} ".yellow.bold, "#{name}".bold+'/'+lib.bold, opts.name.green, opts.homepage.bold, opts.url
        else console.log " #{tgt} ".yellow.bold, "#{name}".bold, values

    done null

  clean: (c)-> $s [
    rmdir 'build'
   ],c

  dist_clean: (c)-> $s [
    rmdir 'build', 'node_modules','contrib'
   ],c

  dirs: (c)-> mkdir(
    'contrib',
    'build/gfx',
    'build/imag'
    'build/client'
    'build/server'
    'build/common'
   )(c)

  assets: (c)->
    for name,script of SCRIPTS when script.build
      await new Promise script.build
    c null

  node: (c)-> depend(dirs)( ->
    generate('build/release.json',       path.join GAME_DIR,'tools','import_git.coffee')(->)
    generate('build/node_packages.html', path.join GAME_DIR,'tools','import_npm.coffee')(c)
   )

  contrib: (c)-> depend(node)( -> $p (
    fetch 'build/'+lib, data.url for lib, data of TARGETS.client.contrib
   ), c )

  libs: (c)-> depend(dirs)( ->
    if exists 'build/lib.js'
      console.log ' exists '.green.bold, 'build/lib.js'.green
      return c null
    browserify = require('browserify')()
    bundle  = (module) -> browserify.require module, expose : module
    bundle lib for lib in TARGETS.client.libs
    browserify.bundle().pipe(fs.createWriteStream('build/lib.js')).on 'close', -> c null )

  sources: (c)-> depend(libs)( ->
    console.log TARGETS.compile
    $s [
      (c) ->
        fs.writeFileSync path.join('build','build.json'), JSON.stringify TARGETS
        $p ( TARGETS.compile.map (directive)->
          [ source, scope ] = directive
          compile source+'.coffee', path.join('build', scope, path.basename source + '.js' )
        ), c
      (c) ->
        list = []
        # prepend client.js
        TARGETS.common.sources.filter (i) -> list.push 'build/common/' + i + '.js'
        TARGETS.client.sources.filter (i) -> list.push 'build/client/' + i + '.js' if i isnt 'client'
        list.unshift 'build/client/client.js'
        exec("""
          cat #{list.join(' ')} > build/client.js;
          sha512sum build/client.js > build/hashsums
          awk '
          BEGIN{ print "NUU.hash = {" }
               { RS=","; print c "\\"" $2 "\\": \\"" $1 "\\"" }
            END{ print "}" }
          ' build/hashsums >> build/client.js
        """)(c)
    ], c )
  debug:  (c)-> depend(assets)(-> exec("node --debug .")(c))
  run:    (c)-> depend(assets)(-> exec("node . &")(c))
  all:    (c)-> run c
)
