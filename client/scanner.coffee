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

class Scanner
  ox     : 0
  oy     : 0
  id     : 0
  type   : 0
  width  : 150
  height : 150
  scale  : 1.0
  active : true

  constructor: ->
    Sprite.scanner = @
    Sprite.stage.addChild @gfx = new PIXI.Graphics
    label = {}
    # TODO: labels need gc or be properly implemented
    ####### needs to be done :) :D
    update = =>
      @gfx.clear()
      $win = $(window)
      wd = $win.width()
      hg = $win.height()
      px = py = 0
      pl = NUU.player
      tg = NUU.target
      px = floor pl.x
      py = floor pl.y
      hw = wd / 2
      hh = hg / 2
      dist = (s) -> Math.sqrt(Math.pow(px-s.x,2)+Math.pow(py-s.y,2))
      if (pl = NUU.vehicle) # re-using pl reference
        px = floor pl.x
        py = floor pl.y
        dx = floor px * -1 + @ox
        dy = floor py * -1 + @oy
        for i,s of Stellar.byId 
          x    = max 10, min wd-10, hw + (s.x - px) / @scale
          y    = max 10, min wd-10, hh + (s.y - py) / @scale
          size = max 1,  min 5,     floor s.size / @scale
          s.pdist = dist s
          @gfx.beginFill 0xFFFF00
          @gfx.drawRect x,y,size,size
          @gfx.endFill()
          unless label[s.id]
            @gfx.addChild label[s.id] = new PIXI.Text ( s.name || 'ukn' ), font: '10px monospace', fill: 'red'
          else label[s.id].position.set x, y
        @gfx.fillAlpha = .5
        for i,s of Debris.byId
          x    = max 10, min wd-10, hw + (s.x - px) / @scale
          y    = max 10, min hg-10, hh + (s.y - py) / @scale
          size = max 1.5, min 3,    floor s.size / @scale
          x = wd if x > wd; x = 0  if x < 0
          y = hg if y > hg; y = 0  if y < 0
          s.pdist = dist s
          @gfx.beginFill 0xCCCCCC
          @gfx.drawRect x,y,size,size
          @gfx.endFill()
        @gfx.fillAlpha = 1
        for i,s of Ship.byId
          s.pdist = dist s
          x    = max 10, min wd-10, hw + (s.x - px) / @scale
          y    = max 10, min wd-10, hh + (s.y - py) / @scale
          size = max 1, min 2.5,    floor s.size / @scale
          @gfx.beginFill 0xFF00FF
          @gfx.drawRect x,y,size,size
          @gfx.endFill()
          unless label[s.id]
            @gfx.addChild label[s.id] = new PIXI.Text ( s.name || 'ukn' ), font: '10px monospace', fill: 'red'
          else label[s.id].position.set x, y
      null
    setInterval update, 33


Sprite.on 'gameLayer', -> new Scanner
