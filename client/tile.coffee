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

$abstract 'Tile',
  assetPrefix: '/build/outfit/space/'
  layer: 'tile'
  count: null

  loadAssets: ->
    @loadTile ( @assetPrefix + @sprite + '.png' ), 'sprite', (e,s)=>
      @count = @sprite.meta.count
      @loaded = true
      # @show @updateSprite()
      @sprite.anchor.set 0.5

  loadTile: (url,dest='sprite',callback=$void) ->
    callback null, @[dest] = movieFactory url, url

  updateSprite: (time)->
    @update time
    p = @sprite.position.set @x + OX, @y + OY unless @ is VEHICLE
    @sprite.gotoAndStop @count - parseInt @d * ( @count / 360 )
    true

# IMPLEMENTATIONS

$Tile Ship,
  spriteMode:0
  layer: 'ship'

  loadAssets: ->
    console.log ':gfx', 'ship$', 'assets', @id, @name if debug
    p = '/build/ship/' + @sprite.replace(/_.*/,'') + '/' + @sprite
    @imgCom = p + '_comm.png'
    # Cache.get p + '_comm.png', (cached) => @imgCom = cached
    @loadTile p + '.png', 'sprite', (e,s) =>
      { @radius, @size, @count } = ( @spriteNormal = @sprite = s ).meta
      @loaded = true
      # @show @updateSprite()
    @loadTile p + '_engine.png', 'spriteEngine'

  updateSprite: (time)->
    @update time
    if @state.acceleration then if @spriteMode is 0
      @changeSprite @spriteEngine
      @spriteMode = 1
    else if @spriteMode is 1
      @changeSprite @spriteNormal
      @spriteMode = 0
    @sprite.anchor.set 0.5
    p = @sprite.position.set @x + OX, @y + OY
    if @count is 1 then @sprite.rotation = ( @d + 90 % 360 ) / 360 * TAU
    else @sprite.gotoAndStop @count - parseInt @d * ( @count / 360 )
    true


$Tile Missile, sprite: 'banshee', ttlFinal: yes
