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

module.exports = (__targets) ->

  require 'colors'

  global.fs = require 'fs'
  global.cp = require 'child_process'
  global.util = require 'util'
  global.path = require 'path'
  global.async = require 'async'
  global.touch = require 'touch'
  global.coffee = require 'coffeescript'
  global.request = require 'request'
  global.filesize = require 'file-size'
  global.fast_image_size = require 'fast-image-size'

  util.print = (s)-> process.stdout.write(s,'utf8')

  process.chdir path.dirname __dirname

  global.$s = async.series
  global.$p = async.parallel

  global.exec = (cmd)-> (c)->
    console.log cmd.grey
    cp.spawn( 'sh', [ '-c', cmd ], stdio: 'inherit' ).on 'close', ->
      c null

  global.exists = fs.existsSync
  global.fileExists = (p)-> fs.existsSync(p) and fs.statSync(p).isFile()
  global.dirExists  = (p)-> fs.existsSync(p) and fs.statSync(p).isDirectory()

  mkdirp = require('mkdirp')
  global.mkdir = (args...)-> (c)->
    mk = (a)-> (c)->
      if fs.existsSync a then c null
      else mkdirp a, -> c null
    $p ( mk a for a in args ), -> c null

  global.link = (src,dst)-> (c)->
    if await new Promise (resolve)-> fs.exists dst, resolve
      console.log dst.green
      c null
    else fs.symlink ( a = path.relative(path.dirname(dst),src) ), dst, c

  global.linkFilesIn = (src,dst)-> (c)->
    fs.readdir src, (err,files)->
      ln = (s,d)-> (c)->
        fs.symlink s,d,c
        console.log 'link'.grey, s, d
      $p (
        for f in files when fs.statSync(s = path.join src, f).isFile() and not fs.existsSync(d = path.join(dst,f))
          ln path.join('..','..',s), d
      ), c

  global.convFilesIn = (src,dst)-> (c)->
    unless 0 is ( cp.spawnSync 'which',['inkscape'] ).status
      console.log 'warn'.yellow, 'inkscape not installed: cannot convert svgs'
      do c
    files = await new Promise (resolve,reject)-> fs.readdir src, (err,files)->
      return reject err if err
      resolve files
      return
    conv = (s)->
      d = s.replace /svg$/, 'png'
      return Promise.resolve() unless s.match /\.svg$/
      return Promise.resolve() if fs.existsSync(d) and ( stat = fs.statSync s ) and ( dstat = fs.statSync d ) and stat.mtime.toString().trim() is dstat.mtime.toString().trim()
      new Promise (resolve)-> ( cp.spawn "inkscape",['-z','-e',d,'-w',1024,s] ).on 'close',->
        console.log 'conv'.grey, s, d
        touch.sync d, ref:s
        do resolve
    Promise.all(
      for f in files when fs.statSync(s = path.join src, f).isFile()
        conv s, path.join dst
    ).then -> do c

  global.linkDirsIn = (src,dst)-> (c)->
    fs.readdir src, (err,files)->
      ln = (s,d)-> (c)->
        fs.symlink s,d,c
        console.log 'link'.grey, s, d
      $p (
        for f in files when fs.statSync(s = path.join src, f).isDirectory() and not fs.existsSync(d = path.join(dst,f))
          ln path.join('..','..',s), d
      ), c

  global.relPath = (s,d)->
    i = -1
    noop while s[++i] is d[i]
    c = s.substring 0, i
    s = s.substring i
    d = d.substring i
    path.join path.dirname(d).replace(/[^/]+/g,".."), s

  global.linkFlatten = (src,dst)-> (c)->
    links = []
    dirs = await new Promise (resolve,reject)-> fs.readdir src, (error,files)->
      if error then reject error else resolve files
    await Promise.all dirs.map (dir)-> new Promise (resolve,reject)->
      return do resolve unless fs.statSync("#{src}/#{dir}").isDirectory()
      fs.readdir "#{src}/#{dir}", (error,files)->
        return reject error if error
        links = links.concat files.map (file)-> new Promise (resolve,reject)->
          return do resolve unless file.match /png$/
          s = relPath "#{src}/#{dir}/#{file}", d = "#{dst}/#{file}"
          fs.exists d, (exists)->
            return do resolve if exists
            fs.symlink s,d, (error)->
              return reject error if error
              console.log 'link'.grey, d.green
              do resolve
        do resolve
    c null

  global.generate = (dst,generator)-> (c)->
    unless fs.existsSync dst
      require(generator)(dst,c)
    else
      console.log dst.green
      c null

  global.rmdir = (args...)-> (c)->
    rm = (a)-> exec "rm -rf ./#{a}"
    $p ( rm a for a in args ), -> c null

  global.unzip = (src,dst)-> (c)->
    unless dirExists dst then exec( """sh -c '
      sync;
      rm -rf   _nuu_extract_;
      mkdir -p _nuu_extract_;
      unzip -d _nuu_extract_   #{src};
      mv       _nuu_extract_/* #{dst};
      rm -rf   _nuu_extract_;
    '""" )(c)
    else dst.green; c null

  global.fetch = (dst,src)-> (c)->
    if not fs.existsSync dst
      util.print [ 'fetch'.yellow, dst, src.replace(/\/.*\//,'/.../'), 'connecting...'.blue ].join ' '
      r = request.get src
      r.on 'headers', ->
      r.on 'end', ->
        console.log '\x1b[2K\x1b[0G' + 'fetch'.green, dst, filesize(fs.statSync(dst).size).human(si:yes, fixed:2), 'done'.green
        c null
      r.on 'data', -> util.print '\x1b[2K\x1b[0G' + [ 'fetch'.yellow, dst, filesize(fs.statSync(dst).size).human(si:yes, fixed:2) ].join ' '
      r.pipe(fs.createWriteStream dst)
    else c null

  global.compile = (src,dst)-> (c)->
    return c null unless src.match /\.coffee$/
    return c null if ( stat = fs.statSync(src) ).isDirectory()
    if fs.existsSync(dst)
      if ( dstat = fs.statSync(dst) )
        if stat.mtime.toString().trim() is dstat.mtime.toString().trim()
          # console.log 'up-todate:'.green, src.yellow, ( dstat || mtime: null ).mtime
          return c null
    console.log 'compile:'.red, src.yellow, stat.mtime, ( dstat || mtime: null ).mtime
    compiled = coffee.compile fs.readFileSync( src, 'utf8')
    compiled = '#!/usr/bin/env node\n' + compiled if src.match /server\.coffee$/
    fs.writeFileSync dst, compiled
    cp.execSync "chmod a+x #{dst}" if src.match /server\.coffee$/
    touch.sync dst, ref: src
    c null

  global.depend = (deps...)-> (c)->
    $s deps, -> c null
    null

  global.target = (obj={}) ->
    for name, fnc of obj
      unless global[name]
        global[name] = fnc
      else
        console.log name.yellow, 'is already defined'.red
        process.exit 1
    null

  target.exec = (name,c) -> if global[name]? then global[name](c||->)

  process.argv.shift()
  process.argv.shift()

  target __targets
  TARGET = process.argv[0] || 'all'
  await new Promise (resolve)-> target.exec 'init', resolve
  await new Promise (resolve)-> target.exec TARGET, resolve
  await new Promise (resolve)-> target.exec 'post', resolve
