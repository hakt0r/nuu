
# ███████ ██████   █████   ██████ ███████
# ██      ██   ██ ██   ██ ██      ██
# ███████ ██████  ███████ ██      █████
#      ██ ██      ██   ██ ██      ██
# ███████ ██      ██   ██  ██████ ███████

$public class Nebula
  @list: [ "02","16","21","25","29","33","04","17","22","26","30","34","10","19","23","27","31","12","20","24","28","32" ]
  @random:->
    idx = round Nebula.deterministic.double() * ( Nebula.list.length - 1 )
    img = Nebula.list[idx]
    n = PIXI.Sprite.fromImage "build/gfx/nebula#{img}.png"
    n.position.set(
      Nebula.deterministic.double() * 4*WIDTH  - 2*WIDTH
      Nebula.deterministic.double() * 4*HEIGHT - 2*HEIGHT )
    Sprite.nebulae.addChild n

NUU.on 'rules', ->
  Nebula.deterministic = new Deterministic rules.systemName + "-nebulae"
  Nebula.random() for i in [0..2+max 1, Math.ceil Nebula.deterministic.double()*5]
  return

makeStarfield = (mod...)->
  field = (rmax,smax)->
    [ rx, ry, rr, rb ] = [ random()*512, random()*512, random()*smax, random()*rmax ]
    g.fillStyle = 'rgba(255,255,255,'+rb+')'
    g.beginPath()
    g.arc rx,ry,rr,0,TAU
    g.fill()
    return
  c = $ '<canvas class="offscreen" width=512 height=512>'
  g = c[0].getContext '2d'
  field.apply null, x for i in [0..x[2]] while x = mod.shift()
  return new PIXI.TilingSprite PIXI.Texture.fromCanvas c[0]

Sprite.initSplash = ->
  @layer 'bg', new PIXI.Container
  @layer 'fx', new PIXI.Container
  @layer 'fg', new PIXI.Container
  @bg.addChild @nebulae   = new PIXI.Container
  @bg.addChild @starfield = makeStarfield [1,0.3,250],[1.5,0.7,20],[2,0.7,5]
  @fx.addChild @parallax  = makeStarfield [1,0.2,500]
  Nebula.deterministic = new Deterministic 'nuusplash'
  Nebula.random() for i in [0..2+max 1, Math.ceil Nebula.deterministic.double()*5]
  @starfield.alpha = 1.0
  @parallax.alpha  = 1.0
  @nebulae.alpha   = .03
  @on 'resize', @resizeStars = (wd,hg,hw,hh) =>
    @starfield.width  = @parallax.width  = wd
    @starfield.height = @parallax.height = hg
  @resizeStars window.innerWidth,window.innerHeight,window.innerWidth/2,window.innerHeight/2
  @animate = @animateSplash
  return

Sprite.animateSplash = (timestamp) ->
  vx = .0123; vy = -.0223
  @starfield.tilePosition.x -= vx * 2
  @starfield.tilePosition.y -= vy * 2
  @nebulae.  position.x     -= vy * 0.2
  @nebulae.  position.y     -= vy * 0.2
  @parallax. tilePosition.x -= vx * 8
  @parallax. tilePosition.y -= vy * 8
  @renderer.render @stage
  return

do Sprite.initSplash

#  █████  ███    ██ ██ ███    ███  █████  ████████ ███████
# ██   ██ ████   ██ ██ ████  ████ ██   ██    ██    ██
# ███████ ██ ██  ██ ██ ██ ████ ██ ███████    ██    █████
# ██   ██ ██  ██ ██ ██ ██  ██  ██ ██   ██    ██    ██
# ██   ██ ██   ████ ██ ██      ██ ██   ██    ██    ███████

Sprite.initSpace = ->
  @layer 'stel', new PIXI.Container
  @layer 'debr', new PIXI.Container
  @layer 'tile', new PIXI.Container
  @layer 'weap', new PIXI.Container
  @layer 'ship', new PIXI.Container
  @layer 'play', new PIXI.Container
  do Scanner.show
  do HUD.show
  @repositionPlayer = @repositionPlayerSpace
  @animate = @animateSpace
  return

Sprite.repositionPlayerSpace = (w=WIDTH,h=HEIGHT,hw=WDB2,hh=HGB2)->
  return unless ( v = VEHICLE ) and v.loaded
  r = v.radius
  v.sprite.position.set hw - r, hh - r

Sprite.animateSpace = (timestamp) ->
  return unless VEHICLE
  HUD.frame++
  VEHICLE.update time = NUU.time(); window.OX = -VEHICLE.x + WDB2; window.OY = -VEHICLE.y + HGB2

  sc = min 2, Sprite.scale
  if sc isnt @lastSC
    @stel.scale.x = @stel.scale.y = @debr.scale.x = @debr.scale.y = @ship.scale.x = @ship.scale.y = @weap.scale.x = @weap.scale.y = @tile.scale.x = @tile.scale.y = @play.scale.x = @play.scale.y = @fx.scale.x = @fx.scale.y = @fg.scale.x = @fg.scale.y = sc
    @stel.position.x = @debr.position.x = @ship.position.x = @weap.position.x = @tile.position.x = @play.position.x = @fx.position.x = @fg.position.x = .5 * ( WIDTH - WIDTH * sc )
    @stel.position.y = @debr.position.y = @ship.position.y = @weap.position.y = @tile.position.y = @play.position.y = @fx.position.y = @fg.position.y = .5 * ( HEIGHT - HEIGHT * sc )
    @lastSC = sc

  [ vx, vy ] = $v.mult(
    $v.normalize VEHICLE.v.slice()
    Math.min 0.1, Math.max 0.3, $v.mag(VEHICLE.v.slice()) * 1/Speed.max * 3 )
  vx = 0.07 if vx is 0
  vy = 0.07 if vy is 0

  @nebulae.  position.x = VEHICLE.x * -0.0000034
  @nebulae.  position.y = VEHICLE.y * -0.0000034
  @starfield.tilePosition.x -= vx * 10
  @starfield.tilePosition.y -= vy * 10
  @parallax. tilePosition.x -= vx * 8
  @parallax. tilePosition.y -= vy * 8

  length = ( list = @visibleList ).length; i = -1
  while ++i < length
    continue if VEHICLE is s = list[i]
    s.updateSprite NUU.time()
    continue unless beam = Weapon.beam[s.id]
    sp = beam.sprite
    sp.tilePosition.x += 0.5
    sp.position.set s.x + OX, s.y + OY
    sp.rotation = ( s.d + beam.dir ) / RAD

  length = ( list = Weapon.proj ).length; i = -1
  while ++i < length
    s = list[i]
    t = time - s.ms
    x = s.sx + s.vx * t
    y = s.sy + s.vy * t
    s.sprite.position.set x + OX, y + OY
    if s.tt < time
      Sprite.weap.removeChild s.sprite
      list[i] = null
  Weapon.proj = Weapon.proj.filter (i)-> i isnt null

  @renderHUD()
  @renderScanner()
  VEHICLE.updateSprite time
  @renderer.render @stage
  return

NUU.on '$obj:range:short', (list)-> list.forEach (s)-> s.show()
NUU.on '$obj:range:mid',   (list)-> list.forEach (s)-> s.hide()
NUU.on '$obj:range:long',  (list)-> list.forEach (s)-> s.hide()

# ███████ ████████ ██             ██ ██    ██ ███    ███ ██████
# ██         ██    ██             ██ ██    ██ ████  ████ ██   ██
# █████      ██    ██             ██ ██    ██ ██ ████ ██ ██████
# ██         ██    ██        ██   ██ ██    ██ ██  ██  ██ ██
# ██         ██    ███████    █████   ██████  ██      ██ ██

NET.on 'jump', (v)->
  VEHICLE.sprite.visible = false unless arrive = v is 2
  callback = if arrive then ( -> VEHICLE.spriteNormal.visible = VEHICLE.spriteEngine.visible = true ) else undefined
  new Shim onComplete:callback, reverse: arrive, state: S:$fixedTo, relto:VEHICLE, x:0, y:0
  if arrive = v is 2
    VEHICLE.update()
    $obj.select yes
  return

$public class Shim extends $obj
  @interfaces: []
  constructor: (opts={})->
    super Object.assign {
      sprite: 'shim'
      name: 'A Shim'
      ttl: opts.ttl || NUU.time() + 500
      ttlFinal: yes
      layer:'fg'
    }, opts

$Animated Shim
