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

$obj.register class Explosion extends $obj
  @sizes: ['exps','expm','expl','expl2']
  @interfaces: [$obj]
  id: 'animation'
  parent: null
  constructor: (parent,i=-1)->
    return unless parent and parent.id
    return if parent.destructing and parent.constructor.type is "station"
    i = round random() if i is -1
    qs = parent.size/4
    hs = parent.size/2
    super
      parent:parent
      id:'animation' + $Animated.id++
      sprite:Explosion.sizes[i]
      state:
        S: $fixedTo
        relto: parent
        x: -qs+random()*hs
        y: -qs+random()*hs
    Sound['explosion0.wav'].play() if Sound.on

$Animated Explosion, layer: 'fx', loop: no

# A collage animation to 'splode ships and stuff :>
$Animated.destroy = (v,t=100,c=5) ->
  $Animated.explode v, min(t,round(random()*t)), 1 for i in [0...c-1]

$Animated.respawn = (v,t=4000,c=25) ->
  $Animated.explode v, min(t,round(random()*t)) for i in [0...c-1]
  $Animated.explode v, t, 3
  setTimeout ( -> v.hide() ), t
  setTimeout ( -> v.show() ), t + 3000
  return

$Animated.explode = (v,t,i) ->
  setTimeout ( -> new Explosion v,i ), t

NUU.on '$obj:hit',      (v) -> $Animated.explode v, 0, 1
NUU.on '$obj:shield',   (v) -> $Animated.explode v, 0, 2
NUU.on '$obj:disabled', (v) -> $Animated.explode v, 0, 3

NUU.on '$obj:destroyed', (v) ->
  return $Animated.destroy v, 100, 5 unless v.constructor.name is 'Ship'
  return $Animated.respawn v
