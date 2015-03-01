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

$static 'Sprite', new class SpriteSurface extends EventEmitter

  constructor: (callback)->
    @visible  = {}
    @stage    = stage    = new PIXI.Stage 0x000000
    @renderer = renderer = PIXI.autoDetectRenderer 640,480, antialias: yes

    @layer 'bg',   new PIXI.DisplayObjectContainer
    @layer 'stel', new PIXI.DisplayObjectContainer
    @layer 'debr', new PIXI.DisplayObjectContainer
    @layer 'ship', new PIXI.DisplayObjectContainer
    @layer 'weap', new PIXI.Graphics
    @layer 'scan', new PIXI.Graphics
    @layer 'play', new PIXI.DisplayObjectContainer
    @layer 'pwep', new PIXI.Graphics
    @layer 'fg',   new PIXI.DisplayObjectContainer

    animate = =>
      requestAnimationFrame animate
      @renderSpace()
      HUD.update()
      Scanner.render()
      renderer.render stage
      return
    requestAnimationFrame animate

    app.on 'runtime:ready', =>
      document.body.appendChild renderer.view
      @window = $ window
      do @resize = =>
        @hw = ( @wd = @window.width()  ) / 2
        @hh = ( @hg = @window.height() ) / 2
        @renderer.resize @wd, @hg
        @emit 'resize', @wd, @hg, @hw, @hh
      @window.on 'resize', @resize
  
    @on 'resize', (wd,hg,hw,hh) =>
      console.log 'NUU.render.resize', wd, hg, hw, hh
      return unless Asset.imag.starfield
      @fg.removeChildren()
      @bg.removeChildren()
      @fg.addChild @parallax  = new PIXI.TilingSprite PIXI.Texture.fromImage Asset.imag.parallax.src
      @fg.addChild @parallax2 = new PIXI.TilingSprite PIXI.Texture.fromImage Asset.imag.parallax.src
      @bg.addChild @starfield = new PIXI.TilingSprite PIXI.Texture.fromImage Asset.imag.starfield.src
      @starfield.width  = @parallax2.width  = @parallax.width  = wd
      @starfield.height = @parallax2.height = @parallax.height = hg
    null

  layer: (name,container)->
    @[name] = container
    @stage.addChild container
    @visible[name] = []
    container

  start: (callback) =>
    @startTime    = Ping.remoteTime()
    NUU.thread 'select', 500, @select()
    callback null if callback
    null

  stop: ->
    clearInterval @select.timer 
    @bg.removeChildren()

  select: -> =>
    pl = NUU.vehicle
    px = floor pl.x
    py = floor pl.y
    wd2 = @wd + @wd
    hg2 = @hg + @hg
    rdst = @hw + @hh
    dist = (s) -> sqrt(pow(px-s.x,2)+pow(py-s.y,2))
    TIME = NUU.time()
    s.update() for s in $obj.list
    for s in $obj.list
      if s.ttl and s.ttl < TIME
        console.log 'hiding', s.id
        s.hide() if s.currentSprite
        continue
      s.update()
      if s.inVisibleRange px, py, wd2, hg2
        s.show() unless s.currentSprite
      else if @visible[s.id]
        s.hide() if s.currentSprite
    null

## ASSET LOADERS FOR GAME OBJECTS
app.on '$obj:add', (obj) -> obj.loadAssets()
app.on '$obj:inRange', (obj) -> obj.show()
app.on '$obj:outRange', (obj) -> obj.hide()
app.on '$obj:del', (obj) -> obj.hide()

$obj::inVisibleRange = (x,y,fx,fy)->
  @size + fx > abs( @x - x ) and @size + fy > abs( @y - y )

$obj::inVisibleRangeLocal = ->
  v = NUU.vehicle || x:0, y:0
  @inVisibleRange v.x, v.y, 2000, 2000

## GENERIC OBJECTS
$obj::layer = 'bg'
Stellar::layer = 'stel'

$obj::loadAssets = ->
  @img = Asset.imag.loading
  Asset.load 'stel', @sprite, @sprite, (@img) =>
    @show()

$obj::updateSprite = ->
  if Sprite.visible[@id]
    old = @currentSprite
    Sprite[@layer].addChild @currentSprite = @getSprite()
    Sprite[@layer].removeChild old
  else @currentSprite = @getSprite()
  null

$obj::updateTile = ->
  return unless @currentSprite
  n = (@count - round(@d / (360 / (@count - 1)))) % @count
  @currentSprite.tilePosition.set(
    -( floor(n % @cols) * @size )
    -( floor(n / @cols) * @size ) )
  null

$obj::show = ->
  if @currentSprite
    return @updateSprite()
  else @updateSprite()
  Sprite.visible[@layer].push @
  Sprite.visible[@id] = @currentSprite
  Sprite[@layer].addChild @currentSprite

$obj::hide = -> if @currentSprite
  Array.remove Sprite.visible[@layer], @
  Sprite[@layer].removeChild @currentSprite
  delete Sprite.visible[@id]
  @currentSprite = null

$obj::getSprite = -> PIXI.Sprite.fromImage @img.src
$obj::removeSprite = -> @updateSprite 'stel', yes

## SHIPS
Ship::layer = 'ship'
Ship::loadAssets = ->
  @img = Asset.imag.loading
  url = ( name = @sprite ) + '/' + name
  url = url.replace(/_.*/,'')+'/'+name if name.match /_/
  async.parallel [
    (cb) =>
      Asset.load 'ship', name, url, (@img) =>
        @size = ( @img.naturalWidth - ( @img.naturalWidth % @cols ) ) / @cols
        @count = @cols * @rows
        @updateTile()
        cb null
    (cb) =>
      Asset.load 'ship',name+'_comm',url+'_comm', (img) =>
        Sprite.lastload = img # for splash progress
        @img_comm = img
        cb null
    (cb) =>
      Asset.load 'ship',name+'_engine',url+'_engine', (img) =>
        @img_engine = img
        cb null
  ], =>
    @show()
    Sprite.repositionPlayer() if @id is NUU.vehicle.id

Ship::getSprite = ->
  t = new PIXI.TilingSprite PIXI.Texture.fromImage @img.src, @size, @size
  t.width  = @size
  t.height = @size
  t

## ANIMATIONS
Animated::layer = 'debr'
Animated::loadAssets = -> @show()

Animated::getSprite = ->
  ani = Asset.spfx[@animation].create(@x,@y,@endless)
  ani.obj = @
  ani.sprite._animation = ani
  ani.sprite

Animated::hide = -> if @currentSprite
  @currentSprite._animation.endless = no
  super
