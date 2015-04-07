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

###

  Sprites can be either Sprites, Tiles or Animations.
  $obj defaults to Sprite.

    client/gfx_sprite.coffee
    client/gfx_tile.coffee
    client/gfx_animation.coffee

###

movieCache = {}
$static 'movieFactory', (sprite, url, _loop) ->
  return c() if (c = movieCache[sprite])
  base = new PIXI.BaseTexture.fromImage url
  meta = $meta[url]
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
  movieCache[sprite] = ->
    c = new PIXI.MovieClip a, s, s
    c.meta = meta
    c.loop = _loop
    c
  movieCache[sprite]()

$static 'Sprite', new class SpriteSurface extends EventEmitter
  visible: {}
  visibleList: []
  nextSelect: 0

  constructor: (callback)->
    @stage    = stage    = new PIXI.Stage 0x000000
    @renderer = renderer = PIXI.autoDetectRenderer 640,480, antialias: yes

    @layer 'bg',   new PIXI.DisplayObjectContainer
    @layer 'stel', new PIXI.DisplayObjectContainer
    @layer 'debr', new PIXI.DisplayObjectContainer
    @layer 'ship', new PIXI.DisplayObjectContainer
    @layer 'weap', new PIXI.Graphics
    @layer 'tile', new PIXI.DisplayObjectContainer
    @layer 'play', new PIXI.DisplayObjectContainer
    @layer 'fx',   new PIXI.Graphics
    @layer 'fg',   new PIXI.DisplayObjectContainer

    @fg.addChild @parallax  = new PIXI.TilingSprite PIXI.Texture.fromImage '/build/imag/parallax.png'
    @fg.addChild @parallax2 = new PIXI.TilingSprite PIXI.Texture.fromImage '/build/imag/parallax.png'
    @bg.addChild @starfield = new PIXI.TilingSprite PIXI.Texture.fromImage '/build/imag/starfield.png'

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
      requestAnimationFrame @animate = @animate.bind @
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

  animate: (timestamp) ->
    window.TIME  = NUU.time()
    window.ETIME = Math.floor(TIME/1000000)*1000000
    VEHICLE.updateSprite()
    window.OX = floor -VEHICLE.x + WDB2
    window.OY = floor -VEHICLE.y + HGB2

    if @nextSelect < TIME  
      @nextSelect = TIME + 500
      VEHICLE.update()
      { x,y } = VEHICLE
      # destructor-aware loop
      i = -1; s = null; list = $obj.list; length = list.length
      while ++i < length
        s = list[i]
        if s.ttl and s.ttl < TIME
          s.hide()
          if s.ttlFinal
            s.destructor(); length--; i--
          continue
        s.update()
        if -WIDTH<(s.x-x)<WIDTH and -HEIGHT<(s.y-y)<HEIGHT
          s.show()
        else s.hide()

    # STARS
    @starfield.tilePosition.x -= VEHICLE.m[0] * 0.1
    @starfield.tilePosition.y -= VEHICLE.m[1] * 0.1
    @parallax. tilePosition.x -= VEHICLE.m[0] * 1.25
    @parallax. tilePosition.y -= VEHICLE.m[1] * 1.25
    @parallax2.tilePosition.x -= VEHICLE.m[0] * 1.5
    @parallax2.tilePosition.y -= VEHICLE.m[1] * 1.5

    # clear weapons gfx area
    @weap.clear()

    # fastest case
    length = ( list = @visibleList ).length; i = -1
    while ++i < length
      # loop reached
      ( s = list[i] ).updateSprite()
      # draw beam weapon
      if ( beam = Weapon.beam[s.id] ) and 0 < ( x = floor s.x + OX ) < WIDTH and 0 < ( y = floor s.y + OY ) < HEIGHT
        d = s.d / RAD
        @weap.beginFill 0xFF0000, 0.7
        @weap.lineStyle 1+random(), 0xFF0000, 0.7
        @weap.moveTo x, y
        @weap.lineTo x + cos(d) * beam.range, y + sin(d) * beam.range
        @weap.endFill()

    # draw projectiles
    for s in Weapon.proj
      ticks = (TIME - s.ms) / TICK
      x = OX + floor(s.sx + s.m[0] * ticks)
      y = OY + floor(s.sy + s.m[1] * ticks)
      if 0 < x < WIDTH and 0 < y < HEIGHT
        @weap.beginFill 0xFF0000, 0.7
        @weap.drawCircle x-1, y-1, 3
        @weap.endFill()

    @renderHUD()     # if @renderHUD
    @renderScanner() # if @renderScanner
    @renderer.render @stage
    requestAnimationFrame @animate
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
