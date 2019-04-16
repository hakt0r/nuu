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

  if DRONES_ACTIVE and not process.env.NOAI
    Miner.max  = 100
    Trader.max = 333
    Drone.max  = 100
    AI.autospawn()
  else Miner.max = Trader.max = Drone.max  = 0

  NUU.emit 'rules', rules

rules.dm.stars = [
  # The Planets
  [ 0,   Star,    'Sol',                 'orange05',              0,           $fixed ]
  [ 1,   Planet,  'Mercury',             'A01',                   58000000,    $orbit, 0, t:2112 ]
  [ 2,   Planet,  'Venus',               'A02',                   108000000,   $orbit, 0, t:5400 ]
  [ 3,   Planet,  'Earth',               'M00',                   149600000,   $orbit, 0, t:8760, provides:{O2:1000,H20:1000,Pu:10,Fe:100,Farmland:1000},occupiedBy:{gov:'AI',level:15} ]
  [ 4,   Moon,    'Moon',                'moon-M01',              375000,      $orbit, 3, t:648, provides:{Fe:1000,H3:1000},occupiedBy:{gov:'US',level:6} ]
  [ 5,   Planet,  'Mars',                'K04',                   228000000,   $orbit, 0, t:16488, provides:{Fe:1000,H3:1000},occupiedBy:gov:'US',level:9 ]
  [ 6,   Planet,  'Jupiter',             'J01',                   778500000,   $orbit, 0, t:105120,  provides:{e:50,H:1000,H2:500,H3:30,CH4:1,H20:1,NH3:1,Si:1,Ne:1},orbits:[640,1280,1920,2560],occupiedBy:{gov:'US',level:20} ]
  [ 7,   Planet,  'Saturn',              'I07',                   1430000000,  $orbit, 0, t:254040 ]
  [ 8,   Planet,  'Uranus',              'O04',                   2880000000,  $orbit, 0, t:735840 ]
  [ 9,   Planet,  'Neptun',              'P04',                   4500000000,  $orbit, 0, t:1445400 ]
  [ 10,  Planet,  'Pluto',               'D07',                   6500000000,  $orbit, 0, t:2172480 ]
  # SciFi
  [ 11,  Station, 'Serenity',            'station-battlestation', 1000,        $orbit, 0, template:'Fortress' ]
  [ 12,  Station, 'Nibiru',              'station-sphere',        10000000000, $orbit, 0, template:'Outpost' ]
  [ 13,  Planet,  'Testa'     ,          'A01',                   2300000,     $orbit, 0 ]
  # Moons of Mars
  [ 20,  Moon,    'Phobos',              'D04',                   9380,        $orbit, 5, t:0]
  [ 21,  Moon,    'Deimos',              'D04',                   23460,       $orbit, 5, t:0]
  # Moons of Jupiter
  [ 30,  Moon,    'Metis',               'moon-M01',              127690,      $orbit, 6,  d:60,   m:3.6,      t:7,       i:0.06,    e:0.0002 ]
  [ 31,  Moon,    'Adrastea',            'moon-I01',              129000,      $orbit, 6,  d:20,   m:0.2,      t:7,       i:0.03,    e:0.0015 ]
  [ 32,  Moon,    'Amalthea',            'moon-P02',              181366,      $orbit, 6,  d:250,  m:208,      t:12,      i:0.374,   e:0.0032 ]
  [ 33,  Moon,    'Thebe',               'moon-P00',              221889,      $orbit, 6,  d:116,  m:43,       t:16,      i:1.076,   e:0.0175 ]
  [ 34,  Moon,    'Io',                  'M05',                   421700,      $orbit, 6,  d:3660, m:8900000,  t:42,      i:0.05,    e:0.0041, provides:{Farmland:1000,H2O:1000,Fe:100,O2:100},occupiedBy:{gov:'US',level:10} ]
  [ 35,  Moon,    'Europa',              'M02',                   671034,      $orbit, 6,  d:3121, m:4800000,  t:85,      i:0.471,   e:0.0094, provides:{Fe:1000},occupiedBy:{gov:'US',level:15} ]
  [ 36,  Moon,    'Ganymede',            'A04',                   1070412,     $orbit, 6,  d:5262, m:15000000, t:171,     i:0.204,   e:0.0011, provides:{Fe:1000},occupiedBy:{gov:'US',level:10} ]
  [ 37,  Moon,    'Callisto',            'C00',                   1882709,     $orbit, 6,  d:4820, m:11000000, t:400,     i:0.205,   e:0.0074 ]
  [ 38,  Moon,    'Themisto',            'moon-I01',              7393216,     $orbit, 6,  d:8,    m:0.069,    t:3116,    i:45.762,  e:0.2115 ]
  [ 39,  Moon,    'Leda',                'moon-X00',              11187781,    $orbit, 6,  d:16,   m:0.6,      t:5802,    i:27.562,  e:0.1673 ]
  [ 40,  Moon,    'Himalia',             'moon-P03',              11451971,    $orbit, 6,  d:170,  m:670,      t:6008,    i:30.486,  e:0.1513 ]
  [ 41,  Moon,    'Lysithea',            'D06',                   11740560,    $orbit, 6,  d:36,   m:6.3,      t:6237,    i:27.006,  e:0.1322 ]
  [ 42,  Moon,    'Elara',               'D06',                   11778034,    $orbit, 6,  d:86,   m:87,       t:6267,    i:29.691,  e:0.1948 ]
  [ 43,  Moon,    'Dia',                 'D07',                   12570424,    $orbit, 6,  d:4,    m:0.009,    t:6910,    i:27.584,  e:0.2058 ]
  [ 44,  Moon,    'Carpo',               'D06',                   17144873,    $orbit, 6,  d:3,    m:0.0045,   t:11006,   i:56.001,  e:0.2735 ]
  [ 45,  Moon,    'S/2003 J12',          'D03',                   17739539,    $orbit, 6,  d:1,    m:0.00015,  t:-11584,  i:142.68,  e:0.4449 ]
  [ 46,  Moon,    'Euporie',             'D04',                   19088434,    $orbit, 6,  d:2,    m:0.0015,   t:-12930,  i:144.694, e:0.096 ]
  [ 47,  Moon,    'S/2003 J3',           'D04',                   19621780,    $orbit, 6,  d:2,    m:0.0015,   t:-13476,  i:146.363, e:0.2507 ]
  [ 48,  Moon,    'S/2003 J18',          'D04',                   19812577,    $orbit, 6,  d:2,    m:0.0015,   t:-13673,  i:147.401, e:0.1569 ]
  [ 49,  Moon,    'Jupiter LII',         'D03',                   20307150,    $orbit, 6,  d:1,    m:0,        t:14366,   i:150.4,   e:0 ]
  [ 50,  Moon,    'Thelxinoe',           'D04',                   20453753,    $orbit, 6,  d:2,    m:0.0015,   t:-14342,  i:151.292, e:0.2684 ]
  [ 51,  Moon,    'Euanthe',             'D06',                   20464854,    $orbit, 6,  d:3,    m:0.0045,   t:-14354,  i:143.409, e:0.2 ]
  [ 52,  Moon,    'Helike',              'D07',                   20540266,    $orbit, 6,  d:4,    m:0.009,    t:-14433,  i:154.586, e:0.1374 ]
  [ 53,  Moon,    'Orthosie',            'D04',                   20567971,    $orbit, 6,  d:2,    m:0.0015,   t:-14462,  i:142.366, e:0.2433 ]
  [ 54,  Moon,    'Iocaste',             'moon-A01',              20722566,    $orbit, 6,  d:5,    m:0.019,    t:-14626,  i:147.248, e:0.2874 ]
  [ 55,  Moon,    'S/2003 J16',          'D04',                   20743779,    $orbit, 6,  d:2,    m:0.0015,   t:-14648,  i:150.769, e:0.3184 ]
  [ 56,  Moon,    'Praxidike',           'moon-A00',              20823948,    $orbit, 6,  d:7,    m:0.043,    t:-14733,  i:144.205, e:0.184 ]
  [ 57,  Moon,    'Harpalyke',           'D07',                   21063814,    $orbit, 6,  d:4,    m:0.012,    t:-14988,  i:147.223, e:0.244 ]
  [ 58,  Moon,    'Mneme',               'D04',                   21129786,    $orbit, 6,  d:2,    m:0.0015,   t:-15059,  i:149.732, e:0.3169 ]
  [ 59,  Moon,    'Hermippe',            'D07',                   21182086,    $orbit, 6,  d:4,    m:0.009,    t:-15115,  i:151.242, e:0.229 ]
  [ 60,  Moon,    'Thyone',              'D07',                   21405570,    $orbit, 6,  d:4,    m:0.009,    t:-15355,  i:147.276, e:0.2525 ]
  [ 61,  Moon,    'Ananke',              'D06',                   21454952,    $orbit, 6,  d:28,   m:3,        t:-15408,  i:151.564, e:0.3445 ]
  [ 62,  Moon,    'Herse',               'D04',                   22134306,    $orbit, 6,  d:2,    m:0.0015,   t:-16146,  i:162.49,  e:0.2379 ]
  [ 63,  Moon,    'Aitne',               'D06',                   22285161,    $orbit, 6,  d:3,    m:0.0045,   t:-16311,  i:165.562, e:0.3927 ]
  [ 64,  Moon,    'Kale',                'D04',                   22409207,    $orbit, 6,  d:2,    m:0.0015,   t:-16447,  i:165.378, e:0.2011 ]
  [ 65,  Moon,    'Taygete',             'moon-A01',              22438648,    $orbit, 6,  d:5,    m:0.016,    t:-16480,  i:164.89,  e:0.3678 ]
  [ 66,  Moon,    'S/2003 J19',          'D04',                   22709061,    $orbit, 6,  d:2,    m:0.0015,   t:-16778,  i:164.727, e:0.1961 ]
  [ 67,  Moon,    'Chaldene',            'D07',                   22713444,    $orbit, 6,  d:4,    m:0.0075,   t:-16783,  i:167.07,  e:0.2916 ]
  [ 68,  Moon,    'S/2003 J15',          'D04',                   22720999,    $orbit, 6,  d:2,    m:0.0015,   t:-16792,  i:141.812, e:0.0932 ]
  [ 69,  Moon,    'S/2003 J10',          'D04',                   22730813,    $orbit, 6,  d:2,    m:0.0015,   t:-16803,  i:163.813, e:0.3438 ]
  [ 70,  Moon,    'S/2003 J23',          'D04',                   22739654,    $orbit, 6,  d:2,    m:0.0015,   t:-16812,  i:148.849, e:0.393 ]
  [ 71,  Moon,    'Erinome',             'D06',                   22986266,    $orbit, 6,  d:3,    m:0.0045,   t:-17087,  i:163.737, e:0.2552 ]
  [ 72,  Moon,    'Aoede',               'D07',                   23044175,    $orbit, 6,  d:4,    m:0.009,    t:-17151,  i:160.482, e:0.6011 ]
  [ 73,  Moon,    'Kallichore',          'D04',                   23111823,    $orbit, 6,  d:2,    m:0.0015,   t:-17227,  i:164.605, e:0.2041 ]
  [ 74,  Moon,    'Kalyke',              'moon-A01',              23180773,    $orbit, 6,  d:5,    m:0.019,    t:-17304,  i:165.505, e:0.2139 ]
  [ 75,  Moon,    'Carme',               'moon-M02',              23197992,    $orbit, 6,  d:46,   m:13,       t:-17323,  i:165.047, e:0.2342 ]
  [ 76,  Moon,    'Callirrhoe',          'moon-M03',              23214986,    $orbit, 6,  d:9,    m:0.087,    t:-17342,  i:139.849, e:0.2582 ]
  [ 77,  Moon,    'Eurydome',            'D06',                   23230858,    $orbit, 6,  d:3,    m:0.0045,   t:-17360,  i:149.324, e:0.3769 ]
  [ 78,  Moon,    'Pasithee',            'D04',                   23307318,    $orbit, 6,  d:2,    m:0.0015,   t:-17446,  i:165.759, e:0.3288 ]
  [ 79,  Moon,    'Jupiter LI',          'D04',                   23314335,    $orbit, 6,  d:2,    m:0,        t:4606802, i:163.2,   e:0.320 ]
  [ 80,  Moon,    'Kore',                'D04',                   23345093,    $orbit, 6,  d:2,    m:0.0015,   t:-18624,  i:137.371, e:0.1951 ]
  [ 81,  Moon,    'Cyllene',             'D04',                   23396269,    $orbit, 6,  d:2,    m:0.0015,   t:-17546,  i:140.148, e:0.4115 ]
  [ 82,  Moon,    'Eukelade',            'D07',                   23483694,    $orbit, 6,  d:4,    m:0.009,    t:-17644,  i:163.996, e:0.2828 ]
  [ 83,  Moon,    'S/2003 J4',           'D04',                   23570790,    $orbit, 6,  d:2,    m:0.0015,   t:-17742,  i:147.175, e:0.3003 ]
  [ 84,  Moon,    'Pasiphae',            'D06',                   23609042,    $orbit, 6,  d:60,   m:30,       t:-17786,  i:141.803, e:0.3743 ]
  [ 85,  Moon,    'Hegemone',            'D06',                   23702511,    $orbit, 6,  d:3,    m:0.0045,   t:-17892,  i:152.506, e:0.4077 ]
  [ 86,  Moon,    'Arche',               'D06',                   23717051,    $orbit, 6,  d:3,    m:0.0045,   t:-17908,  i:164.587, e:0.1492 ]
  [ 87,  Moon,    'Isonoe',              'D07',                   23800647,    $orbit, 6,  d:4,    m:0.0075,   t:-18003,  i:165.127, e:0.1775 ]
  [ 88,  Moon,    'S/2003 J9',           'D03',                   23857808,    $orbit, 6,  d:1,    m:0.00015,  t:-18068,  i:164.98,  e:0.2761 ]
  [ 89,  Moon,    'S/2003 J5',           'D07',                   23973926,    $orbit, 6,  d:4,    m:0.009,    t:-18200,  i:165.549, e:0.307 ]
  [ 90,  Moon,    'Sinope',              'D03',                   24057865,    $orbit, 6,  d:38,   m:7.5,      t:-18295,  i:153.778, e:0.275 ]
  [ 91,  Moon,    'Sponde',              'D04',                   24252627,    $orbit, 6,  d:2,    m:0.0015,   t:-18518,  i:154.372, e:0.4431 ]
  [ 92,  Moon,    'Autonoe',             'D07',                   24264445,    $orbit, 6,  d:4,    m:0.009,    t:-18532,  i:151.058, e:0.369 ]
  [ 93,  Moon,    'Megaclite',           'moon-A01',              24687239,    $orbit, 6,  d:5,    m:0.021,    t:-19018,  i:150.398, e:0.3077 ]
  [ 94,  Moon,    'S/2003 J2',           'D04',                   30290846,    $orbit, 6,  d:2,    m:0.0015,   t:-25848,  i:153.521, e:0.1882 ]
  # Moons of Saturn
  [ 100, Moon,    'Mimas',               'D01',                   185540,      $orbit, 7, t:0]
  [ 101, Moon,    'Enceladus',           'D05',                   238040,      $orbit, 7, t:0]
  [ 102, Moon,    'Tethys',              'D05',                   294670,      $orbit, 7, t:0]
  [ 103, Moon,    'Dione',               'D05',                   377420,      $orbit, 7, t:0]
  [ 104, Moon,    'Rhea',                'D05',                   527070,      $orbit, 7, t:0]
  [ 105, Moon,    'Titan',               'D04',                   1221870,     $orbit, 7, t:0]
  [ 106, Moon,    'Hyperion',            'D01',                   1500880,     $orbit, 7, t:0]
  [ 107, Moon,    'Iapetus',             'D02',                   3560840,     $orbit, 7, t:0]
  [ 108, Moon,    'Phoebe',              'D02',                   12947780,    $orbit, 7, t:0]
  [ 109, Moon,    'Janus',               'D02',                   151460,      $orbit, 7, t:0]
  [ 110, Moon,    'Epimetheus',          'D05',                   151410,      $orbit, 7, t:0]
  [ 111, Moon,    'Helene',              'D04',                   377420,      $orbit, 7, t:0]
  [ 112, Moon,    'Telesto',             'D04',                   294710,      $orbit, 7, t:0]
  [ 113, Moon,    'Calypso',             'D05',                   294710,      $orbit, 7, t:0]
  [ 114, Moon,    'Atlas',               'D02',                   137670,      $orbit, 7, t:0]
  [ 115, Moon,    'Prometheus',          'D05',                   139380,      $orbit, 7, t:0]
  [ 116, Moon,    'Pandora',             'D04',                   141720,      $orbit, 7, t:0]
  [ 117, Moon,    'Pan',                 'D03',                   133580,      $orbit, 7, t:0]
  [ 118, Moon,    'Ymir',                'D05',                   23140400,    $orbit, 7, t:0]
  [ 119, Moon,    'Paaliaq',             'D04',                   15200000,    $orbit, 7, t:0]
  [ 120, Moon,    'Tarvos',              'D05',                   17983000,    $orbit, 7, t:0]
  [ 121, Moon,    'Ijiraq',              'D02',                   11124000,    $orbit, 7, t:0]
  [ 122, Moon,    'Suttungr',            'D01',                   19459000,    $orbit, 7, t:0]
  [ 123, Moon,    'Kiviuq',              'D01',                   11110000,    $orbit, 7, t:0]
  [ 124, Moon,    'Mundilfari',          'D02',                   18628000,    $orbit, 7, t:0]
  [ 125, Moon,    'Albiorix',            'D04',                   16182000,    $orbit, 7, t:0]
  [ 126, Moon,    'Skathi',              'D02',                   15540000,    $orbit, 7, t:0]
  [ 127, Moon,    'Erriapus',            'D03',                   17343000,    $orbit, 7, t:0]
  [ 128, Moon,    'Siarnaq',             'D01',                   18015400,    $orbit, 7, t:0]
  [ 129, Moon,    'Thrymr',              'D05',                   20314000,    $orbit, 7, t:0]
  [ 130, Moon,    'Narvi',               'D03',                   19007000,    $orbit, 7, t:0]
  [ 131, Moon,    'Methone',             'D01',                   194440,      $orbit, 7, t:0]
  [ 132, Moon,    'Pallene',             'D04',                   212280,      $orbit, 7, t:0]
  [ 133, Moon,    'Polydeuces',          'D03',                   377200,      $orbit, 7, t:0]
  [ 134, Moon,    'Daphnis',             'D02',                   136500,      $orbit, 7, t:0]
  [ 135, Moon,    'Aegir',               'D05',                   20751000,    $orbit, 7, t:0]
  [ 136, Moon,    'Bebhionn',            'D01',                   17119000,    $orbit, 7, t:0]
  [ 137, Moon,    'Bergelmir',           'D03',                   19336000,    $orbit, 7, t:0]
  [ 138, Moon,    'Bestla',              'D04',                   20192000,    $orbit, 7, t:0]
  [ 139, Moon,    'Farbauti',            'D05',                   20377000,    $orbit, 7, t:0]
  [ 140, Moon,    'Fenrir',              'D01',                   22454000,    $orbit, 7, t:0]
  [ 141, Moon,    'Fornjot',             'D03',                   25146000,    $orbit, 7, t:0]
  [ 142, Moon,    'Hati',                'D03',                   19846000,    $orbit, 7, t:0]
  [ 143, Moon,    'Hyrrokkin',           'D01',                   18437000,    $orbit, 7, t:0]
  [ 144, Moon,    'Kari',                'D05',                   22089000,    $orbit, 7, t:0]
  [ 145, Moon,    'Loge',                'D04',                   23058000,    $orbit, 7, t:0]
  [ 146, Moon,    'Skoll',               'D01',                   17665000,    $orbit, 7, t:0]
  [ 147, Moon,    'Surtur',              'D05',                   22704000,    $orbit, 7, t:0]
  [ 148, Moon,    'Anthe',               'D01',                   197700,      $orbit, 7, t:0]
  [ 149, Moon,    'Jarnsaxa',            'D05',                   18811000,    $orbit, 7, t:0]
  [ 150, Moon,    'Greip',               'D03',                   18206000,    $orbit, 7, t:0]
  [ 151, Moon,    'Tarqeq',              'D02',                   18009000,    $orbit, 7, t:0]
  [ 152, Moon,    'Aegaeon',             'D03',                   167500,      $orbit, 7, t:0]
  [ 153, Moon,    'S/2004 S 7',          'D05',                   20999000,    $orbit, 7, t:0]
  [ 154, Moon,    'S/2004 S 12',         'D03',                   19878000,    $orbit, 7, t:0]
  [ 155, Moon,    'S/2004 S 13',         'D04',                   18404000,    $orbit, 7, t:0]
  [ 156, Moon,    'S/2004 S 17',         'D05',                   19447000,    $orbit, 7, t:0]
  [ 157, Moon,    'S/2006 S 1',          'D01',                   18790000,    $orbit, 7, t:0]
  [ 158, Moon,    'S/2006 S 3',          'D04',                   22096000,    $orbit, 7, t:0]
  [ 159, Moon,    'S/2007 S 2',          'D01',                   16725000,    $orbit, 7, t:0]
  [ 160, Moon,    'S/2007 S 3',          'D05',                   18975000,    $orbit, 7, t:0]
  [ 161, Moon,    'S/2009 S 1',          'D01',                   117000,      $orbit, 7, t:0]
  # Moons of Uranus
  [ 170, Moon,    'Ariel',               'D03',                   190900,      $orbit, 8, t:0]
  [ 171, Moon,    'Umbriel',             'D01',                   266000,      $orbit, 8, t:0]
  [ 172, Moon,    'Titania',             'D05',                   436300,      $orbit, 8, t:0]
  [ 173, Moon,    'Oberon',              'D05',                   583500,      $orbit, 8, t:0]
  [ 174, Moon,    'Miranda',             'D02',                   129900,      $orbit, 8, t:0]
  [ 175, Moon,    'Cordelia',            'D01',                   49800,       $orbit, 8, t:0]
  [ 176, Moon,    'Ophelia',             'D04',                   53800,       $orbit, 8, t:0]
  [ 177, Moon,    'Bianca',              'D05',                   59200,       $orbit, 8, t:0]
  [ 178, Moon,    'Cressida',            'D02',                   61800,       $orbit, 8, t:0]
  [ 179, Moon,    'Desdemona',           'D01',                   62700,       $orbit, 8, t:0]
  [ 180, Moon,    'Juliet',              'D05',                   64400,       $orbit, 8, t:0]
  [ 181, Moon,    'Portia',              'D01',                   66100,       $orbit, 8, t:0]
  [ 182, Moon,    'Rosalind',            'D01',                   69900,       $orbit, 8, t:0]
  [ 183, Moon,    'Belinda',             'D01',                   75300,       $orbit, 8, t:0]
  [ 184, Moon,    'Puck',                'D04',                   86000,       $orbit, 8, t:0]
  [ 185, Moon,    'Caliban',             'D03',                   7231100,     $orbit, 8, t:0]
  [ 186, Moon,    'Sycorax',             'D05',                   12179400,    $orbit, 8, t:0]
  [ 187, Moon,    'Prospero',            'D01',                   16256000,    $orbit, 8, t:0]
  [ 188, Moon,    'Setebos',             'D04',                   17418000,    $orbit, 8, t:0]
  [ 189, Moon,    'Stephano',            'D04',                   8004000,     $orbit, 8, t:0]
  [ 190, Moon,    'Trinculo',            'D03',                   8504000,     $orbit, 8, t:0]
  [ 191, Moon,    'Francisco',           'D01',                   4276000,     $orbit, 8, t:0]
  [ 192, Moon,    'Margaret',            'D01',                   14345000,    $orbit, 8, t:0]
  [ 193, Moon,    'Ferdinand',           'D02',                   20901000,    $orbit, 8, t:0]
  [ 194, Moon,    'Perdita',             'D02',                   76417,       $orbit, 8, t:0]
  [ 195, Moon,    'Mab',                 'D05',                   97736,       $orbit, 8, t:0]
  [ 196, Moon,    'Cupid',               'D02',                   74392,       $orbit, 8, t:0]
  [ 197, Moon,    'Triton',              'D02',                   354800,      $orbit, 8, t:0]
  [ 198, Moon,    'Nereid',              'D05',                   5513820,     $orbit, 8, t:0]
  [ 199, Moon,    'Naiad',               'D03',                   48224,       $orbit, 8, t:0]
  [ 200, Moon,    'Thalassa',            'D02',                   50075,       $orbit, 8, t:0]
  [ 201, Moon,    'Despina',             'D05',                   52526,       $orbit, 8, t:0]
  [ 202, Moon,    'Galatea',             'D05',                   61953,       $orbit, 8, t:0]
  [ 203, Moon,    'Larissa',             'D04',                   73548,       $orbit, 8, t:0]
  [ 204, Moon,    'Proteus',             'D01',                   117647,      $orbit, 8, t:0]
  [ 205, Moon,    'Halimede',            'D04',                   15728000,    $orbit, 8, t:0]
  [ 206, Moon,    'Psamathe',            'D04',                   46695000,    $orbit, 8, t:0]
  [ 207, Moon,    'Sao',                 'D04',                   22422000,    $orbit, 8, t:0]
  [ 208, Moon,    'Laomedeia',           'D05',                   23571000,    $orbit, 8, t:0]
  [ 209, Moon,    'Neso',                'D02',                   48387000,    $orbit, 8, t:0]
  [ 210, Moon,    'Hippocamp',           'D01',                   105283,      $orbit, 8, t:0]
  # Pluto
  [ 220, Moon,    'Charon',              'D01',                   19591,       $orbit, 10,t:0]
  [ 221, Moon,    'Nix',                 'D02',                   48671,       $orbit, 10,t:0]
  [ 222, Moon,    'Hydra',               'D01',                   64698,       $orbit, 10,t:0]
  [ 223, Moon,    'Kerberos',            'D01',                   57729,       $orbit, 10,t:0]
  [ 224, Moon,    'Styx',                'D02',                   42393,       $orbit, 10,t:0]]

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
