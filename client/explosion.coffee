###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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
      id:'animation' + $Animated.id++
      sprite: Array.random Explosion.sizes
      state:
        S: $fixedTo
        relto: @parent.id
        x: -qs+random()*hs
        y: -qs+random()*hs
    Sound['explosion0.wav'].play() if Sound.on

$Animated Explosion, layer: 'fx', loop: no

# A collage animation to 'splode ships and stuff :>
$Animated.destroy = (v,t=4000,c=25) ->
  $Animated.explode v, min(t,round(random()*t)) for i in [0...c]
  setTimeout ( -> v.destructing = no ), t
  null

$Animated.explode = (v,t) ->
  setTimeout ( -> new Explosion v ), t

NUU.on '$obj:hit', (v) ->
  $Animated.explode v, 0

NUU.on '$obj:destroyed', (v) ->
  return $Animated.destroy v, 1500, 5 unless v.constructor.name is 'Ship'
  return $Animated.destroy v
