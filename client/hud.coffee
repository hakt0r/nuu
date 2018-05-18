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

$static 'HUD', new class HUDRenderer
  fontSize:12
  constructor: ->
    Sprite.hud = @
    Sprite.stage.addChild @gfx = new PIXI.Graphics true

    @gfx.addChild @system = new PIXI.Text '', fontFamily: 'monospace', fontSize:@fontSize+'px', fill: 'red', align:'right'
    @gfx.addChild @text   = new PIXI.Text '', fontFamily: 'monospace', fontSize:@fontSize+'px', fill: 'red'
    @gfx.addChild @notice = new PIXI.Text '', fontFamily: 'monospace', fontSize:@fontSize+'px', fill: 'red'
    @gfx.addChild @debug  = new PIXI.Text '', fontFamily: 'monospace', fontSize:@fontSize+'px', fill: 'red'
    @text.position.set   WDB2 - 50, HEIGHT - 120
    @system.position.set        10, HEIGHT - 10 - @system.height
    @startTime = Ping.remoteTime()
    @frame = 0

    @label = {}

    @resize Sprite.on 'resize', @resize.bind @
    Sprite.renderHUD =          @render.bind @, @gfx

    NUU.on 'enterVehicle', shpHandler = (t) =>
      console.log 'shp', t if debug
      if @playerSprite
        @gfx.removeChild @playerSprite
        delete @playerSprite
      return unless t?
      img = t.imgCom || t.img || '/build/imag/noscanimg.png'
      debugger if img is '/build/imag/noscanimg.png'
      console.log img
      @gfx.addChild @playerSprite = s = PIXI.Sprite.fromImage img
      r = s.width / s.height
      s.width  = 100
      s.height = r * 100
      s.alpha  = 0.8
      Sprite.resize()
      clearTimeout shpHandler.timer
      shpHandler.timer = setTimeout ( -> s.tint = 0xFFFFFF ), 100
      null
    null

    NUU.on 'newTarget', tgtHandler = (t) =>
      if @targetSprite
        @gfx.removeChild @targetSprite
        delete @targetSprite
      return unless t?
      console.log 'tgt', t if debug
      img = t.imgCom || t.img || '/build/imag/noscanimg.png'
      @gfx.addChild @targetSprite = s = PIXI.Sprite.fromImage img
      r = s.width / s.height
      s.tint = 0x0000FF
      s.width  = 100
      s.height = r * 100
      s.alpha  = 0.8
      Sprite.resize()
      clearTimeout tgtHandler.timer
      tgtHandler.timer = setTimeout ( ->
        if Target.hostile[TARGET.id] then s.tint = 0xFF0000
        else if t.npc  then s.tint = 0xFFFF00
        else if t.ally then s.tint = 0x00FF00
        else s.tint = 0xFFFFFF
      ), 100
      null
    null

  resize: ->
    @debug.position.set 10, 10
    @notice.position.set WIDTH - 20 - @notice.width, 10
    @text.position.set WDB2 + 115, HEIGHT - 10 - @text.height
    @system.position.set(
      ( WIDTH / 2 ) - 115 - @system.width,
      HEIGHT - 10 - @system.height )
    @targetSprite.position.set WDB2 + 5,   HEIGHT - @targetSprite.height - 35 if @targetSprite
    @playerSprite.position.set WDB2 - 105, HEIGHT - @playerSprite.height - 35 if @playerSprite
    @system.fontSize = @text.fontSize = @notice.fontSize = @debug.fontSize = @fontSize + 'px'

  render: (g) ->
    @frame++
    dir = ((VEHICLE.d + 180) % 360) / RAD
    radius  = VEHICLE.size / 2 + 10

    # STATS
    g.clear()
    unless VEHICLE.dummy
      g.beginFill(0x00FF00,0.3); g.endFill g.drawRect WDB2 - 105, HEIGHT - 40, 100, 10
      g.beginFill(0x00FF00,1.0); g.endFill g.drawRect WDB2 - 105, HEIGHT - 40, VEHICLE.fuel   / VEHICLE.fuelMax   * 100, 10
      g.beginFill(0xFF0000,0.3); g.endFill g.drawRect WDB2 - 105, HEIGHT - 30, 100, 10
      g.beginFill(0xFF0000,1.0); g.endFill g.drawRect WDB2 - 105, HEIGHT - 30, VEHICLE.energy / VEHICLE.energyMax * 100, 10
      g.beginFill(0x0000FF,0.3); g.endFill g.drawRect WDB2 - 105, HEIGHT - 20, 100, 10
      g.beginFill(0x0000FF,1.0); g.endFill g.drawRect WDB2 - 105, HEIGHT - 20, VEHICLE.shield / VEHICLE.shieldMax * 100, 10
      g.beginFill(0xFFFF00,0.3); g.endFill g.drawRect WDB2 - 105, HEIGHT - 10, 100, 10
      g.beginFill(0xFFFF00,1.0); g.endFill g.drawRect WDB2 - 105, HEIGHT - 10, VEHICLE.armour / VEHICLE.armourMax * 100, 10
    # DIR
    g.beginFill 0, 0
    g.lineStyle 3, 0xFFFF00, 1
    g.moveTo WDB2 - cos(dir) * radius,       HGB2 - sin(dir) * radius
    g.lineTo WDB2 - cos(dir) * radius * 1.1, HGB2 - sin(dir) * radius * 1.1
    g.endFill()
    # SPEED
    g.beginFill 0, 0
    g.lineStyle 1.5, 0xFF0000, 1
    g.moveTo WDB2, HGB2
    g.lineTo WDB2 + VEHICLE.m[0], HGB2 + VEHICLE.m[1]
    g.endFill()

    # TARGET
    if s = TARGET
      dir = NavCom.relAngle VEHICLE, s
      # - POINTER
      g.beginFill 0, 0
      g.lineStyle 3, 0xFF0000, 1
      g.moveTo WDB2 - cos(dir) * radius,       HGB2 - sin(dir) * radius
      g.lineTo WDB2 - cos(dir) * radius * 1.1, HGB2 - sin(dir) * radius * 1.1
      g.endFill()
      # - FORCE
      g.beginFill 0, 0
      g.lineStyle 1.5, 0xFFFF00, 1
      g.moveTo WDB2 - cos(dir) * radius * 1.1,          HGB2 - sin(dir) * radius * 1.1
      g.lineTo WDB2 - cos(dir) * radius * 1.1 + s.m[0], HGB2 - sin(dir) * radius * 1.1 + s.m[1]
      g.endFill()
      # - GUIDE - pursuit
      vec = NavCom.steer(VEHICLE,s,'pursue')
      g.beginFill 0, 0
      g.lineStyle 1, 0xaaaaFF, 0.8
      g.moveTo WDB2, HGB2
      g.lineTo (bsx = WDB2 + vec.force[0]), (bsy = HGB2 + vec.force[1])
      g.endFill()
      if vec.approach_force
        g.beginFill 0, 0
        g.lineStyle 1, 0x0000FF, 0.8
        g.moveTo bsx, bsy
        g.lineTo bsx + vec.approach_force[0], bsy + vec.approach_force[1]
        g.endFill()

      g.beginFill 0, 0
      g.moveTo WDB2 - cos(vec.rad) * radius,       HGB2 - sin(vec.rad) * radius
      g.lineStyle 1, 0x0000FF, 1
      g.lineTo WDB2 - cos(vec.rad) * radius * 1.1, HGB2 - sin(vec.rad) * radius * 1.1

      # STATS
      g.lineStyle 0, 0x0000FF, 0
      g.beginFill(0x0000FF,0.3); g.endFill g.drawRect WDB2 + 5, HEIGHT - 20, 100, 10
      g.beginFill(0x0000FF,1.0); g.endFill g.drawRect WDB2 + 5, HEIGHT - 20, s.shield / s.shieldMax * 100, 10
      g.beginFill(0xFFFF00,0.3); g.endFill g.drawRect WDB2 + 5, HEIGHT - 10, 100, 10
      g.beginFill(0xFFFF00,1.0); g.endFill g.drawRect WDB2 + 5, HEIGHT - 10, s.armour / s.armourMax * 100, 10

    # TEXT
    if ( p = NUU.player )
      t = ''
      t += v + '\n\n' for k,v of @widgetList
      t += if p.primary.slot?   then "#{p.primary.slot.name}\n" else "locked [0]\n"
      t += if p.secondary.slot? then "#{p.secondary.slot.name}" else "locked [1]"
      @system.text = t

    t = ''
    cid = Target.class
    list = Target.typeNames
    if s = TARGET
      s.ap_dist = $dist(VEHICLE,s)
      s.ap_eta = Math.round( s.ap_dist / (Math.sqrt( Math.pow(VEHICLE.m[0],2) + Math.pow(VEHICLE.m[1],2) ) / 0.04))
      t += "#{s.name} [#{s.id}]\n"
      t += "d[#{htime(s.ap_eta)}/#{hdist s.ap_dist}]\n"
      t += "m[#{round s.m[0]}x#{round s.m[0]}y]\n\n"
      t += "[#{list[cid]}:#{cid}:#{Target.id}]"
      # @startTime = TIME; @frame = 0
    else if NUU.player then t += "[#{list[cid]}] no target"
    @text.text = t

    @notice.text = Notice.queue.join '\n'
    @notice.position.set WIDTH - 20 - @notice.width, 10

    # STATS
    fps = round((TIME - @startTime) / @frame)
    t = if debug then "[tps#{fps}|" +
      "o#{$obj.list.length}|"+
      "v#{Sprite.visibleList.length}]\n"+
      "co[#{parseInt VEHICLE.d}|#{VEHICLE.x.toFixed 0}|#{VEHICLE.y.toFixed 0}|" +
      "m[#{round VEHICLE.m[0]}|#{round VEHICLE.m[1]}|#{round $v.dist $v.zero, VEHICLE.m}]\n" +
      "s[#{VEHICLE.state.S}]]\n"+
      "sc[#{Scanner.scale}] "+
      "rx[#{NET.PPS.in}(#{parseInt NET.PPS.inAvg.avrg})]"+
      "tx[#{NET.PPS.out}(#{parseInt NET.PPS.outAvg.avrg})]"+
      "ping[#{round Ping.trip.avrg}] "+
      "dt[#{round Ping.delta.avrg}]"+
      "er[#{round Ping.error.avrg}]"+
      "skew[#{round Ping.skew.avrg}]\n"+
      "hostiles:#{if Target.hostile then Object.keys(Target.hostile).length else 0}" else ''
    @debug.text = t
    @resize()
  widgetList: []
  widget: (name,v,nokey=false)->
    value = name + ': ' + v
    value = v if nokey
    if v then @widgetList[name] = value
    else delete @widgetList[name]
