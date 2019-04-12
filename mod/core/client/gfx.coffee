###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
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

# ██████  ██ ██   ██ ██      ██ ███████
# ██   ██ ██  ██ ██  ██      ██ ██
# ██████  ██   ███   ██      ██ ███████
# ██      ██  ██ ██  ██ ██   ██      ██
# ██      ██ ██   ██ ██  █████  ███████

###
  WebGL with Canvas fallback powered by PIXI.js
  # PITFALL: Hack PIXI to use Cache
###

PIXI.BaseTexture.fromImage = (imageUrl, crossorigin, scaleMode, sourceScale) ->
  baseTexture = PIXI.utils.BaseTextureCache[imageUrl]
  if !baseTexture
    image = new Image
    image.crossOrigin = 'anonymous'
    baseTexture = new PIXI.BaseTexture(image, scaleMode)
    baseTexture.imageUrl = imageUrl
    baseTexture.sourceScale = sourceScale if sourceScale
    baseTexture.resolution = PIXI.utils.getResolutionOfUrl(imageUrl)
    Cache.get imageUrl, (cachedUrl) ->
      image.src = cachedUrl # Setting this triggers load
      PIXI.BaseTexture.addToCache baseTexture, imageUrl
  baseTexture

PIXI.Ticker         = PIXI.ticker.Ticker         unless PIXI.Ticker
PIXI.AnimatedSprite = PIXI.extras.AnimatedSprite unless PIXI.AnimatedSprite
PIXI.TilingSprite   = PIXI.extras.TilingSprite   unless PIXI.TilingSprite

PIXI.bringToFront = (sprite, parent) ->
  sprite = if typeof sprite != 'undefined' then sprite.target or sprite else this
  parent = parent or sprite.parent or 'children': false
  return unless chd = parent.children
  return unless -1 isnt idx = chd.indexOf sprite
  chd.push sprite
  return

PIXI.blurOut = (o,t=1500,s=2)-> new Promise (resolve)->
  o.filterArea = new PIXI.Rectangle 0,0,WIDTH,HEIGHT
  i = -s; f = setInterval (-> o.filters = [new PIXI.filters.BlurFilter i+=s]), TICK
  setTimeout (-> clearInterval(f); o.filters = []; resolve() ), t
  return

# ██████  ███████ ███    ██ ██████  ███████ ██████  ███████ ██████
# ██   ██ ██      ████   ██ ██   ██ ██      ██   ██ ██      ██   ██
# ██████  █████   ██ ██  ██ ██   ██ █████   ██████  █████   ██████
# ██   ██ ██      ██  ██ ██ ██   ██ ██      ██   ██ ██      ██   ██
# ██   ██ ███████ ██   ████ ██████  ███████ ██   ██ ███████ ██   ██

$static 'Sprite', new class NUU.Render extends EventEmitter
  visible: {}
  visibleList: []
  nextSelect: 0

  constructor: (callback)->
    super()
    @scale = 1
    @tick = 0
    @stage = stage = new PIXI.Container # 0x000000
    @pixi = new PIXI.Application 640, 480, antialias:no, forceFXAA:yes, autoResize:no
    @renderer = renderer = @pixi.renderer
    @emit 'init'
    document.body.appendChild renderer.view
    window.addEventListener 'resize', @resize
    @ticker = new PIXI.Ticker
    @ticker.add =>
      do @animate
    setInterval (=> do $obj.select ), TICK * 3
    @ticker.start()
    do @resize
    do @initialize
    return

  initialize:-> new Promise (resolve,reject)=> $.ajax '/build/images.json',
    success:(result)=>
      $static '$meta', result
      @makeMovie k, '/build/gfx/' + k + '.png' for k in @preload
      NUU.emit 'gfx:ready'
      do resolve
    error:reject

  repositionPlayer:->
  animate:->

  resize:=>
    w = window
    d = document
    w.WIDTH  = w.innerWidth
    w.HEIGHT = w.innerHeight
    w.WDB2 = WIDTH  / 2
    w.HGB2 = HEIGHT / 2
    w.WDT2 = WIDTH  + WIDTH
    w.HGT2 = HEIGHT + HEIGHT
    @renderer.resize WIDTH, HEIGHT
    @emit 'resize', WIDTH, HEIGHT, WDB2, HGB2
    do @repositionPlayer
    return

  layer:(name,container)->
    @[name] = container
    @stage.addChild container
    @visible[name] = []
    container

  start:(callback) =>
    @startTime = NUU.time()
    do callback if callback
    return

  stop:-> @bg.removeChildren()

Sprite.preload = [
  'exps','expm','expl','expl2','cargo','debris0','debris1','debris2','debris3','debris4','debris5']

# ███    ███  ██████  ██    ██ ██ ███████ ███████
# ████  ████ ██    ██ ██    ██ ██ ██      ██
# ██ ████ ██ ██    ██ ██    ██ ██ █████   ███████
# ██  ██  ██ ██    ██  ██  ██  ██ ██           ██
# ██      ██  ██████    ████   ██ ███████ ███████

movieCache = {}

Sprite.makeMovie = (sprite, url, _loop)->
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
