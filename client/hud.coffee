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

class HUD

  constructor: ->
    Sprite.hud = @
    Sprite.stage.addChild @gfx = new PIXI.Graphics

    @gfx.addChild @text = new PIXI.Text 'offline', font: '10px monospace', fill: 'green'
    @text.position.set 10, 55
    @gfx.addChild @debug = new PIXI.Text 'offline', font: '10px monospace', fill: 'green'

    @startTime = Ping.remoteTime()
    @frame = 0

    @wd = @hg = @hw = @hh = 0
    @label = {}
    @win = $ window
    @win.on 'resize', @resize
    @resize()
    @timer = setInterval @update, 33

    NUU.on 'newTarget', (t) =>
      if @targetSprite
        @gfx.removeChild @targetSprite
        delete @targetSprite
      img = t.img
      img = t.img_comm if t.img_comm
      @gfx.addChild @targetSprite = s = PIXI.Sprite.fromImage img.src
      s.width  = 100
      s.height = 100
      s.alpha  = 0.1
      s.position.set 10, 55
      null
    null

  resize: =>
    @wd = @win.width();  @hw = @wd / 2
    @hg = @win.height(); @hh = @hg / 2
    @debug.position.set 10, @hg - 20

  update: =>
    @frame++

    p = NUU.player
    pl = p.vehicle
    now = Ping.remoteTime()
    dir = ((pl.d + 180) % 360) / RAD
    radius  = pl.size / 2 + 10
    PIcent  = PI / 100
    TAUcent = TAU / 100

    # STATS
    @gfx.clear()
    @gfx.beginFill(0x0000FF,.5); @gfx.endFill @gfx.drawRect 10, 40, pl.shield / pl.shieldMax * 100, 8, 5
    @gfx.beginFill(0xFFFF00,.5); @gfx.endFill @gfx.drawRect 10, 30, pl.armor  / pl.armorMax  * 100, 8, 5
    @gfx.beginFill(0xFF0000,.5); @gfx.endFill @gfx.drawRect 10, 20, pl.energy / pl.energyMax * 100, 8, 5
    @gfx.beginFill(0x00FF00,.5); @gfx.endFill @gfx.drawRect 10, 10, pl.fuel   / pl.fuelMax   * 100, 8, 5
    # DIR
    @gfx.beginFill 0, 0
    @gfx.lineStyle 3, 0xFFFF00, 1 
    @gfx.moveTo @hw - cos(dir) * radius,       @hh - sin(dir) * radius
    @gfx.lineTo @hw - cos(dir) * radius * 1.1, @hh - sin(dir) * radius * 1.1
    @gfx.endFill()
    # SPEED
    @gfx.beginFill 0, 0
    @gfx.lineStyle 1.5, 0xFF0000, 1 
    @gfx.moveTo @hw, @hh
    @gfx.lineTo @hw + pl.mx, @hh + pl.my
    @gfx.endFill()

    # TARGET
    if (s = NUU.target)
      dir = Sprite.relAngle pl, s
      size  = parseInt(s.size)
      hsize = size / 2
      px = floor pl.x
      py = floor pl.y
      dx = floor px * -1 + @hw
      dy = floor py * -1 + @hh
      ox = s.x + dx
      oy = s.y + dy
      fx = s.x - (size / 2)
      fy = s.y - (size / 2)
      # - POINTER
      @gfx.beginFill 0, 0
      @gfx.lineStyle 3, 0xFF0000, 1 
      @gfx.moveTo @hw - cos(dir) * radius,       @hh - sin(dir) * radius
      @gfx.lineTo @hw - cos(dir) * radius * 1.1, @hh - sin(dir) * radius * 1.1
      @gfx.endFill()
      # - FORCE
      @gfx.beginFill 0, 0
      @gfx.lineStyle 1.5, 0xFFFF00, 1 
      @gfx.moveTo @hw - cos(dir) * radius * 1.1,        @hh - sin(dir) * radius * 1.1
      @gfx.lineTo @hw - cos(dir) * radius * 1.1 + s.mx, @hh - sin(dir) * radius * 1.1 + s.my
      @gfx.endFill()
      # - GUIDE
      @gfx.beginFill 0, 0
      @gfx.lineStyle 5, 0xFF0000, 0.3
      @gfx.moveTo @hw, @hh
      @gfx.lineTo ox, oy
      @gfx.endFill()
      # - SHIELDS
      @gfx.beginFill 0, 0
      @gfx.lineStyle 5, 0x00FF00, 0.5
      @gfx.drawRect ox, oy - hsize, min(0, s.shield / s.shieldMax * 100), 5
      @gfx.endFill()
      # - ARMOR
      @gfx.beginFill 0, 0
      @gfx.lineStyle 5, 0xFFFF00, 0.5
      @gfx.drawRect ox, oy - hsize + 7, min(0, s.armor / s.armorMax * 100), 5
      @gfx.endFill()

    # TEXT
    t = ''
    if ( s = NUU.target )
      cid = NUU.targetClass
      list = ['ship','stel','roid']
      s.ap_dir = Math.round((360 + (Math.atan2((s.x - px), (-s.y - py)) / Math.PI) * 180) % 360)
      s.ap_dist = s.pdist
      s.ap_eta = Math.round( s.ap_dist / (Math.sqrt( Math.pow(pl.mx,2) + Math.pow(pl.my,2) ) / 0.04))
      t += "#{s.name} [#{list[cid]}:#{NUU.target.id}]\n"
      t += "ds: #{hdist s.ap_dist}\n"
      t += "eta: #{htime(s.ap_eta)}\n\n"
    else t += 'no target\n'
    t +=  if p.primary.slot?   then "[#{p.primary.id}] #{p.primary.slot.name}\n" else "#1 locked\n"
    t +=  if p.secondary.slot? then "[#{p.secondary.id}] #{p.secondary.slot.name}" else "#2 locked\n"
    @text.setText t

    # STATS
    fps = round((now - @startTime) / @frame)
    t = "fps[#{fps}] " +
      "co[#{pl.d}|x#{pl.x.toFixed 0}|y#{pl.y.toFixed 0}] " + 
      "m[x#{round pl.mx}|y#{round pl.my}] " +
      "s[#{pl.state}] "+
      "sc[#{Sprite.scanner.scale}] "+
      "ping[#{round Ping.trip.avrg}]"+ 
      "dt[#{round Ping.delta.avrg}]"+
      "er[#{round Ping.error.avrg}]"+
      "skew[#{round Ping.skew.avrg}]"
    @debug.setText t


Sprite.relAngle = (me,it) ->
  ( 360 - (Math.atan2(it.x - me.x, it.y - me.y) * 180 / PI) - 90 ) % 360 / RAD

Sprite.on 'gameLayer', -> new HUD