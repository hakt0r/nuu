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
  width  : 150
  height : 150
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
    @gfx.width = @gfx.height = 300; @fullscreen = true
    #app.on '$obj:add', @addLabel()
    #app.on '$obj:del', @removeLabel()
    Sprite.renderScanner = @render.bind @

  addLabel: -> (s) =>
    @removeLabel s if @label[s.id]
    @gfx.addChild @label[s.id] = new PIXI.Text ( s.name || 'ukn' ),
      fontFamily: 'monospace', fontSize:'10px', fill: 'white'

  removeLabel: -> (s) => if @label[s.id]
    @gfx.removeChild @label[s.id]
    delete @label[s.id]

  render: -> if ( pl = VEHICLE )
    if @fullscreen
      W2 = WDB2; H2 = HGB2; W = WIDTH; H = HEIGHT
    else W2 = H2 = ( W = H = @width ) / 2
    px = pl.x
    py = pl.y
    l = @label
    ( g = @gfx ).clear()
    for s in $obj.list
      w = s.state.orbit / @scale
      x = W2 + ( s.state.relto.x - px ) / @scale
      y = H2 + ( s.state.relto.y - py ) / @scale
      if s.state.S is $orbit and Scanner.orbits
        if ( -w < x < W + w ) and ( -w < y < H + w ) and ( w < W or w < H )
          g.lineStyle 2, @color.Orbit
          g.endFill g.drawCircle x, y, w
    for s in $obj.list
      w = max 2,  min 5,                 floor s.size / @scale
      x = max 10, min W  - 10, W2 + (s.x - px ) / @scale
      y = max 10, min H - 10, H2 + (s.y - py ) / @scale
      g.beginFill if s is TARGET then 0xFF0000 else @color[s.constructor.name] || 0xFFFFFF
      # g.endFill g.drawCircle x, y, w
      g.endFill g.drawRect x - w/2, y - w/2, w, w
      l[s.id].position.set x, y if l[s.id]
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
