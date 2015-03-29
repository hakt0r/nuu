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

$static 'HUD', new class HUDRenderer

  constructor: ->
    Sprite.hud = @
    Sprite.stage.addChild @gfx = new PIXI.Graphics

    @gfx.addChild @text   = new PIXI.Text 'offline', font: '10px monospace', fill: 'green'
    @gfx.addChild @notice = new PIXI.Text 'offline', font: '10px monospace', fill: 'green'
    @gfx.addChild @debug  = new PIXI.Text 'offline', font: '10px monospace', fill: 'green'
    @text.position.set(10,55)

    @startTime = Ping.remoteTime()
    @frame = 0

    @wd = @hg = @hw = @hh = 0
    @label = {}
    @win = $ window
    @win.on 'resize', @resize()
    @resize()()

    NUU.on 'newTarget', (t) =>
      if @targetSprite
        @gfx.removeChild @targetSprite
        delete @targetSprite
      img = t.img
      img = t.imgCom if t.imgCom
      @gfx.addChild @targetSprite = s = PIXI.Sprite.fromImage img
      s.width  = 100
      s.height = 100
      s.alpha  = 0.3
      s.position.set 10, 55
      null
    null

  resize: -> =>
    @wd = @win.width();  @hw = @wd / 2
    @hg = @win.height(); @hh = @hg / 2
    @debug.position.set 10, @hg - 20
    @notice.position.set @wd - 20 - @notice.width, 10

  widget: (name,value)->
    if value then @widgetList[name] = value
    else delete @widgetList[name]
  widgetList: []

  update: ->
    @frame++

    p = NUU.player
    pl = NUU.vehicle
    return unless pl
    now = Ping.remoteTime()
    dir = ((pl.d + 180) % 360) / RAD
    radius  = pl.size / 2 + 10
    PIcent  = PI / 100
    TAUcent = TAU / 100

    # STATS
    @gfx.clear()
    @gfx.beginFill(0x00FF00,.5); @gfx.endFill @gfx.drawRect 200, 10, pl.fuel   / pl.fuelMax   * 100, 8, 5
    @gfx.beginFill(0xFF0000,.5); @gfx.endFill @gfx.drawRect 300, 10, pl.energy / pl.energyMax * 100, 8, 5
    @gfx.beginFill(0xFFFF00,.5); @gfx.endFill @gfx.drawRect 400, 10, pl.armour  / pl.armourMax  * 100, 8, 5
    @gfx.beginFill(0x0000FF,.5); @gfx.endFill @gfx.drawRect 500, 10, pl.shield / pl.shieldMax * 100, 8, 5
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
    @gfx.lineTo @hw + pl.m[0], @hh + pl.m[1]
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
      @gfx.lineTo @hw - cos(dir) * radius * 1.1 + s.m[0], @hh - sin(dir) * radius * 1.1 + s.m[1]
      @gfx.endFill()
      # - GUIDE
      @gfx.beginFill 0, 0
      @gfx.lineStyle 1.0, 0x00FF00, 1.0
      @gfx.moveTo @hw, @hh
      @gfx.lineTo ox, oy
      @gfx.endFill()
      # - GUIDE - seek
      vec = NavCom.steer s,pl,'seek'
      @gfx.beginFill 0, 0
      @gfx.lineStyle 2, 0x0000FF, 0.3
      @gfx.moveTo @hw, @hh
      @gfx.lineTo @hw + vec.force[0], @hh + vec.force[1]
      @gfx.endFill()
      @gfx.beginFill 0, 0
      @gfx.lineStyle 1, 0x0000FF, 1
      @gfx.moveTo @hw - cos(vec.rad) * radius,       @hh - sin(vec.rad) * radius
      @gfx.lineTo @hw - cos(vec.rad) * radius * 1.1, @hh - sin(vec.rad) * radius * 1.1
      # - GUIDE - pursuit
      vec = NavCom.steer s,pl,'pursuit'
      @gfx.beginFill 0, 0
      @gfx.lineStyle 2, 0xFFFF00, 0.3
      @gfx.moveTo @hw, @hh
      @gfx.lineTo @hw + vec.force[0], @hh + vec.force[1]
      @gfx.endFill()
      @gfx.beginFill 0, 0
      @gfx.lineStyle 1, 0xFFFF00, 1
      @gfx.moveTo @hw - cos(vec.rad) * radius,       @hh - sin(vec.rad) * radius
      @gfx.lineTo @hw - cos(vec.rad) * radius * 1.1, @hh - sin(vec.rad) * radius * 1.1

      # STATS
      @gfx.beginFill(0xFFFF00,.5); @gfx.endFill @gfx.drawRect 10, 120, s.armour  / s.armourMax  * 100, 8, 5
      @gfx.beginFill(0x0000FF,.5); @gfx.endFill @gfx.drawRect 10, 130, s.shield / s.shieldMax * 100, 8, 5


    # TEXT
    t = ''
    if ( s = NUU.target )
      cid = NUU.targetClass
      list = ['ship','stel','roid']
      s.ap_dist = s.pdist
      s.ap_eta = Math.round( s.ap_dist / (Math.sqrt( Math.pow(pl.m[0],2) + Math.pow(pl.m[1],2) ) / 0.04))
      t += "#{s.name} [#{list[cid]}:#{NUU.target.id}]\n"
      t += "ds: #{hdist s.ap_dist}\n"
      t += "m: #{round s.m[0]}x #{round s.m[0]}y\n"
      t += "eta: #{htime(s.ap_eta)}\n\n\n\n\n"
      t += "plan: #{NUU.targetMode}\n\n"
    else t += 'no target\n'

    t += if p.primary.slot?   then "[#{p.primary.id}] #{p.primary.slot.name}\n" else "#1 locked\n"
    t += if p.secondary.slot? then "[#{p.secondary.id}] #{p.secondary.slot.name}" else "#2 locked\n"

    t += '\n\n' + k+': '+v for k,v of @widgetList

    @text.setText t

    @notice.setText Notice.queue.join '\n'
    @notice.position.set @wd - 20 - @notice.width, 10

    # STATS
    fps = round((now - @startTime) / @frame)
    t = "tps[#{fps}] " +
      "co[#{pl.d}|x#{pl.x.toFixed 0}|y#{pl.y.toFixed 0}] " + 
      "m[x#{round pl.m[0]}|y#{round pl.m[1]}:#{round $v.dist $v.zero, pl.m}] " +
      "s[#{pl.state}] "+
      "sc[#{Scanner.scale}] "+
      "ping[#{round Ping.trip.avrg}]"+ 
      "dt[#{round Ping.delta.avrg}]"+
      "er[#{round Ping.error.avrg}]"+
      "skew[#{round Ping.skew.avrg}]"
    @debug.setText t


Sprite.relAngle = (me,it) ->
  ( 360 - (Math.atan2(it.x - me.x, it.y - me.y) * 180 / PI) - 90 ) % 360 / RAD

Kbd.macro 'targetClassNext','Sy','Select next target class', ->
  list = [Ship.byId,Stellar.byId,$obj.byId]
  NUU.targetId = 0
  NUU.targetClass = Math.min(++NUU.targetClass,list.length-1)
  Kbd.macro.targetPrev()
  if NUU.targetClass is 0 then NUU.targetMode = 'land'
  if NUU.targetClass is 1 then NUU.targetMode = 'land'

Kbd.macro 'targetClassPrev','Sg','Select previous target class', ->
  list = [Ship.byId,Stellar.byId,$obj.byId]
  NUU.targetId = 0
  NUU.targetClass = Math.max(--NUU.targetClass,0)
  Kbd.macro.targetPrev()
  if NUU.targetClass is 0 then NUU.targetMode = 'land'
  if NUU.targetClass is 1 then NUU.targetMode = 'land'

Kbd.macro 'targetNext','y','Select next target', ->
  list = [Ship.byId,Stellar.byId,$obj.byId]
  cl = list[NUU.targetClass]
  list = Object.keys(cl)
  NUU.targetId = id = Math.min(++NUU.targetId,list.length-1)
  NUU.target = cl[list[id]]
  NUU.emit 'newTarget', NUU.target

Kbd.macro 'targetPrev','g','Select next target', ->
  list = [Ship.byId,Stellar.byId,$obj.byId]
  cl = list[NUU.targetClass]
  NUU.targetId = id = Math.max(--NUU.targetId,0)
  list = Object.keys(cl)
  NUU.target = cl[list[id]]
  NUU.emit 'newTarget', NUU.target

Kbd.macro 'targetClosest','u','Select closest target', ->
  v = NUU.vehicle
  list = [Ship.byId,Stellar.byId,$obj.byId]
  cl = list[NUU.targetClass]
  closest = null
  closestDist = Infinity
  for k,t of cl when t.id isnt v.id and (d = $dist v, t) < closestDist
    closest = t
    closestDist = d
  NUU.targetId = id = closest.id
  NUU.target = closest
  NUU.emit 'newTarget', NUU.target
