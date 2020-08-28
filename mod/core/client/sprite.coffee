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

# ███████ ██████  ██████  ██ ████████ ███████     ██████   █████  ████████  ██████ ██   ██
# ██      ██   ██ ██   ██ ██    ██    ██          ██   ██ ██   ██    ██    ██      ██   ██
# ███████ ██████  ██████  ██    ██    █████       ██████  ███████    ██    ██      ███████
#      ██ ██      ██   ██ ██    ██    ██          ██   ██ ██   ██    ██    ██      ██   ██
# ███████ ██      ██   ██ ██    ██    ███████     ██████  ██   ██    ██     ██████ ██   ██

$public class GFX.SpriteBatch
  lastLength: 0
  count: 0
  max: 0xFFFF
  nextId: 0
  freeId: null
  constructor:(opts={})->
    @freeId = []
    Object.assign @, opts
  initialize:(opts={})->
    @geometry = new THREE.BufferGeometry
    @geometry.defineAttributes @, @max, opts.attributes
    GFX.debugShader 'FRAGMENT_SHADER', opts.fragment || @constructor.fragment
    GFX.debugShader 'VERTEX_SHADER',   opts.vertex   || @constructor.vertex
    @material = new THREE.ShaderMaterial
      precision:      'highp'
      transparent:    yes
      depthWrite:     yes
      uniforms:       opts.uniforms
      fragmentShader: opts.fragment || @constructor.fragment
      vertexShader:   opts.vertex   || @constructor.vertex
    @particles = new THREE.Points @geometry, @material
    @particles.position.z = opts.layer || 500
    @particles.for = @constructor.name
    GFX.scene.add @particles
    GFX.children.push @ # GFX.scene.add d = new THREE.Sprite new THREE.SpriteMaterial map:@labelTexture; d.scale.set 1024, 1024, 1

# ███████ ██ ███    ██  ██████  ██      ███████ ███████
# ██      ██ ████   ██ ██       ██      ██      ██
# ███████ ██ ██ ██  ██ ██   ███ ██      █████   ███████
#      ██ ██ ██  ██ ██ ██    ██ ██      ██           ██
# ███████ ██ ██   ████  ██████  ███████ ███████ ███████

$public class GFX.SingleSprite extends GFX.SpriteBatch
  used:0
  constructor:(width=8192,height=16384)->
    super width, height
    @texture = new GFX.BatchTexture width, height, @, debug
    @initialize
      attributes:
        position: type:Float32Array, count:3, init:[0,0,2000]
        time:     type:Float32Array, count:1, init:0
        sliceId:  type:Uint16Array,  count:1, init:0 # GFX.BatchTexture.MAX_SLICES
        info:     type:Uint8Array,   count:4, init:0
      uniforms:
        debug:     value: 0
        uTime:     value: 0
        uScreen:   value: [GFX.width,GFX.height]
        uUser:     value: [0,0]
        uScale:    value: 1
        uSlice:    value: @texture
        uSlicePos: value: @texture.slicePositionTexture
        uSliceDiv: value: @texture.sliceDivisionTexture
        uSliceDim: value: [@texture.width,@texture.height]
    GFX.startTime = NUU.time()
    return
  preload:(url,meta)-> @texture.addSource url, meta

GFX.SingleSprite::update = (time=NUU.time())->
  VEHICLE.update time
  length = ( list = GFX.visibleList ).length; i = 0
  @positionInterleaved.needsUpdate = true
  @infoInterleaved.needsUpdate = true
  @material.uniforms.uTime.value = time - GFX.startTime
  @material.uniforms.uUser.value[0] = ox = VEHICLE.x
  @material.uniforms.uUser.value[1] = oy = VEHICLE.y
  @material.uniforms.uScale.value = GFX.scale
  @material.uniforms.uScreen.value = [ GFX.width, GFX.height ]
  # sprites
  while i < length
    s = list[i++]
    s.updateSprite     time,ox,oy
    s.updateShortrange time,ox,oy,3
  # projectiles
  length = ( list = Weapon.proj ).length; i = 0
  while i < length
    s = list[i]
    p = s.sprite.position
    t = time - s.ms
    p[0] = ox - s.sx + s.vx * t
    p[1] = oy - s.sy + s.vy * t
    if s.tt < time
      s.sprite.destroy()
      list[i] = false
    i++
  Weapon.proj = Weapon.proj.filter (i)-> i isnt false
  HUD.render()
  return

GFX.SingleSprite.vertex = """
attribute vec4 info;
attribute float sliceId;
attribute float time;
attribute float id;

uniform float uTime;
uniform float uScale;
uniform float debug;
uniform  vec2 uUser, uScreen, uSliceDim;

uniform sampler2D uSlicePos;
uniform sampler2D uSliceDiv;

varying vec4 vOffset;
varying vec2 vCrop;
varying mat2 vRotation;

const float TAU      = 6.283185307179586;
const float BYTE2RAD = TAU/255.;
const float DPX = 1./255.;
const float HIDE = 2000.;

float roundFloat(float v){
  float f = floor(v);
  if ( .5 > v - f ) return f;
  return f + 1.; }

void main() {
  vec4 dm;
  vec2 pos = position.xy, size, aspect, colsRows, TPX = 1. / uSliceDim;
  float z = position.z, frame, cols, rows, count, img, dt = uTime - info[1], minSize = 16.;
  // SPRITE
  vOffset = texture2D( uSlicePos, vec2( DPX * (mod(sliceId,255.)+.5), DPX * -(sliceId/255. +.5) ));
  dm      = texture2D( uSliceDiv, vec2( DPX * (mod(sliceId,255.)+.5), DPX * -(sliceId/255. +.5) ));
  cols    = roundFloat(1./dm.r);
  rows    = roundFloat(1./dm.g);
  count   = cols * rows;
  aspect  = vOffset.ba * uSliceDim;
  vCrop   = vec2(1.,1.); if ( aspect.x > aspect.y ){ vCrop = vec2(0.,aspect.y/aspect.x); }
  vec2 subDimensions = vOffset.ba * dm.rg;
  subDimensions.y = subDimensions.y / vCrop.y; // non-square
  if ( count > 1. ){
    if ( info[2] > 0. ){ // animation state
      frame = (uTime-time)/info[2];
      if (( info[3] == 0. ) && ( frame > count )) z = HIDE;
      img = floor(mod(frame,count));
      if ( info[1] == 1. ) img = count - img;
      minSize = 1.; }
    else { // rotation  state
      img = floor( info[0] * count/255. );
      if ( img > 0. ) img = count - img; }
    colsRows = vec2( floor(mod(img,cols)), floor(img/cols) );
    vOffset = vec4( vOffset.rg + colsRows * subDimensions, subDimensions ); }
  else {  vOffset = vec4( vOffset.rg, subDimensions ); }
  size = uSliceDim * subDimensions;
  gl_PointSize = max(minSize, max( size.x, size.y ) * uScale );
  // ROTATION
  float v = 0.; vRotation = mat2( cos(v),sin(v), -sin(v),cos(v) );
  // POSITION
  pos.y = -pos.y;
  if ( uScale != 1. ) pos = pos * uScale;
  gl_Position = projectionMatrix * modelViewMatrix * vec4( pos, z, 1.0 ); }
"""

GFX.SingleSprite.fragment = """
  const      vec2 mid = vec2(0.5, 0.5);
uniform sampler2D uSlice;
uniform     float debug;
uniform     float uTime;
uniform      vec2 uSliceDim;
varying      vec2 vCrop;
varying      vec4 vOffset;
varying      mat2 vRotation;
void main() {
  vec2 txo, pro; vec4 tex;
  txo = vec2(.5/uSliceDim.x,.5/uSliceDim.y);
  pro = vRotation * (gl_PointCoord - mid) + mid;
  pro = gl_PointCoord;
  tex = texture2D( uSlice, pro * vOffset.ba + vOffset.rg );
  if ( tex.a < .01 ) discard;
  gl_FragColor = tex; }
"""

# ██████   █████  ████████  ██████ ██   ██     ████████ ███████ ██   ██ ████████ ██    ██ ██████  ███████
# ██   ██ ██   ██    ██    ██      ██   ██        ██    ██       ██ ██     ██    ██    ██ ██   ██ ██
# ██████  ███████    ██    ██      ███████        ██    █████     ███      ██    ██    ██ ██████  █████
# ██   ██ ██   ██    ██    ██      ██   ██        ██    ██       ██ ██     ██    ██    ██ ██   ██ ██
# ██████  ██   ██    ██     ██████ ██   ██        ██    ███████ ██   ██    ██     ██████  ██   ██ ███████

class GFX.BatchTexture extends THREE.DataTexture
  @SINGLE: cols:1, rows:1
  isBatchTexture: true
  MAX_SLICES:     0xFFFF
  sliceId:        0
  constructor:(width=1024,height=1024,parent,debug)->
    super     ( new Uint8Array width * height * 4 ), width, height, THREE.RGBAFormat
    @slices   = GFX.Slice.Allocator width, height
    @refs     = new Set
    @bySource = new Map
    @loading  = new Object
    @width    = width
    @height   = height
    @parent   = parent
    @renderer = GFX.renderer
    @needsUpdate = yes

    @slicePosition        = new Float32Array @MAX_SLICES * 4
    @sliceDivision        = new Float32Array @MAX_SLICES * 4
    @slicePositionTexture = new THREE.DataTexture @slicePosition, 0xFF, 0xFF, THREE.RGBAFormat, THREE.FloatType
    @sliceDivisionTexture = new THREE.DataTexture @sliceDivision, 0xFF, 0xFF, THREE.RGBAFormat, THREE.FloatType
    return unless debug
    GFX.scene.add @debugBG = d = new THREE.Sprite new THREE.SpriteMaterial color: 0xffffff
    GFX.scene.add @debug = d = new THREE.Sprite new THREE.SpriteMaterial map:@, color: 0xffffff
    do r = =>
      @debugBG.scale.set 128, 128, 1
      @debugBG.position.set(-GFX.wdb2+66,GFX.hgb2-66,1)
      @debug.scale.set 128, 128, 1
      @debug.position.set(-GFX.wdb2+66,GFX.hgb2-66,1)
    GFX.on 'resize', r
    return

GFX.BatchTexture::updateDivision = (slice,meta)->
  id4 = slice.id * 4
  @slicePosition[id4]   = slice.x / @width
  @slicePosition[id4+1] = slice.y / @height
  @slicePosition[id4+2] = slice.w / @width
  @slicePosition[id4+3] = slice.h / @height
  @sliceDivision[id4]   = 1 / meta.cols
  @sliceDivision[id4+1] = 1 / meta.rows
  @slicePositionTexture.needsUpdate = true
  @sliceDivisionTexture.needsUpdate = true
  return

GFX.BatchTexture::deferAdd = (slice,source,meta)->
  # console.log "gfx:add", (if source.match then source else '[buffer]'), slice.w, slice.h if debug
  source = await Cache.getTexture source if source.match
  @renderer.copyTextureToTexture slice, source, @
  return

GFX.BatchTexture::addSource = (source,meta)->
  if slice = @bySource.get source
    slice.refCount++
    return slice
  unless slice = @slices.split meta.width, meta.height
    return console.error 'outOfCake', @
  # console.log "gfx:request", source, meta.width, meta.height if debug
  @bySource.set source, slice
  slice.refCount = 0
  slice.id = @sliceId++
  @updateDivision slice, meta
  setTimeout @deferAdd.bind @, slice, source, meta
  return slice

GFX.BatchTexture::dropSource = (source)->
  return false unless slice = @bySource.get source
  return  true unless 0 is --slice.refCount
  true

# ██████  ███████ ██      ███████  ██████   █████  ████████ ███████ ███████
# ██   ██ ██      ██      ██      ██       ██   ██    ██    ██      ██
# ██   ██ █████   ██      █████   ██   ███ ███████    ██    █████   ███████
# ██   ██ ██      ██      ██      ██    ██ ██   ██    ██    ██           ██
# ██████  ███████ ███████ ███████  ██████  ██   ██    ██    ███████ ███████

GFX.SpriteBatch::getId = ->
  id = @freeId.shift() if 0 < @freeId.length
  id = @nextId++   unless id
  id

GFX.SpriteBatch::shrinkFreeIds = ->
  sorted = @freeId.sort reverseNumeric
  @nextId = sorted.reduce reduceDescending, @nextId
  @freeId = sorted.slice 1 + idx if -1 isnt idx = sorted.indexOf @nextId
reverseNumeric   = (a,b)-> b-a
reduceDescending = (c,v)-> if c - 1 is v then v else c

GFX.SpriteBatch::addDelegate = (delegate)->
  delegate.id = id = @getId(); id3 = delegate.id*3; id4 = delegate.id*4
  delegate.position = @positionArray.subarray id3, id3+3
  delegate.info     = @infoArray    .subarray id4, id4+4
  delegate.sliceId  = @sliceIdArray .subarray id,  id+1
  delegate.time     = @timeArray    .subarray id,  id+1
  delegate.position[0] = delegate.position[1] = 0
  delegate.position[2] = 2000
  delegate.info[0] = delegate.info[1] = delegate.info[2] = delegate.info[3] = 0
  if delegate.animated
    delegate.info[1] = delegate.reverse
    delegate.info[2] = 16.6
    delegate.info[3] = delegate.loop
    delegate.time[0] = NUU.time() - GFX.startTime
    @timeInterleaved.needsUpdate = true
  delegate.sliceId[0] = delegate.slice.id
  @sliceIdInterleaved.needsUpdate = true
  @positionInterleaved.needsUpdate = true
  @infoInterleaved.needsUpdate = true
  # @geometry.setDrawRange 0, 128 # ++@used

GFX.SpriteBatch::removeDelegate = (delegate)->
  return unless delegate.position
  @freeId.push delegate.id
  delegate.id = false
  delegate.position[2] = 2000

GFX.SpriteBatch::Sprite = (source,opts)->
  new GFX.Sprite @, source, opts

GFX.Delegate = (Type)-> Object.assign Type::,
  show:->
    # console.log 'show', @
    @slice = @batch.texture.addSource @source, @
    @batch.addDelegate @
  hide:->
    # console.log 'hide', @
    @batch.texture.dropSource @source
    @batch.removeDelegate @
  destroy:->
    @hide()
    return

GFX.Delegate class GFX.Sprite
  constructor:(@batch,@source,opts)->
    Object.assign @, opts
