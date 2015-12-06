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

$static 'HUD', new class HUDRenderer

  constructor: ->
    Sprite.hud = @
    Sprite.stage.addChild @gfx = new PIXI.Graphics

    @gfx.addChild @text   = new PIXI.Text 'offline', fontFamily: 'monospace', fontSize:'10px', fill: 'green'
    @gfx.addChild @notice = new PIXI.Text 'offline', fontFamily: 'monospace', fontSize:'10px', fill: 'green'
    @gfx.addChild @debug  = new PIXI.Text 'offline', fontFamily: 'monospace', fontSize:'10px', fill: 'green'
    @text.position.set(10,35)

    @startTime = Ping.remoteTime()
    @frame = 0

    @label = {}

    @resize Sprite.on 'resize', @resize.bind @
    Sprite.renderHUD =          @render.bind @, @gfx

    NUU.on 'newTarget', (t) =>
      if @targetSprite
        @gfx.removeChild @targetSprite
        delete @targetSprite
      return unless t?
      console.log 'tgt', t
      img = t.imgCom || t.img || '/build/imag/noscanimg.png'
      @gfx.addChild @targetSprite = s = PIXI.Sprite.fromImage img
      s.width  = 100
      s.height = 100
      s.alpha  = 0.3
      s.position.set 10, 55
      null
    null

  resize: ->
    @debug.position.set 10, HEIGHT - 20
    @notice.position.set WIDTH - 20 - @notice.width, 10

  render: (g) ->
    @frame++
    dir = ((VEHICLE.d + 180) % 360) / RAD
    radius  = VEHICLE.size / 2 + 10

    # STATS
    g.clear()
    g.beginFill(0x00FF00,.5); g.endFill g.drawRect 10, 10, VEHICLE.fuel   / VEHICLE.fuelMax   * 100, 5
    g.beginFill(0xFF0000,.5); g.endFill g.drawRect 10, 15, VEHICLE.energy / VEHICLE.energyMax * 100, 5
    g.beginFill(0xFFFF00,.5); g.endFill g.drawRect 10, 20, VEHICLE.armour / VEHICLE.armourMax * 100, 5
    g.beginFill(0x0000FF,.5); g.endFill g.drawRect 10, 25, VEHICLE.shield / VEHICLE.shieldMax * 100, 5
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
    if (s = NUU.target)
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
      g.lineStyle 1, 0x0000FF, 1
      g.moveTo WDB2 - cos(vec.rad) * radius,       HGB2 - sin(vec.rad) * radius
      g.lineTo WDB2 - cos(vec.rad) * radius * 1.1, HGB2 - sin(vec.rad) * radius * 1.1

      # STATS
      g.beginFill(0xFFFF00,1); g.endFill g.drawRect 10, 130, s.armour / s.armourMax * 100, 5
      g.beginFill(0x0000FF,1); g.endFill g.drawRect 10, 135, s.shield / s.shieldMax * 100, 5

    # TEXT
    t = ''

    if ( p = NUU.player )
      t += if p.primary.slot?   then "[#{p.primary.id}] #{p.primary.slot.name}\n" else "#1 locked\n"
      t += if p.secondary.slot? then "[#{p.secondary.id}] #{p.secondary.slot.name}" else "#2 locked\n"

    t += '\n\n'

    if ( s = NUU.target )
      cid = NUU.targetClass
      list = ['ship','stel','roid','hostile']
      s.ap_dist = $dist(VEHICLE,s)
      s.ap_eta = Math.round( s.ap_dist / (Math.sqrt( Math.pow(VEHICLE.m[0],2) + Math.pow(VEHICLE.m[1],2) ) / 0.04))
      t += "#{s.name} [#{list[cid]}:#{NUU.targetId}]\n"
      t += "ds: #{hdist s.ap_dist}\n"
      t += "m: #{round s.m[0]}x #{round s.m[0]}y\n"
      t += "eta: #{htime(s.ap_eta)}\n\n\n\n\n"
      t += "plan: #{NUU.targetMode}\n\n"
    else t += 'no target\n'

    t += '\n\n' + k+': '+v for k,v of @widgetList

    @text.text = t

    @notice.text = Notice.queue.join '\n'
    @notice.position.set WIDTH - 20 - @notice.width, 10

    # STATS
    fps = round((TIME - @startTime) / @frame)
    t = "[tps#{fps}|" +
      "o#{$obj.list.length}|"+
      "v#{Sprite.visibleList.length}]"+
      " co[#{parseInt VEHICLE.d}|#{VEHICLE.x.toFixed 0}|#{VEHICLE.y.toFixed 0}|" +
      "m[#{round VEHICLE.m[0]}|#{round VEHICLE.m[1]}|#{round $v.dist $v.zero, VEHICLE.m}] " +
      "s[#{VEHICLE.state.S}]]"+
      "| sc[#{Scanner.scale}] "+
      "| rx[#{NET.PPS.in}(#{parseInt NET.PPS.inAvg.avrg})] "+
      " tx[#{NET.PPS.out}(#{parseInt NET.PPS.outAvg.avrg})] "+
      " ping[#{round Ping.trip.avrg}]"+
      "dt[#{round Ping.delta.avrg}]"+
      "er[#{round Ping.error.avrg}]"+
      "skew[#{round Ping.skew.avrg}]"
    @debug.text = t

  widgetList: []
  widget: (name,value)->
    if value then @widgetList[name] = value
    else delete @widgetList[name]
