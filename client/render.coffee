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

Sprite.gameLayer 'main',
  draw : (c) ->
    canvas = c.canvas
    $c = $(canvas); $c.attr('id','u_canvas'); $c.insertBefore('#u_vt')
    pl = null; sc = 1; alerts = []; _win = $ window
    wd = hg = hw = hh = px = py = pox = poy = ps = 0
    b = beam = dir = dx = dy = fps = hs = hud = i = img = k = now = ox = oy = p = radius = rdst = rx = ry = s = scanner = size = target = ticks = x = y = 0

    log = (args...) -> alerts.push args.join ' '
 
    dist = (s) -> sqrt(pow(px-s.x,2)+pow(py-s.y,2))

    Sprite.thread.hud = Sprite.hud.start 100
    Sprite.thread.target = Sprite.target.start 1000
    Sprite.thread.scanner = Sprite.scanner.start 500

    Sprite.resize = ->
      canvas.width  = wd = _win.width()
      canvas.height = hg = _win.height()
      hw = wd / 2; hh = hg / 2
      return unless Sprite.imag.starfield
      Sprite.imag.$starfield = Sprite.paint wd * 2, hg * 2, (cv, w, h) =>
        p = cv.createPattern(Sprite.imag.starfield, "repeat")
        cv.fillStyle = p
        cv.fillRect 0, 0, w, h
      Sprite.imag.$parallax = Sprite.paint wd * 2, hg * 2, (cv, w, h) =>
        p = cv.createPattern(Sprite.imag.parallax, "repeat")
        cv.fillStyle = p
        cv.fillRect 0, 0, w, h
      pl = NUU.vehicle
      ps = pl.size / 2
      pox = hw - ps
      poy = hh - ps
      Sprite.emit 'resize', wd, hg
    _win.on 'resize', Sprite.resize; Sprite.resize()

    return ->
      return unless (p = NUU.player)
      alerts = []; now = Ping.remoteTime()
      unless @startTime?
        @frame = 0
        @startTime = now
      else @frame++

      pl.update() unless pl.state is manouvering
      scanner = Sprite.scanner
      target  = Sprite.target
      hud     = Sprite.hud

      c.globalAlpha = 1
      c.lineWidth = 2
      c.strokeStyle = "red"

      # sc = (abs(@mx)+abs(@my))*0.01 + 1 if NUU.scale # speedscale  
      px = floor pl.x
      py = floor pl.y
      dx = floor px * -1 + hw
      dy = floor py * -1 + hh
      rdst = (hw + hh)
      pl.sx  = floor (pl.sx  - pl.mx * 0.1) % hw               # background starfield
      pl.sy  = floor (pl.sy  - pl.my * 0.1) % hh               # calculations

      # c.globalAlpha = 0.3 if NUU.motionBlur                    # motion blur 
      c.drawImage Sprite.imag.$starfield, pl.sx - hw, pl.sy - hh    # draw starfield
      # c.globalAlpha = 1 if NUU.motionBlur                      # motion blur 

      for i,s of Stellar.byId
        s.update()
        size = parseInt(s.size)
        hs = size/2
        ox = floor(s.x+dx-hs)
        oy = floor(s.y+dy-hs)
        s.pdist = dist s
        if s.pdist < rdst + size
          img = s.img
          c.drawImage img, 0, 0, img.naturalWidth, img.naturalHeight, ox, oy, size, size  if img.naturalWidth > 0

      # OBJECTS
      for i,s of Debris.byId
        s.update()
        s.pdist = dist s
        if s.pdist < rdst
          hs = s.size/2
          ox = floor(s.x+dx-hs)
          oy = floor(s.y+dy-hs)
          img = s.img
          size = parseInt(s.size)
          c.drawImage img, 0, 0, img.naturalWidth, img.naturalHeight, ox, oy, size, size  if img.naturalWidth > 0
        else if s is target
          x = hw + (s.x - px) / scanner.scale
          y = hh + (s.y - py) / scanner.scale
          c.fillStyle = "red"
          c.arc x, y, 3, 0, PI * 2, true
          c.fill()

      # WEAPONS
      for k,s of Weapon.proj
        ticks = (now - s.ms) / TICK
        x = dx + floor(s.sx + s.mx * ticks)
        y = dy + floor(s.sy + s.my * ticks)
        if x > 0 and x < wd and y > 0 and y < hg
          c.fillStyle = 'red'
          c.beginPath()
          c.arc x, y, 3, 0, PI * 2, true
          c.fill(); c.closePath()

      # OTHER SHIPS
      for i,s of Ship.byId
        s.update() unless s.state is manouvering
        s.pdist = dist s
        dir = s.d / RAD
        size = parseInt s.size
        hs = size / 2
        if s.pdist < rdst
          rx = floor s.x + dx
          ry = floor s.y + dy
          ox = floor rx  - hs
          oy = floor ry  - hs
          # draw beam weapon
          if (beam = Weapon.beam[s.id])? then for k,b of beam
            c.fillStyle = 'red'
            c.lineWidth = 1.0
            c.beginPath()
            c.moveTo rx, ry
            c.lineTo rx + cos(dir) * 300, ry + sin(dir) * 300
            c.stroke(); c.closePath()
          img = if moving < s.state then s.img_engine else s.img
          Sprite.update s
          c.drawImage img, s.ix, s.iy, size, size, ox, oy, size, size

      AnimatedSprite.render(dx,dy,c)

      # PLAYER
      s = pl
      img = @ship[pl.sprite]
      c.drawImage img, pl.ix, pl.iy, pl.size, pl.size, pox, poy, pl.size, pl.size if no
      size = pl.size
      radius = size / 2 + 10
      
      # STARFIELD OR ATMOSPHERE    
      pl.psx = floor (pl.psx - pl.mx * 1.5) % hw                        # foreground starfield
      pl.psy = floor (pl.psy - pl.my * 1.5) % hh                        # calculations
      c.drawImage Sprite.imag.$parallax, pl.psx.toFixed(0) - hw, pl.psy.toFixed(0) - hh # draw starfield

      # HUD
      #c.globalAlpha = 0.4
      #c.drawImage scanner.ctx.canvas, 0,0,150,150, 1,1,150,150
      #c.drawImage target.ctx.canvas,  0,0,150,150, 1,156,150,150
      #c.drawImage hud.ctx.canvas,     0,0,wd,hg,   0,0,wd,hg
      #c.globalAlpha = 1

      fps = round((now - @startTime) / @frame)
      alerts.push "fps[#{fps}]  co[#{pl.d}|x#{px}|y#{py}] s[#{pl.state}] m[x#{round pl.mx}|y#{round pl.my}] sc[#{scanner.scale}]  ping[#{round Ping.trip.avrg}]" + 
        "dt[#{round Ping.delta.avrg}]" +
        "er[#{round Ping.error.avrg}]" +
        "skew[#{round Ping.skew.avrg}] "
      alerts = alerts.concat Notice.queue

      c.font = "10px monospace" # FIXME
      c.strokeStyle = "black"
      c.fillStyle = "red"
      for i of alerts
        c.strokeText alerts[i], 5, 16 + i * 16
        c.fillText   alerts[i], 5, 16 + i * 16

      return
      [x,y] = NUU.lastMove
      c.beginPath()
      c.strokeStyle = "yellow"
      c.lineWidth = 1
      c.arc x, y, 10, 0, TAU, true
      c.arc x, y, 13, 0, TAU, true
      c.closePath(); c.stroke()