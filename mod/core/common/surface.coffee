###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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

Stellar::genMap = ->
  vm = require('voronoi-map')
  map = vm.map width: 1000.0, height: 1000.0
  map.newIsland(vm.islandShape.makeRadial(1), 1)

  map.go0PlacePoints(100)
  map.go1ImprovePoints()
  map.go2BuildGraph()
  map.assignBiomes()
  map.go3AssignElevations()
  map.go4AssignMoisture()
  map.go5DecorateMap()

  lava = vm.lava()
  roads = vm.roads()
  roads.createRoads(map, [0, 0.05, 0.37, 0.64])
  watersheds = vm.watersheds()
  watersheds.createWatersheds(map)
  noisyEdges = vm.noisyEdges()
  noisyEdges.buildNoisyEdges(map, lava, map.mapRandom.seed)
  @map = map

Stellar::renderMap = (c) ->
  vm.canvasRender.graphicsReset(c, map.SIZE.width, map.SIZE.height, vm.style.displayColors)
  vm.canvasRender.renderDebugPolygons(c, map, vm.style.displayColors)
