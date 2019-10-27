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

# ███████  ██████  █████  ███    ██ ███    ██ ███████ ██████
# ██      ██      ██   ██ ████   ██ ████   ██ ██      ██   ██
# ███████ ██      ███████ ██ ██  ██ ██ ██  ██ █████   ██████
#      ██ ██      ██   ██ ██  ██ ██ ██  ██ ██ ██      ██   ██
# ███████  ██████ ██   ██ ██   ████ ██   ████ ███████ ██   ██

$obj.symbol = [
  '🌑','🌍','⚫','🞄','⯁','◆','🌒','⧫','▲','⚑','⛏','⛊','⚡','🕱','🍽','❖','🅰','⯌','🞉','◐','⬢','䷡','🏘','⚒','💰','🏭' ]

$obj.color  = [
  0xFFFFFF,0xCCCCCC,0xFFAA22,0x2222FF,0xFFFF00,0x66FF00,0x00FFFF,0xFF00FF,0xAA22FF,0xFF0000 ]

$obj::scannerId = -1
$obj::scannerTint = 0
$obj::scannerLayer = 1
$obj::scannerSymbol = '◆'

Stellar::  scannerTint = 1; Stellar::  scannerLayer =  2; Stellar::  scannerSymbol = '◆'
Asteroid:: scannerTint = 1; Asteroid:: scannerLayer =  3; Asteroid:: scannerSymbol = '⯁'
Debris::   scannerTint = 2; Debris::   scannerLayer =  4; Debris::   scannerSymbol = '❖'
Cargo::    scannerTint = 3; Cargo::    scannerLayer =  5; Cargo::    scannerSymbol = '🅰'
Star::     scannerTint = 4; Star::     scannerLayer = 10; Star::     scannerSymbol = '⯌'
Planet::   scannerTint = 5; Planet::   scannerLayer =  9; Planet::   scannerSymbol = '🞉'
Moon::     scannerTint = 6; Moon::     scannerLayer =  8; Moon::     scannerSymbol = '◐'
Station::  scannerTint = 7; Station::  scannerLayer =  7; Station::  scannerSymbol = '⬢'
Ship::     scannerTint = 8; Ship::     scannerLayer =  6; Ship::     scannerSymbol = '▲'

#  ██████  ██████  ███    ██ ████████ ██████   ██████  ██
# ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██
# ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██
# ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██
#  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████


$public class ScannerControl
  scale: 16
  point: 30
  width: 200
  active: yes
  orbits: yes
  fullscreen: no

  constructor:-> NUU.once 'start', =>
    @$  = new GFX.ScannerLayer
    # @$.texture.debug.position.x += 128
    NUU.on '$obj:add',    @$.addObjects.bind @$
    NUU.on '$obj:del',    @$.delObjects.bind @$
    NUU.on 'target:new',  @$.selTarget .bind @$
    NUU.on 'target:lost', @$.delTarget .bind @$
    GFX.on 'resize',      @resize
    @resize()
    return

  zoomIn:=>  @scale = max 1,         @scale/1.2; @$.update true
  zoomOut:=> @scale = min 134217728, @scale*1.2; @$.update true

  toggle:=>
    @active = not @active
    if @active then GFX.scene.add @$.particles
    else GFX.scene.remove @$.particles
    GFX.resize true
    return

  toggleFullscreen:=>
    @fullscreen = not @fullscreen
    @toggle()  if not @active
    GFX.resize true
    return

  resize:(w=GFX.width,h=GFX.height,w2=w/2,h2=h/2)=>
    document.body.classList[if @active     then 'remove' else 'add'] 'scanner-off'
    document.body.classList[if @fullscreen then 'add' else 'remove'] 'scanner-full'
    if @fullscreen
         @point = 30; W = min(w,h)-20; W2 = W/2; @oy = 0
    else @point = 15; W = 200; W2 = W/2; @oy = -h2 + W2 + 25
    @width = W; @radius = W2
    @$.update()

$static 'Scanner', new ScannerControl

# ██   ██ ███████ ██████   ██████   █████  ██████  ██████
# ██  ██  ██      ██   ██ ██    ██ ██   ██ ██   ██ ██   ██
# █████   █████   ██████  ██    ██ ███████ ██████  ██   ██
# ██  ██  ██      ██   ██ ██    ██ ██   ██ ██   ██ ██   ██
# ██   ██ ███████ ██████   ██████  ██   ██ ██   ██ ██████

Kbd.macro 'scanToggleFS', 'aEnter',  'Toggle Scanner FS',  Scanner.toggleFullscreen
Kbd.macro 'scanToggle',   'Enter',   'Toggle Scanner',     Scanner.toggle
Kbd.macro 'scanPlus',     'Equal',   'Zoom scanner in',    Scanner.zoomIn
Kbd.macro 'scanMinus',    'Minus',   'Zoom scanner out',   Scanner.zoomOut

# ██       █████  ██    ██ ███████ ██████
# ██      ██   ██  ██  ██  ██      ██   ██
# ██      ███████   ████   █████   ██████
# ██      ██   ██    ██    ██      ██   ██
# ███████ ██   ██    ██    ███████ ██   ██

$public class GFX.ScannerLayer extends GFX.SpriteBatch
  constructor:->
    super()
    @labelMap = new Map
    @texture = new GFX.BatchTexture 512, 512
    @makeTextures()
    $obj.byClass.forEach (obj)->
      obj::scannerSymbol = $obj.symbol.indexOf s if isNaN s = obj::scannerSymbol
    colors = $obj.color.reduce ( (b,c)->
      b.concat [(c>>16&0xFF)/255,(c>>8&0xFF)/255,(c&0xFF)/255] ), []
    @initialize
      attributes:
        position: type:Float32Array, count:3, init:[0,0,2000]
        velocity: type:Float32Array, count:4, init:0
        time:     type:Float32Array, count:1, init:0
        info:     type:Uint8Array,   count:4, init:0
        uid:      type:Uint16Array,  count:1, init:'$id'
        sliceId:  type:Uint16Array,  count:1, init:0xFFFF # GFX.BatchTexture.MAX_SLICES
      uniforms:
        uColor:     value: colors
        uTime:      value: NUU.time()
        uScreen:    value: [GFX.width,GFX.height]
        uUser:      value: [0,0]
        debug:      value: 0
        uScale:     value: 1
        uRadius:    value: 200
        uPointSize: value: 30
        uGlobalY:   value: 0
        uMap:       value: @map
        uMapSize:   value: @mapSize
        uIconCols:  value: @mapCols
        uIconSize:  value: @mapIcon
        uSliceMap:  value: @texture
        uSlicePos:  value: @texture.slicePositionTexture
        uSliceDiv:  value: @texture.sliceDivisionTexture
        uSliceDim:  value: [@texture.width,@texture.height]
    return

# ██████  ███████ ██      ███████  ██████   █████  ████████ ███████
# ██   ██ ██      ██      ██      ██       ██   ██    ██    ██
# ██   ██ █████   ██      █████   ██   ███ ███████    ██    █████
# ██   ██ ██      ██      ██      ██    ██ ██   ██    ██    ██
# ██████  ███████ ███████ ███████  ██████  ██   ██    ██    ███████

class GFX.ScannerDelegate
  id:       null
  uid:      null
  info:     null
  label:    null
  position: null
  velocity: null
  constructor:(@batch)->
    @id = @batch.getId()
    id3 = @id*3; id4 = @id*4
    @uid      = @batch.uidArray     .subarray @id, @id+1
    @info     = @batch.infoArray    .subarray id4, id4+4
    @label    = @batch.sliceIdArray .subarray @id, @id+1
    @position = @batch.positionArray.subarray id3, id3+3
    @velocity = @batch.velocityArray.subarray id4, id4+4
  swap:(source)->
    source.info    .set @info
    source.label   .set @label
    source.position.set @position
    source.velocity.set @velocity
    @position[2] = 2000; @label[0] = 0xFFFF
    @info[0] = @info[1] = @info[2] = @info[3] = 0
    @velocity[0] = @velocity[1] = @velocity[2] = @velocity[3] = @position[0] = @position[1] = 0
    @batch.texture.dropSource source.source
    @batch.removeDelegate @
    Object.assign @, source
    return

GFX.SpriteBatch::Text = (source,opts)->
  new GFX.Text @, source, opts

GFX.Delegate class GFX.Text
  cnv: cnv = new OffscreenCanvas 128, 16
  ctx: cnv.getContext '2d'
  constructor:(@batch,@text,opts={})->
    @id = @batch.getId()
    Object.assign @, opts
    @style = Object.assign (
      font:         'bold 12px Lato'
      fillStyle:    'white'
      strokeStyle:  'black'
      textBaseline: 'top'
      lineJoin:     'miter'
      miterLimit:   2
      lineWidth:    3
    ), @style || {}
    id4 = @id * 4
    @velocity = @batch.velocityArray.subarray id4, id4+4
    @update()
    @show()
  update:->
    Object.assign @ctx, @style
    @ctx.clearRect 0,0,128,16
    @ctx.strokeText @text,3,3
    @ctx.fillText   @text,3,3
    dim = @ctx.measureText @text
    @h = 16; @w = ceil dim.width + 3
    @source = new THREE.DataTexture (@ctx.getImageData 0,0,@w,@h), @w,@h,THREE.RGBAFormat
    @source.needsUpdate = yes
    @slice = @batch.texture.addSource @source, width:@w,height:@h,cols:1,rows:1
  set:(@text,style)->
    @batch.texture.dropSource @source
    @style = Object.assign @style, style if style
    @update()
  swap:(source)->
    source.info    .set @info
    source.label   .set @label
    source.position.set @position
    source.velocity.set @velocity
    @position[2] = 2000; @sliceId[0] = 0xFFFF
    @info[0] = @info[1] = @info[2] = @info[3] = 0
    @velocity[0] = @velocity[1] = @velocity[2] = @velocity[3] = @position[0] = @position[1] = 0
    @batch.texture.dropSource source.source
    @batch.removeDelegate @
    Object.assign @, source
    return

# ██  ██████  ██████  ███    ██ ███████
# ██ ██      ██    ██ ████   ██ ██
# ██ ██      ██    ██ ██ ██  ██ ███████
# ██ ██      ██    ██ ██  ██ ██      ██
# ██  ██████  ██████  ██   ████ ███████

GFX.ScannerLayer::makeTextures = ->
  fs = 15; @mapIcon = ic = 28; ih = ic / 2
  spriteRow    = TAU / 6
  spriteAngle  = TAU / 36
  symbols      = $obj.symbol
  symbolCount  = symbols.length
  @mapSize = THREE.Math.ceilPowerOfTwo ic * ceil sqrt symbolCount
  @mapCols = floor @mapSize / ic
  # cnv = document.createElement 'canvas'; cnv.width = cnv.height = @mapSize; document.body.append cnv; g = cnv.getContext '2d'
  # tmp = document.createElement 'canvas'; tmp.width = tmp.height = @mapSize; document.body.append tmp; t = tmp.getContext '2d'
  tmp = new OffscreenCanvas ic*10, ic*10; t = tmp.getContext '2d'
  cnv = new OffscreenCanvas @mapSize, @mapSize; g = cnv.getContext '2d'
  t.font         = g.font         = "#{fs}px monospace";
  t.fillStyle    = g.fillStyle    = 'white'
  t.textBaseline = g.textBaseline = 'top'
  t.fontWeight   = g.fontWeight   = 'bold'
  g.fillStyle = 'white'
  snum = 0; bg = 0
  for k,v of symbols
    sx =       snum % @mapCols
    sy = floor snum / @mapCols
    t.clearRect 0,0,fs*10,fs*10
    t.fillText  v, ic/2, ic/2
    d = GFX.getBoundingBox t,0,0,fs*10,fs*10
    g.translate sx*ic+ic/2-d.width/2, sy*ic+ic/2-(d.top-ic/2+d.height/2)-1
    g.fillText v, 0, 0
    g.resetTransform()
    snum++
  @map = new THREE.CanvasTexture cnv
  @map.premultiplyAlpha = yes
  @map.transparent = yes
  @map.needsUpdate = yes
  @map

# ██    ██ ██████  ██████   █████  ████████ ███████
# ██    ██ ██   ██ ██   ██ ██   ██    ██    ██
# ██    ██ ██████  ██   ██ ███████    ██    █████
# ██    ██ ██      ██   ██ ██   ██    ██    ██
#  ██████  ██      ██████  ██   ██    ██    ███████

GFX.ScannerLayer::update = ->
  return unless VEHICLE.updateScanner
  # { width,height,wdb2,hgb2 } = GFX
  { x,y } = VEHICLE
  uniforms = @material.uniforms
  uniforms.uScale.value  = sc = Scanner.scale
  uniforms.uRadius.value = rd = Scanner.radius
  uniforms.uGlobalY.value = Scanner.oy
  uniforms.uPointSize.value = Scanner.point
  uniforms.uUser.value[0] = x
  uniforms.uUser.value[1] = y
  uniforms.uTime.value = -GFX.startTime + time = NUU.time()
  # $obj.scope.visible.forEach (s)-> s.updateShortrange time,x,y,3
  TARGET .updateShortrange time,x,y,2 if TARGET
  VEHICLE.updateShortrange time,x,y,1
  @positionInterleaved.needsUpdate = true
  @velocityInterleaved.needsUpdate = true
  @infoInterleaved    .needsUpdate = true
  return

DEG2BYTE = 255/360

$obj::updateScanner = (time,x,y,type)->
  @update time; return unless s = @scanner
  s.position[0] = @x
  s.position[1] = @y
  s.velocity[0] = @v[0]
  s.velocity[1] = @v[1]
  s.velocity[2] = @a || 0
  s.velocity[3] = time - GFX.startTime
  s.info[2]     = @d * DEG2BYTE
  s.info[3]     = 0
  return

$obj::updateScannerLabel = (time,x,y,type)->
  @update time; return unless ( s = @scanner ) and ( l = @label )
  l.position[0] = s.position[0] = @x
  l.position[1] = s.position[1] = @y
  l.velocity[0] = s.velocity[0] = @v[0]
  l.velocity[1] = s.velocity[1] = @v[1]
  l.velocity[2] = s.velocity[2] = @a || 0
  l.velocity[3] = s.velocity[3] = time - GFX.startTime
  l.info[2]     = s.info[2]     = @d * DEG2BYTE
  l.info[3]     = s.info[3]     = 0
  return

$obj::updateShortrange = (time,x,y,type)->
  @update time; return unless s = @scanner
  rd = Scanner.radius
  sc = Scanner.scale
  dx = @x-x
  dy = @y-y
  mag = sqrt dx**2 + dy**2
  sx = dx/mag * scl = min rd, mag/sc
  sy = dy/mag * scl
  s.position[0] = sx
  s.position[1] = sy
  s.velocity[0] = @v[0]
  s.velocity[1] = @v[1]
  s.velocity[2] = @a || 0
  s.velocity[3] = time - GFX.startTime
  s.info[2]     = @d * DEG2BYTE
  s.info[3]     = type
  return

$obj::updateShortrangeLabel = (time,x,y,type)->
  @update time; return unless ( s = @scanner ) and ( l = @label )
  rd = Scanner.radius
  sc = Scanner.scale
  dx = @x-x
  dy = @y-y
  mag = sqrt dx**2 + dy**2
  sx = dx/mag * scl = min rd, mag/sc
  sy = dy/mag * scl
  l.position[0] = s.position[0] = sx
  l.position[1] = s.position[1] = sy
  l.velocity[0] = s.velocity[0] = @v[0]
  l.velocity[1] = s.velocity[1] = @v[1]
  l.velocity[2] = s.velocity[2] = @a || 0
  l.velocity[3] = s.velocity[3] = time - GFX.startTime
  l.info[2]     = s.info[2]     = @d * DEG2BYTE
  l.info[3]     = s.info[3]     = type
  return

# ██      ██ ███████ ███████  ██████ ██    ██  ██████ ██      ███████
# ██      ██ ██      ██      ██       ██  ██  ██      ██      ██
# ██      ██ █████   █████   ██        ████   ██      ██      █████
# ██      ██ ██      ██      ██         ██    ██      ██      ██
# ███████ ██ ██      ███████  ██████    ██     ██████ ███████ ███████

# Fun fact: I never used this pattern in pubcode,
#   in the 2 decades that I've known it.

GFX.ScannerLayer::orderedObjects = []
GFX.ScannerLayer::orderedLabels  = []

GFX.ScannerLayer::addObjects = (list)->
  for o in list
    o.scanner = s = new GFX.ScannerDelegate @
    s.position[2] = 50 + o.scannerLayer  || 1
    s.info[0]     = o.scannerTint   || 0
    s.info[1]     = o.scannerSymbol || 0
  @orderedObjects = @orderedObjects.concat list
  @updateLabels()
  @geometry.computeBoundingSphere()
  return

GFX.ScannerLayer::updateLabels = (obj=TARGET)->
  labels = []; labelDiff = []
  labels.push = obj if obj
  labels = labels.concat Stellar.list.filter (s)-> s.bigMass is true
  for o,i in labels
    text = o.name || o.constructor.name + '-' + o.id
    continue if ( l = o.label )?.text is text
    labelDiff.push o
    o.label = l = @Text text, o:o, style:{}
    l.position[2] = 50 + o.scannerLayer  || 1
    @labelMap.set o, l
    o.updateScanner    = $obj::updateScannerLabel
    o.updateShortrange = $obj::updateShortrangeLabel
  @orderedLabels = @orderedLabels.concat labelDiff
  labelDiff = []
  @labelMap.forEach (label,o)-> labelDiff.push o if -1 is labels.indexOf o
  @delLables labelDiff
  return

GFX.ScannerLayer::delObjects = (listIds,list)->
  swapped = 0
  labelDiff = []
  length = @orderedObjects.length; count = list.length
  pop = @orderedObjects.slice(length-count*2).reverse()
  g = list[0]
  while count > 0
    o = pop.shift()
    continue unless -1 is list.indexOf o
    d = list.shift()
    o.scanner.swap d.scanner
    d.scanner = false
    labelDiff.push d if d.label
    @orderedObjects[@orderedObjects.indexOf d] = o
    count--
    swapped++
  @orderedObjects.splice @orderedObjects.length - swapped
  @delLables labelDiff

GFX.ScannerLayer::delLables = (list)->
  swapped = 0
  length = @orderedLabels.length; count = list.length
  pop = @orderedLabels.slice(length-count*2).reverse()
  while count > 0
    o = pop.shift()
    continue unless -1 is list.indexOf o
    d = list.shift()
    l = o.label
    o.label.swap d.label
    d.label = false
    d.updateScanner    = $obj::updateScanner
    d.updateShortrange = $obj::updateShortrange
    @labelMap.delete o
    @orderedLabels[@orderedLabels.indexOf d] = o
    count--
    swapped++
  @orderedLabels.splice @orderedLabels.length - swapped
  return

GFX.ScannerLayer::selTarget = (obj,old)->
  obj.scanner.info[0] = 9 if obj
  old.scanner.info[0] = old.scannerTint if old
  @updateLabels obj
  return

GFX.ScannerLayer::delTarget = (old)->
  @selTarget null, old
  return

# ██    ██ ███████ ██████  ████████ ███████ ██   ██
# ██    ██ ██      ██   ██    ██    ██       ██ ██
# ██    ██ █████   ██████     ██    █████     ███
#  ██  ██  ██      ██   ██    ██    ██       ██ ██
#   ████   ███████ ██   ██    ██    ███████ ██   ██

GFX.ScannerLayer.vertex = """
attribute float id, sliceId;
attribute vec4 info, velocity;

uniform float uTime, uScale, uPointSize, uRadius, uGlobalY, uMapSize, uIconSize, uIconCols, debug;
uniform  vec2 uUser;
uniform  vec3 uColor[10];

uniform sampler2D uSliceMap;
uniform sampler2D uSliceDiv;
uniform sampler2D uSlicePos;
uniform vec2      uSliceDim;

varying float vAlpha, vDist, vLabel;
varying  vec2 vIconSize, vOffset;
varying  mat2 vRotation;
varying  vec3 vColor;
varying  vec4 vfIcon, vfLabel, vLabelSize;

const   float DPX      = 1./255.;
const   float TAU      = 6.283185307179586;
const   float PI       = TAU/2.;
const   float PIb2     = TAU/4.;
const   float BYTE2RAD = TAU/255.;

void main() {
  float v, z, dt = uTime - velocity.w;

  if ( position.z == 2000. ){ gl_Position = vec4(position,0.); return; }

  // READ TINT
  v = info.x;  z = position.z; vAlpha = 0.5;

  // MARK TARGET / HOSTILES
  if ( v ==  9. ) { z =  100.; vAlpha = 1.0; }
  if ( v == 99. ) { z = 2000.; }
  vColor = uColor[int(v)];

  // READ ICON - CALCULATE ATLAS POSITION
  v = info.y;
  vIconSize = vec2( 1./uMapSize*uIconSize, 1./uMapSize*uIconSize );
  vOffset   = vec2( mod(v,uIconCols), -floor(v/uIconCols) ) * vIconSize;

  // READ ROTATION - PREPARE MATRIX
  v = TAU - mod(info.z*BYTE2RAD+PIb2,TAU);
  vRotation = mat2( cos(v),sin(v), -sin(v),cos(v) );

  // CALCULATE POSITION
  vec2 dp,sp; float mg, sl;
  // SHORTRANGE DIRECT POSITIONING
       if ( info.w == 1. ){ sp = vec2(0.,0.); }
  else if ( info.w  > 1. ){ sp = vec2(position.x,-position.y); }
  // LONGRANGE GPU-APPROXIMATION
  else {
    dp = position.xy + dt * vec2(velocity.x,velocity.y) - uUser;
    mg = length(dp);
    sl = min(uRadius,mg/uScale);
    sp = dp*sl/mg;
    sp.y = -sp.y ; }

  // CULL ASTEROIDS
  if (( info.y == 4. )&&( info.x != 99. )){
    if ( sl == uRadius ){ z = 2000.; } }

  // ADD HUD-OFFSET
  sp.y += uGlobalY;

  // RENDER ICON
  if ( sliceId == 65535. ){
    vLabel = 65535.;
    gl_Position = projectionMatrix * modelViewMatrix * vec4( sp, z, 1.0 );
    gl_PointSize = uPointSize;
    return;
  }

  // RENDER LABEL
  vec2 subDimensions, aspect, crop; vec4 dm;
  vLabel = sliceId;
  vLabelSize = texture2D( uSlicePos, vec2( DPX * (mod(sliceId,255.)+.5), DPX * -(sliceId/255. +.5) ));
          dm = texture2D( uSliceDiv, vec2( DPX * (mod(sliceId,255.)+.5), DPX * -(sliceId/255. +.5) ));
  aspect = vLabelSize.ba * uSliceDim;
  crop   = vec2(1.,1.); if ( aspect.x > aspect.y ){ crop = vec2(0.,aspect.y/aspect.x); }
  subDimensions = vLabelSize.ba * dm.rg;
  subDimensions.y = subDimensions.y / crop.y; // non-square

  vLabelSize = vec4( vLabelSize.rg, subDimensions );
  vec2 sz = uSliceDim * vLabelSize.ba;
  vfLabel = vec4(0.);
  vfLabel.x = max(sz.x,sz.y);
  vfLabel.y = min(sz.x,sz.y);
  vfLabel.z = vfLabel.y/vfLabel.x;
  vfLabel.w = (1.-(aspect.y/aspect.x))/2.;
  gl_PointSize = max(sz.x,sz.y);

  if (sp.x > 0.){ sp.x -= gl_PointSize/2. + uPointSize/4. + 1.; }
  else {          sp.x += gl_PointSize/2. + uPointSize/4. + 1.; }
  sp.y += uPointSize/6.;
  gl_Position = projectionMatrix * modelViewMatrix * vec4( sp, z, 1.0 ); }
"""

# ███████ ██████   █████   ██████  ███    ███ ███████ ███    ██ ████████
# ██      ██   ██ ██   ██ ██       ████  ████ ██      ████   ██    ██
# █████   ██████  ███████ ██   ███ ██ ████ ██ █████   ██ ██  ██    ██
# ██      ██   ██ ██   ██ ██    ██ ██  ██  ██ ██      ██  ██ ██    ██
# ██      ██   ██ ██   ██  ██████  ██      ██ ███████ ██   ████    ██

GFX.ScannerLayer.fragment = """
uniform sampler2D uMap;
uniform sampler2D uSliceMap;
uniform sampler2D uSliceDiv;
uniform sampler2D uSlicePos;
uniform vec2      uSliceDim;
uniform float debug;

varying float vAlpha, vDist, vLabel;
varying  vec2 vIconSize, vOffset;
varying  mat2 vRotation;
varying  vec3 vColor;
varying  vec4 vfIcon, vfLabel, vLabelSize;

const vec2 mid = vec2(0.5, 0.5);

void renderIcon(vec2 p){
  vec2 txo = vec2(.5/128.,.5/128.);
  vec2 pro = vRotation * (p - mid) + mid;
  vec2 ptr = vec2( pro.x*vIconSize.x, 1. - pro.y*vIconSize.y ) + vOffset;
  vec4 tex = texture2D( uMap, ptr + txo );
  if ( tex.a < 0.001 ) discard;
  gl_FragColor = vec4( vColor, tex.a * vAlpha ); }

void renderLabel(vec2 p){
  if ( p.y <     vfLabel.w ) discard;
  if ( p.y > 1.- vfLabel.w ) discard;
  p.y = ( p.y - vfLabel.w ) * vfLabel.z;
  vec2 txo = vec2(.5/uSliceDim.x,.5/uSliceDim.y);
  vec4 tex = texture2D( uSliceMap, p * vLabelSize.ba + vLabelSize.rg + txo );
  if ( tex.a < 0.001 ) discard;
  gl_FragColor = vec4(tex.rgb, 0.5); }

void main() {
  if ( vLabel == 65535. ) { renderIcon(gl_PointCoord); return; }
  renderLabel(gl_PointCoord); }
"""
