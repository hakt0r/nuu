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

$obj::layer       = 'bg'
$obj::loaded      = no
$obj::assetPrefix = '/build/stel/'

$obj::loadAssets = ->
  url = @assetPrefix + @sprite + '.png'
  @meta   = $meta[ url ]
  @sprite = PIXI.Sprite.fromImage url
  @size   = @meta.width
  @radius = @size / 2
  @show @loaded = true

$obj::show = ->
  return if Sprite.visible[@id]
  Sprite.visibleList.push @
  Sprite.visible[@id] = @sprite
  Sprite[@layer].addChild @sprite

$obj::hide = ->
  return unless ( s = Sprite.visible[@id] )
  Array.remove Sprite.visibleList, @
  Sprite[@layer].removeChild s
  delete Sprite.visible[@id]

$obj::changeSprite = (newSprite) ->
  if ( old = Sprite.visible[@id] )
    Sprite[@layer].addChild @sprite = newSprite
    Sprite[@layer].removeChild old
  Sprite.visible[@id] = @sprite = newSprite
  null

$obj::updateSprite = ->
  @update()
  p = @sprite.position
  p.x = @x + OX - @radius
  p.y = @y + OY - @radius
  true

Stellar::layer = 'stel'

app.on '$obj:inRange',  (obj) -> obj.show()
app.on '$obj:outRange', (obj) -> obj.hide()
app.on '$obj:del',      (obj) -> obj.hide()
app.on '$obj:add',      (obj) -> obj.loadAssets()
