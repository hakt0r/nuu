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

###

  Sprites can be either Sprites, Tiles or Animations.
  $obj defaults to Sprite.

    client/gfx_sprite.coffee
    client/gfx_tile.coffee
    client/gfx_animation.coffee

###

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

$static 'Sprite', new class SpriteSurface extends EventEmitter
  visible: {}
  visibleList: []
  nextSelect: 0

  constructor: (callback)->
    @tick = 0
    @stage    = stage    = new PIXI.Container # 0x000000
    @pixi = new PIXI.Application 640, 480, antialias: yes, forceFXAA:yes, autoResize:true
    @renderer = renderer = @pixi.renderer

    @layer 'bg',   new PIXI.Container
    @layer 'stel', new PIXI.Container
    @layer 'debr', new PIXI.Container
    @layer 'ship', new PIXI.Container
    @layer 'weap', new PIXI.Container
    @layer 'tile', new PIXI.Container
    @layer 'play', new PIXI.Container
    @layer 'fx',   new PIXI.Container
    @layer 'fg',   new PIXI.Container

    @bg.addChild @starfield = makeStarfield [1,0.3,2000],[1.5,0.7,20]
    @bg.addChild @parallax  = makeStarfield [1,0.3,2000]
    @bg.addChild @parallax2 = makeStarfield [1,0.3,2000]

    NUU.on 'runtime:ready', =>
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

  repositionPlayer: (w=WIDTH,h=HEIGHT,hw=WDB2,hh=HGB2)->
    return unless ( v = VEHICLE ) and v.loaded
    r = v.radius
    v.sprite.position.set hw - r, hh - r

  select: ->
    W = WIDTH  * 10 # TODO: EventHorizon
    H = HEIGHT * 10 # TODO: EventHorizon
    VEHICLE.update time = NUU.time()
    { x,y } = VEHICLE
    # destructor-aware loop
    i = -1; s = null; list = $obj.list; length = list.length
    while ++i < length
      s = list[i]
      s.update()
      if s.ttl and s.ttl < time
        s.hide()
        if s.ttlFinal
          s.destructor(); length--; i--
        continue
      if -W<(s.x-x)<W and -H<(s.y-y)<H
        continue if SHORTRANGE[s.id]
        SHORTRANGE[s.id] = s
        NUU.emit '$obj:inRange', s
      else
        continue unless SHORTRANGE[s.id]
        delete SHORTRANGE[s.id]
        NUU.emit '$obj:outRange', s

    null

  animate: (timestamp) ->
    return unless VEHICLE
    time = NUU.time()
    VEHICLE.update time
    window.OX = -VEHICLE.x + WDB2
    window.OY = -VEHICLE.y + HGB2

    # # SPEEDSCALE (REVIVAL)
    # if NUU.settings.gfx.speedScale
    #   sc = 1 / ( max 1, ( abs(VEHICLE.m[0]) + abs(VEHICLE.m[1]) ) / 500 )
    #   @bg.scale.x = @bg.scale.y = @stel.scale.x = @stel.scale.y = @debr.scale.x = @debr.scale.y = @ship.scale.x = @ship.scale.y = @weap.scale.x = @weap.scale.y = @tile.scale.x = @tile.scale.y = @play.scale.x = @play.scale.y = @fx.scale.x = @fx.scale.y = @fg.scale.x = @fg.scale.y = sc
    #   @bg.position.x = @stel.position.x = @debr.position.x = @ship.position.x = @weap.position.x = @tile.position.x = @play.position.x = @fx.position.x = @fg.position.x = .5 * ( WIDTH - WIDTH * sc )
    #   @bg.position.y = @stel.position.y = @debr.position.y = @ship.position.y = @weap.position.y = @tile.position.y = @play.position.y = @fx.position.y = @fg.position.y = .5 * ( HEIGHT - HEIGHT * sc )

    # STARS
    [ mx, my ] = vectors.normalize Array::slice.call VEHICLE.m;
    mx =  1 if mx is 0
    my = -1 if my is 0
    @starfield.tilePosition.x -= mx
    @starfield.tilePosition.y -= my
    @parallax. tilePosition.x -= mx * 1.25
    @parallax. tilePosition.y -= my * 1.25
    @parallax2.tilePosition.x -= mx * 1.5
    @parallax2.tilePosition.y -= my * 1.5

    length = ( list = @visibleList ).length; i = -1
    # time = NUU.time()
    while ++i < length
      ( s = list[i] ).updateSprite time
      continue unless beam = Weapon.beam[s.id]
      sp = beam.sprite
      sp.tilePosition.x += 0.5
      sp.position.set s.x + OX, s.y + OY
      sp.rotation = ( s.d + beam.dir ) / RAD

    length = ( list = Weapon.proj ).length; i = -1
    # time = NUU.time()
    while ++i < length
      s = list[i]
      ticks = ( time - s.ms ) * TICKi
      x = floor s.sx + s.mx * ticks
      y = floor s.sy + s.my * ticks
      s.sprite.position.set x + OX, y + OY
      if s.tt < time
        Sprite.weap.removeChild s.sprite
        list[i] = null
    Weapon.proj = Weapon.proj.filter (i)-> i isnt null

    @renderHUD()     # if @renderHUD
    @renderScanner() # if ++@tick % 10 is 0
    # if VEHICLE.sprite
    #   # VEHICLE.sprite.anchor = [0,0]
    #   VEHICLE.sprite.position.set WDB2, HGB2
    @renderer.render @stage
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
