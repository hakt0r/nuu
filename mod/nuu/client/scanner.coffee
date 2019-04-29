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

$static 'Scanner', new class NUU.Scanner

  scale:         16
  width:         200

  active:        true
  orbits:        yes
  midRange:      yes
  longRange:     yes

  fullscreen:    no
  wasFullscreen: no

  color:
    Orbit:    [0x330000]
    SubOrbit: [0x330033]
    Stellar:  [0xFFFFFF,'◆',null,'dynamic',false] # gen
    Debris:   [0xCCCCCC,'◆',null,'dynamic',false] # gen
    Cargo:    [0xCCCC00,'◆',null,'dynamic',false] # gen
    Star:     [0xFFFF00,'◍',null,'star',   10   ] # star
    Planet:   [0xCCFFCC,'◎',null,'planet', 500  ] # planet
    Moon:     [0x00FFFF,'◌',null,'moon',   5000 ] # moon
    Asteroid: [0xFFFFFF,'◆',null,'roid',   10000] # roid
    Station:  [0xFF00FF,'◊',null,'station',1000 ] # station
    Ship:     [0xCC00FF,'◭',null,'ship',   10000] # ship

  constructor:-> Sprite.renderScanner = ->

  show:->
    for k,v of @color when sym = v[1]
      t = new PIXI.Text sym, fontFamily: 'monospace', fontSize:'20px', fill: 'white'
      t.updateText()
      v[2] = t.texture
    @$ = new PIXI.Container
    @bg = new PIXI.Sprite
    @bg.alpha = 0.7
    @$.addChild @bg
    # @$.addChild @orbit = new PIXI.Graphics true
    @$.addChild @dynamic = new PIXI.Container
    @$.addChild @star    = new PIXI.ParticleContainer 10
    @$.addChild @planet  = new PIXI.ParticleContainer 500
    @$.addChild @moon    = new PIXI.ParticleContainer 5000
    @$.addChild @roid    = new PIXI.ParticleContainer 10000
    @$.addChild @station = new PIXI.ParticleContainer 1000
    @$.addChild @ship    = new PIXI.ParticleContainer 10000
    @$.addChild @title   = new PIXI.Container
    NUU.on '$obj:add',    @addObjects
    NUU.on '$obj:del',    @removeObjects
    NUU.on 'target:new',  @newTarget
    NUU.on 'target:lost', @lostTarget
    Sprite.renderScanner = @render
    Sprite.layer 'scanner', @$
    Sprite.on 'resize', @resize
    do @resize
    return

  resize:=>
    @renderLongrange = @renderMidrange = yes
    if @fullscreen
      W = max(WIDTH,HEIGHT)/-10 + sqrt WIDTH**2 + HEIGHT**2
      W2 = W/2
      W2R = W2/2
      @$.position.set (WIDTH-W)/2,(HEIGHT-W)/2
      @dynamic.position.set W2R,W2R; @title.position.set W2R,W2R
      @star.position.set W2R,W2R;    @planet.position.set W2R,W2R
      @moon.position.set W2R,W2R;    @roid.position.set W2R,W2R
      @station.position.set W2R,W2R; @ship.position.set W2R,W2R
      @$.removeChild @bg
    else
      W = @width; W2 = W/2; W2R = W2/2
      @$.position.set WDB2-W2-3, HEIGHT - W - 18
      @dynamic.position.set W2R,W2R; @title.position.set W2R,W2R
      @star.position.set W2R,W2R;    @planet.position.set W2R,W2R
      @moon.position.set W2R,W2R;    @roid.position.set W2R,W2R
      @station.position.set W2R,W2R; @ship.position.set W2R,W2R
      #@orbit.position.set W2R+7,W2R+7
      c = document.createElement 'canvas'
      c.width = c.height = WIDTH + 8
      g = c.getContext '2d'
      g.fillStyle = "#000"
      g.strokeStyle = "#444"
      g.strokeWidth = 2
      g.beginPath()
      g.arc W2+2, W2+2, W2, 0, TAU
      g.fill()
      g.stroke()
      @bg.setTexture t = PIXI.Texture.from c
      @bg.___tex__.destroy() if @bg.___tex__
      @bg.___tex__ = t
      @$.addChildAt @bg, 0
    @radius = @W2 = W2; @W2R = W2R
    do @render

  symbolStyle:(s,inRange=false)->
    fallback = @color.Stellar
    scope = @dynamic
    return [ fallback[0], fallback[1], '', fallback[2], 0.2, scope ] unless t = @color[s.constructor.name]
    [fill, name, texture, scopeName] = t
    scope = @[scopeName]
    title = ''
    title = s.name if inRange
    alpha = .2
    switch s.constructor
      when Star, Planet
        title = s.name || s.constructor.name
        alpha = .5
      when Station
        alpha = 1
      when Ship
        alpha = .2
    if s is TARGET
      fill  = 0xffffff
      alpha = 1
      title = s.name || s.constructor.name
    return [name,fill,title,texture,alpha,scope]

  addObjects:(list,inRange)=>
    list = [list] unless list.push
    for s in list when not s.symbol
      [ name,fill,title,texture,alpha,scope ] = @symbolStyle s, inRange
      @makeSymbol s, texture, fill, alpha, scope
      @makeTitle  s, title,   fill, alpha, scope
      s.scope = scope
      s.ref @, @removeSymbol
    return

  removeObjects:(list)=>
    list = [list] unless list.push
    removeSymbol s for s in list when s.symbol
    return

  updateSymbol:(s,old=s.scope,inRange=false)->
    [sym, fill, text, tex, alpha, scope] = @symbolStyle s, inRange
    if symbol = s.symbol
      old.removeChild symbol; scope.addChild symbol
      symbol.tint  = fill
      symbol.scope = scope
      symbol.alpha = alpha
      symbol.scale.set if TARGET is s then 1 else .5
    if title = s.title
      @title.removeChild title
      if text is ''
        title.destroy()
        delete s.title
      else
        if text isnt title.text
          title.text = text
          title.updateText()
        @title.addChild title
        title.scope = scope
        title.tint  = fill
        title.alpha = alpha
        title.style.strokeThickness = if TARGET is s then 2 else 0
        title.updateText()
    else if text isnt ''
      @makeTitle s, text, fill, alpha, scope
    return

  makeSymbol:(s,tex,fill,alpha,scope)->
    scope.addChild symbol = s.symbol = new PIXI.Sprite tex
    symbol.o = s
    symbol.scope = scope
    symbol.tint  = fill
    symbol.alpha = alpha
    symbol.scale.set .5
    symbol.anchor.set .5,.5
    symbol

  makeTitle:(s,text,fill,alpha)->
    return null if title is ''
    @title.addChild title = s.title = new PIXI.Text text, fontFamily: 'Lato', fontSize:'10px', fill: 0xFFFFFF
    title.updateText()
    title.o = s
    title.anchor.set 0, .5
    title.tint  = fill
    title.alpha = alpha
    title.style.stroke = 0x000000
    title

  removeSymbol:(s)->
    return unless s.id?
    scope = s.scope; delete s.scope
    if symbol = s.symbol
      scope.removeChild symbol
      symbol.destroy()
      s.symbol = false
    if title = s.title
      @title.removeChild title
      title.destroy()
      s.title = false
    return

  newTarget:(obj,old)=>
    for r in [{s:obj,inRange:yes},{s:old,inRange:no}] when r.s
      {s,inRange} = r
      if symbol = s.symbol
        @updateSymbol s,s.scope,inRange
      else @addObjects [s],s.scope,inRange
    do @render
    return
  lostTarget:(old)=> @newTarget null, old

  render:=>
    return unless @active
    return unless PL = VEHICLE
    { W2, W2R }    = @
    { x,y }        = PL
    TG             = TARGET
    @wasFullscreen = @fullscreen
    @lastScale     = @scale
    for scope in [@dynamic,@star,@planet,@moon,@roid,@station,@ship]
      for c in scope.children
        s = c.o
        { x:sx, y:sy, d, symbol } = s
        dx = sx - x
        dy = sy - y
        mag = sqrt(dx**2+dy**2)
        scl = min W2-5,mag/@scale
        dx = (dx/mag)*scl+W2R
        dy = (dy/mag)*scl+W2R
        symbol.position.x = dx
        symbol.position.y = dy
        symbol.rotation = RADi * (d+90)
    cld = @title.children.slice()
    for c in @title.children
      s = c.o
      { x:sx, y:sy, title } = s
      dx = sx - x
      dy = sy - y
      mag = sqrt(dx**2+dy**2)
      scl = min W2-5,mag/@scale
      dx = (dx/mag)*scl+W2R
      dy = (dy/mag)*scl+W2R
      o = if s is TG then 10 else 5
      if dx < 0 then title.position.set dx+o,             dy
      else           title.position.set dx-o-title.width, dy
    return

  toggle:=>
    @$.visible = @active = not @active
    if @active then Sprite.stage.addChild @$
    else Sprite.stage.removeChild @$
    PIXI.bringToFront HUD.layer
    return

  toggleFullscreen:=>
    @fullscreen = not @fullscreen
    @toggle() if not @active
    do @resize
    return

  zoomIn:=>  @scale = max 1,         @scale / 2
  zoomOut:=> @scale = min 134217728, @scale * 2

Object.defineProperty PIXI.Sprite::, 'o', default:null, writable:yes

Kbd.macro 'scanToggleFS', 'aEnter',  'Toggle Scanner FS',  Scanner.toggleFullscreen
Kbd.macro 'scanToggle',   'Enter',   'Toggle Scanner',     Scanner.toggle
Kbd.macro 'scanPlus',     'Equal',   'Zoom scanner in',    Scanner.zoomIn
Kbd.macro 'scanMinus',    'Minus',   'Zoom scanner out',   Scanner.zoomOut
