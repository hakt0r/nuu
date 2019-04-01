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

$static 'Scanner', new class ScannerRenderer
  id     : 0
  type   : 0
  width  : 200
  height : 200
  scale  : 1.0
  active : true
  label  : {}
  orbits : yes
  fullscreen : no

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

  constructor: ->
    @gfx = Sprite.layer 'scan', new PIXI.Graphics true
    # @gfx.cacheAsBitmap = yes
    @gfx.width = @gfx.height = @width
    @circleMode = yes
    @fullscreen = no
    Sprite.renderScanner = @render.bind @
    NUU.on '$obj:add', @addLabel()
    NUU.on '$obj:del', @removeLabel()
    NUU.on '$obj:inRange', (obj) ->
      return unless obj and l = Scanner.label[obj.id]
      [l.text, l.style.fill,l._label.text] = Scanner.labelStyle obj, true
      PIXI.bringToFront l
      null
    NUU.on '$obj:outRange', (obj) ->
      return unless obj and l = Scanner.label[obj.id]
      [l.text, l.style.fill,l._label.text] = Scanner.labelStyle obj
      null
    NUU.on 'newTarget', (obj,old) ->
      if obj and l = Scanner.label[obj.id]
        [l.text, l.style.fill,l._label.text] = Scanner.labelStyle obj, true
        PIXI.bringToFront l
      if old and l = Scanner.label[old.id]
        [l.text, l.style.fill,l._label.text] = Scanner.labelStyle old
      null
    null

  labelStyle: (s,inRange=false)->
    return ['◆','white',''] unless t = Scanner.color[s.constructor.name]
    [fill, name] = t
    title = ''
    if      s.constructor is Star   then title = s.name || 'Star'
    else if s.constructor is Planet then title = s.name || 'Planet'
    title = '' if inRange
    fill = 'red'     if s is TARGET
    return [name,fill,title]

  addLabel: -> (s) =>
    return unless s.name
    @removeLabel s if @label[s.id]
    [name,fill,title] = @labelStyle s
    @gfx.addChild l = @label[s.id] = new PIXI.Text name,  fontFamily: 'monospace', fontSize:'8px', fill: fill
    @gfx.addChild l._label         = new PIXI.Text title, fontFamily: 'monospace', fontSize:'8px', fill: fill
    l.$obj = s
    null

  removeLabel: -> (s) =>
    return unless l = @label[s.id]
    _label = l._label
    delete @label[s.id]
    l.visible = no
    @gfx.removeChild l
    Array.remove @gfx.children, l
    l.destroy()
    return unless _label
    _label.visible = no
    @gfx.removeChild _label
    Array.remove @gfx.children, _label
    _label.destroy()

  render: ->
    return unless @active
    return unless pl = VEHICLE
    if @fullscreen
      W = min WIDTH, HEIGHT; W2 = W/2-150; W2R = WDB2; H2R = HGB2
      @gfx.position.set 0,0 unless @gfx.position[0] is 0
    else
      W2 = H2 = ( W = H = @width ) / 2; W2R = H2R = 100
      @gfx.position.set WDB2 - 100, HEIGHT - 210
    @radius = W2
    lb = @label
    px = pl.x; py = pl.y
    ( g = @gfx ).clear()
    g.fillAlpha = 0.2
    canHazOrbit = Array.uniq [TARGET,VEHICLE].concat Object.values Target.hostile
    canHazOrbit.map ( s )-> canHazOrbit.push s.state.relto if s.state.relto
    canHazOrbit = Array.uniq canHazOrbit
    skipId = canHazOrbit.map (i)-> i.id
    a = [0,0] # static allocation for magnitude-input in loop
    for s in canHazOrbit
      w = max 1, min 2, s.size * 100 / @scale
      a[0] = s.x - px
      a[1] = s.y - py
      l = min W2-5, ( $v.mag v = a ) / @scale
      v = $v.mult $v.normalize(v), l
      if L = lb[s.id]
        hw = L.width/2
        hh = L.height/2
        L.position.set v[0]+W2R-hw, v[1]+H2R-hh
        if v[0] < 0 then L._label.position.set v[0]+W2R+4,                v[1]+H2R+1-hh
        else             L._label.position.set v[0]+W2R-3-L._label.width, v[1]+H2R+1-hh
      g.lineStyle 2, @color.SubOrbit
      mv = max abs(v[0]), abs(v[1])
      mc = max abs(W2R),  abs(H2R)
      if s is TARGET then for o in s.orbits || [] when mc * 1.25 > mv + o / @scale
        g.endFill g.drawCircle v[0]+W2R, v[1]+H2R, o / @scale
      g.lineStyle 2, @color.Orbit
      if s.state.S is $orbit and Scanner.orbits
        o = s.state.orb / @scale
        a[0] = s.state.relto.x - px
        a[1] = s.state.relto.y - py
        ol = min W2-5, ( $v.mag ov = a ) / @scale
        ov = $v.mult $v.normalize(ov), ol
        if o + ol < W2
          g.endFill g.drawCircle v[0]+W2R, v[1]+H2R, o
    # TODO: more inRange magic
    # time = NUU.time()
    # return if @nextUpdate > time; @nextUpdate = time + if @scale < 1024 then TICK else 250
    for s in $obj.list
      continue unless -1 is skipId.indexOf s.id
      w = max 1, min 2, s.size * 100 / @scale
      a[0] = s.x - px
      a[1] = s.y - py
      l = min W2-5, ( $v.mag v = a ) / @scale
      v = $v.mult $v.normalize(v), l
      if L = lb[s.id]
        hw = L.width/2
        hh = L.height/2
        L.position.set v[0]+W2R-hw, v[1]+H2R-hh
        if v[0] < 0 then L._label.position.set v[0]+W2R+4,                v[1]+H2R+1-hh
        else             L._label.position.set v[0]+W2R-3-L._label.width, v[1]+H2R+1-hh
    null

  toggleFS: ->
    if not @active then Sprite.stage.addChild @gfx
    @active = true
    @fullscreen = not @fullscreen


  toggle: ->
    @active = not @active
    #console.log Sprite.stage.children.indexOf @gfx
    if @active then Sprite.stage.addChild @gfx
    else Sprite.stage.removeChild @gfx

  zoomIn: ->
    Scanner.scale = max 1, Scanner.scale / 2

  zoomOut: ->
    Scanner.scale = min 134217728, Scanner.scale * 2

Kbd.macro 'scanToggleFS', 'aEnter',  'Toggle Scanner FS',  Scanner.toggleFS.bind Scanner
Kbd.macro 'scanToggle',   'Enter',   'Toggle Scanner',     Scanner.toggle.bind Scanner
Kbd.macro 'scanPlus',     'Equal',   'Zoom scanner in',    Scanner.zoomIn.bind Scanner
Kbd.macro 'scanMinus',    'Minus',   'Zoom scanner out',   Scanner.zoomOut.bind Scanner
