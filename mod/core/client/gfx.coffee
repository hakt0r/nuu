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

###

  Sprites can be either Sprites, Tiles or Animations.
  $obj defaults to Sprite.

    client/gfx_sprite.coffee
    client/gfx_tile.coffee
    client/gfx_animation.coffee

###

NUU.on 'runtime:ready', -> $static 'Sprite', new SpriteSurface

PIXI.bringToFront = (sprite, parent) ->
  sprite = if typeof sprite != 'undefined' then sprite.target or sprite else this
  parent = parent or sprite.parent or 'children': false
  return unless chd = parent.children
  return unless -1 isnt idx = chd.indexOf sprite
  chd.push sprite
  return

# Moved in v5 we use both atm
PIXI.Ticker = PIXI.ticker.Ticker                 unless PIXI.Ticker
PIXI.AnimatedSprite = PIXI.extras.AnimatedSprite unless PIXI.AnimatedSprite
PIXI.TilingSprite   = PIXI.extras.TilingSprite   unless PIXI.TilingSprite

movieCache = {}
$static 'movieFactory', (sprite, url, _loop) ->
  unless (c = movieCache[sprite])
    base = new PIXI.BaseTexture.fromImage url
    meta = $meta[String.filename sprite]
    a = []
    l = meta.cols
    meta.radius = ( meta.size = s = meta.width / l ) / 2
    r = floor meta.height / s
    # r = meta.rows # fail: some effects
    c = meta.count = l*r
    for n in [0..c-1]
      x = floor(n % l) * s
      y = floor(n / l) * s
      a.push new PIXI.Texture base, new PIXI.Rectangle(x,y,s,s)
    movieCache[sprite] = c = (_loop)->
      c = new PIXI.AnimatedSprite a, true
      c.meta = meta
      c.onComplete = _loop unless ( c.loop = _loop is true )
      c
  c(_loop)

makeStarfield = (mod...)->
  field = (rmax,smax)->
    [ rx, ry, rr, rb ] = [ random()*1024, random()*1024, random()*smax, random()*rmax ]
    g.fillStyle = 'rgba(255,255,255,'+rb+')'
    g.beginPath()
    g.arc rx,ry,rr,0,TAU
    g.fill()
    null
  c = $ '<canvas class="offscreen" width=1024 height=1024>'
  g = c[0].getContext '2d'
  field.apply null, x for i in [0..x[2]] while x = mod.shift()
  return new PIXI.TilingSprite PIXI.Texture.fromCanvas c[0]

$static 'SpriteSurface', class SpriteSurface extends EventEmitter
  visible: {}
  visibleList: []
  nextSelect: 0

  constructor: (callback)->
    super()

    @scale = 1
    @tick = 0
    @stage    = stage    = new PIXI.Container # 0x000000
    @pixi = new PIXI.Application 640, 480, antialias: no, forceFXAA:yes, autoResize:no
    @renderer = renderer = @pixi.renderer

    @emit 'init'

    document.body.appendChild renderer.view
    d = $ document
    w = $ window
    do @resize = =>
      window.WIDTH  = d.width()
      window.HEIGHT = d.height()
      window.WDB2 = WIDTH  / 2
      window.HGB2 = HEIGHT / 2
      window.WDT2 = WIDTH  + WIDTH
      window.HGT2 = HEIGHT + HEIGHT
      @renderer.resize WIDTH, HEIGHT
      @emit 'resize', WIDTH, HEIGHT, WDB2, HGB2
    w.on 'resize', @resize
    @ticker = new PIXI.Ticker
    @ticker.add => do @animate
    @ticker.start()
    $interval 500, @select.bind @
    $.ajax '/build/images.json', success: (result) =>
      $static '$meta', result
      # preload animations
      for k in ['exps','expm','expl','expl2','cargo','debris0','debris1','debris2','debris3','debris4','debris5']
        movieFactory k, '/build/spfx/' + k + '.png'
      NUU.emit 'gfx:ready'

    @on 'resize', @repositionPlayer.bind @
    @on 'resize', (wd,hg,hw,hh) =>
      @starfield.width  = @parallax2.width  = @parallax.width  = wd
      @starfield.height = @parallax2.height = @parallax.height = hg
    null

  layer: (name,container)->
    @[name] = container
    @stage.addChild container
    @visible[name] = []
    container

  start: (callback) =>
    @startTime = NUU.time()
    callback null if callback
    null

  stop: ->
    @bg.removeChildren()
