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

$static 'PIXI', require 'pixi.js'

class SpriteSurface extends EventEmitter
  thread : {}
  stel: {}
  ship: {}

  init : (callback) =>

    animate = ->
      requestAnimationFrame animate
      renderer.render stage
      return

    stage.addChild game
    document.body.appendChild renderer.view
    requestAnimationFrame animate

    async.parallel [
      (c) => @imag 'nuulogo',   -> c null
      (c) => @imag 'nuuseal',   -> c null
      (c) => @imag 'starfield', -> c null
      (c) => @imag 'parallax',  -> c null
      (c) => @imag 'loading'  , -> c null
      (c) => @spfx 'exps',      -> c null
      (c) => @spfx 'expm',      -> c null
      (c) => @spfx 'expm2',     -> c null
      (c) => @spfx 'expl',      -> c null
      (c) => @spfx 'expl2',     -> c null
    ], ->
      callback null if callback

  gameLayer : (name,opts={}) ->
    @on 'gameLayer', => @layer name, opts

  layer : (opts={}) ->
    return unless opts.name
    Sprite[opts.name] = opts
    opts.width  = w = Sprite.width unless opts.width
    opts.height = h = Sprite.height unless opts.height
    opts.graphics = graphics = new PIXI.Graphics w, h
    # opts.sprite = sprite = PIXI.Sprite.fromImage 'build/imag/loading.png'
    # opts.ctx = ctx = graphics.context
    game.addChild graphics
    opts.tick  = -> opts.draw graphics, opts, w, h
    # sprite.setTexture graphics.generateTexture()
    opts.start = (time=TICK) ->
      opts.timer = setInterval opts.tick, time
    opts.stop  = -> clearInterval opts.timer
    opts.init(graphics,opts,w,h)
    opts

  offscreen : (w, h, fnc) ->
    b = new PIXI.CanvasBuffer w, h
    fnc b.context, w, h
    b

  paint : (w, h, fnc) ->
    opts.buffer = buffer = new PIXI.CanvasBuffer w, h
    opts.sprite = sprite = PIXI.Sprite.fromImage 'build/imag/loading.png'
    game.addChild sprite
    fnc buffer, sprite, w, h
    buffer

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

  start : (opts, callback) =>
    @emit 'gameLayer'
    callback null if callback

  update : (s) ->
    return unless s and s.currentSprite
    n = (s.count - round(s.d / (360 / (s.count - 1)))) % s.count
    s.currentSprite.tilePosition.set(
      - ( floor(n % s.cols) * s.size )
      - ( floor(n / s.cols) * s.size )
    )

$static 'Sprite', new SpriteSurface
Sprite.stage = stage = new PIXI.Stage 0x000000
Sprite.renderer = renderer = PIXI.autoDetectRenderer 640,480, antialias: yes
Sprite.game = game = new PIXI.DisplayObjectContainer

$ ->
  $win = $(window)
  $win.on 'resize', -> renderer.resize $win.width(), $win.height()
  renderer.resize $win.width(), $win.height()
