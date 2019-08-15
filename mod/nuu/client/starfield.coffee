
# ███    ██ ███████ ██████  ██    ██ ██       █████
# ████   ██ ██      ██   ██ ██    ██ ██      ██   ██
# ██ ██  ██ █████   ██████  ██    ██ ██      ███████
# ██  ██ ██ ██      ██   ██ ██    ██ ██      ██   ██
# ██   ████ ███████ ██████   ██████  ███████ ██   ██

NUU.on 'rules', ->
  # Nebula.deterministic = new Deterministic rules.systemName + "-nebulae"
  # Nebula.random() for i in [0..2+max 1, Math.ceil Nebula.deterministic.double()*5]
  return

$public class Nebula
  @list: [ "02","16","21","25","29","33","04","17","22","26","30","34","10","19","23","27","31","12","20","24","28","32" ]
  @random:->
    idx = round Nebula.deterministic.double() * ( Nebula.list.length - 1 )
    img = Nebula.list[idx]
    n = PIXI.Sprite.from "build/gfx/nebula#{img}.png"
    n.position.set(
      Nebula.deterministic.double() * 4*GFX.width  - 2*GFX.width
      Nebula.deterministic.double() * 4*GFX.height - 2*GFX.height )
    GFX.nebulae.addChild n

# ███████ ████████  █████  ██████  ███████ ██ ███████ ██      ██████
# ██         ██    ██   ██ ██   ██ ██      ██ ██      ██      ██   ██
# ███████    ██    ███████ ██████  █████   ██ █████   ██      ██   ██
#      ██    ██    ██   ██ ██   ██ ██      ██ ██      ██      ██   ██
# ███████    ██    ██   ██ ██   ██ ██      ██ ███████ ███████ ██████

$public class GFX.StarfieldLayer
  count:1000
  constructor:->
    VEHICLE.v = [random(),random()]
    @geometry  = new THREE.Geometry
    i = 0
    while i++ < @count
      @geometry.vertices.push new THREE.Vector3(0,0,0)
    map = GFX.loader.load 'build/gfx/moon-D02.png'
    # material = new THREE.PointsMaterial transparent:true, alphaTest:0.1, size:1.5
    # GFX.debugShader 'FRAGMENT_SHADER', GFX.StarfieldLayer.fragment
    # GFX.debugShader 'VERTEX_SHADER',   GFX.StarfieldLayer.vertex
    @material = new THREE.ShaderMaterial
      precision:'highp'
      transparent: true
      depthWrite: false
      uniforms:
        uScreen: value: [GFX.width,GFX.height]
        uOffset: value: [0,0]
        uMap:    value: map
      fragmentShader: GFX.StarfieldLayer.fragment
      vertexShader:   GFX.StarfieldLayer.vertex
      blending:       THREE.AdditiveBlending
      # transformFeedbackVaryings: outPosition: 'position'
    @particles = new THREE.Points @geometry, @material
    @particles.for = 'starfield'
    @randomize()
    GFX.scene.add @particles
    GFX.children.push @
    GFX.on 'resize', @randomize.bind(@)
    @lastUpdate = performance.now()
  randomize:->
    { width,height,wdb2,hgb2 } = GFX
    return if @lastWidth is width and @lastHeight is height
    @lastWidth = width; @lastHeight = height
    pos = @geometry.vertices; i = 0
    while i < @count
      p = pos[i]
      p.z = random()
      p.x = -wdb2 + width *Math.random()
      p.y = -wdb2 + height*Math.random()
      i++
    @material.uniforms.uScreen.value = [width,height]
    @geometry.verticesNeedUpdate = true
    @lastUpdate = performance.now()
    return
  update:(time=performance.now())->
    [vx,vy]  = VEHICLE.v
    svx = svy = 0
    m = min 0.2, mag = Math.sqrt vx*vx + vy*vy
    if m isnt 0
      svx = vx / mag * m
      svy = vy / mag * m
    uniforms = @material.uniforms
    dt = time - @lastUpdate
    uniforms.uOffset.value[0] += -svx * dt
    uniforms.uOffset.value[1] +=  svy * dt
    @material.needsUpdate = true
    @lastUpdate = time
    return

GFX.StarfieldLayer.vertex = """
uniform highp vec2 uScreen;
uniform highp vec2 uOffset;
varying float vAlpha;
void main() {
  vAlpha = (position.z + abs(sin(position.x + position.y))) / 4.;
	highp vec3 newPosition = vec3(
    -uScreen.x/2. + mod(position.x + uOffset.x *vAlpha,uScreen.x),
    -uScreen.y/2. + mod(position.y + uOffset.y *vAlpha,uScreen.y),
    position.z );
	gl_Position = projectionMatrix * modelViewMatrix * vec4( newPosition, 1.0 );
  gl_PointSize = 3.5 + abs(sin(position.x))*position.z; }
"""

GFX.StarfieldLayer.fragment = """
uniform sampler2D uMap;
varying float vAlpha;
void main() {
	vec4 tex = texture2D( uMap, gl_PointCoord );
	gl_FragColor = vec4( 1., 1., 1., tex.a * vAlpha * .2 ); }
"""
