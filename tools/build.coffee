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


require('./csmake.coffee')(

  init: (c) ->
    global.NUUWD = path.join path.dirname __dirname
    global.targets =
      common : JSON.parse fs.readFileSync './common/build.json'
      server : JSON.parse fs.readFileSync './server/build.json'
      client : JSON.parse fs.readFileSync './client/build.json'
    c null

  clean: (c)-> $s [
    rmdir 'build'
   ],c

  dist_clean: (c)-> $s [
    rmdir 'build', 'node_modules','contrib'
   ],c

  dirs: (c)-> mkdir(
    'contrib',
    'build/stel',
    'build/imag'
    'build/client'
    'build/server'
    'build/common'
   )(c)

  assets: (c)->
    dirs = fs.readdirSync('mod')
    series = []
    # fetch 'contrib/fontawesome.zip', 'https://use.fontawesome.com/releases/v5.0.13/fontawesome-free-5.0.13.zip'
    # unzip 'contrib/fontawesome.zip', 'contrib/fontawesome'
    # link  'contrib/fontawesome/web-fonts-with-css',     'build/fontawesome'
    series.push require f for d in dirs when fs.existsSync f = path.join NUUWD, 'mod', d, 'build.coffee'
    $s series, ->
      console.log 'done'
      c null

  node: (c)-> depend(dirs)( ->
    # generate('build/git_history.html',   path.join NUUWD,'tools','import_git.coffee')(->)
    generate('build/node_packages.html', path.join NUUWD,'tools','import_npm.coffee')(c)
   )

  contrib: (c)-> depend(node)( -> $p (
    fetch 'build/'+lib, data.url for lib, data of targets.client.contrib
   ), c )

  libs: (c)-> depend(dirs)( ->
    if exists 'build/lib.js'
      console.log ':bld', 'build/lib.js'.green
      return c null
    browserify = require('browserify')()
    bundle  = (module) -> browserify.require module, expose : module
    bundle lib for lib in targets.client.libs
    browserify.bundle().pipe(fs.createWriteStream('build/lib.js')).on 'close', ->
      c null )

  sources: (c)-> depend(libs)( ->
    $s [
      (c) ->
        list = []
        list.push compile 'common/'+lib+'.coffee', 'build/common/'+lib+'.js' for lib in targets.common
        list.push compile 'client/'+lib+'.coffee', 'build/client/'+lib+'.js' for lib in targets.client.sources
        list.push compile 'server/'+lib+'.coffee', 'build/server/'+lib+'.js' for lib in targets.server.sources
        $p list, c
      (c) ->
        list = []
        targets.common.filter (i) -> list.push 'build/common/' + i + '.js'
        targets.client.sources.filter (i) -> list.push 'build/client/' + i + '.js'
        list.unshift list.pop()
        exec('cat ' + list.join(' ') + ' > build/client.js')(c)
    ], c )

  sysgen: (c)-> depend(assets)(-> exec("coffee mod/nuu/sysgen.coffee")(c))
  debug:  (c)-> depend(assets)(-> exec("coffee --nodejs debug server/server.coffee")(c))
  run:    (c)-> depend(assets)(-> exec("coffee server/server.coffee &")(c))
  all:    (c)-> run c
)
