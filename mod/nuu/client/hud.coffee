###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2018 flyc0r

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

NUU.symbol = Launcher:'➜➤', Beam:'⌇', Projectile:'•', turret: '⦿', helm:'☸', passenger:'♿'

Weapon.guiSymbol = (e,u)->
  s = NUU.symbol[e.extends||e] || ''
  s = if s.length is 1 then s else if e.type is 'fighter bay' then s[1] else s[0]
  s += NUU.symbol.turret if e.turret
  s = s + '☢' if e.name and e.name.match 'Cheaters'
  s = if u then "[#{s}:#{u}]" else "[#{s}]"
  s

Weapon.guiName = (e)->
  s = Weapon.guiSymbol e
  n = e.name
  n = n.replace 'FighterBay', ''
  n = n.replace 'Beam', ''
  n = n.replace 'Launcher', ''
  n = n.replace 'Turret', ''
  n = n.replace 'Cannon', ''
  n = n.replace 'Cheaters', '' if n.match 'Cheaters'
  n = n.replace /.*Systems/, ''
  while m = n.match /([^ ])([A-Z][a-z])/
    n = n.replace m[0], m[1] + ' ' + m[2]
  return n.trim() + s

###
  ███████ ██    ██ ███████ ███    ██ ████████ ███████
  ██      ██    ██ ██      ████   ██    ██    ██
  █████   ██    ██ █████   ██ ██  ██    ██    ███████
  ██       ██  ██  ██      ██  ██ ██    ██         ██
  ███████   ████   ███████ ██   ████    ██    ███████
###

NUU.on 'enterVehicle', shpHandler = (t) ->
  HUD[k].visible = HUD[k+'bg'].visible = true for k,v of HUD.healhBars
  console.log 'ship', t if debug
  if HUD.playerSprite
    HUD.layer.removeChild HUD.playerSprite
    delete HUD.playerSprite
  return unless t?
  img = t.imgCom || t.img || '/build/imag/noscanimg.png'
  debugger if img is '/build/imag/noscanimg.png'
  HUD.layer.addChild HUD.playerSprite = s = PIXI.Sprite.fromImage img
  r = s.width / s.height
  s.width  = 100
  s.height = r * 100
  s.alpha  = 0.8
  HUD.energy.visible = HUD.energy.bg.visible = HUD.armour.visible = HUD.armour.bg.visible = HUD.shield.visible = HUD.shield.bg.visible = HUD.fuel.visible = HUD.fuel.bg.visible = yes
  clearTimeout shpHandler.timer # SWITCH ANIMATION
  shpHandler.timer = setTimeout ( -> s.tint = 0xFFFFFF ), 100
  do uiArrow.createTurrets # TURRET INDICATORS
  do Sprite.resize         # RESIZE EVERYTHING
  null
null

NET.on 'setMount', (users) ->
  idx = NUU.player.mountId
  if ( s = VEHICLE.mountSlot[idx] ) and ( e = s.equip ) and e.turret
    VEHICLE.setWeap s.idx
  else if VEHICLE.slots.weapon.length isnt idx
    VEHICLE.setWeap VEHICLE.slots.weapon.length
  mounts = VEHICLE.mount.map (user,idx)->
    Weapon.guiSymbol VEHICLE.mountSlot[idx].equip || VEHICLE.mountType[idx], user
  n = NUU.player.user.nick + '@' + VEHICLE.name + '.' + $obj.byId[0].name + ' '
  HUD.wdg mount:v:n+mounts.join(''), true

NUU.on 'switchWeapon', switchWeapon = (slot,weap) ->
  console.log "weap", slot, weap if debug
  p = NUU.player
  if e = p.primary.slot
    HUD.primary.style.fontWeight = 'bold'
    HUD.primary.style.fontFamily = 'monospace'
    HUD.primary.style.fill = if e.color then e.color
    HUD.primary.text = "#{Weapon.guiName e}"
  else
    HUD.primary.style.fill = $palette.grey;
    HUD.primary.text = "locked [0]"
  if e = p.secondary.slot
    s = NUU.symbol[e.extends]
    s = if s.length is 1 then s else if e.type is 'fighter bay' then s[1] else s[0]
    s += NUU.symbol.turret if e.turret
    HUD.secondary.style.fill = if e.color then e.color
    HUD.secondary.text = "#{Weapon.guiName e}"
  else
    HUD.secondary.style.fill = $palette.grey
    HUD.secondary.text = "locked [1]"
  HUD.resize()

NUU.on 'newTarget', tgtHandler = (t) ->
  if HUD.targetSprite
    HUD.layer.removeChild HUD.targetSprite
    delete HUD.targetSprite
  return unless t?
  console.log 'targ', t if debug
  img = t.imgCom || t.img || '/build/imag/noscanimg.png'
  HUD.layer.addChild HUD.targetSprite = s = PIXI.Sprite.fromImage img
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

$static '$palette',
  red:0xe6194b
  green:0x3cb44b
  yellow:0xffe119
  blue:0x0082c8
  orange:0xf58231
  purple:0x911eb4
  cyan:0x46f0f0
  magenta:0xf032e6
  lime:0xd2f53c
  pink:0xfabebe
  teal:0x008080
  lavender:0xe6beff
  brown:0xaa6e28
  beige:0xfffac8
  maroon:0x800000
  mint:0xaaffc3
  olive:0x808000
  coral:0xffd8b1
  navy:0x000080
  grey:0x808080
  white:0xFFFFFF
  black:0x000000
$static '$paletteKey', {}
$paletteKey[v] = k for k,v of $palette

ntime = ->
  d = new Date NUU.time()
  h = d.getUTCHours();   h = '0' + h if h < 10
  m = d.getUTCMinutes(); m = '0' + m if m < 10
  s = d.getUTCSeconds(); s = '0' + m if s < 10
  return [h,m,s].join ':'
# setInterval ( -> HUD.wdg aa_date: v:ntime() ), 250

###
  ██    ██ ██   ██████   █████  ██████
  ██    ██      ██   ██ ██   ██ ██   ██
  ██    ██ ██   ██████  ███████ ██████
  ██    ██ ██   ██   ██ ██   ██ ██   ██
   ██████  ██   ██████  ██   ██ ██   ██
###

class uiBar extends PIXI.Sprite
  constructor:(HUD,name,color)->
    gfx = new PIXI.Graphics
    gfx.clear()
    gfx.beginFill color
    gfx.drawRect 0,0,100,9
    gfx.endFill()
    super tex = Sprite.renderer.generateTexture gfx
    Object.assign @, tex:tex, HUD:HUD, name:name, color:color
    @HUD.layer.addChild @
    @HUD.layer.addChild @bg = new PIXI.Sprite @tex
    @visible = @bg.visible = no
    @bg.alpha = 0.3
    @HUD[@name] = @
    gfx.destroy()

uiBar::setPosition = (x,y)->
  @bg.position.set x,y
  @position.set x,y

uiBar::remove = ->
  @HUD.layer.removeChild @
  @HUD.layer.removeChild @bg
  @tex.destroy()
  @bg.destroy()
  @destroy()
  delete @HUD[@name]

uiBar.init = -> new uiBar HUD,k,v for k,v of @healhBars
uiBar.healhBars =
  fuel:0x00FF00
  energy:0xFF0000
  shield:0x0000FF
  armour:0xFFFF00
  targetShield:0x0000FF
  targetArmour:0xFFFF00

###
  ██    ██ ██    █████  ██████  ██████   ██████  ██     ██
  ██    ██      ██   ██ ██   ██ ██   ██ ██    ██ ██     ██
  ██    ██ ██   ███████ ██████  ██████  ██    ██ ██  █  ██
  ██    ██ ██   ██   ██ ██   ██ ██   ██ ██    ██ ██ ███ ██
   ██████  ██   ██   ██ ██   ██ ██   ██  ██████   ███ ███
###

class uiArrow extends PIXI.Text
  constructor:(HUD,name,color,sign='▲',weap)->
    console.log 'ARROW', name, color, sign, weap if debug
    c = if color.match then color else $paletteKey[color]
    super sign, fontFamily: 'monospace', fontSize:HUD.fontSize+'px', fill: c
    Object.assign @, HUD:HUD,name:name,color:color,sign:sign,weap:weap
    @anchor.set 0.5, 1
    @HUD.layer.addChild @HUD[@name] = @
    return unless @weap
    @weap.color = @color
    null
uiArrow::remove = -> @HUD.layer.removeChild @

uiArrow.turret = []
uiArrow.createTurrets = ->
  uiArrow.turret.map( (i)-> i.remove() )
  uiArrow.palette = [ $palette.orange, $palette.purple, $palette.lime, $palette.teal, $palette.brown, $palette.maroon ]
  uiArrow.turret = VEHICLE.slots.weapon
    .filter (i)-> i and i.equip and i.equip.turret
    .map  (v,i)-> new uiArrow HUD, 'turret' + i, uiArrow.palette[i], '⧋', v.equip
  null

###
  ██    ██ ██ ████████ ███████ ██   ██ ████████
  ██    ██       ██    ██       ██ ██     ██
  ██    ██ ██    ██    █████     ███      ██
  ██    ██ ██    ██    ██       ██ ██     ██
   ██████  ██    ██    ███████ ██   ██    ██
###

class uiText
  constructor:(@HUD, name, opts)->
    o = fontFamily: 'monospace', fontSize:@HUD.fontSize+'px', fill: 'red'
    o[k] = v for k,v of opts
    @HUD.layer.addChild @HUD[name] = new PIXI.Text (o.text or ''), o

uiText.init = -> new uiText HUD, name, opts for name,opts of {
  system:{align:'right',fill:$palette.green}
  primary:{align:'right',fill:$palette.grey}
  secondary:{align:'right',fill:$palette.grey}
  topLeft:{fill:'grey'}
  text:{}
  notice:{}
  debug:{}}

###
  ██    ██ ██ ██    ██ ███████  ██████ ████████  ██████  ██████
  ██    ██ ██ ██    ██ ██      ██         ██    ██    ██ ██   ██
  ██    ██ ██ ██    ██ █████   ██         ██    ██    ██ ██████
  ██    ██ ██  ██  ██  ██      ██         ██    ██    ██ ██   ██
   ██████  ██   ████   ███████  ██████    ██     ██████  ██   ██
###

class uiVector extends PIXI.Sprite
  constructor:(HUD,name,color)->
    gfx = new PIXI.Graphics
    gfx.clear()
    gfx.beginFill color
    gfx.drawRect 0,0,50,2
    gfx.endFill()
    super tex = Sprite.renderer.generateTexture gfx
    Object.assign @, tex:tex,HUD:HUD,name:name,color:color
    @HUD.layer.addChild @
    @HUD[@name] = @
    @position.set 100,100
    @anchor.set 0,0.5
    gfx.destroy()

uiVector::remove = ->
  @HUD.layer.removeChild @
  @tex.destroy()
  @destroy()
  delete @HUD[@name]

###
  ██    ██ ██ ██   ██ ██    ██ ██████
  ██    ██    ██   ██ ██    ██ ██   ██
  ██    ██ ██ ███████ ██    ██ ██   ██
  ██    ██ ██ ██   ██ ██    ██ ██   ██
   ██████  ██ ██   ██  ██████  ██████
###

new class uiHUD
  fontSize:12
  frame: 0
  label: {}
  constructor: ->
    $static 'HUD', @
    Sprite.renderHUD = @render.bind @, @layer
    Sprite.stage.addChild @layer = new PIXI.Container
    Sprite.on 'resize', @resize.bind @
    @startTime = NUU.time()
    new uiArrow  @, 'dir',      'yellow'
    new uiArrow  @, 'targetDir',   'red'
    new uiVector @, 'speed',    0x00FF00
    new uiVector @, 'approach', 0xFFFF00
    new uiVector @, 'pursuit',  0xFF0000
    do uiBar.init # HEALTH BARS
    do uiText.init # TEXT NODES
    @topLeft.position.set 10, 10
    do @resize # UPDATE DYNAMIC POSITIONS

  resize: ->
    LeftAlign  = (o,x,y)-> x = WDB2 - x - 5; y = HEIGHT - y; if o.setPosition then o.setPosition x,y else o.position.set x,y
    RightAlign = (o,x,y)-> x = WDB2 + x + 5; y = HEIGHT - y; if o.setPosition then o.setPosition x,y else o.position.set x,y
    @system.fontSize = @text.fontSize = @notice.fontSize = @debug.fontSize = @fontSize + 'px'
    @notice.position.set        WIDTH - 20 - @notice.width, 10
    @debug.position.set         10,  26
    LeftAlign  @system,         110 + @system.width, @system.height + 10
    LeftAlign  @playerSprite,   100, @playerSprite.height + 35 if @playerSprite
    LeftAlign  @secondary,      110 + @secondary.width, 10 + @secondary.height
    LeftAlign  @primary,        110 + @primary.width,   10 + @secondary.height + @primary.height
    LeftAlign  @fuel,           100, 40
    LeftAlign  @energy,         100, 30
    LeftAlign  @shield,         100, 20
    LeftAlign  @armour,         100, 10
    RightAlign @speed       ,   -5,  200
    RightAlign @pursuit     ,   -5,  200
    RightAlign @approach    ,   -5,  200
    RightAlign @targetShield,   5,   20
    RightAlign @targetArmour,   5,   10
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
      uiArrow.turret.map (t)->
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
    @targetShield.visible = @targetArmour.visible = @targetShield.bg.visible = @targetArmour.bg.visible = @targetDir.visible = @approach.visible = @pursuit.visible = TARGET?
    unless TARGET
      m = VEHICLE.m.slice()
      l = 50 / Speed.max * $v.mag(m)
      m = $v.mult $v.normalize(m), l
      @speed.width = l
      @speed.rotation = ( PI + $v.heading $v.zero, m ) % TAU
    else if TARGET
      # MY-SPEED relto
      m = $v.sub VEHICLE.m.slice(), TARGET.m
      l = 50 / Speed.max * $v.mag(m)
      m = $v.mult $v.normalize(m), l
      @speed.width = l
      @speed.rotation = ( PI + $v.heading $v.zero, m ) % TAU
      # - GUIDE - pursuit
      vec = NavCom.steer(VEHICLE,TARGET,'pursue')
      m = vec.force.slice()
      l = 25 / Speed.max * $v.mag(m)
      m = $v.mult $v.normalize(m), l
      @pursuit.width = l
      @pursuit.rotation = ( PI + $v.heading $v.zero, m ) % TAU
      if @approach.visible = vec.approach_force?
        m = vec.approach_force.slice()
        l = 25 / Speed.max * $v.mag(m)
        m = $v.mult $v.normalize(m), l
        @approach.width = l
        @approach.rotation =( PI +  $v.heading $v.zero, m ) % TAU
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
    else if not VEHICLE.dummy
      @targetShield.visible = @targetArmour.visible = @targetDir.visible = false
      t += "[#{list[cid]}] no target"
    else t = ''
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
      "m[#{round VEHICLE.m[0]}|#{round VEHICLE.m[1]}|#{round $v.dist $v.zero, VEHICLE.m}]" +
      "s[#{VEHICLE.state.S}]]\n"+
      "scanner[#{Scanner.scale}]\n"+
      "net[rx:#{NET.PPS.in}(#{parseInt NET.PPS.inAvg.avrg})|"+
      "tx:#{NET.PPS.out}(#{parseInt NET.PPS.outAvg.avrg}|"+
      "ping:#{round Ping.avrgPing}]\n"+
      "dt[#{round Ping.avrgDelta}]\n"+
      "hostiles:#{if Target.hostile then Object.keys(Target.hostile).length else 0}" else ''
    @resize()

  widgetList: []

  widget: (name,v,nokey=false)->
    value = name + ': ' + v
    value = v if nokey
    if v then @widgetList[name] = value
    else delete @widgetList[name]

  wdg: (opts)-> for name, o of opts
    o = v:o if o.match
    o.p = 'topLeft'    unless o.p
    l = @wdg[o.p] = {} unless l = @wdg[o.p] = {}
    if o.v
      value = o.v
      value = name + ': ' + v if o.k is yes
      l[name] = value
    else delete l[name]
    @[o.p].text = Object.values(l).join ' '