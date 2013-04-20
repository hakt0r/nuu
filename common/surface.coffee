
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

Stellar::renderMap : (c) ->
  vm.canvasRender.graphicsReset(c, map.SIZE.width, map.SIZE.height, vm.style.displayColors)
  vm.canvasRender.renderDebugPolygons(c, map, vm.style.displayColors)
