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

Sprite.on 'resize', repositionPlayer = (w,h,hw,hh)->
  return unless ( v = NUU.vehicle )
  hs = v.size / 2
  v.currentSprite.position.set hw - hs, hh - hs

Sprite.repositionPlayer = ->
  repositionPlayer @wd,@hg,@hw,@hh

Sprite.renderSpace = ->
  return unless ( p = NUU.player )

  px = py = 0
  alerts = []
  pl = null
  sc = 1
  now = Ping.remoteTime()

  log = (args...) -> alerts.push args.join ' ' 
  dist = (s) -> sqrt(pow(px-s.x,2)+pow(py-s.y,2))

  pl = NUU.vehicle
  pl.update()
  pl.updateTile()
  ps = pl.size / 2
  pox = @hw - ps
  poy = @hh - ps

  scanner = Sprite.scanner
  target  = Sprite.target
  hud     = Sprite.hud

  # sc = (abs(@m[0])+abs(@m[1]))*0.01 + 1 if NUU.scale # speedscale  
  px = floor pl.x
  py = floor pl.y
  dx = floor px * -1 + @hw
  dy = floor py * -1 + @hh
  rdst = @hw + @hh

  Animation.render dx, dy

  # STARS
  @starfield.tilePosition.x -= pl.m[0] * 0.1
  @starfield.tilePosition.y -= pl.m[1] * 0.1
  @parallax.tilePosition.x  -= pl.m[0] * 1.25
  @parallax.tilePosition.y  -= pl.m[1] * 1.25
  @parallax2.tilePosition.x -= pl.m[0] * 1.5
  @parallax2.tilePosition.y -= pl.m[1] * 1.5

  # STELLARS / ASTEROIDS / CARGO / DEBRIS
  for s in @visible.stel.concat(@visible.debr).concat(@visible.pwep)
    s.update()
    size = parseInt s.size
    hs = size / 2
    ox = floor s.x + dx - hs
    oy = floor s.y + dy - hs
    s.currentSprite.position.set ox, oy

  for s in @visible.tile
    s.update()
    size = parseInt s.size
    hs = size / 2
    ox = floor s.x + dx - hs
    oy = floor s.y + dy - hs
    s.currentSprite.position.set ox, oy
    s.updateTile()

  @weap.clear()

  # SHIPS
  for s in @visible.ship.concat pl
    s.update()
    size = parseInt s.size
    hs = size / 2
    dir  = s.d / RAD
    rx = floor s.x + dx
    ry = floor s.y + dy
    ox = floor rx  - hs
    oy = floor ry  - hs
    s.currentSprite.position.set ox, oy
    s.updateTile()
    # draw beam weapon
    if ( beam = Weapon.beam[s.id] )
      @weap.beginFill 0xFF0000, 0.7
      @weap.lineStyle 1+random(), 0xFF0000, 0.7
      @weap.moveTo rx, ry
      @weap.lineTo rx + cos(dir) * beam.range, ry + sin(dir) * beam.range
      @weap.endFill()

  # WEAPONS
  for s in Weapon.proj
    ticks = (now - s.ms) / TICK
    x = dx + floor(s.sx + s.m[0] * ticks)
    y = dy + floor(s.sy + s.m[1] * ticks)
    if x > 0 and x < @wd and y > 0 and y < @hg
      @weap.beginFill 0xFF0000, 0.7
      @weap.drawCircle x-1, y-1, 3
      @weap.endFill()
