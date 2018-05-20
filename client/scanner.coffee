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

$static 'Scanner', new class ScannerRenderer
  id     : 0
  type   : 0
  width  : 100
  height : 100
  scale  : 1.0
  active : true
  label  : {}
  orbits : yes
  fullscreen : no

  color:
    Orbit:    0x330000
    Ship:     0xFF00FF
    Stellar:  0xFFFF00
    Debris:   0xCCCCCC
    Cargo:    0xCCCCCC
    Asteroid: 0xCCCCCC

  constructor: ->
    @gfx = Sprite.layer 'scan', new PIXI.Graphics true
    @gfx.width = @gfx.height = 100
    @circleMode = yes
    @fullscreen = no
    Sprite.renderScanner = @renderCircle.bind @
    #app.on '$obj:add', @addLabel()
    #app.on '$obj:del', @removeLabel()

  addLabel: -> (s) =>
    @removeLabel s if @label[s.id]
    @gfx.addChild @label[s.id] = new PIXI.Text ( s.name || 'ukn' ),
      fontFamily: 'monospace', fontSize:'10px', fill: 'white'

  removeLabel: -> (s) => if @label[s.id]
    @gfx.removeChild @label[s.id]
    delete @label[s.id]

  renderRect:   -> if ( pl = VEHICLE )
    if @fullscreen
      W = min WIDTH, HEIGHT; W2 = W/2-100; W2R = WDB2; H2R = HGB2
      @gfx.position.set 0,0 unless @gfx.position[0] is 0
    else
      W2 = H2 = ( W = H = @width ) / 2; W2R = H2R = 50
      @gfx.position.set WDB2 + 10, HEIGHT - 135
    px = pl.x; py = pl.y
    ( g = @gfx ).clear()
    g.fillAlpha = 0.2
    for s in $obj.list
      w = max 1, min 2, s.size * 100 / @scale
      x = max 0, min W - 5, W2 + (s.x - px ) / @scale
      y = max 0, min H - 5, H2 + (s.y - py ) / @scale
      g.beginFill if s is TARGET then 0xFF0000 else @color[s.constructor.name] || 0xFFFFFF
      # g.endFill g.drawRect v[0] + W2 - w/2, v[1] + H2 - w/2, w, w
      g.endFill g.drawCircle x, y, w
      #l[s.id].position.set x, y if l[s.id]

  renderCircle: -> if ( pl = VEHICLE )
    return if @nextUpdate > TIME; @nextUpdate = TIME + if @scale < 1024 then TICK else 250
    if @fullscreen
      W = min WIDTH, HEIGHT; W2 = W/2-150; W2R = WDB2; H2R = HGB2
      @gfx.position.set 0,0 unless @gfx.position[0] is 0
    else
      W2 = H2 = ( W = H = @width ) / 2; W2R = H2R = 50
      @gfx.position.set WDB2 + 10, HEIGHT - 135
    px = pl.x; py = pl.y
    ( g = @gfx ).clear()
    g.fillAlpha = 0.2
    for s in $obj.list
      w = max 1, min 2, s.size * 100 / @scale
      l = min W2-5, ( $v.mag v = [ s.x - px, s.y - py ] ) / @scale
      v = $v.mult $v.normalize(v), l
      if s.state.S is $orbit and Scanner.orbits
        o = s.state.orbit / @scale
        ol = min W2-5, ( $v.mag ov = [ s.state.relto.x - px, s.state.relto.y - py ] ) / @scale
        ov = $v.mult $v.normalize(ov), ol
        if o + ol < W2
          g.lineStyle 2, @color.Orbit
          g.endFill g.drawCircle ov[0]+W2R, ov[1]+H2R, o
      g.beginFill if s is TARGET then 0xFF0000 else @color[s.constructor.name] || 0xFFFFFF
      # g.endFill g.drawRect v[0] + W2 - w/2, v[1] + H2 - w/2, w, w
      g.endFill g.drawCircle v[0]+W2R, v[1]+H2R, w
      #l[s.id].position.set x, y if l[s.id]
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
    Scanner.scale = Scanner.scale * 2

Kbd.macro 'scanToggleFS', 'aEnter',  'Toggle Scanner FS',  Scanner.toggleFS.bind Scanner
Kbd.macro 'scanToggle',   'Enter',   'Toggle Scanner',     Scanner.toggle.bind Scanner
Kbd.macro 'scanPlus',     'Equal',   'Zoom scanner in',    Scanner.zoomIn.bind Scanner
Kbd.macro 'scanMinus',    'Minus',   'Zoom scanner out',   Scanner.zoomOut.bind Scanner
