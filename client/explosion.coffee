###

  * c) 2007-2016 Sebastian Glaser <anx@ulzq.de>
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

$obj.register class Explosion extends $obj
  @sizes: ['exps','expm','expl','expl2']
  @interfaces: [$obj]
  id: 'animation'
  parent: null
  constructor: (@parent)->
    return unless @parent and @parent.id
    qs = @parent.size/4
    hs = @parent.size/2
    super
      sprite: Array.random(Explosion.sizes)
      state:
        S: $relative
        relto: @parent.id
        x: -qs+Math.random()*hs
        y: -qs+Math.random()*hs
    Sound['explosion0.wav'].play() if Sound.on

$Animated Explosion, layer: 'fx', loop: no

# A collage animation to 'splode ships and stuff :>
$Animated.destroy = (v,t) -> for i in [0...25]
  $Animated.explode v, Math.min(10000,Math.round(Math.random()*10000))

$Animated.explode = (v,t) -> setTimeout ( -> new Explosion v ), t

NUU.on 'ship:hit',       (v) -> $Animated.explode v, 0
NUU.on 'ship:destroyed', (v) -> $Animated.destroy v
