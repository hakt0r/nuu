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

class SpaceRenderer
  sprite: {}
  constructor: ->

    Sprite.main = @
    Sprite.stage.addChild @frame = new PIXI.DisplayObjectContainer
    @frame.addChild @bg    = new PIXI.DisplayObjectContainer
    @frame.addChild @stel  = new PIXI.DisplayObjectContainer
    @frame.addChild @debr  = new PIXI.DisplayObjectContainer
    @frame.addChild @ship  = new PIXI.DisplayObjectContainer
    @frame.addChild @weap  = new PIXI.Graphics
    @frame.addChild @play  = new PIXI.DisplayObjectContainer
    @frame.addChild @fg    = new PIXI.DisplayObjectContainer
    ( @window = $(window) ).on 'resize', @resize
    @start @updatePlayer @resize()
    Sprite.stage.addChild Sprite.scanner.gfx
    Sprite.stage.addChild Sprite.hud.gfx

  resize: =>
    return unless Sprite.imag.starfield
    @bg.addChild @starfield = new PIXI.TilingSprite PIXI.Texture.fromImage Sprite.imag.starfield.src
    @fg.addChild @parallax  = new PIXI.TilingSprite PIXI.Texture.fromImage Sprite.imag.parallax.src
    @starfield.width  = @parallax.width = @wd = @window.width();   @hw = @wd / 2
    @starfield.height = @parallax.height = @hg = @window.height(); @hh = @hg / 2

  stop: ->
    clearInterval @timer 
    @bg.removeChildren()
    @sprite = {}

  start: ->
    @startTime = Ping.remoteTime()
    @timer = setInterval @update

  updateShip: (s,remove=false,layer='ship') =>
    layer = 'play' if s is NUU.vehicle
    console.log 'updateShip', layer, s
    @[layer].removeChild @sprite[s.id] if @sprite[s.id]
    unless remove
      @sprite[s.id] = s.currentSprite = t = new PIXI.TilingSprite PIXI.Texture.fromImage s.img.src, s.size, s.size
      t.width  = s.size
      t.height = s.size
      Sprite.update s
      @[layer].addChild t
    else delete @sprite[s.id]
    t
    
  updateSprite: (layer='bg',s,remove=false) =>
    console.log 'updateSprite', s
    @[layer].removeChild @sprite[s.id] if @sprite[s.id]
    unless remove
      @sprite[s.id] = s = PIXI.Sprite.fromImage s.img.src
      @[layer].addChild s
    else delete @sprite[s.id]
    s

  updatePlayer: =>
    return unless NUU.player
    return unless NUU.player.vehicle
    @updateShip('play',NUU.player.vehicle)

  update: =>
    return unless ( p = NUU.player )

    px = py = 0
    alerts = []
    pl = null
    sc = 1
    now = Ping.remoteTime()

    log = (args...) -> alerts.push args.join ' ' 
    dist = (s) -> sqrt(pow(px-s.x,2)+pow(py-s.y,2))

    pl = NUU.vehicle
    pl.update() unless pl.state is manouvering
    ps = pl.size / 2
    pox = @hw - ps
    poy = @hh - ps

    scanner = Sprite.scanner
    target  = Sprite.target
    hud     = Sprite.hud

    # sc = (abs(@mx)+abs(@my))*0.01 + 1 if NUU.scale # speedscale  
    px = floor pl.x
    py = floor pl.y
    dx = floor px * -1 + @hw
    dy = floor py * -1 + @hh
    rdst = (@hw + @hh)

    # STARS
    @starfield.tilePosition.x -= pl.mx * 0.1
    @starfield.tilePosition.y -= pl.my * 0.1

    # STELLARS
    for i,s of Stellar.byId
      s.update()
      size = parseInt s.size
      if ( s.pdist = dist s ) < rdst + size
        hs = size / 2
        ox = floor s.x + dx - hs
        oy = floor s.y + dy - hs
        unless @sprite[s.id]
          @updateSprite('stel',s).position.set ox, oy
        else @sprite[s.id].position.set ox, oy
      else if @sprite[s.id] then @updateSprite 'stel',s,yes

    # DEBRIS
    for i,s of Debris.byId
      s.update()
      size = parseInt s.size
      if ( s.pdist = dist s ) < rdst + size
        hs = size / 2
        ox = floor s.x + dx - hs
        oy = floor s.y + dy - hs
        unless @sprite[s.id]
          @updateSprite('debr',s).position.set ox, oy
        else @sprite[s.id].position.set ox, oy
      else if @sprite[s.id] then @updateSprite 'debr',s,yes

    # WEAPONS
    @weap.clear()
    for k,s of Weapon.proj
      ticks = (now - s.ms) / TICK
      x = dx + floor(s.sx + s.mx * ticks)
      y = dy + floor(s.sy + s.my * ticks)
      if x > 0 and x < @wd and y > 0 and y < @hg
        @weap.beginFill 0xFF0000, 0.3
        @weap.drawCircle x-1, y-1, 3
        @weap.endFill()

    # OTHER SHIPS
    for i,s of Ship.byId
      s.update() unless s.state is manouvering
      size = parseInt s.size
      dir  = s.d / RAD
      if ( s.pdist = dist s ) < rdst + size
        rx = floor s.x + dx
        ry = floor s.y + dy
        hs = size / 2
        ox = floor rx  - hs
        oy = floor ry  - hs
        # img = if moving < s.state then s.img_engine else s.img
        unless @sprite[s.id]
          @updateShip(s).position.set ox, oy
        else
          @sprite[s.id].position.set ox, oy
          Sprite.update s
        # draw beam weapon
        #if (beam = Weapon.beam[s.id])? then for k,b of beam
        #  @weap.beginFill 0xFF0000, 1
        #  @weap.lineStyle 2, 0xFF0000, 1
        #  @weap.moveTo rx, ry
        #  @weap.lineTo rx + cos(dir) * 300, ry + sin(dir) * 300
        #  @weap.endFill()
      else if @sprite[s.id] then @updateShip s, yes

    AnimatedSprite.render dx, dy, @weap
    
    # STARFIELD OR ATMOSPHERE    
    @parallax.tilePosition.x -= pl.mx * 1.5
    @parallax.tilePosition.y -= pl.my * 1.5

Sprite.on 'gameLayer', -> new SpaceRenderer
