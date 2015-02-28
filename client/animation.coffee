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
  constructor : (@name,@img) ->
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
  create : (x,y) ->
    @state[0].push [x,y,t = new PIXI.TilingSprite @Texture]
    t.height = t.width = @size
    Sprite.main.weap.addChild t

  # The static part handles shifting the state-groups
  @byName : {}
  @shift : =>
    for name, ani of @byName
      ani.state.unshift []
      for i in ani.state.pop()
        Sprite.main.weap.removeChild i[2]
    null

  #  and removing ended animations.
  @render : (dx,dy,c) =>
    for name, ani of @byName
      img = ani.img
      size = ani.size
      cols = ani.cols
      for imgNumber, state of ani.state
        for i in state 
          ix = floor(imgNumber % cols) * size
          iy = floor(imgNumber / cols) * size
          i[2].position.set i[0]+dx, i[1]+dy
          i[2].tilePosition.set -ix,-iy
    null

  # A collage animation to 'splode ships and stuff :>
  @splode = (v) -> ->
    Sprite.spfx.exps.create(v.x-50+Math.random()*50,v.y-50+Math.random()*50)
    Sound['explosion0.wav'].play() if Sound.on

app.on 'ready', ->

  NUU.on 'targetDestroyed', (v) ->
    $timeout Math.min(10000,Math.round(Math.random()*10000)), AnimatedSprite.splode(v) for i in [0...25]
    $timeout 10000, -> console.log 'mayhem'

  NUU.on 'targetHit', (v) ->
    Sprite.spfx.exps.create(v.x,v.y)
