
$public class SpriteSurface
  @renderer: null
  @camera3d: null
  @scene3d: null
  @scene2d: null
  @camera2d: null
  @spriteTL: null
  @spriteTR: null
  @spriteBL: null
  @spriteBR: null
  @spriteC: null
  @mapC: null
  @group: null

  constructor:->
    @width = window.innerWidth; @height = window.innerHeight; @wdb2 = @width/2; @hgb2 = @height/2
    @camera3d = new THREE.PerspectiveCamera 60, @width / @height, 1, 2100
    @camera3d.position.z = 1500
    @camera2d = new THREE.OrthographicCamera -@wdb2, @wdb2, @hgb2, -@hgb2, 1, 10
    @camera2d.position.z = 10
    @scene3d = new THREE.Scene
    @scene3d.fog = new THREE.Fog 0x000000, 1500, 2100
    @scene2d = new THREE.Scene
    # create sprites
    amount = 200
    radius = 500
    @loader = new THREE.TextureLoader
    @loader.load 'textures/sprite0.png', createHUDSprites
    @mapB = @loader.load('textures/sprite1.png')
    @mapC = @loader.load('textures/sprite2.png')
    @group = new THREE.Group
    materialC = new THREE.SpriteMaterial map: @mapC, color: 0xffffff, fog: true
    materialB = new THREE.SpriteMaterial map: @mapB, color: 0xffffff, fog: true
    a = 0
    while a < amount
      x = Math.random() - 0.5
      y = Math.random() - 0.5
      z = Math.random() - 0.5
      material = undefined
      if z < 0
        material = materialB.clone()
      else
        material = materialC.clone()
        material.color.setHSL 0.5 * Math.random(), 0.75, 0.5
        material.map.offset.set -0.5, -0.5
        material.map.repeat.set 2, 2
      sprite = new (THREE.Sprite)(material)
      sprite.position.set x, y, z
      sprite.position.normalize()
      sprite.position.multiplyScalar radius
      @group.add sprite
      a++
    @scene3d.add @group
    @renderer = new THREE.WebGLRenderer
    @renderer.setPixelRatio window.devicePixelRatio
    @renderer.setSize window.innerWidth, window.innerHeight
    @renderer.autoClear = false
    # To allow render overlay on top of sprited sphere
    document.body.appendChild @renderer.domElement
    window.addEventListener 'resize', onWindowResize, false
    animate()
    return

  createHUDSprites: (texture) ->
    material = new (THREE.SpriteMaterial)(map: texture)
    @width = material.map.image.@width
    @height = material.map.image.@height
    @spriteTL = new (THREE.Sprite)(material)
    @spriteTL.center.set 0.0, 1.0
    @spriteTL.scale.set @width, @height, 1
    @scene2d.add @spriteTL
    @spriteTR = new (THREE.Sprite)(material)
    @spriteTR.center.set 1.0, 1.0
    @spriteTR.scale.set @width, @height, 1
    @scene2d.add @spriteTR
    @spriteBL = new (THREE.Sprite)(material)
    @spriteBL.center.set 0.0, 0.0
    @spriteBL.scale.set @width, @height, 1
    @scene2d.add @spriteBL
    @spriteBR = new (THREE.Sprite)(material)
    @spriteBR.center.set 1.0, 0.0
    @spriteBR.scale.set @width, @height, 1
    @scene2d.add @spriteBR
    @spriteC = new (THREE.Sprite)(material)
    @spriteC.center.set 0.5, 0.5
    @spriteC.scale.set @width, @height, 1
    @scene2d.add @spriteC
    updateHUDSprites()
    return

  updateHUDSprites: ->
    @width = window.innerWidth / 2
    @height = window.innerHeight / 2
    @spriteTL.position.set -@width, @height, 1
    @spriteTR.position.set @width, @height, 1
    @spriteBL.position.set -@width, -@height, 1
    @spriteBR.position.set @width, -@height, 1
    @spriteC.position.set 0, 0, 1
    return

  onWindowResize: ->
    @width = window.innerWidth
    @height = window.innerHeight
    @camera3d.aspect = @width / @height
    @camera3d.updateProjectionMatrix()
    @camera2d.left = -@wdb2
    @camera2d.right = @wdb2
    @camera2d.top = @hgb2
    @camera2d.bottom = -@hgb2
    @camera2d.updateProjectionMatrix()
    updateHUDSprites()
    @renderer.setSize window.innerWidth, window.innerHeight
    return

  animate:->
    requestAnimationFrame animate
    render()
    return

  render = ->
    time = Date.now() / 1000
    i = 0
    l = @group.children.length
    while i < l
      sprite = @group.children[i]
      material = sprite.material
      scale = Math.sin(time + sprite.position.x * 0.01) * 0.3 + 1.0
      imageWidth = 1
      imageHeight = 1
      if material.map and material.map.image and material.map.image.@width
        imageWidth = material.map.image.@width
        imageHeight = material.map.image.@height
      sprite.material.rotation += 0.1 * i / l
      sprite.scale.set scale * imageWidth, scale * imageHeight, 1.0
      if material.map != @mapC
        material.opacity = Math.sin(time + sprite.position.x * 0.01) * 0.4 + 0.6
      i++
    @group.rotation.x = time * 0.5
    @group.rotation.y = time * 0.75
    @group.rotation.z = time * 1.0
    @renderer.clear()
    @renderer.render @scene3d, @camera3d
    @renderer.clearDepth()
    @renderer.render @scene2d, @camera2d
    return
