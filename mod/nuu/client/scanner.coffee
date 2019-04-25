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
      t = new PIXI.Text sym, fontFamily: 'monospace', fontSize:'8px', fill: 'white'
      t.updateText()
      v[2] = t.texture
    @$ = new PIXI.Container
    @bg = new PIXI.Sprite
    @bg.alpha = 0.4
    @$.addChild @bg
    # @$.addChild @orbit = new PIXI.Graphics true
    @$.addChild @long  = new PIXI.Container; @long.alpha = 0.4
    @$.addChild @mid   = new PIXI.Container; @mid .alpha = 0.7
    @$.addChild @short = new PIXI.Container
    NUU.on '$obj:add',         @addLabel   .bind @
    NUU.on '$obj:range:short', @addToRange 'short', @short, yes
    NUU.on '$obj:range:mid',   @addToRange 'mid',   @mid,   yes
    NUU.on '$obj:range:long',  @addToRange 'long',  @long,  yes
    Sprite.layer 'scanner', @$
    NUU.on 'target:new', @newTarget
    NUU.on 'target:lost', @lostTarget
    Sprite.renderScanner = @render
    Sprite.on 'resize', @resize
    do @resize
    return

  resize:=>
    @renderLongrange = @renderMidrange = yes
    if @fullscreen
      W = max WIDTH - 28, HEIGHT - 38
      W2 = W/2
      W2R = W2/2
      @$.position.set (WIDTH-W)/2,(HEIGHT-W)/2
    else
      W = @width; W2 = W/2; W2R = W2/2
      @$.position.set WDB2-W2-2, HEIGHT - W - 18
    @radius = @W2 = W2; @W2R = W2R
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
    do @render

  labelStyle:(s,inRange=false)->
    fallback = @color.Stellar
    return [
      fallback[0]
      fallback[1]
      ''
      fallback[2]
    ] unless t = @color[s.constructor.name]
    [fill, name, sym] = t
    title = ''
    if      s.constructor is Star    then title = s.name || 'Star'
    else if s.constructor is Planet  then title = s.name || 'Planet'
    # else if s.constructor is Moon    then title = s.name || 'Moon'
    # else if s.constructor is Station then title = s.name || 'Station'
    # title = ''    if inRange
    fill = 'red'  if s is TARGET
    return [name,fill,title,sym]

  addLabel:(list,scope=@short)->
    list = [list] unless list.push
    for s in list
      continue if s.label or not s.name
      [ name, fill, title, tex ] = @labelStyle s
      scope.addChild l = s.label = new PIXI.Sprite tex
      scope.addChild t = s.title = new PIXI.Text title, fontFamily: 'monospace', fontSize:'8px', fill: fill
      s.scope = l.scope = t.scope = scope
      l.tint  = fill
      l.anchor.set .5
      t.pivot.set .5, .5
      s.ref @, @removeLabel
    return

  removeLabel:(s)->
    return unless s.id?
    return unless label = s.label
    scope = label.scope
    scope.removeChild label
    scope.removeChild title = s.title
    delete s.label
    delete s.title
    delete s.scope
    label.destroy()
    title.destroy()
    return

  addToRange:(name,scope,inRange)=> (list)=>
    @updateLabel list, scope, inRange

  updateLabel:(list,scope,inRange)->
    add = []
    for s in list
      if old = s.scope
        continue if old is scope
        old.removeChild l = s.label; scope.addChild l
        old.removeChild t = s.title; scope.addChild t
        s.scope = l.scope = t.scope = scope
        [sym, fill, text] = @labelStyle s, inRange
        t.text = text if text isnt t.text
        l.tint = fill
      else add.push s
    @addLabel add, scope
    return

  newTarget:(obj,old)=>
    if obj and l = obj.label
      t = obj.title
      [sym, fill, text] = @labelStyle obj, yes
      t.text = text if text isnt t.text
      l.tint = fill
      PIXI.bringToFront l
    if old and l = old.label
      t = old.title
      [sym, fill, text] = @labelStyle old
      t.text = text if text isnt t.text
      l.tint = fill
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
      if L = s.label
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
    while i < length
      s = list[i++]
      w = max 1, min 2, s.size * 100 / @scale
      a[0] = s.x - x
      a[1] = s.y - y
      l = min W2-5, ( $v.mag v = a ) / @scale
      v = $v.mult $v.norm(v), l
      if L = s.label
        L.position.set v[0]+W2R, v[1]+W2R
        L.rotation = RADi * (s.d+90)
        T = s.title
        if v[0] < 0 then T.position.set v[0]+W2R+4,         v[1]+W2R+1-4
        else             T.position.set v[0]+W2R-3-T.width, v[1]+W2R+1-4
    return

  toggle:=>
    @$.visible = @active = not @active
    if @active then Sprite.stage.addChild @$
    else Sprite.stage.removeChild @$
    PIXI.bringToFront HUD.layer
    return

  toggleFullscreen:=>
    if not @active then Sprite.stage.addChild @$
    @active = true
    @fullscreen = not @fullscreen
    do @resize
    return

  zoomIn:=>  @scale = max 1,         @scale / 2
  zoomOut:=> @scale = min 134217728, @scale * 2

Kbd.macro 'scanToggleFS', 'aEnter',  'Toggle Scanner FS',  Scanner.toggleFullscreen
Kbd.macro 'scanToggle',   'Enter',   'Toggle Scanner',     Scanner.toggle
Kbd.macro 'scanPlus',     'Equal',   'Zoom scanner in',    Scanner.zoomIn
Kbd.macro 'scanMinus',    'Minus',   'Zoom scanner out',   Scanner.zoomOut
