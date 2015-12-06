###

  * c) 2007-2016 Sebastian Glaser <anx@ulzq.de>
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

  constructor: ->
    @gfx = Sprite.layer 'scan', new PIXI.Graphics
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

  color:
    Orbit:    0x330000
    Ship:     0xFF00FF
    Stellar:  0xFFFF00
    Debris:   0xCCCCCC
    Cargo:    0xCCCCCC
    Asteroid: 0xCCCCCC

  render: -> if ( pl = VEHICLE )
    px = pl.x
    py = pl.y
    l = @label
    ( g = @gfx ).clear()
    for s in $obj.list
      x = max 10, min WIDTH  - 10, WDB2 + (s.x - px) / @scale
      y = max 10, min HEIGHT - 10, HGB2 + (s.y - py) / @scale
      w = max 2,  min 5,                floor s.size / @scale
      g.beginFill @color[s.constructor.name] || 0xFFFFFF
      g.endFill g.drawRect x, y, w, w
      l[s.id].position.set x, y if l[s.id]
      w = s.state.orbit / @scale
      x = WDB2 + ( s.state.relto.x - px ) / @scale
      y = HGB2 + ( s.state.relto.y - py ) / @scale
      if s.state.S is $orbit and Scanner.orbits
        if ( -w < x < WIDTH + w ) and ( -w < y < HEIGHT + w ) and ( w < WIDTH or w < HEIGHT )
          g.lineStyle 2, @color.Orbit
          g.endFill g.drawCircle x, y, w
    null

  toggle: ->
    @active = not @active
    #console.log Sprite.stage.children.indexOf @gfx
    if @active then Sprite.stage.addChild @gfx
    else Sprite.stage.removeChild @gfx

  zoomIn: ->
    Scanner.scale = max 0.25, Scanner.scale / 2

  zoomOut: ->
    Scanner.scale = Scanner.scale * 2

Kbd.macro 'scanToggle', 'S+', 'Toggle Scanner',   Scanner.toggle.bind Scanner
Kbd.macro 'scanPlus',   '+',  'Zoom scanner in',  Scanner.zoomIn.bind Scanner
Kbd.macro 'scanMinus',  '-',  'Zoom scanner out', Scanner.zoomOut.bind Scanner
