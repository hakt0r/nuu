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

FUNCTION  = 'function'

$public class AnimatedSprite
  constructor : (@name,@img) ->
    AnimatedSprite.byName[@name] = @
    @rows = @cols = 6; @count = 36
    @size = @img.naturalWidth / @cols
    @state = []
    @state[i] = [] for i in [0...@count-1]
    null
  create : (x,y) -> @state[0].push [x,y]
  @byName : {}
  @shift : =>
    for name, ani of @byName
      ani.state.unshift []
      ani.state.pop()
    null
  @render : (dx,dy,c) =>
    for name, ani of @byName
      img = ani.img
      size = ani.size
      cols = ani.cols
      for imgNumber, state of ani.state
        for i in state 
          ix = Math.floor(imgNumber % cols) * size
          iy = Math.floor(imgNumber / cols) * size
          c.drawImage img, ix, iy, size, size, i[0]+dx, i[1]+dy, size, size
    null

class SpriteSurface extends EventEmitter
  thread : {}
  ship : {}

  init : (callback) =>
    NUU.on 'hitTarget', (v) -> Sprite.spfx.exps.create(v.x,v.y)
    ready  = (cb) -> -> cb null
    async.parallel [
      (cb) => @imag 'nuulogo',   ready cb
      (cb) => @imag 'starfield', ready cb
      (cb) => @imag 'parallax',  ready cb
      (cb) => @imag 'loading'  , ready cb
      (cb) => @spfx  'exps',     ready cb
      (cb) => @spfx  'expm',     ready cb
      (cb) => @spfx  'expm2',    ready cb
      (cb) => @spfx  'expl',     ready cb
      (cb) => @spfx  'expl2',    ready cb
    ], ->
      callback null if callback

  gameLayer : (name,opts={}) ->
    @on 'gameLayer', => @layer name, opts

  layer : (name,opts={}) ->
    opts = draw : opts if typeof opts is FUNCTION
    opts.name = name
    opts.width = Sprite.width unless opts.width
    opts.height = Sprite.height unless opts.height
    Sprite[name] = opts
    Sprite.paint opts.width, opts.height, (c) =>
      $c = $ c.canvas
      $c.attr 'id', 'u_' + name
      $c.appendTo 'body'
      Sprite[name].ctx = c
      opts.draw = opts.draw(c,opts).bind @
    opts.start = (time=TICK) -> opts.timer = setInterval Sprite[name].draw, time
    opts.stop = -> clearInterval opts.timer
    opts

  load : (type,name,url,callback) =>
    return @[type][name].listen.push callback if @[type][name]?
    rec = @[type][name] = obj : null, listen : [callback], url : "#{type}/#{url}.png"
    Cache.get rec.url, (objURL) => # console.log "Load: #{rec.url} " + if objURL then 'ok' else 'fail'
      e = new Image
      e.src = objURL
      rec.obj = e
      e.onload = -> c e for c in rec.listen

  imag  : (name, callback) ->
    @load( 'imag', name, name, (img) =>
      @['imag'][name] = img; callback null )

  spfx  : (name, callback) =>
    @load 'spfx', name, name, (img) =>
      console.log 'spfx', name
      @['spfx'][name] = new AnimatedSprite name, img
      callback null

  outfit  : (name, callback) => @load( 'outfit', name, name, (img) => callback img )

  asteroid : (data, callback) =>
    name = data.sprite
    @load 'stel',name,name+'/sprites', (img) ->
      data.img = img
      callback new Asteroid data

  stel : (data, callback) =>
    name = data.sprite
    @load 'stel',name,name+'/sprites', (img) ->
      data.img = img
      callback new Stellar data

  start : (opts, callback) =>
    @emit 'gameLayer'
    Sprite.main.start 33
    callback null if callback

  update : (s) ->
    return unless s?
    image_num = (s.count - Math.round(s.d / (360 / (s.count - 1)))) % s.count
    s.ix = Math.floor(image_num % s.cols) * s.size
    s.iy = Math.floor(image_num / s.cols) * s.size

  paint : (w, h, fnc) ->
    c = document.createElement("canvas")
    c.width = w
    c.height = h
    fnc c.getContext("2d"), w, h
    c

$static 'Sprite', new SpriteSurface
