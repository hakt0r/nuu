###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2008 flyc0r

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

$public class AnimatedSprite

  # AnmiatedSprite, sadly, follows the factory-pattern
  #  an instance reprensents one sprite-animation
  constructor: (@name,@img) ->
    AnimatedSprite.byName[@name] = @
    @rows = @cols = 6
    @count = 36
    @size = @img.naturalWidth / @cols
    @state = []
    @state[i] = [] for i in [0...@count-1]
    @Texture = t = new PIXI.Texture.fromImage @img.src
    null

  # You can use the ::create(x,y):: function to
  #  get an actual instance of an animation.  
  create: (x,y,endless=no,parent=no) ->
    t = new PIXI.TilingSprite @Texture
    t.height = t.width = @size
    s = new AnimationState t, x, y, endless, parent
    @state[0].push s
    return s

class AnimationState
  x:0
  y:0
  sprite: null
  parent: no
  endless: no
  constructor: (@sprite,@x,@y,@endless,@parent) ->
    if @parent
      Sprite.stage.addChild @sprite
    @sprite.position.set @x, @y

# The static part handles shifting the state-groups
#  and removing ended animations.
AnimatedSprite.byName = {}

AnimatedSprite.shift = ->
  for name, ani of @byName
    n = []
    for i in ani.state.pop()
      if i.endless then n.push i
      else i.obj.destructor()
    ani.state.unshift n
  null

AnimatedSprite.render = (dx,dy) ->
  @shift()
  for name, ani of @byName
    size = ani.size
    cols = ani.cols
    for state, imgNumber in ani.state
      ix = floor(imgNumber % cols) * size
      iy = floor(imgNumber / cols) * size
      i.sprite.tilePosition.set -ix,-iy for i in state
  null

  # A collage animation to 'splode ships and stuff :>
  @splode = (v,t) -> setTimeout ( ->
    qs = v.size/4
    hs = v.size/2
    new Explosion state:
      S: $relative
      relto: v.id
      x: -qs+Math.random()*hs
      y: -qs+Math.random()*hs
    Sound['explosion0.wav'].play() if Sound.on ), t

$obj.register class Explosion extends Animated
  @interfaces: [$obj,Animated]
  id: 'animation'
  layer: 'pwep'
  endless: no
  animation: 'exps'

NUU.on 'ship:destroyed', (v) ->
  for i in [0...25]
    AnimatedSprite.splode v, Math.min(10000,Math.round(Math.random()*10000))
  $timeout 9000, ->
    v.invisible = yes

NUU.on 'ship:hit', (v) -> Ship.splode v, 0
