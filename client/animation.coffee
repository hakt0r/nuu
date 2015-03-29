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

###  

  If you want animations on your $obj you can either implement it like this:

    class <constructor>
      @implements: [$Animated]

  Or, in order to extend an existing $obj:

    $Animated <constructor>

  See below for Cargo and Debris.

###

$abstract 'Animated', 
  layer: 'debr'
  loadAssets: -> Asset.loadAnimation.call @, @animation = 'spfx/' + @animation + '.png'
  getSprite: ->
    @update()
    ani = Asset[@animation].create(@x,@y,@endless,@parent)
    ani.obj = @
    ani.sprite._animation = ani
    ani.sprite
  hide: -> if @currentSprite
    @currentSprite._animation.endless = no
    $obj::hide.call @

###
  An AnimationState is a representation of an animated event, usually an $obj.
###

class AnimationState
  x:0
  y:0
  sprite: null
  parent: no
  endless: no
  constructor: (@sprite,@x,@y,@endless,@parent) ->
    Sprite.stage.addChild @sprite if @parent # FIXME


###

  Animation -sadly- follows the factory-pattern, so:
    an instance reprensents a factory for animations of it's kind.

  Create a new Animation(Factory) like this:

    explosion = new Animation name, url, meta

  You can use the create function to get an actual instance of an animation:

    explosion.create(x,y)

###

$public class Animation
  constructor: (@name,@url,meta) ->
    Animation[@name] = @
    Animation.list.push @
    @rows = @cols = 6
    @count = 36
    @size = meta.width / @cols
    @state = []
    @state[i] = [] for i in [0...@count-1]
    @Texture = t = new PIXI.Texture.fromImage @url
    null

  create: (x,y,endless=no,parent=no) ->
    t = new PIXI.TilingSprite @Texture
    t.height = t.width = @size
    s = new AnimationState t, x, y, endless, parent
    @state[0].push s
    return s

###
 The static part handles shifting the state-groups
  and removing ended animations.

###
Animation.list = []

Animation.shift = ->
  for ani in @list
    n = []
    for i in ani.state.pop()
      if i.endless then n.push i
      else i.obj.destructor()
    ani.state.unshift n
  null

Animation.render = (dx,dy) ->
  @shift()
  for ani in @list
    size = ani.size
    cols = ani.cols
    for state, imgNumber in ani.state
      ix = floor(imgNumber % cols) * size
      iy = floor(imgNumber / cols) * size
      for i in state
        i.sprite.tilePosition.set -ix,-iy
  null

$abstract.Animated Debris
Debris::animation = 'debris0'

$abstract.Animated Cargo
Cargo::animation = 'cargo'
Cargo::endless = yes
