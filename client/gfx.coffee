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

String.filename = (p)-> p.replace(/.*\//, '').replace(/\..*/,'')

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
      c = new PIXI.extras.AnimatedSprite a, true
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
  return new PIXI.extras.TilingSprite PIXI.Texture.fromCanvas c[0]

$static 'Sprite', new class SpriteSurface extends EventEmitter
  visible: {}
  visibleList: []
  nextSelect: 0

  constructor: (callback)->
    @stage    = stage    = new PIXI.Container # 0x000000
    @renderer = renderer = PIXI.autoDetectRenderer 640,480, antialias: yes

    @layer 'bg',   new PIXI.Container
    @layer 'stel', new PIXI.Container
    @layer 'debr', new PIXI.Container
    @layer 'ship', new PIXI.Container
    @layer 'weap', new PIXI.Graphics
    @layer 'tile', new PIXI.Container
    @layer 'play', new PIXI.Container
    @layer 'fx',   new PIXI.Graphics
    @layer 'fg',   new PIXI.Container

    @bg.addChild @starfield = makeStarfield [1,0.3,2000],[1.5,0.7,20]
    @bg.addChild @parallax  = makeStarfield [1,0.3,2000]
    @bg.addChild @parallax2 = makeStarfield [1,0.3,2000]

    app.on 'runtime:ready', =>
      document.body.appendChild renderer.view
      w = $ window
      do @resize = =>
        window.WIDTH  = w.width()
        window.HEIGHT = w.height()
        window.WDB2 = WIDTH  / 2
        window.HGB2 = HEIGHT / 2
        window.WDT2 = WIDTH  + WIDTH
        window.HGT2 = HEIGHT + HEIGHT
        @renderer.resize WIDTH, HEIGHT
        @emit 'resize', WIDTH, HEIGHT, WDB2, HGB2
      w.on 'resize', @resize
      @ticker = new PIXI.ticker.Ticker
      @ticker.add => do @animate
      @ticker.start()
      $interval 500, @select.bind @
      $.ajax('/build/images.json').success (result) =>
        $static '$meta', result
        # preload animations
        for k in ['exps','expm','expl','expl2','cargo','debris0','debris1','debris2','debris3','debris4','debris5']
          movieFactory k, '/build/spfx/' + k + '.png'
        app.emit 'gfx:ready'

    @on 'resize', @repositionPlayer.bind @
    @on 'resize', (wd,hg,hw,hh) =>
      @starfield.width  = @parallax2.width  = @parallax.width  = wd
      @starfield.height = @parallax2.height = @parallax.height = hg
    null

  repositionPlayer: (w=WIDTH,h=HEIGHT,hw=WDB2,hh=HGB2)->
    return unless ( v = VEHICLE ) and v.loaded
    r = v.radius
    v.sprite.position.set hw - r, hh - r

  select: (timestamp) ->
    W = WIDTH  * 4 # TODO: EventHorizon
    H = HEIGHT * 4 # TODO: EventHorizon
    VEHICLE.update()
    { x,y } = VEHICLE
    # destructor-aware loop
    i = -1; s = null; list = $obj.list; length = list.length
    while ++i < length
      s = list[i]
      s.update()
      if s.ttl and s.ttl < TIME
        s.hide()
        if s.ttlFinal
          s.destructor(); length--; i--
        continue
      if -W<(s.x-x)<W and -H<(s.y-y)<H then s.show() else s.hide()

  animate: (timestamp) ->
    window.TIME  = NUU.time()
    window.ETIME = Math.floor(TIME/1000000)*1000000
    VEHICLE.updateSprite()
    window.OX = -VEHICLE.x + WDB2
    window.OY = -VEHICLE.y + HGB2

    # SPEEDSCALE (REVIVAL)
    if app.settings.gfx.speedScale
      sc = 1 / ( max 1, ( abs(VEHICLE.m[0]) + abs(VEHICLE.m[1]) ) / 500 )
      @bg.scale.x = @bg.scale.y = @stel.scale.x = @stel.scale.y = @debr.scale.x = @debr.scale.y = @ship.scale.x = @ship.scale.y = @weap.scale.x = @weap.scale.y = @tile.scale.x = @tile.scale.y = @play.scale.x = @play.scale.y = @fx.scale.x = @fx.scale.y = @fg.scale.x = @fg.scale.y = sc
      @bg.position.x = @stel.position.x = @debr.position.x = @ship.position.x = @weap.position.x = @tile.position.x = @play.position.x = @fx.position.x = @fg.position.x = .5 * ( WIDTH - WIDTH * sc )
      @bg.position.y = @stel.position.y = @debr.position.y = @ship.position.y = @weap.position.y = @tile.position.y = @play.position.y = @fx.position.y = @fg.position.y = .5 * ( HEIGHT - HEIGHT * sc )

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

    # clear weapons gfx area
    @weap.clear()

    # fastest case TODO: still?
    length = ( list = @visibleList ).length; i = -1
    while ++i < length
      # loop reached
      ( s = list[i] ).updateSprite()
      # draw beam weapon
      if ( beam = Weapon.beam[s.id] ) and 0 < ( x = s.x + OX ) < WIDTH and 0 < ( y = s.y + OY ) < HEIGHT
        d = s.d / RAD
        @weap.beginFill 0xFF0000, 0.7
        @weap.lineStyle 1+random(), 0xFF0000, 0.7
        @weap.moveTo x, y
        @weap.lineTo x + cos(d) * beam.range, y + sin(d) * beam.range
        @weap.endFill()

    # draw projectiles
    for s in Weapon.proj
      ticks = (TIME - s.ms) / TICK
      x = OX + s.sx + s.m[0] * ticks
      y = OY + s.sy + s.m[1] * ticks
      if 0 < x < WIDTH and 0 < y < HEIGHT
        @weap.beginFill 0xFF0000, 0.7
        @weap.drawCircle x-1, y-1, 3
        @weap.endFill()

    @renderHUD()     # if @renderHUD
    @renderScanner() # if @renderScanner
    @renderer.render @stage
    null

  layer: (name,container)->
    @[name] = container
    @stage.addChild container
    @visible[name] = []
    container

  start: (callback) =>
    @startTime = Ping.remoteTime()
    callback null if callback
    null

  stop: ->
    @bg.removeChildren()
