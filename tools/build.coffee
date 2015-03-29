###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
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

  naev: (c) -> depend(dirs)( -> $s [
    fetch       'contrib/naev.zip', 'https://github.com/bobbens/naev/archive/master.zip'
    unzip       'contrib/naev.zip', 'contrib/naev-master'
    link        'contrib/naev-master/dat/gfx/ARTWORK_LICENSE', 'build/ARTWORK_LICENSE.txt'
    link        'contrib/naev-master/dat/snd/SOUND_LICENSE',   'build/SOUND_LICENSE.txt'
    link        'contrib/naev-master/dat/gfx/spfx',            'build/spfx'
    link        'contrib/naev-master/dat/gfx/ship',            'build/ship'
    link        'contrib/naev-master/dat/gfx/outfit',          'build/outfit'
    link        'contrib/naev-master/dat/snd/sounds',          'build/sounds'
    linkFilesIn 'contrib/naev-master/dat/gfx/bkg',             'build/stel'
    linkFilesIn 'contrib/naev-master/dat/gfx/bkg/star',        'build/stel'
    linkFilesIn 'contrib/naev-master/dat/gfx/planet/space',    'build/stel'
    generate    'build/objects.json',                          'import_naev.coffee'
   ],c )

  node: (c)-> depend(dirs)( ->
    generate('build/node_packages.html','import_npm.coffee')(c)
   )

  contrib: (c)-> depend(node,naev)( -> $p (
    fetch 'build/'+lib, data.url for lib, data of targets.client.contrib
   ), c )

  libs: (c)-> depend(dirs)( ->
    if exists 'build/lib.js'
      console.log 'build/lib.js'.green
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

  assets: (c)-> depend(contrib,sources)( -> $s [
    mkdir 'build/imag'
    linkFilesIn 'client/gfx', 'build/imag'
    (c) ->
      list = {}
      read = (dir)->
        for file in fs.readdirSync dir
          p = dir + '/' + file
          stat = fs.statSync p
          if stat.isDirectory()
            read p
          else if file.match /\.(png|jpg|gif)$/
            r = fast_image_size p
            delete r.image
            delete r.type
            list[p] = r
      read 'build'
      fs.writeFileSync 'build/images.json', JSON.stringify list
      c null
   ],c )

  run: (c)-> depend(assets)(->
    exec("coffee server/server.coffee")(c))

  debug: (c)-> depend(assets)(->
    exec("coffee --nodejs debug server/server.coffee")(c))

  all: (c)-> run c

)
