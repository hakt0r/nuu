###

  * c) 2007-2022 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2022 flyc0r

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

# ███    ███ ██  ██████  ██████   ██████
# ████  ████ ██ ██    ██ ██   ██ ██    ██
# ██ ████ ██ ██ ██    ██ ██████  ██    ██
# ██  ██  ██ ██ ██ ▄▄ ██ ██   ██ ██    ██
# ██      ██ ██  ██████  ██   ██  ██████
#                   ▀▀

$$$ = document
$$ = window
$ = (query)-> document.querySelector query
$.all = (query)-> Array.prototype.slice.call document.querySelectorAll query
$.map = (query,fn)-> Array.prototype.slice.call(document.querySelectorAll query).map(fn)
$.make = (html)->
  template = document.createElement 'template'
  template.innerHTML = html
  html = template.content
  if ( node = html.childNodes ).length is 1 then node[0] else html

# ██   ██ ██    ██ ██████
# ██   ██ ██    ██ ██   ██
# ███████ ██    ██ ██   ██
# ██   ██ ██    ██ ██   ██
# ██   ██  ██████  ██████

$static '$palette', red:0xe6194b,green:0x3cb44b,yellow:0xffe119,blue:0x0082c8,orange:0xf58231,purple:0x911eb4,cyan:0x46f0f0,magenta:0xf032e6,lime:0xd2f53c,pink:0xfabebe,teal:0x008080,lavender:0xe6beff,brown:0xaa6e28,beige:0xfffac8,maroon:0x800000,mint:0xaaffc3,olive:0x808000,coral:0xffd8b1,navy:0x000080,grey:0x808080,white:0xFFFFFF,black:0x000000
$static '$paletteKey', {}
$paletteKey[v] = k for k,v of $palette

NUU.symbol = Launcher:'➤', Beam:'⌇', Projectile:'•', turret: '⦿', helm:'☸', passenger:'♿'

Weapon.guiSymbol = (e,u)->
  s = NUU.symbol[e.extends||e] || ''
  s = if s.length is 1 then s else if e.type is 'fighter bay' then s[1] else s[0]
  s += NUU.symbol.turret if e.turret
  s = s + '☢' if e.name and e.name.match 'Cheaters'
  s

Weapon.guiName = (e)->
  n = e.name || e[0].toUpperCase() + e.substring 1
  n = n.replace 'FighterBay', ''
  n = n.replace 'Beam', ''
  n = n.replace 'Launcher', ''
  n = n.replace 'Turret', ''
  n = n.replace 'Cannon', ''
  n = n.replace 'Cheaters', '' if n.match 'Cheaters'
  n = n.replace /[a-zA-Z]+Systems/, ''
  n = n.replace m[0], m[1] + ' ' + m[2] while m = n.match /([^ ])([A-Z][a-z])/
  return n.trim()

###
  ███████ ██    ██ ███████ ███    ██ ████████ ███████
  ██      ██    ██ ██      ████   ██    ██    ██
  █████   ██    ██ █████   ██ ██  ██    ██    ███████
  ██       ██  ██  ██      ██  ██ ██    ██         ██
  ███████   ████   ███████ ██   ████    ██    ███████
###

NUU.on 'start', -> HUD.show()

NUU.on 'mouse:grab',    -> HUD.widget 'mouse', 'mouse', true if window.HUD
NUU.on 'mouse:release', -> HUD.widget 'mouse', null          if window.HUD

NUU.on 'enterVehicle', shpHandler = (vehicle)->
  return unless vehicle?
  HUD.shipImage$.src = vehicle.imgCom || vehicle.img || '/build/imag/noscanimg.png'
  uiArrow.createTurrets()
  return

NET.on 'setMount', (users) ->
  idx = NUU.player.mountId
  if ( s = VEHICLE.mountSlot[idx] ) and ( e = s.equip ) and e.turret
    VEHICLE.setWeap s.idx
  else if VEHICLE.slots.weapon.length isnt idx
    VEHICLE.setWeap VEHICLE.slots.weapon.length
  mounts = VEHICLE.mount.map (user,idx)->
    if e = VEHICLE.mountSlot[idx].equip || VEHICLE.mountType[idx]
      if user then s = """<span class="user">#{
        if Array.isArray user then user.join '</span><span class="user">' else user
        }</span>"""
      else         s =  """<span class="name">#{Weapon.guiName e}</span>"""
      s + """<span class="symbol">#{Weapon.guiSymbol e}</span>"""
  HUD.mounts$.innerHTML = mounts.join '\n'
  HUD.updateTopBar()
  return

NUU.on 'switchWeapon', switchWeapon = (slot,weap) ->
  console.log "weap", slot, weap if debug
  p = NUU.player
  if e = p.primary.slot
    HUD.primary$.style.fontWeight = 'bold'
    HUD.primary$.style.fontFamily = 'monospace'
    HUD.primary$.style.fill = if e.color then e.color
    HUD.primary$.innerHTML = "#{Weapon.guiName e} #{Weapon.guiSymbol e}"
  else
    HUD.primary$.style.fill = $palette.grey
    HUD.primary$.innerHTML = "locked [0]"
  if e = p.secondary.slot
    s = NUU.symbol[e.extends]
    s = if s.length is 1 then s else if e.type is 'fighter bay' then s[1] else s[0]
    s += NUU.symbol.turret if e.turret
    HUD.secondary$.style.fill = if e.color then e.color
    HUD.secondary$.innerHTML = "#{Weapon.guiName e} #{Weapon.guiSymbol e}"
  else
    HUD.secondary$.style.fill = $palette.grey
    HUD.secondary$.innerHTML = "locked [1]"
  return

NUU.on 'target:new', tgtHandler = (vehicle) ->
  unless vehicle
    HUD.targetImage$.style.display = 'none'
    document.body.classList.add 'no-target'
    return
  document.body.classList.remove 'no-target'
  HUD.targetImage$.src = vehicle.imgCom || vehicle.img || '/build/imag/noscanimg.png'
  HUD.targetImage$.style.display = null
  HUD.targetInfo$.innerHTML = """#{vehicle.name} (#{vehicle.constructor.name})"""
  HUD.target$.classList.remove c for c in ['hostile','ally','npc']
  HUD.target$.classList.add 'hostile' if Target.hostile[vehicle.id]
  HUD.target$.classList.add 'npc'     if vehicle.npc
  HUD.target$.classList.add 'ally'    if vehicle.ally
  return

#  █████  ██████  ██████   ██████  ██     ██
# ██   ██ ██   ██ ██   ██ ██    ██ ██     ██
# ███████ ██████  ██████  ██    ██ ██  █  ██
# ██   ██ ██   ██ ██   ██ ██    ██ ██ ███ ██
# ██   ██ ██   ██ ██   ██  ██████   ███ ███

class uiArrow
  constructor:(HUD,name,color,sign='▲',weap)->
    HUD[name] = @
    c = if color.match then color else $paletteKey[color]
    @$ = $.make """<span class="arrow #{name}">"""
    @$.innerText = sign
    @$.style.color = color
    Object.assign @, HUD:HUD,name:name,color:color,sign:sign,weap:weap
    HUD.$.append @$
    return unless @weap
    @weap.color = @color
  set:(x,y,r)->
    @$.style.top  = (GFX.hgb2+y)+'px'
    @$.style.left = (GFX.wdb2+x)+'px'
    @$.style.transform = "translate(-50%,-50%) rotate(#{r}rad)"
    return
  remove:-> @$.remove()
  @turret:[]
  @createTurrets: ->
    uiArrow.turret.map (i)-> i.remove()
    uiArrow.palette = [ $palette.orange, $palette.purple, $palette.lime, $palette.teal, $palette.brown, $palette.maroon ]
    uiArrow.turret = VEHICLE.slots.weapon
    .filter (i)-> i and i.equip and i.equip.turret
    .map  (v,i)-> new uiArrow HUD, 'turret' + i, uiArrow.palette[i], '⧋', v.equip
    return

###
  ██    ██ ██ ██   ██ ██    ██ ██████
  ██    ██    ██   ██ ██    ██ ██   ██
  ██    ██ ██ ███████ ██    ██ ██   ██
  ██    ██ ██ ██   ██ ██    ██ ██   ██
   ██████  ██ ██   ██  ██████  ██████
###

$static 'HUD', new class NUU.HUD
  constructor:->
    $$$.body  .append             @$ = $.make """<div class="hud"></div>"""
    @$        .append       @domain$ = $.make """<div class="domain"></div>"""
    @$        .append      @scanner$ = $.make """<div class="panel scanner"></div>"""
    @scanner$ .append        @scale$ = $.make """<div class="scale"></div>"""
    @$        .append         @ship$ = $.make """<div class="panel ship">"""
    @ship$    .append    @shipImage$ = $.make """<img class="comm"/>"""
    @ship$    .append     @shipInfo$ = $.make """<div class="info"/>"""
    @ship$    .append       @mounts$ = $.make """<div class="mounts"/>"""
    @ship$    .append      @primary$ = $.make """<div class="weapon primary"/>"""
    @ship$    .append    @secondary$ = $.make """<div class="weapon secondary"/>"""
    @$        .append       @target$ = $.make """<div class="panel target">"""
    @target$  .append  @targetImage$ = $.make """<img class="comm"/>"""
    @target$  .append   @targetInfo$ = $.make """<div class="info"/>"""
    @target$  .append @targetShield$ = $.make """<div class="bar targetShield"><div class="value"></div></div>"""
    @target$  .append @targetArmour$ = $.make """<div class="bar targetArmour"><div class="value"></div></div>"""
    $$$.body  .append        @debug$ = $.make """<div class="debug"></div>"""
    $$$.body  .append       @notice$ = $.make """<div class="notice"></div>"""
    # new uiArrow  @,       'dir', 'yellow'
    # new uiArrow  @, 'targetDir', 'red'
    @addBar @ship$,   name for name in ['throttle','fuel','energy','shield','armour']
    @addBar @target$, name for name in ['targetArmour','targetShield']
    # for name,color of (
    #   force:'#FF00FF',approach:'#FFFF00',match:'#FF0000',accel:'#00FF00',glide:'#FFFFFF',deccel:'#00FFFF'
    # ) then @addVector name, color

  addBar:(parent,name)->
    parent.append @[name+'$'] = $.make """<div class="bar #{name}"></div>"""
    @[name+'$'].append @[name+'Value$'] = $.make """<div class="value"></div>"""
    Object.defineProperty @, name,
      get:=> parseInt @[name+'Value$'].style.width
      set:(v)=> @[name+'Value$'].style.width = max(0,min(v,100)) + 'px'

  addVector:(name,color)->
    @$.append @[name+'$'] = vector = $.make """<div class="vector #{name}"></div>"""
    vector.style.backgroundColor = color
    @[name] = setVector: (x1,y1,x2,y2,limit=Infinity)->
      vector.style.left  = x1 + 'px'
      vector.style.top   = y1 + 'px'
      vector.style.width = ( min limit, sqrt (x1-x2)**2 + (y1-y2)**2 ) + 'px'
      vector.style.transform = "rotate(#{$v.head([x2-x1,y2-y1],[1,0])}rad)"

  show:->
    @$.style.display = 'block'
    return

  hide:->
    @$.style.display = 'none'
    return

# ██    ██ ██████  ██████   █████  ████████ ███████
# ██    ██ ██   ██ ██   ██ ██   ██    ██    ██
# ██    ██ ██████  ██   ██ ███████    ██    █████
# ██    ██ ██      ██   ██ ██   ██    ██    ██
#  ██████  ██      ██████  ██   ██    ██    ███████

  render:->
    { size, d, v } = VEHICLE
    [ vx, vy ] = v
    ox = GFX.wdb2
    oy = GFX.height - ( GFX.hgb2 + Scanner.oy )
    radius = size / 2
    t = hscale(Scanner.scale) + " / " + Target.typeNames[Target.class]
    @scale$.innerText = t unless @scale$.innerText is t
    if TARGET
      [ tx,ty ] = TARGET.v
      # @force.setVector ox, oy, ox+tx-vx, oy+ty-vy, Scanner.radius
      @targetShield = TARGET.shield / TARGET.shieldMax * 100
      @targetArmour = TARGET.armour / TARGET.armourMax * 100
      # @targetDir.set(
      #   cos(relDir = $v.head TARGET.p, VEHICLE.p) * radius * 1.1
      #   sin(relDir) * radius * 1.1
      #   ( relDir + PI/2 ) % TAU )
    else
      # @force.setVector ox, oy, ox+vx, oy+vy, Scanner.radius
    unless VEHICLE.dummy or not p = NUU.player
      @fuel   = VEHICLE.fuel   / VEHICLE.fuelMax   * 100
      @energy = VEHICLE.energy / VEHICLE.energyMax * 100
      @shield = VEHICLE.shield / VEHICLE.shieldMax * 100
      @armour = VEHICLE.armour / VEHICLE.armourMax * 100
      @throttle = round VEHICLE.throttle * 100
      # @dir.set(
      #   cos(dir = d / RAD) * radius * 1.1
      #   sin(dir) * radius * 1.1
      #   ( ( d + 90 ) % 360 ) / RAD )
      # uiArrow.turret.map (t)->
      #   t.set (
      #     cos(dir = ( tdir = VEHICLE.d + t.weap.dir ) / RAD) * radius * 1.1
      #     sin(dir) * radius * 1.1
      #     (( tdir + 90 ) % 360 ) / RAD )
    @renderDebug() if debug
    return

  # ██     ██ ██ ██████   ██████  ███████ ████████
  # ██     ██ ██ ██   ██ ██       ██         ██
  # ██  █  ██ ██ ██   ██ ██   ███ █████      ██
  # ██ ███ ██ ██ ██   ██ ██    ██ ██         ██
  #  ███ ███  ██ ██████   ██████  ███████    ██

  widgetList: []

  widget: (name,v,nokey=false)->
    value = name + ': ' + v
    value = v if nokey
    if v then @widgetList[name] = value
    else delete @widgetList[name]
    @renderWidgets()

  renderWidgets:->
    t = ''
    t += v + '\n' for k,v of @widgetList
    t += "\n#{VEHICLE.name} (#{VEHICLE.constructor.name})"
    @shipInfo$.innerHTML = t.trim()
    return

#  ██████ ██       ██████   ██████ ██   ██
# ██      ██      ██    ██ ██      ██  ██
# ██      ██      ██    ██ ██      █████
# ██      ██      ██    ██ ██      ██  ██
#  ██████ ███████  ██████   ██████ ██   ██

ntime = ->
  d = new Date NUU.time()
  h = d.getUTCHours();   h = '0' + h if h < 10
  m = d.getUTCMinutes(); m = '0' + m if m < 10
  s = d.getUTCSeconds(); s = '0' + m if s < 10
  return [h,m,s].join ':'
# setInterval ( -> HUD.wdg aa_date: v:ntime() ), 250

# ████████  ██████  ██████  ██████   █████  ██████
#    ██    ██    ██ ██   ██ ██   ██ ██   ██ ██   ██
#    ██    ██    ██ ██████  ██████  ███████ ██████
#    ██    ██    ██ ██      ██   ██ ██   ██ ██   ██
#    ██     ██████  ██      ██████  ██   ██ ██   ██

HUD.topBarFields = {}
HUD.updateTopBar = (key,value)->
  if value then HUD.topBarFields[key] = value else delete HUD.topBarFields[key] if key
  add = ( v for k,v of HUD.topBarFields ).join ''
  system = $obj.byId[0]?.name
  t = []
  t.push """<span class="user">#{n}</span>@""" if n = NUU.player?.user?.nick
  t.push """<span class="vehicle">#{n}</span>""" if n = VEHICLE.name
  t.push """.<span class="relto">#{n}</span>""" if ( n = VEHICLE.state?.relto?.name ) and n isnt system
  t.push """.<span class="starsystem">#{system}</span>""" if system
  t.push add
  HUD.domain$.innerHTML = t.join ''
  return

# ██████  ███████ ██████  ██    ██  ██████
# ██   ██ ██      ██   ██ ██    ██ ██
# ██   ██ █████   ██████  ██    ██ ██   ███
# ██   ██ ██      ██   ██ ██    ██ ██    ██
# ██████  ███████ ██████   ██████   ██████

HUD.renderDebug = ->
  if vec = VEHICLE?.state?.vector
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
  @debug$.innerHTML = unless debug then '' else "\n" +
    "     time: #{Date.now()} #{NET.FPS}tps\n" +
    "     ping: #{round Ping.avrgPing}ms delta: #{round Ping.avrgDelta}ms\n"+
    "       tx: #{NET.PPS.out}(#{parseInt NET.PPS.outAvg.avrg})pps #{NET.PPS.outKb.toFixed(2)}kbps\n"+
    "       rx: #{NET.PPS.in }(#{parseInt NET.PPS.inAvg.avrg })pps #{NET.PPS.inKb.toFixed(2) }kbps\n"+
    "  objects: #{$obj.list.length}"+
    " vehicles: #{GFX.visibleList.length} "+
    " hostiles: #{if Target.hostile then Object.keys(Target.hostile).length else 0}\n" +
    "    state: #{State.toKey[VEHICLE.state.S]} #{if VEHICLE.state.relto? then 'relto ' + VEHICLE.state.relto.name +  ' ' else''}"+
    "#{parseInt VEHICLE.d}d #{VEHICLE.x.toFixed 0}x #{VEHICLE.y.toFixed 0}y " +
    "#{round VEHICLE.v[0]}vx #{round VEHICLE.v[1]}vy #{1000 * round $v.mag VEHICLE.v}pps\n" +
    "  scanner: #{Scanner.scale} "
  return
