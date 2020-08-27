
DEG2BYTE = 255/360

$static 'vt', new VT100

GFX.splashInit = ->
  new GFX.StarfieldLayer layer:0
  Promise.resolve()

GFX.initGame = ->
  GFX.singles = new GFX.SingleSprite
  GFX.beam = new GFX.BeamRenderer
  # list = ( [k,v] for k,v of $meta )
  # .filter (i)-> not ( i[1].rows > 1 or i[1].rows > 1 )
  # .sort (a,b)->
  #   ba = b[1].width * b[1].height
  #   aa = a[1].width * a[1].height
  #   ba - aa
  # list.forEach (a,x)->
  #   url = "build/gfx/#{a[0]}.png"
  #   GFX.singles.addURL url, a[1]
  # GFX.singles.addURL '/build/gfx/' + k + '.png', $meta[k] for k in @preload
  GFX.singles.preload '/build/gfx/' + k + '.png', $meta[k] for k in @preload
  return

GFX.repositionPlayer = (w=WIDTH,h=HEIGHT,hw=WDB2,hh=HGB2)->
  return unless ( v = VEHICLE )?.loaded
  r = v.radius
  v.sprite.position.set hw - r, hh - r

GFX.animateGame = (timestamp) ->
  return unless VEHICLE
  time = NUU.time()
  HUD.frame++
  VEHICLE.update time
  window.OX = -VEHICLE.x
  window.OY = -VEHICLE.y
  sc = min 2, GFX.scale; isc = 1/sc
  maxs = 1024*isc; minx = miny = -maxs; maxx = WIDTH*isc + maxs;  maxy = HEIGHT*isc + maxs
  # if sc isnt @lastSC
  #   @stel.scale.x = @stel.scale.y = @debr.scale.x = @debr.scale.y = @ship.scale.x = @ship.scale.y = @weap.scale.x = @weap.scale.y = @tile.scale.x = @tile.scale.y = @play.scale.x = @play.scale.y = @fx.scale.x = @fx.scale.y = @fg.scale.x = @fg.scale.y = sc
  #   @stel.position.x = @debr.position.x = @ship.position.x = @weap.position.x = @tile.position.x = @play.position.x = @fx.position.x = @fg.position.x = .5 * ( WIDTH - WIDTH * sc )
  #   @stel.position.y = @debr.position.y = @ship.position.y = @weap.position.y = @tile.position.y = @play.position.y = @fx.position.y = @fg.position.y = .5 * ( HEIGHT - HEIGHT * sc )
  #   @lastSC = sc
  ssc = Scanner.scale
  srd = Scanner.radius
  # @nebulae.  position.x = VEHICLE.x * -0.0000034
  # @nebulae.  position.y = VEHICLE.y * -0.0000034
  # @starfield.update()
  # visible sprites
  length = ( list = @visibleList ).length; i = 0
  list[i++].updateSprite(time,OX,OY,ssc,srd,minx,maxx,miny,maxy) while i < length
  return

NUU.on '$obj:del', (obj) ->
  Array.remove VEHICLE.hostile, obj
  return

#  ██████  ██████       ██ ███████  ██████ ████████ ███████
# ██    ██ ██   ██      ██ ██      ██         ██    ██
# ██    ██ ██████       ██ █████   ██         ██    ███████
# ██    ██ ██   ██ ██   ██ ██      ██         ██         ██
#  ██████  ██████   █████  ███████  ██████    ██    ███████

$obj::layer       = GFX.STAR
$obj::loaded      = no
$obj::assetPrefix = '/build/gfx/'

$obj::loadAssets = ->
  { @size, @radius } = @meta = $meta[@sprite]
  @img = url = @assetPrefix + @sprite + '.png'
  @sprite = GFX.singles.Sprite @img, @meta # if @size < 256 # else @sprite = new THREE.Sprite await GFX.TextureCache.preload @img
  @loaded = true
  return

$obj::show = ->
  return console.log @name, @id, 'already visible' if GFX.visible[@id] #if debug
  console.log ':gfx', 'show$', @id, @name, @sprite if debug
  @sprite.show()
  @sprite.position[2] = @layer
  GFX.visible[@id] = @sprite
  GFX.visibleList.push @
  return

$obj::hide = ->
  return console.log @name, @id, 'already hidden' unless old = GFX.visible[@id] #if debug
  console.log ':gfx', 'hide$', @id, @name if debug
  @sprite.hide()
  delete GFX.visible[@id]
  Array.remove GFX.visibleList, @
  return

$obj::updateSprite = (time,ox,oy)->
  @update time
  pos = @sprite.position
  pos[0] = @x-ox
  pos[1] = @y-oy
  true

Stellar::layer = GFX.STAR

# ███████ ██   ██ ██ ██████
# ██      ██   ██ ██ ██   ██
# ███████ ███████ ██ ██████
#      ██ ██   ██ ██ ██
# ███████ ██   ██ ██ ██


Ship::loadAssets = ->
  @imgCom = "/build/gfx/#{@sprite}_comm.png"
  @spriteNormal = GFX.singles.Sprite "/build/gfx/#{@sprite}.png", $meta[@sprite]
  @spriteEngine = GFX.singles.Sprite "/build/gfx/#{@sprite}_engine.png", $meta[@sprite+'_engine']
  @sprite = @spriteNormal
  return

Ship::updateSprite = (time,ox,oy,sc,rd,minx,maxx,miny,maxy)->
  @update time
  { position, info } = @sprite
  position[0] = x = @x - ox
  position[1] = y = @y - oy
  info[0] = DEG2BYTE * @d
  if @state.acceleration
    if @sprite is @spriteNormal
      @spriteNormal.hide()
      @spriteEngine.show()
      @sprite = @spriteEngine
  else
    if @sprite is @spriteEngine
      @spriteNormal.show()
      @spriteEngine.hide()
      @sprite = @spriteNormal
  @sprite.position[2] = @layer
  return unless b = @beam
  x =  @x - ox
  y = -@y + oy # webgl...
  rotation = ( @d + b.dir ) * RADi
  b.position[0] = x
  b.position[1] = y
  b.position[3] = x + b.range * cos rotation
  b.position[4] = y - b.range * sin rotation
  true

Ship::layer = GFX.SHIP

# ████████ ██ ██      ███████
#    ██    ██ ██      ██
#    ██    ██ ██      █████
#    ██    ██ ██      ██
#    ██    ██ ███████ ███████

$abstract 'Tile',
  layer: GFX.WEAPON
  loadAssets: -> @sprite = GFX.singles.Sprite "/build/gfx/#{@sprite}.png", $meta[@sprite]
  updateSprite: (time,ox,oy,sc,rd,minx,maxx,miny,maxy)->
    @update time
    { position, info } = @sprite
    position[0] = @x - ox
    position[1] = @y - oy
    position[2] = 1
    info[0] = DEG2BYTE * @d
    true

$Tile Missile, sprite: 'banshee', ttlFinal: yes

#  █████  ███    ██ ██ ███    ███  █████  ████████ ██  ██████  ███    ██
# ██   ██ ████   ██ ██ ████  ████ ██   ██    ██    ██ ██    ██ ████   ██
# ███████ ██ ██  ██ ██ ██ ████ ██ ███████    ██    ██ ██    ██ ██ ██  ██
# ██   ██ ██  ██ ██ ██ ██  ██  ██ ██   ██    ██    ██ ██    ██ ██  ██ ██
# ██   ██ ██   ████ ██ ██      ██ ██   ██    ██    ██  ██████  ██   ████

$abstract 'Animated',
  layer: GFX.DEBRIS
  loop: no
  loadAssets:->
    meta = Object.assign {
      ttl:      @ttl
      loop:     @loop is true
      reverse:  @reverse is true
      animated: true
    }, $meta[@sprite]
    @sprite = GFX.singles.Sprite "/build/gfx/#{@sprite}.png", meta
  updateSprite:(t,x,y)-> @update t; pos = @sprite.position; pos[0] = @x-x; pos[1] = @y-y; true

$Animated.id = 0
$Animated Debris, sprite: 'debris0'
$Animated Cargo,  sprite: 'cargo', loop:yes

# ███████ ██   ██ ██████  ██       ██████  ███████ ██  ██████  ███    ██
# ██       ██ ██  ██   ██ ██      ██    ██ ██      ██ ██    ██ ████   ██
# █████     ███   ██████  ██      ██    ██ ███████ ██ ██    ██ ██ ██  ██
# ██       ██ ██  ██      ██      ██    ██      ██ ██ ██    ██ ██  ██ ██
# ███████ ██   ██ ██      ███████  ██████  ███████ ██  ██████  ██   ████

$obj.register class Explosion extends $obj
  @sizes: ['exps','expm','expl','expl2']
  @interfaces: []
  id: 'animation'
  parent: null
  effect: true
  constructor: (parent,i)->
    i = round random() if i is -1
    qs = parent.size/4
    hs = parent.size/2
    super
      parent:parent
      id:'animation' + $Animated.id++
      sprite: Explosion.sizes[i]
      state:
        S: $fixedTo
        relto: parent
        x: -qs+random()*hs
        y: -qs+random()*hs
    Sound['explosion0.wav'].play() if Sound.on
    @show()
  @create:(parent,i=-1)->
    return false unless parent and parent.id
    return false if parent.destructing and parent.constructor.type is "station"
    new Explosion parent, i

$Animated Explosion, loop:no, layer: GFX.EXPLOSION

# A collage animation to 'splode ships and stuff :>
$Animated.destroy = (v,t=100,c=5) ->
  $Animated.explode v, min(t,round(random()*t)), 1 for i in [0...c-1]

$Animated.respawn = (v,t=4000,c=25) ->
  $Animated.explode v, min(t,round(random()*t)) for i in [0...c-1]
  $Animated.explode v, t, 3
  setTimeout ( -> v.hide() ), t
  setTimeout ( -> v.show() ), t + 3000
  if v is VEHICLE
    for t in [0..8]
      ( (t)-> setTimeout (-> HUD.widget 'respawn',(8-t)+'s'), t*1000 )(t)
    setTimeout (-> HUD.widget 'respawn',null), 9000
  return

$Animated.explode = (v,t,i) ->
  setTimeout ( -> Explosion.create v,i ), t

NUU.on '$obj:hit',      (v) -> $Animated.explode v, 0, 1
NUU.on '$obj:shield',   (v) -> $Animated.explode v, 0, 2
NUU.on '$obj:disabled', (v) -> $Animated.explode v, 0, 3

NUU.on '$obj:destroyed', (v) ->
  return $Animated.destroy v, 100, 5 unless v.constructor.name is 'Ship'
  return $Animated.respawn v

# ██████  ██████   ██████       ██ ███████  ██████ ████████ ██ ██      ███████
# ██   ██ ██   ██ ██    ██      ██ ██      ██         ██    ██ ██      ██
# ██████  ██████  ██    ██      ██ █████   ██         ██    ██ ██      █████
# ██      ██   ██ ██    ██ ██   ██ ██      ██         ██    ██ ██      ██
# ██      ██   ██  ██████   █████  ███████  ██████    ██    ██ ███████ ███████

Weapon.Projectile.loadAssets = ->
  # @base = GFX.singles.Sprite "/build/gfx/#{@sprite}.png", $meta[@sprite]
  return # w = @meta.width / @meta.cols; new PIXI.Rectangle 0,0,w,w

window.ProjectileAnimation = (@perp,@weap,@ms,@tt,@sx,@sy,@vx,@vy,@dir)->
  sprite = @weap.sprite
  @sprite = GFX.singles.Sprite "/build/gfx/#{sprite}.png", $meta[sprite]
  @sprite.show()
  @sprite.position[0] = @perp.x # + VEHICLE.x
  @sprite.position[1] = @perp.y # + VEHICLE.y
  @sprite.position[2] = GFX.WEAPON
  @sprite.info[0] = DEG2BYTE * RAD * @dir
  @sprite.info[1] = 0
  @sprite.info[2] = 0
  @sprite.batch.infoInterleaved.needsUpdate = true
  @destroy = @sprite.destroy.bind @sprite
  Weapon.proj.push @

# ██████  ███████  █████  ███    ███
# ██   ██ ██      ██   ██ ████  ████
# ██████  █████   ███████ ██ ████ ██
# ██   ██ ██      ██   ██ ██  ██  ██
# ██████  ███████ ██   ██ ██      ██

Weapon.Beam.loadAssets = ->
Weapon.Beam.show = -> GFX.beam.add    @ship
Weapon.Beam.hide = -> GFX.beam.remove @ship

$public class GFX.BeamRenderer
  max: 100
  nextId:0
  constructor:(opts={})->
    @list = []
    @geometry = new THREE.BufferGeometry
    @geometry.defineAttributes @, @max,
      position: type:Float32Array, count:3, init:[0,0,1]
      color:    type:Float32Array, count:4, init:1
    @material  = new THREE.LineBasicMaterial
    @particles = new THREE.Line @geometry, @material
    GFX.scene.add @particles
    GFX.children.push @
  add:(object)->
    id = @nextId++; id6 = id * 6
    object.beam.position = @positionArray.subarray id6, id6+6
    @list.push object
    GFX.beam.geometry.setDrawRange 0, @list.length + 1
    @positionInterleaved.needsUpdate = true
  remove:(object)->
    return unless object.beam
    Array.remove @list, object
    @nextId--
    GFX.beam.geometry.setDrawRange 0, @list.length
    return unless @list.length > 0
    last = @list.pop()
    object.beam.position.set last.beam.position
    object.beam.position = false
    last.beam.position = object.beam.position
  update:->
    @positionInterleaved.needsUpdate = true

# ███████ ███████ ██      ███████  ██████ ████████
# ██      ██      ██      ██      ██         ██
# ███████ █████   ██      █████   ██         ██
#      ██ ██      ██      ██      ██         ██
# ███████ ███████ ███████ ███████  ██████    ██

new class $obj.Select extends $worker.InlineThread
  constructor:->
    super()
    @visible = new Set
    @short   = new Set
    @long    = new Set
    @slice = 300; @offset = 0
    @timer = setInterval ( =>
      @update $obj.list.slice @offset, @offset + @slice
      @offset = @offset + @slice
      @offset = 0 if @offset >= $obj.list.length
    ), TICK
    @thread.addEventListener 'message', @result
    $obj.scope = @
    $obj.select = @update.bind @
  update:(list)->
    visible = []; short = []; long = []
    visible2 = 10000**2
    short2   = 5e7**2
    length   = list.length
    time     = NUU.time()
    VEHICLE.updateScanner()
    {x,y}    = VEHICLE
    for s,i in list
      s.updateScanner time,x,y,false
      dx = s.x-x
      dy = s.y-y
      d2 = dx*dx + dy*dy
      if visible2 > d2
        unless @visible.has s
          @visible.add s; visible.push s; s.show()
      else
        s.hide() if @visible.delete s
        if short2 > d2
          unless @short.has s
            @short.add s; short.push s
        else unless @long.has s
            @long.add s; long.push s
    NUU.emit '$obj:range:visible', visible, @visible if visible.length isnt 0
    NUU.emit '$obj:range:short',     short,   @short if short.length isnt 0
    NUU.emit '$obj:range:long',       long,    @long if long.length isnt 0
    NUU.emit '$obj:range:long:update',         @long if list is $obj.list
    return
  worker:-> return

# ███████ ████████ ██             ██ ██    ██ ███    ███ ██████
# ██         ██    ██             ██ ██    ██ ████  ████ ██   ██
# █████      ██    ██             ██ ██    ██ ██ ████ ██ ██████
# ██         ██    ██        ██   ██ ██    ██ ██  ██  ██ ██
# ██         ██    ███████    █████   ██████  ██      ██ ██

NET.on 'jump', (v)->
  VEHICLE.hide() unless arrive = v is 2
  if arrive then setTimeout (
    -> VEHICLE.show()
  ), 500
  new Shim reverse:arrive, state: S:$fixedTo, relto:VEHICLE, x:0, y:0
  return unless arrive
  VEHICLE.update()
  $obj.select yes
  return

$public class Shim extends $obj
  @interfaces: []
  effect: true
  constructor: (opts={})->
    super Object.assign {
      id:     'shim'
      sprite: 'shim'
      name: 'A Shim'
      ttl: opts.ttl || NUU.time() + 500
      ttlFinal: yes
      layer: GFX.EXPLOSION
      loop: no
    }, opts
    @show()

$Animated Shim
