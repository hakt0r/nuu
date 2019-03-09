###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
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

rules.dm.server = ->
  $static 'DRONES_ACTIVE', yes
  $static 'DRONES_MAX',    10
  $static 'ROIDS_MAX',     100

  rules.stats = stats = {}

  NET.on 'shipname', (msg,src) ->
    return src.error '_invalid_msg'   unless typeof msg is 'string'
    return src.error '_no_handle'     unless u = src.handle
    return src.error '_no_vehicle'    unless o = u.vehicle
    return src.error '_not_the_owner' unless o.user is u
    s = u.db.loadout[v.tplName] || s = u.db.loadout[v.tplName] = {}
    s.name = o.name = msg

  NET.on 'inventory', (msg,src) ->
    return src.error '_invalid_msg'   unless typeof msg is 'string'
    return src.error '_no_handle'     unless u = src.handle
    return src.error '_no_vehicle'    unless o = u.vehicle
    return src.error '_not_the_owner' if msg is 'ship' and o.user isnt u
    src.json inventory: switch msg
      when 'ship' then o.inventory || o.inventory = {}
      else u.db.inventory || u.db.inventory = {}
    null

  NET.on 'unlocks', (msg,src) ->
    return src.error '_invalid_msg'   unless typeof msg is 'string'
    return src.error '_no_handle'     unless u = src.handle
    src.json unlocks: u.db.unlocks || u.db.unlocks = {}
    null

  ### ███████ ██    ██ ███████ ███    ██ ████████ ███████
      ██      ██    ██ ██      ████   ██    ██    ██
      █████   ██    ██ █████   ██ ██  ██    ██    ███████
      ██       ██  ██  ██      ██  ██ ██    ██         ██
      ███████   ████   ███████ ██   ████    ██    ███████ ###

  NUU.on 'user:joined', (p) ->
    stats[p.db.nick] = name : p.db.nick, k:0, d:0 unless stats[p.db.nick]
    console.log '::dm', 'joined'.green, p.db.nick, stats[p.db.nick].k.toString().green, stats[p.db.nick].d.toString().red

  NUU.on 'user:left', (p) ->
    delete stats[p.db.nick]

  NUU.on 'station:destroyed', (victim,perp) ->
    console.log '::dm', 'destroyed'.red, victim.name.yellow
    victim.destructor()

  NUU.on 'ship:destroyed', (victim,perp) ->
    console.log '::dm', 'destroyed'.red, victim.name.yellow
    if victim.npc is yes then $timeout 4500, ->
      victim.dropLoot()
      victim.destructor()
      return
    else if victim.mount then victim.mount.map (user)-> if user
      stats[user.db.nick].d++
      console.log '::dm', 'death'.red, user.db.nick.red, '['+perp.name.yellow+']', stats[user.db.nick].k.toString().green, stats[user.db.nick].d.toString().red
      $timeout 4500, ->
        victim.dropLoot()
        victim.respawn()
    if perp.inhabited then perp.mount.map (user)-> if user
      stats[user.db.nick].k++
      i = user.db.unlocks; if v = i[victim.tplName] then i[victim.tplName]++ else i[victim.tplName] = 1; user.save()
      console.log '::dm', 'kill '.green, user.db.nick.green, '['+perp.name.yellow+']', stats[user.db.nick].k.toString().green, stats[user.db.nick].d.toString().red
    NUU.jsoncast stats: stats

  NUU.on 'asteroid:destroyed', (v, resource)->
    v.mount.map (user)->
      return unless user
      console.log '::dm', 'collect', user.db.nick, resource
      # i = user.db.inventory
      # if v = i[t.name] then i[t.name]++ else i[t.name] = 1
      null
    null

  NUU.on 'ship:collect', (v,t,o)->
    name = t.name.replace /[\[\]]/g, ''
    v.mount.map (user)->
      return unless user
      console.log '::dm', 'collect', user.db.nick, name
      i = user.db.unlocks; if v = i[name] then i[name]++ else i[name] = 1; user.save()
      null
    null

  Asteroid.autospawn max: ROIDS_MAX
  AI.autospawn max: DRONES_MAX if DRONES_ACTIVE

  NUU.emit 'rules', rules

rules.dm.stars = [
  [ 0,   Star,    'Sol',                 'orange05',              0,           $fixed ]
  [ 20,  Station, 'Hades Bootcamp',      'station-battlestation', 1000,        $orbit, 0, template:'Fortress' ]

  [ 1,   Planet,  'Mercury-13',          'A01',                   23000000,    $orbit, 0 ]
  [ 999, Planet,  'Mercury',             'A01',                   58000000,    $orbit, 0 ]
  [ 2,   Planet,  'Venus',               'A02',                   108000000,   $orbit, 0 ]

  [ 3,   Planet,  'Earth',               'M00',                   149600000,   $orbit, 0, provides:{O2:1000,H20:1000,Pu:10,Fe:100,Farmland:1000},occupiedBy:{gov:'AI',level:15} ]
  [ 4,   Moon,    'Moon',                'moon-M01',              375000,      $orbit, 3, provides:{Fe:1000,H3:1000},occupiedBy:{gov:'US',level:6} ]

  [ 5,   Planet,  'Mars',                'K04',                   228000000,   $orbit, 0, provides:{Fe:1000,H3:1000},occupiedBy:gov:'US',level:9 ]

  [ 6,   Planet,  'Jupiter',             'J01',                   778500000,   $orbit, 0, provides:{e:50,H:1000,H2:500,H3:30,CH4:1,H20:1,NH3:1,Si:1,Ne:1},orbits:[640,1280,1920,2560],occupiedBy:{gov:'US',level:20} ]
  [ 80,  Moon,    'Ananke',              'D06',                   640,         $orbit, 6, i:15369.12 ]
  [ 81,  Moon,    'Metis',               'moon-M01',              127690,      $orbit, 6, i:7.1472222222 ]
  [ 82,  Moon,    'Adrastea',            'moon-I01',              128690,      $orbit, 6, i:7.2333333333 ]
  [ 83,  Moon,    'Amalthea',            'moon-P02',              181366,      $orbit, 6, i:12.0138888889 ]
  [ 84,  Moon,    'Thebe',               'moon-P00',              221889,      $orbit, 6, i:16.2305555556 ]
  [ 85,  Moon,    'Io',                  'M05',                   421700,      $orbit, 6, i:10120800,provides:{Farmland:1000,H2O:1000,Fe:100,O2:100},occupiedBy:{gov:'US',level:10} ]
  [ 86,  Moon,    'Europa',              'M02',                   671034,      $orbit, 6, i:16104816,provides:{Fe:1000},occupiedBy:{gov:'US',level:15} ]
  [ 87,  Moon,    'Ganymede',            'A04',                   1070412,     $orbit, 6, i:25689888,provides:{Fe:1000},occupiedBy:{gov:'US',level:10} ]
  [ 88,  Moon,    'Callisto',            'C00',                   1882709,     $orbit, 6, i:45185016 ]
  [ 89,  Moon,    'Themisto',            'moon-I01',              7393216,     $orbit, 6, i:177437184 ]
  [ 90,  Moon,    'Leda',                'moon-X00',              11187781,    $orbit, 6, i:268506744 ]
  [ 91,  Moon,    'Himalia',             'moon-P03',              11451971,    $orbit, 6, i:274847304 ]
  [ 92,  Moon,    'Lysithea',            'D06',                   11740560,    $orbit, 6, i:281773440 ]
  [ 93,  Moon,    'Elara',               'D06',                   11778034,    $orbit, 6, i:282672816 ]
  [ 94,  Moon,    'S/2000 J11',          'D07',                   12570424,    $orbit, 6, i:301690176 ]
  [ 95,  Moon,    'Carpo',               'D06',                   17144873,    $orbit, 6, i:411476952 ]
  [ 96,  Moon,    'S/2003 J12',          'D03',                   17739539,    $orbit, 6, i:425748936 ]
  [ 97,  Moon,    'Euporie',             'D04',                   19088434,    $orbit, 6, i:458122416 ]
  [ 98,  Moon,    'S/2003 J3',           'D04',                   19621780,    $orbit, 6, i:470922720 ]
  [ 99,  Moon,    'S/2003 J18',          'D04',                   19812577,    $orbit, 6, i:475501848 ]
  [ 100, Moon,    'S/2011 J1',           'D03',                   20165290,    $orbit, 6, i:483726960 ]
  [ 101, Moon,    'S/2010 J2',           'D03',                   20307150,    $orbit, 6, i:487371600 ]
  [ 102, Moon,    'Thelxinoe',           'D04',                   20453753,    $orbit, 6, i:490890072 ]
  [ 103, Moon,    'Euanthe',             'D06',                   20464854,    $orbit, 6, i:491156496 ]
  [ 104, Moon,    'Helike',              'D07',                   20540266,    $orbit, 6, i:492966384 ]
  [ 105, Moon,    'Orthosie',            'D04',                   20567971,    $orbit, 6, i:493631304 ]
  [ 106, Moon,    'Iocaste',             'moon-A01',              20722566,    $orbit, 6, i:497341584 ]
  [ 107, Moon,    'S/2003 J16',          'D04',                   20743779,    $orbit, 6, i:497850696 ]
  [ 108, Moon,    'Praxidike',           'moon-A00',              20823948,    $orbit, 6, i:499774752 ]
  [ 109, Moon,    'Harpalyke',           'D07',                   21063814,    $orbit, 6, i:505531536 ]
  [ 110, Moon,    'Mneme',               'D04',                   21129786,    $orbit, 6, i:507114864 ]
  [ 111, Moon,    'Hermippe',            'D07',                   21182086,    $orbit, 6, i:508370064 ]
  [ 112, Moon,    'Thyone',              'D07',                   21405570,    $orbit, 6, i:513733680 ]
  [ 114, Moon,    'Herse',               'D04',                   22134306,    $orbit, 6, i:531223344 ]
  [ 115, Moon,    'Aitne',               'D06',                   22285161,    $orbit, 6, i:534843864 ]
  [ 116, Moon,    'Kale',                'D04',                   22409207,    $orbit, 6, i:537820968 ]
  [ 117, Moon,    'Taygete',             'moon-A01',              22438648,    $orbit, 6, i:538527552 ]
  [ 118, Moon,    'S/2003 J19',          'D04',                   22709061,    $orbit, 6, i:545017464 ]
  [ 119, Moon,    'Chaldene',            'D07',                   22713444,    $orbit, 6, i:545122656 ]
  [ 120, Moon,    'S/2003 J15',          'D04',                   22720999,    $orbit, 6, i:545303976 ]
  [ 121, Moon,    'S/2003 J10',          'D04',                   22730813,    $orbit, 6, i:545539512 ]
  [ 122, Moon,    'S/2003 J23',          'D04',                   22739654,    $orbit, 6, i:545751696 ]
  [ 123, Moon,    'Erinome',             'D06',                   22986266,    $orbit, 6, i:551670384 ]
  [ 124, Moon,    'Aoede',               'D07',                   23044175,    $orbit, 6, i:553060200 ]
  [ 125, Moon,    'Kallichore',          'D04',                   23111823,    $orbit, 6, i:554683752 ]
  [ 126, Moon,    'Kalyke',              'moon-A01',              23180773,    $orbit, 6, i:556338552 ]
  [ 127, Moon,    'Carme',               'moon-M02',              23197992,    $orbit, 6, i:556751808 ]
  [ 128, Moon,    'Callirrhoe',          'moon-M03',              23214986,    $orbit, 6, i:557159664 ]
  [ 129, Moon,    'Eurydome',            'D06',                   23230858,    $orbit, 6, i:557540592 ]
  [ 130, Moon,    'S/2011 J2',           'D03',                   23329710,    $orbit, 6, i:559913040 ]
  [ 131, Moon,    'Pasithee',            'D04',                   23307318,    $orbit, 6, i:559375632 ]
  [ 132, Moon,    'S/2010 J1',           'D04',                   23314335,    $orbit, 6, i:559544040 ]
  [ 133, Moon,    'Kore',                'D04',                   23345093,    $orbit, 6, i:560282232 ]
  [ 134, Moon,    'Cyllene',             'D04',                   23396269,    $orbit, 6, i:561510456 ]
  [ 135, Moon,    'Eukelade',            'D07',                   23483694,    $orbit, 6, i:563608656 ]
  [ 136, Moon,    'S/2003 J4',           'D04',                   23570790,    $orbit, 6, i:565698960 ]
  [ 137, Moon,    'Pasiphae',            'D06',                   23609042,    $orbit, 6, i:566617008 ]
  [ 138, Moon,    'Hegemone',            'D06',                   23702511,    $orbit, 6, i:568860264 ]
  [ 139, Moon,    'Arche',               'D06',                   23717051,    $orbit, 6, i:569209224 ]
  [ 140, Moon,    'Isonoe',              'D07',                   23800647,    $orbit, 6, i:571215528 ]
  [ 141, Moon,    'S/2003 J9',           'D03',                   23857808,    $orbit, 6, i:572587392 ]
  [ 142, Moon,    'S/2003 J5',           'D07',                   23973926,    $orbit, 6, i:575374224 ]
  [ 143, Moon,    'Sinope',              'D03',                   24057865,    $orbit, 6, i:577388760 ]
  [ 144, Moon,    'Sponde',              'D04',                   24252627,    $orbit, 6, i:582063048 ]
  [ 145, Moon,    'Autonoe',             'D07',                   24264445,    $orbit, 6, i:582346680 ]
  [ 146, Moon,    'Megaclite',           'moon-A01',              24687239,    $orbit, 6, i:592493736 ]
  [ 147, Moon,    'S/2003 J2',           'D04',                   30290846,    $orbit, 6, i:726980304 ]

  [ 7,  Planet,   'Saturn',              'I07',                   1430000000,  $orbit, 0 ]
  [ 8,  Planet,   'Uranus',              'O04',                   2880000000,  $orbit, 0 ]
  [ 9,  Planet,   'Neptun',              'P04',                   4500000000,  $orbit, 0 ]
  [ 10, Planet,   'Pluto',               'D07',                   6500000000,  $orbit, 0 ]
  [ 12, Station,  'Nibiru',              'station-sphere',        10000000000, $orbit, 0, template:'Outpost' ]]

rules.dm.seedEconomy = (stellar,opts)->
  [ sid, stype, sname ] = stellar
  { level, gov } = Object.assign {level:1,gov:'AI'}, opts.occupiedBy
  l = rules.buildList.slice 0, level
  console.log 'inflating', sname, level, gov if debug
  l.forEach (t)->
    ob = opts.orbits || [500,1000,1500,2000]
    rules.stars.push [rules.lastId++,Station,"#{gov} #{sname} #{t.template}",null,ob[t.o],$orbit,sid,template:t.template]
  return

rules.dm.buildList = [
  { o:0, template:'Fortress' }
  { o:0, template:'Powerplant' }
  { o:0, template:'Mine' }
  { o:0, template:'Habitat' }
  { o:0, template:'Mine' }
  { o:1, template:'Fortress' }
  { o:1, template:'Powerplant' }
  { o:1, template:'Mine' }
  { o:1, template:'Factory' }
  { o:1, template:'Fortress' }
  { o:1, template:'Powerplant' }
  { o:1, template:'Mine' }
  { o:1, template:'Factory' }
  { o:2, template:'Fortress' }
  { o:2, template:'Powerplant' }
  { o:2, template:'Mine' }
  { o:2, template:'Factory' }
  { o:2, template:'Fortress' }
  { o:2, template:'Powerplant' }
  { o:2, template:'Mine' }
  { o:2, template:'Factory' }
  { o:2, template:'Fortress' }
  { o:2, template:'Powerplant' }
  { o:2, template:'Mine' }
  { o:2, template:'Factory' }
  { o:2, template:'Fortress' }
  { o:2, template:'Powerplant' }
  { o:2, template:'Mine' }
  { o:2, template:'Factory' }
]

rules.dm.formula = [
  {     e: H3:0.001 }
  {     e: Pu:0.01 }
  {    H2:  H:10, e:2 }
  {    H3:  H:1,  e:3 }
  {   H20:  H:.66, O:.33 }
  {   CO2:  O:.66, C:.33 }
  { Steel: Fe:.99, C:.01 }
  { CarbonNanotubes: C:1 }
  { Lasertube: C:10      }
]
