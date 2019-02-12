###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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
      [l.text, l.style.fill] = Scanner.labelStyle obj, true
      PIXI.bringToFront l
      null
    NUU.on '$obj:outRange', (obj) ->
      return unless obj and l = Scanner.label[obj.id]
      [l.text, l.style.fill] = Scanner.labelStyle obj
      null
    NUU.on 'newTarget', (obj,old) ->
      if obj and l = Scanner.label[obj.id]
        [l.text, l.style.fill] = Scanner.labelStyle obj, true
        PIXI.bringToFront l
      if old and l = Scanner.label[old.id]
        [l.text, l.style.fill] = Scanner.labelStyle old
      null
    null

  labelStyle: (s,inRange=false)->
    return ['◆','white'] unless t = Scanner.color[s.constructor.name]
    [fill, name] = t
    if      s.constructor is Star   then name += s.name || 'Star'
    else if s.constructor is Planet then name += s.name || 'Planet'
    else if                 inRange then name += s.name || ''
    fill = 'red'     if s is TARGET
    return [name,fill]

  addLabel: -> (s) =>
    return unless s.name
    @removeLabel s if @label[s.id]
    [name,fill] = @labelStyle s
    @gfx.addChild l = @label[s.id] = new PIXI.Text name, fontFamily: 'monospace', fontSize:'8px', fill: fill
    l.$obj = s
    null

  removeLabel: -> (s) =>
    return unless l= @label[s.id]
    @gfx.removeChild @label[s.id]
    delete           @label[s.id]
    # HOTFIX
    @gfx.children.splice @gfx.children.indexOf l
    l.visible = no
    # HOTFIX
    l.destroy()

  render: ->
    return unless pl = VEHICLE
    if @fullscreen
      W = min WIDTH, HEIGHT; W2 = W/2-150; W2R = WDB2; H2R = HGB2
      @gfx.position.set 0,0 unless @gfx.position[0] is 0
    else
      W2 = H2 = ( W = H = @width ) / 2; W2R = H2R = 100
      @gfx.position.set WDB2 - 100, HEIGHT - 210
    lb = @label
    px = pl.x; py = pl.y
    ( g = @gfx ).clear()
    g.fillAlpha = 0.2
    canHazOrbit = Array.uniq [TARGET,VEHICLE].concat Object.values Target.hostile
    canHazOrbit.map ( s )-> canHazOrbit.push s.state.relto if s.state.relto
    canHazOrbit = Array.uniq canHazOrbit
    skipId = canHazOrbit.map (i)-> i.id
    for s in canHazOrbit
      w = max 1, min 2, s.size * 100 / @scale
      l = min W2-5, ( $v.mag v = [ s.x - px, s.y - py ] ) / @scale
      v = $v.mult $v.normalize(v), l
      lb[s.id].position.set v[0]+W2R-2, v[1]+H2R-10 if lb[s.id]
      if s.state.S is $orbit and Scanner.orbits
        o = s.state.orb / @scale
        ol = min W2-5, ( $v.mag ov = [ s.state.relto.x - px, s.state.relto.y - py ] ) / @scale
        ov = $v.mult $v.normalize(ov), ol
        if o + ol < W2
          g.lineStyle 2, @color.Orbit
          g.endFill g.drawCircle ov[0]+W2R, ov[1]+H2R, o
    # TODO: more inRange magic
    # time = NUU.time()
    # return if @nextUpdate > time; @nextUpdate = time + if @scale < 1024 then TICK else 250
    for s in $obj.list
      continue unless -1 is skipId.indexOf s.id
      w = max 1, min 2, s.size * 100 / @scale
      l = min W2-5, ( $v.mag v = [ s.x - px, s.y - py ] ) / @scale
      v = $v.mult $v.normalize(v), l
      lb[s.id].position.set v[0]+W2R-2, v[1]+H2R-10 if lb[s.id]
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
