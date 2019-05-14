###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
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
  s = if s then ( if u then "[#{s}:#{u}]" else "[#{s}]" ) else ''
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

NUU.on 'mouse:grab',    -> HUD.widget 'mouse', 'mouse', true if window.HUD
NUU.on 'mouse:release', -> HUD.widget 'mouse', null          if window.HUD

NUU.on 'enterVehicle', shpHandler = (t) ->
  HUD[k].visible = HUD[k+'bg'].visible = true for k,v of HUD.healhBars
  console.log 'ship', t if debug
  if HUD.playerSprite
    HUD.layer.removeChild HUD.playerSprite
    delete HUD.playerSprite
  return unless t?
  img = t.imgCom || t.img || '/build/imag/noscanimg.png'
  HUD.layer.addChild HUD.playerSprite = s = PIXI.Sprite.fromImage img
  r = s.width / s.height
  s.width  = 100
  s.height = r * 100
  s.alpha  = 0.8
  HUD.throttle.visible = HUD.throttle.bg.visible = HUD.energy.visible = HUD.energy.bg.visible = HUD.armour.visible = HUD.armour.bg.visible = HUD.shield.visible = HUD.shield.bg.visible = HUD.fuel.visible = HUD.fuel.bg.visible = yes
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

NUU.on 'target:new', tgtHandler = (t) ->
  if HUD.targetSprite
    HUD.layer.removeChild HUD.targetSprite
    delete HUD.targetSprite
  return unless t?
  console.log 'targ', t if debug
  img = t.imgCom || t.img || '/build/imag/noscanimg.png'
  HUD.layer.addChild HUD.targetSprite = s = PIXI.Sprite.fromImage img
  if s.height < s.width
    r = s.height / s.width
    s.width  = 100
    s.height = r * 100
  else
    r = s.width / s.height
    s.width = r * 100
    s.height = 100
  s.tint = 0x0000FF
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
    gfx.drawRect 0,0,100,3
    gfx.endFill()
    super tex = Sprite.renderer.generateTexture gfx
    Object.assign @, tex:tex, HUD:HUD, name:name, color:color
    @HUD.layer.addChild @
    @HUD.layer.addChild @bg = new PIXI.Sprite @tex
    @visible = @bg.visible = no
    @alpha = 0.9
    @bg.alpha = 0.2
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
  throttle:0x777777
  fuel:0x007700
  energy:0x770077
  shield:0x777700
  armour:0x770000
  targetShield:0x777700
  targetArmour:0x770000

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

uiText.init = ->
  new uiText HUD, name, opts for name,opts of {
    system:   {fill:$palette.green,align:'right',stroke:0x000000,strokeThickness:2}
    primary:  {fill:$palette.grey,               stroke:0x000000,strokeThickness:2}
    secondary:{fill:$palette.grey,               stroke:0x000000,strokeThickness:2}
    topLeft:  {fill:$palette.grey,               stroke:0x000000,strokeThickness:2}
    text:     {fill:$palette.grey,               stroke:0x000000,strokeThickness:2}
    notice:   {                                  stroke:0x000000,strokeThickness:2}
    debug:    {                                  stroke:0x000000,strokeThickness:2}}
  return

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

$static 'HUD', new class NUU.HUD

  fontSize:10
  frame: 0
  label: {}

  show:->
    Sprite.renderHUD = @render.bind @, @layer
    Sprite.stage.addChild @layer = new PIXI.Container
    Sprite.on 'resize', @resize.bind @
    @startTime = NUU.time()
    new uiArrow  @, 'dir',      'yellow'
    new uiArrow  @, 'targetDir',   'red'
    new uiVector @, 'force',    0xFF00FF
    new uiVector @, 'approach', 0xFFFF00
    new uiVector @, 'match',    0xFF0000
    new uiVector @, 'accel',    0x00FF00
    new uiVector @, 'glide',    0xFFFFFF
    new uiVector @, 'deccel',   0x00FFFF
    do uiBar.init # HEALTH BARS
    do uiText.init # TEXT NODES
    @topLeft.position.set 10, 10
    @dir.visible = @targetDir.visible = no
    @targetShield.visible = @targetArmour.visible = @targetShield.bg.visible = @targetArmour.bg.visible = no
    @glide.visible = @force.visible = @approach.visible = @match.visible = @deccel.visible = @accel.visible = no
    @targetDir.visible = no
    do @resize # UPDATE DYNAMIC POSITIONS

  resize:->
    @system.fontSize = @text.fontSize = @notice.fontSize = @debug.fontSize = @fontSize + 'px'
    @notice.position.set WIDTH - 2 - @notice.width, 2
    @debug.position.set 2,2
    @offset = 110
    @offset = 5 if Scanner.fullscreen or not Scanner.active
    # self
    @topLeft.anchor.set .5, 0
    @topLeft.position.set        WDB2, 2
    @playerSprite.position.set   WDB2 - 100 - @offset,                     HEIGHT - 12 - 100 + ( 100 - @playerSprite.height ) / 2 if @playerSprite

    @secondary.position.set      WDB2 - 100 - @offset,                     HEIGHT - 12 - 72 - @secondary.height
    @primary.position.set        WDB2 - 100 - @offset,                     HEIGHT - 12 - 72 - @secondary.height - @primary.height
    @system.position.set         WDB2 - 100 - @offset - @system.width - 5, HEIGHT - 18 - @system.height

    @throttle.position.set        WDB2 - 100 - @offset,                    HEIGHT - 12 - 20
    @throttle.bg.position.set     WDB2 - 100 - @offset,                    HEIGHT - 12 - 20
    @fuel.position.set            WDB2 - 100 - @offset,                    HEIGHT - 12 - 15
    @fuel.bg.position.set         WDB2 - 100 - @offset,                    HEIGHT - 12 - 15
    @energy.position.set          WDB2 - 100 - @offset,                    HEIGHT - 12 - 10
    @energy.bg.position.set       WDB2 - 100 - @offset,                    HEIGHT - 12 - 10
    @shield.position.set          WDB2 - 100 - @offset,                    HEIGHT - 12 - 110
    @shield.bg.position.set       WDB2 - 100 - @offset,                    HEIGHT - 12 - 110
    @armour.position.set          WDB2 - 100 - @offset,                    HEIGHT - 12 - 105
    @armour.bg.position.set       WDB2 - 100 - @offset,                    HEIGHT - 12 - 105
    # target
    @targetSprite.position.set    WDB2 + @offset,                          HEIGHT - 12 - 100 + ( 100 - @targetSprite.height ) / 2 if @targetSprite
    @text.position.set            WDB2 + @offset + 105,                    HEIGHT - 18 - @text.height
    @targetShield.position.set    WDB2 + @offset,                          HEIGHT - 12 - 110
    @targetShield.bg.position.set WDB2 + @offset,                          HEIGHT - 12 - 110
    @targetArmour.position.set    WDB2 + @offset,                          HEIGHT - 12 - 105
    @targetArmour.bg.position.set WDB2 + @offset,                          HEIGHT - 12 - 105
    return

  render:(g)->
    dir = ((VEHICLE.d + 180) % 360) / RAD
    radius  = VEHICLE.size / 2 + 10
    fox = WDB2; foy = HEIGHT - 108
    fox = WDB2; foy = HGB2 if Scanner.fullscreen
    fol = Scanner.radius
    # PLAYER
    unless VEHICLE.dummy or not p = NUU.player
      @fuel.width   = VEHICLE.fuel   / VEHICLE.fuelMax * 100
      @energy.width = VEHICLE.energy / VEHICLE.energyMax * 100
      @shield.width = VEHICLE.shield / VEHICLE.shieldMax * 100
      @armour.width = VEHICLE.armour / VEHICLE.armourMax * 100
      @throttle.width = parseInt VEHICLE.throttle * 100
      # DIRECTION
      @dir.position.set WDB2 + cos(dir = VEHICLE.d / RAD) * radius * 1.1, HGB2 + sin(dir) * radius * 1.1
      @dir.rotation = ( ( VEHICLE.d + 90 ) % 360 ) / RAD
      # TURRETS
      uiArrow.turret.map (t)->
        t.position.set WDB2 + cos(dir = ( tdir = VEHICLE.d + t.weap.dir ) / RAD) * radius * 1.1, HGB2 + sin(dir) * radius * 1.1
        t.rotation = ( ( tdir + 90 ) % 360 ) / RAD
      # WIDGETS
      t = ''
      t += v + '\n' for k,v of @widgetList
      t = t.trim()
      @system.text = t if t isnt @system.text
    # TARGET
    t = ''
    cid = Target.class
    list = Target.typeNames
    @targetShield.visible = @targetArmour.visible = @targetShield.bg.visible = @targetArmour.bg.visible = @targetDir.visible = @approach.visible = @force.visible = TARGET?
    unless TARGET
      v = VEHICLE.v.slice()
      l = Math.min 50, 50 / Speed.max * $v.mag(v)
      v = $v.mult $v.norm(v), l
      #@speed.width = l
      # @speed.rotation = ( PI + $v.head $v.zero, m ) % TAU
    else if TARGET
      @targetShield.width = TARGET.shield / TARGET.shieldMax * 100
      @targetArmour.width = TARGET.armour / TARGET.armourMax * 100
      # MY-SPEED relto
      v = $v.sub VEHICLE.v.slice(), TARGET.v
      l = Math.min 50, 50 / Speed.max * $v.mag(v)
      v = $v.mult $v.norm(v), l
      #@speed.width = l
      #@speed.rotation = ( PI + $v.head $v.zero, m ) % TAU
      @glide.visible = @force.visible = @approach.visible = @match.visible = @deccel.visible = @accel.visible = ( vec = VEHICLE.state.vec )?.travel?
      if vec
        {x,y} = VEHICLE
        r = Scanner.radius
        sc = Scanner.scale
        ss = Speed.max / r
        fy = foy + 3
        @force.height       = 1
        @force.width        = min r, (( $v.mag VEHICLE.v.slice() )*ss)
        @force.rotation     = $v.head VEHICLE.v.slice(), [1,0]
        @force.position.set fox, fy
        @approach.height    = 2
        @approach.width     = ( $v.mag vec.travel ) / sc
        @approach.rotation  = $v.head vec.apppth, [1,0]
        @approach.position.set fox+(vec.pmapos[0]-x)/sc, fy+(vec.pmapos[1]-y)/sc
        @match.height       = 1
        @match.width        = $v.mag(d=$v.sub(vec.locpos.$,vec.pmapos)) / sc
        @match.rotation     = PI + $v.head d, [1,0]
        @match.position.set fox+((vec.locpos[0]-x)/sc), fy+((vec.locpos[1]-y)/sc)
        @accel.height       = 1
        @accel.width        = vec.accdst / sc
        @accel.rotation     = $v.head vec.apppth, [1,0]
        @accel.position.set fox+((vec.pmapos[0]-x)/sc), fy+((vec.pmapos[1]-y)/sc)
        @glide.height       = 2
        @glide.width        = vec.glidst / sc
        @glide.rotation     = $v.head vec.apppth, [1,0]
        @glide.position.set fox+((vec.pacpos[0]-x)/sc), fy+((vec.pacpos[1]-y)/sc)
        @deccel.height      = 1
        @deccel.width       = vec.decdst / sc
        @deccel.rotation    = $v.head vec.apppth, [1,0]
        @deccel.position.set fox+((vec.pglpos[0]-x)/sc), fy+((vec.pglpos[1]-y)/sc)
      # DIRECTION
      relDir = $v.head TARGET.p, VEHICLE.p
      @targetDir.position.set WDB2 + cos(relDir) * radius * 1.1, HGB2 + sin(relDir) * radius * 1.1
      @targetDir.rotation = ( relDir + PI/2 ) % TAU
      # NAVCOM-DATA
      TARGET.ap_dist = dist = $dist(VEHICLE,TARGET)
      if VEHICLE.state.S is $travel
        eta = ( VEHICLE.state.vec.absETA - do NUU.time ) / 1000
      else
        TARGET.ap_eta = eta = Math.round( TARGET.ap_dist / (Math.sqrt( Math.pow(VEHICLE.v[0],2) + Math.pow(VEHICLE.v[1],2) ) / 0.04))
      t += "#{htime eta}\n"
      t += "#{hdist dist}\n"
      t += "[#{list[cid]}:#{cid}:#{Target.id}]\n"
      # t += "v[#{round TARGET.v[0]*1000}x#{round TARGET.v[1]*1000}y]"
      t += "#{TARGET.name} [#{TARGET.id}]\n"
    else if not VEHICLE.dummy
      @targetShield.visible = @targetArmour.visible = @targetDir.visible = false
      t += "[#{list[cid]}] no target"
    else t = ''
    t = t.trim()
    @text.text = t if t isnt @text.text
    # NOTICES
    @notice.text = Notice.queue.join '\n'
    @notice.position.set WIDTH - 20 - @notice.width, 10
    # DEBUG STATS
    # fps = round((NUU.time() - @startTime) / @frame)

    # ██████  ███████ ██████  ██    ██  ██████
    # ██   ██ ██      ██   ██ ██    ██ ██
    # ██   ██ █████   ██████  ██    ██ ██   ███
    # ██   ██ ██      ██   ██ ██    ██ ██    ██
    # ██████  ███████ ██████   ██████   ██████

    @debug.text = unless debug then '' else "\n" +
      "     time: #{Date.now()} #{NET.FPS}tps\n" +
      "     ping: #{round Ping.avrgPing}ms delta: #{round Ping.avrgDelta}ms\n"+
      "       tx: #{NET.PPS.out}(#{parseInt NET.PPS.outAvg.avrg})pps #{NET.PPS.outKb.toFixed(2)}kbps\n"+
      "       rx: #{NET.PPS.in }(#{parseInt NET.PPS.inAvg.avrg })pps #{NET.PPS.inKb.toFixed(2) }kbps\n"+
      "  objects: #{$obj.list.length}"+
      " vehicles: #{Sprite.visibleList.length} "+
      " hostiles: #{if Target.hostile then Object.keys(Target.hostile).length else 0}\n" +
      "    state: #{State.toKey[VEHICLE.state.S]} #{if VEHICLE.state.relto? then 'relto ' + VEHICLE.state.relto.name +  ' ' else''}"+
      "#{parseInt VEHICLE.d}d #{VEHICLE.x.toFixed 0}x #{VEHICLE.y.toFixed 0}y " +
      "#{round VEHICLE.v[0]}vx #{round VEHICLE.v[1]}vy #{1000 * round $v.mag VEHICLE.v}pps\n" +
      "  scanner: #{Scanner.scale} " +
      " s:#{Scanner.ship.children.length}" +
      " a:#{Scanner.roid.children.length}" +
      " d:#{Scanner.dynamic.children.length}" +
      " p:#{Scanner.planet.children.length}" +
      " m:#{Scanner.moon.children.length}" +
      " b:#{Scanner.station.children.length}\n"
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
