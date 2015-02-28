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

$public class Engine extends CommonEngine
  server    : null
  drone     : {}
  userState : {}
  states   : []
  players   : []

  constructor : (stars) ->
    super
    console.log "Engine"
    @init()
    @start()

  init : ->
    stars = [
      [ 0,  'Sol',     'yellow02',       0,           fixed, 0 ],
      [ 1,  'Mercury', 'A01',            58000000,    orbit, 0 ],
      [ 2,  'Venus',   'A02',            108000000,   orbit, 0 ],
      [ 3,  'Earth',   'M00',            149600000,   orbit, 0 ],
      [ 4,  'Moon',    'moon-M01',       375000,      orbit, 3 ],
      [ 5,  'Mars',    'K04',            228000000,   orbit, 0 ],
      [ 6,  'Jupiter', 'J01',            778500000,   orbit, 0 ],
      [ 7,  'Saturn',  'I07',            1430000000,  orbit, 0 ],
      [ 8,  'Uranus',  'O04',            2880000000,  orbit, 0 ],
      [ 9,  'Neptun',  'P04',            4500000000,  orbit, 0 ],
      [ 10, 'Pluto',   'D07',            6500000000,  orbit, 0 ],
      [ 12, 'Nibiru',  'station-sphere', 10000000000, orbit, 0 ]]
    Item.init(JSON.parse fs.readFileSync './build/objects.json')
    new Stellar(id:i[0],name:i[1],sprite:i[2],orbit:i[3],x:0,y:0,state:i[4],relto:i[5]) for i in stars
    rules(@)

  spawnDrone : ->
    slot= weap= inRange = null
    players = NUU.players; fire = off
    s = new Ship
      target : false
      tpl : 5 # Drone :)
      x  : floor random() * 1000 - 500
      y  : floor random() * 1000 - 500
      mx : floor random() * 10 - 5
      my : floor random() * 10 - 5
      d  : floor random() * 359
    s.name = "ai[##{s.id}]"
    $worker.push ->
      unless s.target or not players[0]?
        s.target = players[0].vehicle
      return 1000 unless s.target
      vec = NavCom.autopilot(s,s.target)
      slot = s.slots.weapon[0]
      weap = s.slots.weapon[0].equip
      inRange = vec.dist < 300
      if not fire and inRange
        # console.log 'engage', weap.id
        NET.weap.write('ai',1,slot,s,s.target)
        fire = on
      else if fire and not inRange
        # console.log 'disengage', weap.id
        NET.weap.write('ai',2,slot,s,s.target)
        fire = off
      unless vec.flags is s.flags
        s.left  = vec.left
        s.right = vec.right
        s.accel = vec.accel
        NET.state.write(s,vec.flags)
      return null
    return s
