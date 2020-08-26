###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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

# ██████  ██ ██   ██ ██ ███████ ██    ██  ██████ ██   ██ ███████  ██    ██  ██
# ██   ██ ██  ██ ██  ██ ██      ██    ██ ██      ██  ██  ██       ██    ██ ███
# ██████  ██   ███   ██ ███████ ██    ██ ██      █████   ███████  ██    ██  ██
# ██      ██  ██ ██  ██      ██ ██    ██ ██      ██  ██       ██   ██  ██   ██
# ██      ██ ██   ██ ██ ███████  ██████   ██████ ██   ██ ███████    ████    ██

$static 'GFX', new class NUU.SpriteSurface extends EventEmitter

  preload: ['exps','expm','expl','expl2','cargo','debris0','debris1','debris2','debris3','debris4','debris5']

  STARFIELD  : 1
  STAR       : 11
  PLANET     : 12
  MOON       : 13
  ASTEROID   : 14
  DEBRIS     : 15
  CARGO      : 16
  SHIP       : 17
  PLAYER     : 18
  WEAPON     : 19
  EXPLOSION  : 20
  HUD        : 21

  renderer    : null
  scene       : null
  camera      : null

  visible     : {}
  visibleList : []
  children    : []

  scale       : 1
  tick        : 0
  startTime   : 0

  constructor:->
    super()
    @updateScreenDimensions()
    try # using webgl2
      @canvas  = document.createElement 'canvas'
      @context = @canvas.getContext 'webgl2'
    @renderer  = new THREE.WebGLRenderer canvas:@canvas, context:@context, antialias:no
    @loader    = new THREE.TextureLoader
    @scene     = new THREE.Scene
    @camera    = new THREE.OrthographicCamera -@wdb2, @wdb2, @hgb2, -@hgb2, 1, 1000
    @scene.fog = new THREE.FogExp2 0x000000, 0.001
    @renderer.setClearColor 0x000000
    @renderer.setPixelRatio window.devicePixelRatio
    @renderer.setSize @width, @height
    @camera.position.z = 1000
    document.body.appendChild @renderer.domElement
    window.addEventListener 'resize', @resize.bind(@)
    animate = =>
      @render()
      requestAnimationFrame animate
      return
    setTimeout =>
      @resize true
      do animate
      await @loadMeta()
      await @splashInit()
      console.log 'gfx:ready'
      NUU.emit 'gfx:ready'
      return

  loadMeta:-> new Promise (resolve,reject)->
    $.ajax '/build/images.json', error:reject, success:(result)-> resolve $static '$meta', result
    return

  start:->
    console.log 'gfx:start'
    @startTime = NUU.time()
    Promise.resolve()

  stop:()->
    Promise.resolve()

  updateScreenDimensions:->
    @width  = window.innerWidth  + 1
    @height = window.innerHeight + 1
    @wdb2   = @width/2
    @hgb2   = @height/2

  resize:(event)->
    @updateScreenDimensions()
    @camera.left = -@wdb2
    @camera.right = @wdb2
    @camera.top = @hgb2
    @camera.bottom = -@hgb2
    @camera.updateProjectionMatrix()
    # @updateHUDSprites()
    @renderer.setSize @width, @height
    @emit 'resize', @width, @height, @wdb2, @hgb2 if event
    return

  render: ->
    time = Date.now() / 1000
    GFX.animateGame()
    c.update() for c in @children
    @renderer.render @scene, @camera
    return

# ████████  ██████   ██████  ██      ███████
#    ██    ██    ██ ██    ██ ██      ██
#    ██    ██    ██ ██    ██ ██      ███████
#    ██    ██    ██ ██    ██ ██           ██
#    ██     ██████   ██████  ███████ ███████

GFX.cropText = (text,opts={})->
  tmp = new OffscreenCanvas 200, 200; t = tmp.getContext '2d'
  opts = Object.assign t, {
    font:         '10px Lato'
    fillStyle:    'white'
    strokeStyle:  'black'
    textBaseline: 'top'
    lineJoin:     'miter'
    miterLimit:   2
    lineWidth:    3
  }, opts
  t.strokeText text,10,10
  t.fillText   text,10,10
  d = GFX.getBoundingBox t,0,0,200,200
  out = new OffscreenCanvas d.width, d.height; t = out.getContext '2d'
  t.drawImage tmp, d.left, d.top, d.width, d.height, 0, 0, d.width, d.height
  s = new THREE.Sprite new THREE.SpriteMaterial map: new THREE.CanvasTexture out
  s.scale.set d.width, d.height, 1
  s

GFX.getBoundingBox = (ctx, left, top, width, height) ->
  { data, width, height } = ctx.getImageData left, top, width, height
  leftMost = topMost = 0; rightMost = width; bottomMost = height
  isTransparent = (x,y)-> not data[y * (width * 4) + x * 4 + 3]
  found = no; for x in [0..width]
    for y in [0..height]
      if not isTransparent x,y
        found = yes
        break
    break if found
    leftMost++
  found = no; for y in [0..height]
    for x in [0..width]
      if not isTransparent x,y
        found = yes; break
    break if found
    topMost++
  found = no; for x in [width..0] by -1
    for y in [0..height]
      if not isTransparent x,y
        found = yes; break
    break if found
    rightMost--
  found = no; for y in [height..0] by -1
    for x in [0..width]
      if not isTransparent x,y
        found = yes; break
    break if found
    bottomMost--
  top:topMost, left:leftMost, bottom:bottomMost, right:rightMost, width:rightMost-leftMost, height:bottomMost-topMost

GFX.debugShader = (type,source)->
  gl = GFX.renderer.context
  type = gl[type]
  shader = gl.createShader type
  if type is gl.VERTEX_SHADER then source = """
  precision mediump float;
  uniform mat4 modelViewMatrix;
  uniform mat4 projectionMatrix;
  attribute vec3 position;
  """ + source
  if type is gl.FRAGMENT_SHADER then source = """
  precision mediump float;
  """ + source
  gl.shaderSource shader, source
  gl.compileShader shader
  unless gl.getShaderParameter shader, gl.COMPILE_STATUS
     console.error gl.getShaderInfoLog shader
     console.log source
  else console.log '%cshader ok', 'color:green'

#  █████  ████████ ████████ ██████  ██ ██████  ██    ██ ████████ ███████ ███████
# ██   ██    ██       ██    ██   ██ ██ ██   ██ ██    ██    ██    ██      ██
# ███████    ██       ██    ██████  ██ ██████  ██    ██    ██    █████   ███████
# ██   ██    ██       ██    ██   ██ ██ ██   ██ ██    ██    ██    ██           ██
# ██   ██    ██       ██    ██   ██ ██ ██████   ██████     ██    ███████ ███████

THREE.BufferGeometry::defineAttributes = (object,max,attributes)->
  bytesPerVertex = 0
  for k,v of attributes
    { type, count } = v
    bytesPerVertex += count * type.BYTES_PER_ELEMENT
  object.buffer = new ArrayBuffer max * bytesPerVertex; p = 0
  for k,v of attributes
    { type, count, init } = v
    nameArray = k + 'Array'
    nameInterleaved = k + 'Interleaved'
    a  = object[nameArray]  = new type object.buffer, p, count * max
    p += object[nameArray].byteLength
    object[nameInterleaved] = new THREE.InterleavedBuffer object[nameArray], count
    object[k] = attribute   = new THREE.InterleavedBufferAttribute object[nameInterleaved], count, 0, no
    if not isNaN init
      a.fill init
    else if Array.isArray init
      l = init.length; i = -1
      a.set(init,i*l) while ++i < max
    else if init is '$id'
      a[i] = i for i in [0..max]
    @addAttribute k, attribute
  return

#  ██████  █████   ██████ ██   ██ ███████
# ██      ██   ██ ██      ██   ██ ██
# ██      ███████ ██      ███████ █████
# ██      ██   ██ ██      ██   ██ ██
#  ██████ ██   ██  ██████ ██   ██ ███████

class GFX.TextureCache
  @mapByPath:{}
  @byPath:{}
  @wait:{}
  @preload:(path)-> new Promise (resolve)=>
    return resolve material   if material = @byPath[path]
    return queue.push resolve if queue    = @wait[path]
    GFX.loader.load path, (textureMap)=>
      @mapByPath[path] = textureMap
      @byPath[path] = material = new THREE.SpriteMaterial map:textureMap, fog:no
      @wait[path].forEach (c)-> c material
    @wait[path] = [resolve]
    return

# ███████ ██      ██  ██████ ███████
# ██      ██      ██ ██      ██
# ███████ ██      ██ ██      █████
#      ██ ██      ██ ██      ██
# ███████ ███████ ██  ██████ ███████

class GFX.Slice
  nextId: 0
  constructor:(@id,@w,@h,@x,@y,@parent)->
    if @id is -1
      @x = @y = 0; @width = @w; @height = @h
      @free = [@main = @]
      @isSplit = new Set
      @isClaimed = new Set
    else { @free, @isClaimed, @isSplit, @main } = @parent
    @s = @w * @h
  split:(w,h,opts={})->
    @free = @free.sort (a,b)-> a.s - b.s
    for slice, idx in @free when slice.w >= w and slice.h >= h
      return slice.decide w, h, @main.nextId++, idx, opts
    return false
  decide:(w,h,id,idx,opts)->
    [a,b,n] = if @x is 0 then @horizontal w,h,id else @vertical w,h,id
    @children = [a,b].filter (i)-> i?
    @isSplit.add @
    @isClaimed.add @claim = Object.assign n, opts
    @free.splice.apply @free, [idx, 1].concat @children
    return n
  horizontal:(w,h,id)-> [
    new GFX.Slice null, @w-w, h,    @x+w, @y,   @ unless 0 is @w-w
    new GFX.Slice null, @w,   @h-h, @x,   @y+h, @ unless 0 is @h-h
    new GFX.Slice id,   w,    h,    @x,   @y,   @ ]
  vertical:(w,h,id)-> [
    new GFX.Slice null, @w-w, @h,   @x+w, @y,   @ unless @w is w
    new GFX.Slice null, w,    @h-h, @x,   @y+h, @ unless @h is h
    new GFX.Slice id,   w,    h,    @x,   @y,   @ ]
  remove:-> # can only remove claim-slices
    return false if @ is @main
    return false unless @parent.claim is @
    p = @parent # parent is always a split-slice
    @isClaimed.delete @
    p.claim = null
    while p.tryRelease()
      break if p is @main
      p = p.parent
    true
  tryRelease:->
    hasSplitChild = yes for c in @children when @isSplit.has c
    return false if hasSplitChild
    @isSplit.delete @
    @free.splice idx, 1 for c in @children when -1 isnt idx = @free.indexOf c
    @free.push @
    true
  optimize:(w=@main.width,h=@main.height)->
    console.log 'optimize'
    clone = new GFX.Slice -1, w, h
    list = @isClaimed.values()
    @free = @free.sort (a,b)-> b.s - a.s
    while not ( r = i.next() ).done
      slice = r.value
      move  = clone.split slice.w, slice.h
      out.push [slice,move]
    out
  @Allocator:(w,h)-> new GFX.Slice -1, w, h
