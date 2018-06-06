###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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

$obj::layer       = 'bg'
$obj::loaded      = no
$obj::assetPrefix = '/build/stel/'

$obj::loadAssets = ->
  @img = url = @assetPrefix + @sprite + '.png'
  { @size, @radius } = @meta = $meta[ @sprite ]
  @sprite = new PIXI.Sprite new PIXI.Texture.fromImage url
  @show @loaded = true

$obj::show = ->
  return if Sprite.visible[@id]
  return unless @loaded
  console.log ':gfx', 'show$', @id, @name, @sprite if debug
  @updateSprite() # PROVEME
  Sprite.visible[@id] = @sprite
  Sprite.visibleList.push @
  Sprite[@layer].addChild @sprite
  null

$obj::hide = ->
  return unless old = Sprite.visible[@id]
  console.log ':gfx', 'hide$', @id, @name if debug
  delete Sprite.visible[@id]
  Array.remove Sprite.visibleList, @
  Sprite[@layer].removeChild old
  null

$obj::changeSprite = (newSprite) ->
  return if newSprite is old = Sprite.visible[@id]
  Sprite.visible[@id] = @sprite = newSprite
  Sprite[@layer].addChild @sprite
  Sprite[@layer].removeChild old
  null

$obj::updateSprite = (time)->
  @update time
  @sprite.position.set @x + OX - @radius, @y + OY - @radius
  true

Stellar::layer = 'stel'

NUU.on '$obj:inRange', (obj) -> obj.show()
NUU.on '$obj:outRange', (obj) -> obj.hide()
NUU.on '$obj:del', (obj) ->
  delete SHORTRANGE[obj.id]
  NUU.emit '$obj:outRange', obj
  Array.remove VEHICLE.hostile, obj if -1 is VEHICLE.hostile.indexOf obj
  null
