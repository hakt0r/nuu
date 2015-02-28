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

DRONES_ACTIVE = on
DRONES_MAX    = 2

$static 'rules', ->
  console.log 'mode'.yellow, 'deathmatch'.red

  if isClient
    NET.on 'stats', (v) -> for id, stat of v
      console.log stat.name + " #{stat.k}  #{stat.d}"

  else
    rules.stats = stats = {}
    rules.drone = drone = {}

    NUU.on 'playerJoined', (p) ->
      stats[p.vehicle.id] = name : p.name, k:0, d:0
      console.log 'new player', p.name, stats

    NUU.on 'playerLeft', (p) ->
      delete stats[p.vehicle.id]

    NUU.on 'targetDestroyed', (victim,perp) ->
      stats[victim.id].d++ unless drone[victim.id]
      if drone[victim.id] then $timeout 10000, ->
        victim.destructor()
        delete drone[victim.id]
      unless drone[perp.id]
        stats[perp.id].k++
      NUU.jsoncast stats : stats
      console.log stats

    $worker.push ->
      roids  = Object.keys(Asteroid.byId).length
      drones = Object.keys(drone).length
      if DRONES_ACTIVE and drones < DRONES_MAX
        dt = DRONES_MAX - drones
        for i in [0...dt]
          s = NUU.spawnDrone()
          drone[s.id] = s
      if roids < 100
        dt = 100 - roids
        new Asteroid for i in [0...dt]
      1000
