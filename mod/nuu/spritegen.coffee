window.RENDERER = RENDERER = window.SCENE = SCENE = window.CAMERA = CAMERA = null
window.RENDER_NAME = RENDER_NAME = 'ohnoes'; window.SEED = SEED = 0
window.MESHES = MESHES = []
window.CREATE = CREATE = {}
window.SHADER = SHADER = {}
window.INIT_QUEUE = INIT_QUEUE = 0
window.DEBUG = DEBUG = no

RENDER_QUEUE = [
  [ 'GasGiant', Math.random().toFixed(9) ]
  [ 'Sun',      Math.random().toFixed(9) ]
  [ 'Planet',   Math.random().toFixed(9) , 'Earth' ]
  [ 'Planet',   Math.random().toFixed(9) , 'Mars' ]
  [ 'Asteroid', Math.random().toFixed(9) ]
  [ 'Asteroid', Math.random().toFixed(9) ]
  [ 'Asteroid', Math.random().toFixed(9) ]
  [ 'Asteroid', Math.random().toFixed(9) ]
  [ 'Asteroid', Math.random().toFixed(9) ]
  [ 'Asteroid', Math.random().toFixed(9) ]
  [ 'Asteroid', Math.random().toFixed(9) ] ]

# RENDER_QUEUE = [
#   [ 'Planet', 'Earth' ] ]

ON_RENDER = []

CREATE.Asteroid = (seed)->
  RENDER_NAME = 'asteroid'; SEED = seed
  size = .1
  uniforms =
    star_spectrum: type: "t", value: star_spectrum
    seed:          type: "f", value: seed
    temperature:   type: "f", value: 4300.0
    time:          type: "f", value: time = Date.now()
    light:         type: "f", value: [Math.sin(time), 0.5, 0.5]
  geometry = new THREE.SphereGeometry( size, 32, 32, 1 )
  material = new (THREE.ShaderMaterial)(
    uniforms: uniforms
    vertexShader: SHADER['vsAsteroid']
    fragmentShader: SHADER['fsAsteroid'])
  roid = new (THREE.Mesh)(geometry, material)
  ON_RENDER.push (delta, now) ->
    uniforms.time.value = now
    roid.rotateY 1 / 2 * delta
    #uniforms.light.value[0] = Math.sin(Date.now()/1000)
  [roid]

CREATE.Planet = (seed,biome='Earth')->
  RENDER_NAME = 'planet_' + biome.toLowerCase(); SEED = seed
  size = .3
  uniforms =
    star_spectrum: type: "t", value: star_spectrum
    seed:          type: "f", value: seed
    temperature:   type: "f", value: 4300.0
    time:          type: "f", value: time = Date.now()
    light:         type: "f", value: [Math.sin(time), 0.5, 0.5]
  geometry = new THREE.SphereGeometry( size, 32, 32, 1 )
  material = new (THREE.ShaderMaterial)(
    uniforms: uniforms
    vertexShader: SHADER['vsPlanet']
    fragmentShader: SHADER['fs'+biome])
  planet = new (THREE.Mesh)(geometry, material)
  geometry = new THREE.PlaneGeometry( size * 2, size * 2, 1,1 )
  material = new (THREE.ShaderMaterial)(
    transparent: true
    uniforms: uniforms
    vertexShader: SHADER['vsPlanet']
    fragmentShader: SHADER['fsAtmosphere'])
  atmosphere = new (THREE.Mesh)(geometry, material)
  atmosphere.translateZ size
  atmosphere.lookAt CAMERA.position
  ON_RENDER.push (delta, now) ->
    uniforms.time.value = now
    planet.rotateY 1 / 2 * delta
    #uniforms.light.value[0] = Math.sin(Date.now()/1000)
  [planet,atmosphere]

CREATE.GasGiant = (seed) ->
  RENDER_NAME = 'gas_giant'; SEED = seed
  size = .4
  uniforms =
    star_spectrum: type: "t", value: star_spectrum
    seed:          type: "f", value: Math.random()
    temperature:   type: "f", value: 4300.0
    time:          type: "f", value: time = Date.now()
    light:         type: "f", value: [Math.sin(time), 0.5, 0.5]
  geometry   = new THREE.SphereGeometry size, 32, 32, 1
  material   = new THREE.ShaderMaterial uniforms: uniforms, vertexShader: SHADER['vsPlanet'], fragmentShader: SHADER['fsGasGiant']
  planet     = new THREE.Mesh geometry, material
  geometry   = new THREE.PlaneGeometry size * 2, size * 2, 1,1
  material   = new THREE.ShaderMaterial transparent: true, uniforms: uniforms, vertexShader: SHADER['vsPlanet'], fragmentShader: SHADER['fsAtmosphere']
  atmosphere = new THREE.Mesh geometry, material
  atmosphere.translateZ size
  atmosphere.lookAt CAMERA.position
  ON_RENDER.push (delta, now) ->
    uniforms.time.value = now
    planet.rotateY 1 / 2 * delta
    #uniforms.light.value[0] = Math.sin(Date.now()/1000)
  [planet,atmosphere]

CREATE.Sun = (seed) ->
  RENDER_NAME = 'sun'; SEED = seed
  size = .4
  temperature = 800.0 + Math.random() * 29200.0
  color = [
    temperature * ( 0.0534 / 255.0 ) - ( 43.0  / 255.0 )
    temperature * ( 0.0628 / 255.0 ) - ( 77.0  / 255.0 )
    temperature * ( 0.0735 / 255.0 ) - ( 115.0 / 255.0 )
    1.0 ]
  uniforms =
    star_spectrum: type: "t", value: window.star_spectrum.image
    seed:          type: "f", value: seed = Math.random()
    temperature:   type: "4f", value: color
    time:          type: "f", value: time = Date.now()
    light:         type: "f", value: [Math.sin(time), 0.5, 0.5]
  console.log 'temp', color
  console.log 'temp', ( (temperature - 80.0) / 3000.0 )
  console.log 'ss', star_spectrum
  geometry = new THREE.SphereGeometry size, 32, 32, 1
  material = new THREE.ShaderMaterial uniforms: uniforms, vertexShader: SHADER['vsPlanet'], fragmentShader: SHADER['fsSun']
  sun      = new THREE.Mesh           geometry, material
  geometry = new THREE.PlaneGeometry  size * 4, size * 4, 1,1
  material = new THREE.ShaderMaterial transparent: true, uniforms: uniforms, vertexShader: SHADER['vsPlanet'], fragmentShader: SHADER['fsSunCorona']
  corona   = new THREE.Mesh           geometry, material
  corona.translateZ size
  ON_RENDER.push (delta, now) ->
    uniforms.time.value = now
    # uniforms.light.value[0] = Math.sin(Date.now())
    sun.rotateY 1 / 2 * delta
    corona.lookAt CAMERA.position
  [sun,corona]

quit = ->
  x = new XMLHttpRequest
  x.open('GET','/quit')
  x.send()

saveImage = (name,blob,callback)->
  x = new XMLHttpRequest
  x.open 'POST', '/upload/'+encodeURIComponent(name), true
  x.setRequestHeader 'Content-Type', 'image/png'
  x.onload = callback
  x.send blob

console.debug = (args...)->
  document.getElementById('debug').innerHTML += '\n' + args.join ' '

window.render = renderNext = ->
  DEBUG = on; setTimeout ( -> DEBUG = no ), 2000
  ON_RENDER = [ -> RENDERER.render SCENE, CAMERA ]
  MESHES.map (m)-> SCENE.children.map (sc)-> SCENE.remove sc if sc is m
  return do quit unless c = RENDER_QUEUE.shift()
  RENDER_TYPE = c.shift()
  console.debug 'render', RENDER_TYPE, c.join ' '
  MESHES = CREATE[RENDER_TYPE].apply null, c
  MESHES.map (m)-> SCENE.add m
  setTimeout ( -> requestAnimationFrame renderImage ), 0

renderImage = (nowMsec) ->
  # measure time
  lastTimeMsec = lastTimeMsec or nowMsec - 1000 / 60
  deltaMsec    = Math.min 200, nowMsec - lastTimeMsec
  lastTimeMsec = nowMsec

  # call each update function
  ON_RENDER.forEach (fnc) ->
    fnc deltaMsec / 1000, nowMsec / 1000
    return

  return requestAnimationFrame renderImage if DEBUG

  # save the result
  RENDERER.domElement.toBlob (blob)->
    saveImage ( RENDER_NAME + "_" + SEED.replace(/[01]\./,'') + '.png' ), blob, renderNext
    return

  return

RENDERER = new (THREE.WebGLRenderer)(antialias: true, alpha:true, preserveDrawingBuffer: true)
RENDERER.setSize window.innerWidth, window.innerHeight
document.body.appendChild RENDERER.domElement
SCENE = new (THREE.Scene)
CAMERA = new (THREE.PerspectiveCamera)(45, window.innerWidth / window.innerHeight, 0.01, 1000)
CAMERA.position.z = 1.5
lastTimeMsec = null

light = new (THREE.DirectionalLight)(0xcccccc, 1)
light.position.set 5, 3, 5
SCENE.add light

get_shader = (k,url)->
  INIT_QUEUE++
  setTimeout ( ->
    x = new XMLHttpRequest
    x.open 'GET', url, true
    x.onload = ->
      --INIT_QUEUE
      SHADER[k] = x.response
      if INIT_QUEUE is 0
        renderNext()
      else console.log INIT_QUEUE
    x.send()
  ), 0

setTimeout ( ->
  s = new Star do_moons:yes, do_gases:yes
  p = s.firstChild
  while p?
    console.debug ' -', p.id, p.type, p.atmosphere
    m = p.firstChild
    while m?
      console.debug ' - + ',m.id, m.type
      m = m.nextObject
    p = p.nextObject
  Loader = new THREE.TextureLoader
  Loader.load './star_spectrum.png', (tex)-> window.star_spectrum = tex
  get_shader "fsSun",        "/shader/sun.frag"
  get_shader "fsSunCorona",  "/shader/sun_corona.frag"
  get_shader "fsGasGiant",   "/shader/gas_giant.frag"
  get_shader "fsEarth",      "/shader/earth.frag"
  get_shader "fsMars",       "/shader/mars.frag"
  get_shader "fsAtmosphere", "/shader/atmosphere.frag"
  get_shader "fsAsteroid",   "/shader/asteroid.frag"
  get_shader "vsAsteroid",   "/shader/asteroid.vert"
  get_shader "vsPlanet",     "/shader/planet.vert"
  null ), 1000
