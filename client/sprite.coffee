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
  # console.log 'show$', @id, @name, @sprite
  @updateSprite() # PROVEME
  Sprite.visible[@id] = @sprite
  Sprite.visibleList.push @
  Sprite[@layer].addChild @sprite
  @sprite.interactive = yes
  @sprite.click = => NUU.emit 'newTarget', NUU.target = @
  null

$obj::hide = ->
  return unless old = Sprite.visible[@id]
  # console.log 'hide$', @id, @name
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

$obj::updateSprite = ->
  @update()
  @sprite.position.set @x + OX - @radius, @y + OY - @radius
  true

Stellar::layer = 'stel'

app.on '$obj:inRange', (obj) -> obj.show()
app.on '$obj:outRange', (obj) -> obj.hide()

Target.types.push $obj.hostile = []
Target.typeNames.push 'hostile'

app.on '$obj:del', (obj) ->
  obj.hide()
  Array.remove $obj.hostile, obj unless -1 is $obj.hostile.indexOf obj
  null

app.on '$obj:add', (obj) ->
  do obj.loadAssets
  $obj.hostile.push obj if obj.npc
  null
