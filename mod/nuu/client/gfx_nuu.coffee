
makeStarfield = (mod...)->
  field = (rmax,smax)->
    [ rx, ry, rr, rb ] = [ random()*1024, random()*1024, random()*smax, random()*rmax ]
    g.fillStyle = 'rgba(255,255,255,'+rb+')'
    g.beginPath()
    g.arc rx,ry,rr,0,TAU
    g.fill()
    null
  c = $ '<canvas class="offscreen" width=1024 height=1024>'
  g = c[0].getContext '2d'
  field.apply null, x for i in [0..x[2]] while x = mod.shift()
  return new PIXI.TilingSprite PIXI.Texture.fromCanvas c[0]

Sprite.initSpace = ->
  @layer 'bg',   new PIXI.Container
  @layer 'stel', new PIXI.Container
  @layer 'debr', new PIXI.Container
  @layer 'ship', new PIXI.Container
  @layer 'weap', new PIXI.Container
  @layer 'tile', new PIXI.Container
  @layer 'play', new PIXI.Container
  @layer 'fx',   new PIXI.Container
  @layer 'fg',   new PIXI.Container

  @bg.addChild @starfield = makeStarfield [1,0.3,2000],[1.5,0.7,20]
  @bg.addChild @parallax  = makeStarfield [1,0.3,4000]
  @bg.addChild @parallax2 = makeStarfield [1,0.3,2000]

  @on 'resize', @resizeStars = (wd,hg,hw,hh) =>
    @starfield.width  = @parallax2.width  = @parallax.width  = wd
    @starfield.height = @parallax2.height = @parallax.height = hg
  @resizeStars window.innerWidth,window.innerHeight,window.innerWidth/2,window.innerHeight/2

do Sprite.initSpace

Sprite.repositionPlayer = (w=WIDTH,h=HEIGHT,hw=WDB2,hh=HGB2)->
  return unless ( v = VEHICLE ) and v.loaded
  r = v.radius
  v.sprite.position.set hw - r, hh - r

Sprite.select = ->
  Horizon = 10 * max WIDTH, HEIGHT
  VEHICLE.update time = NUU.time()
  { x,y } = VEHICLE
  i = -1
  s = null
  list   = $obj.list.slice()
  length = list.length
  while ++i < length
    s = list[i]
    s.update time
    if s.ttl and s.ttl < time
      s.hide()
      s.destructor() if s.ttlFinal
      continue
    if Horizon > sqrt (s.x-x)**2 + (s.y-y)**2
      continue if SHORTRANGE[s.id]
      SHORTRANGE[s.id] = s
      NUU.emit '$obj:inRange', s
      console.log 'inRange', s.name, s.id
    else
      debugger if VEHICLE is s # INVESTIGATE
      continue unless SHORTRANGE[s.id]
      delete SHORTRANGE[s.id]
      NUU.emit '$obj:outRange', s
      console.log 'outRange', s.name, s.id
  null

Sprite.animate = (timestamp) ->
  return unless VEHICLE
  time = NUU.time()
  VEHICLE.update time
  window.OX = -VEHICLE.x + WDB2
  window.OY = -VEHICLE.y + HGB2

  # if NUU.settings.gfx.speedScale
  sc = min 1, Sprite.scale
  # ( max 1, ( abs(VEHICLE.m[0]) + abs(VEHICLE.m[1]) ) / 500 )
  @stel.scale.x = @stel.scale.y = @debr.scale.x = @debr.scale.y = @ship.scale.x = @ship.scale.y = @weap.scale.x = @weap.scale.y = @tile.scale.x = @tile.scale.y = @play.scale.x = @play.scale.y = @fx.scale.x = @fx.scale.y = @fg.scale.x = @fg.scale.y = sc
  @stel.position.x = @debr.position.x = @ship.position.x = @weap.position.x = @tile.position.x = @play.position.x = @fx.position.x = @fg.position.x = .5 * ( WIDTH - WIDTH * sc )
  @stel.position.y = @debr.position.y = @ship.position.y = @weap.position.y = @tile.position.y = @play.position.y = @fx.position.y = @fg.position.y = .5 * ( HEIGHT - HEIGHT * sc )
  # @bg.scale.x = @bg.scale.y =
  # @bg.position.x =
  # @bg.position.y =

  # STARS
  [ mx, my ] = $v.mult(
    $v.normalize(VEHICLE.m.slice()),
    Math.max 0.1, $v.mag(VEHICLE.m.slice()) * 1/Speed.max * 3 )
  mx =  0.1 if mx is 0
  my = -0.1 if my is 0
  @starfield.tilePosition.x -= mx
  @starfield.tilePosition.y -= my
  @parallax. tilePosition.x -= mx * 1.25
  @parallax. tilePosition.y -= my * 1.25
  @parallax2.tilePosition.x -= mx * 10
  @parallax2.tilePosition.y -= my * 10

  length = ( list = @visibleList ).length; i = -1
  # time = NUU.time()
  while ++i < length
    ( s = list[i] ).updateSprite time
    continue unless beam = Weapon.beam[s.id]
    sp = beam.sprite
    sp.tilePosition.x += 0.5
    sp.position.set s.x + OX, s.y + OY
    sp.rotation = ( s.d + beam.dir ) / RAD

  length = ( list = Weapon.proj ).length; i = -1
  # time = NUU.time()
  while ++i < length
    s = list[i]
    ticks = ( time - s.ms ) * TICKi
    x = floor s.sx + s.mx * ticks
    y = floor s.sy + s.my * ticks
    s.sprite.position.set x + OX, y + OY
    if s.tt < time
      Sprite.weap.removeChild s.sprite
      list[i] = null
  Weapon.proj = Weapon.proj.filter (i)-> i isnt null

  @renderHUD()     # if @renderHUD
  @renderScanner() # if ++@tick % 10 is 0
  # if VEHICLE.sprite
  #   # VEHICLE.sprite.anchor = [0,0]
  #   VEHICLE.sprite.position.set WDB2, HGB2
  @renderer.render @stage
  null
