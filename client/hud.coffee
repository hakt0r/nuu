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


$static '$palette', red:0xe6194b,green:0x3cb44b,yellow:0xffe119,blue:0x0082c8,orange:0xf58231,purple:0x911eb4,cyan:0x46f0f0,magenta:0xf032e6,lime:0xd2f53c,pink:0xfabebe,teal:0x008080,lavender:0xe6beff,brown:0xaa6e28,beige:0xfffac8,maroon:0x800000,mint:0xaaffc3,olive:0x808000,coral:0xffd8b1,navy:0x000080,grey:0x808080,white:0xFFFFFF,black:0x000000

$static 'HUD', new class HUDRenderer
  fontSize:12
  constructor: ->
    @startTime = Ping.remoteTime()
    @frame = 0
    @label = {}
    Sprite.hud = @
    Sprite.stage.addChild @layer = new PIXI.Container
    # HEALTH BARS
    gfx = new PIXI.Graphics
    @healhBars =
      fuel:0x00FF00
      energy:0xFF0000
      shield:0x0000FF
      armour:0xFFFF00
      targetShield:0x0000FF
      targetArmour:0xFFFF00
    @healhBar = (name,color)=>
      gfx.clear()
      gfx.beginFill v
      gfx.drawRect 0,0,100,9
      gfx.endFill()
      tex = @[k+'Texture'] = Sprite.renderer.generateTexture gfx
      @layer.addChild @[k+"bg"] = bg = new PIXI.Sprite tex
      bg.alpha = 0.3
      @layer.addChild @[k] = new PIXI.Sprite @[k+'Texture']
    @healhBar k,v for k,v of @healhBars
    # DIRECTION INDICATOR
    @turret = []
    @arrow = (name,color,sign='▲',weap)=>
      t = new PIXI.Text sign, fontFamily: 'monospace', fontSize:@fontSize+'px', fill: color
      t.anchor.set 0.5, 1
      if weap then ( t.weap = weap; weap.color = color )
      t.remove = => @layer.removeChild t
      @layer.addChild @[name] = t
    @arrow 'dir', 'yellow'
    @arrow 'targetDir', 'red'
    # TEXT NODES
    @textNode = (struct)=> for name, opts of struct
      o = fontFamily: 'monospace', fontSize:@fontSize+'px', fill: 'red'
      o[k] = v for k,v of opts
      console.log name, o
      @layer.addChild @[name] = new PIXI.Text (o.text or ''), o
    @textNode
      system:{align:'right',fill:$palette.green}
      primary:{align:'right',fill:$palette.grey}
      secondary:{align:'right',fill:$palette.grey}
      text:{}
      notice:{}
      debug:{}
    @text.position.set WDB2 - 50, HEIGHT - 120
    @system.position.set 10, HEIGHT - 10 - @system.height
    @resize Sprite.on 'resize', @resize.bind @
    Sprite.renderHUD = @render.bind @, @layer
    # EVENT HOOKS
    NUU.on 'enterVehicle', shpHandler = (t) =>
      console.log 'ship', t if debug
      if @playerSprite
        @layer.removeChild @playerSprite
        delete @playerSprite
      return unless t?
      img = t.imgCom || t.img || '/build/imag/noscanimg.png'
      debugger if img is '/build/imag/noscanimg.png'
      @layer.addChild @playerSprite = s = PIXI.Sprite.fromImage img
      r = s.width / s.height
      s.width  = 100
      s.height = r * 100
      s.alpha  = 0.8
      Sprite.resize()
      clearTimeout shpHandler.timer
      shpHandler.timer = setTimeout ( -> s.tint = 0xFFFFFF ), 100
      # TURRET INDICATORS
      v.remove() for v in @turret
      @turretPalette = [ $palette.orange, $palette.purple, $palette.lime, $palette.teal, $palette.brown, $palette.maroon ]
      @turret = VEHICLE.slots.weapon
        .filter (i)-> i.equip.turret
        .map  (v,i)=> @arrow 'turret' + i, @turretPalette[i], '⧋', v.equip
      null
    null

    NET.on 'setMount', (users) -> HUD.widget 'mount', (
      id = NUU.player.mountId
      VEHICLE.name + '['+ id + ':' + VEHICLE.mountName[id] + ']\n' + users
        .filter (i)-> i
        .join ' '
    ), true

    NUU.on 'switchWeapon', switchWeapon = (slot,weap) =>
      console.log "weap", slot, weap if debug
      p = NUU.player
      @primary.text = if p.primary.slot?
        @primary.style.fill = if p.primary.slot.color then p.primary.slot.color else @turret[cix].color
        "#{p.primary.slot.name}"
      else @primary.style.fill = $palette.grey; "locked [0]"
      @secondary.text = if p.secondary.slot?
        @secondary.style.fill = if p.secondary.slot.color then p.secondary.slot.color else @turret[cix].color
        "#{p.secondary.slot.name}"
      else @secondary.style.fill = $palette.grey; "locked [1]"
      @resize()

    NUU.on 'newTarget', tgtHandler = (t) =>
      if @targetSprite
        @layer.removeChild @targetSprite
        delete @targetSprite
      return unless t?
      console.log 'targ', t if debug
      img = t.imgCom || t.img || '/build/imag/noscanimg.png'
      @layer.addChild @targetSprite = s = PIXI.Sprite.fromImage img
      r = s.width / s.height
      s.tint = 0x0000FF
      s.width  = 100
      s.height = r * 100
      s.alpha  = 0.3
      Sprite.resize()
      clearTimeout tgtHandler.timer
      tgtHandler.timer = setTimeout ( ->
        if Target.hostile[t.id] then s.tint = 0xFF0000
        else if t.npc  then s.tint = 0xFFFF00
        else if t.ally then s.tint = 0x00FF00
        else s.tint = 0xFFFFFF
      ), 100
      null
    null


  resize: ->
    LeftAlign  = (o,x,y)-> o.position.set WDB2 - x - 5, HEIGHT - y
    RightAlign = (o,x,y)-> o.position.set WDB2 + x + 5, HEIGHT - y
    @system.fontSize = @text.fontSize = @notice.fontSize = @debug.fontSize = @fontSize + 'px'
    @notice.position.set        WIDTH - 20 - @notice.width, 10
    @debug.position.set         10,  10
    LeftAlign  @system,         110 + @system.width, @system.height + 10
    LeftAlign  @playerSprite,   100, @playerSprite.height + 35 if @playerSprite
    LeftAlign  @secondary,      110 + @secondary.width, 10 + @secondary.height
    LeftAlign  @primary,        110 + @primary.width,   10 + @secondary.height + @primary.height
    LeftAlign  @fuel,           100, 40
    LeftAlign  @fuelbg,         100, 40
    LeftAlign  @energy,         100, 30
    LeftAlign  @energybg,       100, 30
    LeftAlign  @shield,         100, 20
    LeftAlign  @shieldbg,       100, 20
    LeftAlign  @armour,         100, 10
    LeftAlign  @armourbg,       100, 10
    RightAlign @targetShield,   5,   20
    RightAlign @targetShieldbg, 5,   20
    RightAlign @targetArmour,   5,   10
    RightAlign @targetArmourbg, 5,   10
    RightAlign @text,           115, 10 + @text.height
    RightAlign @targetSprite,   5,   @targetSprite.height + 35 if @targetSprite

  render: (g) ->
    @frame++
    dir = ((VEHICLE.d + 180) % 360) / RAD
    radius  = VEHICLE.size / 2 + 10
    fox = WDB2 + 55; foy = HEIGHT - 85
    # fox = WDB2; foy = HGB2 if Scanner.fullscreen
    # PLAYER
    unless VEHICLE.dummy or not p = NUU.player
      @fuel.width   = VEHICLE.fuel   / VEHICLE.fuelMax * 100
      @energy.width = VEHICLE.energy / VEHICLE.energyMax * 100
      @shield.width = VEHICLE.shield / VEHICLE.shieldMax * 100
      @armour.width = VEHICLE.armour / VEHICLE.armourMax * 100
      # DIRECTION
      @dir.position.set WDB2 + cos(dir = VEHICLE.d / RAD) * radius * 1.1, HGB2 + sin(dir) * radius * 1.1
      @dir.rotation = ( ( VEHICLE.d + 90 ) % 360 ) / RAD
      # TURRETS
      @turret.map (t)->
        t.position.set WDB2 + cos(dir = ( tdir = VEHICLE.d + t.weap.dir ) / RAD) * radius * 1.1, HGB2 + sin(dir) * radius * 1.1
        t.rotation = ( ( tdir + 90 ) % 360 ) / RAD
      # WIDGETS
      t = ''
      t += v + '\n\n' for k,v of @widgetList
      @system.text = t
    # TARGET
    t = ''
    cid = Target.class
    list = Target.typeNames
    if TARGET
      @targetShield.visible = @targetArmour.visible = @targetDir.visible = true
      @targetShield.width = TARGET.shield / TARGET.shieldMax * 100
      @targetArmour.width = TARGET.armour / TARGET.armourMax * 100
      # DIRECTION
      relDir = $v.heading TARGET.p, VEHICLE.p
      @targetDir.position.set WDB2 + cos(relDir) * radius * 1.1, HGB2 + sin(relDir) * radius * 1.1
      @targetDir.rotation = ( relDir + PI/2 ) % TAU
      # NAVCOM-DATA
      TARGET.ap_dist = $dist(VEHICLE,TARGET)
      TARGET.ap_eta = Math.round( TARGET.ap_dist / (Math.sqrt( Math.pow(VEHICLE.m[0],2) + Math.pow(VEHICLE.m[1],2) ) / 0.04))
      t += "#{TARGET.name} [#{TARGET.id}]\n"
      t += "d[#{htime(TARGET.ap_eta)}/#{hdist TARGET.ap_dist}]\n"
      t += "m[#{round TARGET.m[0]}x#{round TARGET.m[0]}y]\n\n"
      t += "[#{list[cid]}:#{cid}:#{Target.id}]"
      # @startTime = NUU.time(); @frame = 0
    else
      @targetShield.visible = @targetArmour.visible = @targetDir.visible = false
      t += "[#{list[cid]}] no target"
    @text.text = t
    # NOTICES
    @notice.text = Notice.queue.join '\n'
    @notice.position.set WIDTH - 20 - @notice.width, 10
    # DEBUG STATS
    fps = round((NUU.time() - @startTime) / @frame)
    @debug.text = if debug then "[t:#{Date.now()}:#{NUU.time()-Date.now()}] [tps#{fps}|" +
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
    @resize()

    ###
    unless t
      # MY-SPEED relto $obj[0]
      m = VEHICLE.m.slice()
      l = 50 / Speed.max * $v.mag(m)
      m = $v.mult $v.normalize(m), l
      g.beginFill 0, 0
      g.lineStyle 1.5, 0xFF0000, 1
      g.moveTo fox, foy
      g.lineTo fox + m[0], foy + m[1]
      g.endFill()
    else # HAVE TARGET
      # MY-SPEED relto
      m = $v.sub VEHICLE.m.slice(), t.m
      l = 50 / Speed.max * $v.mag(m)
      m = $v.mult $v.normalize(m), l
      g.beginFill 0, 0
      g.lineStyle 1.5, 0xFF0000, 1
      g.moveTo fox, foy
      g.lineTo fox + m[0], foy + m[1]
      g.endFill()
      # - FORCE
      vec = NavCom.steer(VEHICLE,t,'pursue')
      m = $v.sub t.m.slice(), VEHICLE.m
      l = 50 / Speed.max * $v.mag(m)
      m = $v.mult $v.normalize(m), l
      g.beginFill 0, 0
      g.lineStyle 1.5, 0xFFFF00, 1
      g.moveTo fox,        foy
      g.lineTo fox + m[0], foy + m[1]
      g.endFill()
      # - GUIDE - pursuit
      vec = NavCom.steer(VEHICLE,t,'pursue')
      m = vec.force.slice()
      l = 25 / Speed.max * $v.mag(m)
      m = $v.mult $v.normalize(m), l
      g.beginFill 0, 0
      g.lineStyle 1, 0xaaaaFF, 0.8
      g.moveTo fox, foy
      g.lineTo (bsx = fox + m[0]), (bsy = foy + m[1])
      g.endFill()
      if vec.approach_force
        m = vec.approach_force.slice()
        l = 25 / Speed.max * $v.mag(m)
        m = $v.mult $v.normalize(m), l
        g.beginFill 0, 0
        g.lineStyle 1, 0x0000FF, 0.8
        g.moveTo bsx, bsy
        g.lineTo bsx + m[0], bsy + m[1]
        g.endFill()
      # ???
      g.beginFill 0, 0
      g.moveTo fox - cos(vec.rad) * radius,       foy - sin(vec.rad) * radius
      g.lineStyle 1, 0x0000FF, 1
      g.lineTo fox - cos(vec.rad) * radius * 1.1, foy - sin(vec.rad) * radius * 1.1
    ###
  widgetList: []
  widget: (name,v,nokey=false)->
    value = name + ': ' + v
    value = v if nokey
    if v then @widgetList[name] = value
    else delete @widgetList[name]
