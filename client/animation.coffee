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

  updateSprite:->
    @update()
    @sprite.position.set @x + OX - @radius, @y + OY - @radius
    true

$Animated Debris, sprite: 'debris0'
$Animated Cargo,  sprite: 'cargo', loop: yes
