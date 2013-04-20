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

Sprite.gameLayer 'scanner',
  id : 0
  type : 0
  width: 150
  height: 150
  scale : 100
  active : true

  draw : (c) ->
    wd = 150; hg = 150; hw = 75; hh = 75; px = py = 0
    dist = (s) -> Math.sqrt(Math.pow(px-s.x,2)+Math.pow(py-s.y,2))
    scanner = Sprite.scanner
    Sprite.on 'resize', (w,h) ->
      c.canvas.width  = wd = w
      c.canvas.height = hg = h
      hw = wd / 2; hh = hg / 2
    return ->
      pl = NUU.player
      px = floor pl.x
      py = floor pl.y
      tg = NUU.target
      if (pl = NUU.vehicle) # re-using pl reference
        px = floor pl.x
        py = floor pl.y
        dx = floor px * -1 + @ox
        dy = floor py * -1 + @oy
        c.clearRect 0,0,wd,wd
        for i,s of Stellar.byId
          x = hw + (s.x - px) / scanner.scale
          y = hh + (s.y - py) / scanner.scale
          x = wd if x > wd; x = 0  if x < 0
          y = hg if y > hg; y = 0  if y < 0
          s.pdist = dist s; size = min(max(floor(s.size / scanner.scale),1),5)
          c.beginPath()
          c.fillStyle = "yellow"
          c.arc x, y, size, 0, PI * 2, true
          c.closePath(); c.fill()
          c.strokeStyle = "blue"
          c.beginPath()
          c.arc hw - px / scanner.scale, hh - py / scanner.scale, s.radius / scanner.scale, 0, PI * 2, true
          c.closePath(); c.stroke()
          c.globalOpacity = .5; c.fillStyle = "grey"; c.fillText s.name, x, y; c.globalOpacity = 1
        c.globalOpacity = .5
        for i,s of Debris.byId
          s.pdist = dist s; size = min(max(floor(s.size / scanner.scale),1),1.5)
          x = hw + (s.x - px) / scanner.scale
          y = hh + (s.y - py) / scanner.scale
          x = wd if x > wd; x = 0  if x < 0
          y = hg if y > hg; y = 0  if y < 0
          c.fillStyle = "gray"; c.beginPath(); c.arc x, y, size, 0, PI * 2, true; c.fill(); c.closePath()
        c.globalOpacity = 1
        for i,s of Ship.byId
          s.pdist = dist s; size = min(max(floor(s.size / scanner.scale),1),2.5)
          x = hw + (s.x - px) / scanner.scale
          y = hh + (s.y - py) / scanner.scale
          x = wd if x > wd; x = 0  if x < 0
          y = hg if y > hg; y = 0  if y < 0
          c.globalOpacity = .5; c.fillStyle = "grey";  c.fillText s.name, x + 3, y + 5; c.globalOpacity = 1
          c.fillStyle = "yellow"; c.beginPath(); c.arc x, y, size, 0, PI * 2, true; c.fill(); c.closePath()
