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

$abstract 'Tile',
  assetPrefix: '/build/outfit/space/'
  layer: 'tile'
  count: null
  rows: 6 # null # FIXME: add to $meta
  cols: 6 # null # FIXME: add to $meta

  loadAssets: -> @loadTile( @assetPrefix + @sprite + '.png' )

  loadTile: (url,dest='sprite',callback=$void) ->
    @[dest] = s = movieFactory url, url
    if dest is 'sprite' or dest is 'spriteNormal'
      { @radius, @size, @count } = ( @sprite = s ).meta
      @show @updateSprite @loaded = true
    callback null

  updateSprite: ->
    @update()
    p = @sprite.position.set @x + OX - @radius, @y + OY - @radius
    @sprite.gotoAndStop @count - parseInt @d / ( 360 / @count )
    true

# IMPLEMENTATIONS

$Tile Ship,
  layer: 'ship'
  loadAssets: ->
    p = '/build/ship/' + @sprite + '/' + @sprite
    Cache.get p + '_comm.png', (cached) => @imgCom = cached
    @loadTile p + '_engine.png', 'spriteEngine'
    @loadTile p + '.png', 'spriteNormal', =>
      Sprite.repositionPlayer() if @id is VEHICLE.id

$Tile Missile,
  ttlFinal: yes
  rows: 6 # FIXME: add to $meta
  cols: 6 # FIXME: add to $meta
  sprite: 'seeker'
