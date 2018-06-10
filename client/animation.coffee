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

$abstract 'Animated',
  layer: 'debr'
  loop: no

  loadAssets: ->
    @sprite = movieFactory @sprite, '/build/spfx/' + @sprite + '.png', (
      if @loop is on then on else => @destructor() )
    { @radius, @size } = @sprite.meta
    @updateSprite()
    @sprite.play()
    @show @loaded = true

  updateSprite:(time)->
    @update time
    @sprite.position.set @x + OX - @radius, @y + OY - @radius
    true

$Animated Debris, sprite: 'debris0'
$Animated Cargo,  sprite: 'cargo', loop: yes

Weapon.Beam.loadAssets = ->
  @meta = $meta[@sprite]
  @sprite = new PIXI.TilingSprite PIXI.Texture.fromImage '/build/outfit/space/' + @sprite + '.png'
  @sprite.height = @meta.height
  @sprite.width  = @range
  @sprite.anchor.set 0, 0.5
  @sprite.position.set -100, -100 # offscreen till render
  window.BB = @
  null

Weapon.Beam.show = ->
  Sprite.weap.addChild @sprite

Weapon.Beam.hide = ->
  Sprite.weap.removeChild @sprite

Weapon.Projectile.loadAssets = ->
  @meta = $meta[@sprite]
  w = @meta.width / @meta.cols
  @base = PIXI.Texture.fromImage '/build/outfit/space/' + @sprite + '.png'
  @base = new PIXI.Texture @base.baseTexture, new PIXI.Rectangle 0,0,w,w
  null

window.ProjectileAnimation = (@perp,@weap,@ms,@tt,@sx,@sy,@mx,@my,@dir) ->
  @sprite = new PIXI.Sprite @weap.base
  @sprite.anchor.set 0, 0.5
  @sprite.position.set @perp.x + OX, @perp.y + OY
  @sprite.rotation = @dir
  Sprite.weap.addChild @sprite
  Weapon.proj.push @
