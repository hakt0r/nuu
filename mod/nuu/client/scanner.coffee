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
    Stellar:  [0xFFFFFF,'◆']
    Asteroid: [0xFFFFFF,'◆']
    Debris:   [0xCCCCCC,'◆']
    Cargo:    [0xCCCC00,'◆']
    Planet:   [0xCCFFCC,'◎']
    Moon:     [0x00FFFF,'◌']
    Station:  [0xFF00FF,'◊']
    Ship:     [0xCC00FF,'◭']
    Star:     [0xFFFF00,'◍']

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
    @$.addChild @long  = new PIXI.Container
    @$.addChild @mid   = new PIXI.Container
    @$.addChild @short = new PIXI.Container
    NUU.on '$obj:add',         @addObjects
    NUU.on '$obj:range:short', @addToRange 'short', @short, no
    NUU.on '$obj:range:mid',   @addToRange 'mid',   @mid,   no
    NUU.on '$obj:range:long',  @addToRange 'long',  @long,  no
    NUU.on 'target:new',       @newTarget
    NUU.on 'target:lost',      @lostTarget
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
      @short.position.set W2R,W2R
      @mid  .position.set W2R,W2R
      @long .position.set W2R,W2R
      @$.removeChild @bg
    else
      W = @width; W2 = W/2; W2R = W2/2
      @$.position.set WDB2-W2-3, HEIGHT - W - 18
      @short.position.set W2R+3,W2R+1
      @mid  .position.set W2R+3,W2R+1
      @long .position.set W2R+3,W2R+1
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
    return [ fallback[0], fallback[1], '', fallback[2] ] unless t = @color[s.constructor.name]
    [fill, name, texture] = t
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
    return [name,fill,title,texture,alpha]

  addObjects:(list,scope=@short,inRange)=>
    list = [list] unless list.push
    for s in list
      continue if s.symbol # or not s.name
      [ name, fill, title, texture, alpha ] = @symbolStyle s, inRange
      @makeSymbol s, texture, fill, alpha, scope
      @makeTitle  s, title, fill, alpha, scope
      s.scope = scope
      s.ref @, @removeSymbol
    return

  addToRange:(name,scope,inRange)=> (list)=>
    @updateSymbols list, scope, inRange

  updateSymbols:(list,scope,inRange)->
    add = []
    for s in list
      if old = s.scope
        continue if old is scope
        @updateSymbol s,scope,old,inRange
      else add.push s
    @addObjects add, scope
    return

  updateSymbol:(s,scope,old=s.scope,inRange=false)->
    s.scope = scope
    [sym, fill, text, tex, alpha] = @symbolStyle s, inRange
    if symbol = s.symbol
      old.removeChild symbol; scope.addChild symbol
      symbol.tint  = fill
      symbol.scope = scope
      symbol.alpha = alpha
      symbol.scale.set if TARGET is s then 1 else .5
    if title = s.title
      old.removeChild title
      if text is ''
        title.destroy()
        delete s.title
      else
        if text isnt title.text
          title.text = text
          title.updateText()
        scope.addChild title
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
    symbol.scope = scope
    symbol.tint  = fill
    symbol.alpha = alpha
    symbol.scale.set .5
    symbol.anchor.set .5,.5
    symbol

  makeTitle:(s,text,fill,alpha,scope)->
    return null if title is ''
    scope.addChild title = s.title = new PIXI.Text text, fontFamily: 'Lato', fontSize:'10px', fill: 0xFFFFFF
    title.updateText()
    title.anchor.set 0, .5
    title.tint  = fill
    title.scope = scope
    title.alpha = alpha
    title.style.stroke = 0x000000
    title

  removeSymbol:(s)->
    return unless s.id?
    scope = s.scope; delete s.scope
    if symbol = s.symbol
      scope.removeChild symbol
      symbol.destroy()
      delete s.symbol
    if title = s.title
      scope.removeChild title
      title.destroy()
      delete s.title
    return

  newTarget:(obj,old)=>
    for r in [{s:obj,inRange:yes},{s:old,inRange:no}] when r.s
      {s,inRange} = r
      if symbol = s.symbol
        @updateSymbol s,s.scope,s.scope,inRange
      else @addObjects [s],s.scope,inRange
    @updateMidrange = @updateLongrange = yes
    do @render
    return
  lostTarget:(old)=> @newTarget null, old

  render:=>
    return unless @active
    return unless pl = VEHICLE
    { W2, W2R } = @
    { x,y } = pl
    renderAll       = @wasFullscreen isnt @fullscreen or @scale isnt @lastScale
    renderMidrange  = @updateMidrange  or renderAll
    renderLongrange = @updateLongrange or renderAll
    @updateLongrange = @updateMidrange = no
    @wasFullscreen   = @fullscreen
    @lastScale       = @scale
    # if @orbits and Target
    #   orbits = Array.uniq [TARGET,VEHICLE].concat Object.values Target.hostile
    #   orbits.map (s)-> Array.pushUnique orbits, rel if rel = s.state.relto
    #   @orbit.cacheAsBitmap = no
    #   @renderOrbits @orbit,x,y,W2,W2R,orbits
    #   @orbit.cacheAsBitmap = yes
    if renderMidrange
      @mid.cacheAsBitmap = no
      @renderRange x,y,W2,W2R,MIDRANGE
      @mid.cacheAsBitmap = yes
    if renderLongrange
      @long.cacheAsBitmap = no
      @renderRange x,y,W2,W2R,LONGRANGE
      @long.cacheAsBitmap = yes
    @renderRange x,y,W2,W2R,SHORTRANGE
    return

  renderOrbits:(g,x,y,W2,W2R,list)->
    g.clear(); g.fillAlpha = 0.2
    a = [0,0]
    for s in list
      w = max 1, min 2, s.size * 100 / @scale
      a[0] = s.x - x
      a[1] = s.y - y
      l = min W2-5, ( $v.mag v = a ) / @scale
      v = $v.mult $v.norm(v), l
      if L = s.symbol
        hw = L.width/2
        hh = L.height/2
        L.position.set v[0]+W2R-hw, v[1]+W2R-hh
        T = s.title
        if v[0] < 0 then T.position.set v[0]+W2R+4,         v[1]+W2R+1-hh
        else             T.position.set v[0]+W2R-3-T.width, v[1]+W2R+1-hh
      g.lineStyle 2, @color.SubOrbit
      mv = max abs(v[0]), abs(v[1])
      mc = max abs(W2R),  abs(W2R)
      if s is TARGET then for o in s.orbits || [] when mc * 1.25 > mv + o / @scale
        g.endFill g.drawCircle v[0]+W2R, v[1]+W2R, o / @scale
      g.lineStyle 2, @color.Orbit
      if ( st = s.state ).S is $orbit
        rel = st.relto
        o = st.orb / @scale
        a[0] = rel.x - x
        a[1] = rel.y - y
        ol = min W2-5, ( $v.mag ov = a ) / @scale
        ov = $v.mult $v.norm(ov), ol
        g.endFill g.drawCircle v[0]+W2R, v[1]+W2R, o if o + ol < W2
    return

  renderRange:(x,y,W2,W2R,list)->
    a = [0,0]; length = list.length; i = 0
    TG = TARGET
    while i < length
      s = list[i++]
      w = max 1, min 2, s.size * 100 / @scale
      a[0] = s.x - x
      a[1] = s.y - y
      l = min W2-5, ( $v.mag v = a ) / @scale
      v = $v.mult $v.norm(v), l
      if L = s.symbol
        L.position.set v[0]+W2R, v[1]+W2R
        L.rotation = RADi * (s.d+90)
      if T = s.title
        d = if s is TG then 10 else 5
        if v[0] < 0
          T.position.set v[0]+W2R+d, v[1]+W2R
        else
          T.position.set v[0]+W2R-d-T.width, v[1]+W2R
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

Kbd.macro 'scanToggleFS', 'aEnter',  'Toggle Scanner FS',  Scanner.toggleFullscreen
Kbd.macro 'scanToggle',   'Enter',   'Toggle Scanner',     Scanner.toggle
Kbd.macro 'scanPlus',     'Equal',   'Zoom scanner in',    Scanner.zoomIn
Kbd.macro 'scanMinus',    'Minus',   'Zoom scanner out',   Scanner.zoomOut
