module.exports = (__targets) ->

  require 'colors'

  global.fs = require 'fs'
  global.cp = require 'child_process'
  global.util = require 'util'
  global.path = require 'path'
  global.async = require 'async'
  global.touch = require 'touch'
  global.coffee = require 'coffee-script'
  global.request = require 'request'
  global.filesize = require 'file-size'
  global.fast_image_size = require 'fast-image-size'

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
    unless fs.existsSync(dst)
      fs.symlink ( a = path.relative(path.dirname(dst),src) ), dst, -> c null
    else
      console.log dst.green
      c null

  global.linkFilesIn = (src,dst)-> (c)->
    fs.readdir src, (err,files)->
      ln = (s,d)-> (c)->
        fs.symlink s,d,c
        console.log 'link'.grey, s, d
      $p (
        for f in files when fs.statSync(s = path.join src, f).isFile() and not fs.existsSync(d = path.join(dst,f))
          ln path.join('..','..',s), d
      ), c

  global.generate = (dst,generator)-> (c)->
    unless fs.existsSync dst
      require('./'+generator)(dst,c)
    else
      console.log dst.green
      c null

  global.rmdir = (args...)-> (c)->
    rm = (a)-> exec "rm -rf ./#{a}"
    $p ( rm a for a in args ), -> c null

  global.unzip = (src,dst)-> (c)->
    unless dirExists dst
      exec("""sh -c 'sync; cd #{path.dirname src}; unzip #{path.basename src}'""")(c)
    else dst.green; c null

  global.fetch = (dst,src)-> (c)->
    if not fs.existsSync dst
      util.print [ 'fetch'.yellow, dst, dst, src, 'connecting...'.blue ].join ' '
      r = request.get src
      r.on 'headers', ->
      r.on 'end', ->
        console.log '\x1b[2K\x1b[0G' + 'fetch'.green, dst, src, filesize(fs.statSync(dst).size).human(si:yes, fixed:2), 'done'.green
        c null
      r.on 'data', -> util.print '\x1b[2K\x1b[0G' + [ 'fetch'.yellow, dst, src, filesize(fs.statSync(dst).size).human(si:yes, fixed:2) ].join ' '
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
    fs.writeFileSync dst, coffee.compile fs.readFileSync( src, 'utf8')
    touch.sync dst, ref: src
    c null

  global.depend = (deps...)-> (c)->
    $s deps, -> c null        

  global.target = (obj={}) ->
    for name, fnc of obj
      unless global[name]
        global[name] = fnc
      else
        console.log name.yellow, 'is already defined'.red
        process.exit 1

  target.exec = (name,c) -> global[name](c||->)

  process.argv.shift()
  process.argv.shift()

  target __targets
  $s [
    (c)-> target.exec 'init', c
    (c)-> target.exec (process.argv[0] || 'all'), c
  ]