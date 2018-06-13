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

DRONES_ACTIVE = yes
DRONES_MAX    = 100
ROIDS_MAX     = 100

rules.server = ->
  rules.stats = stats = {}

  NET.on 'shipname', (msg,src) ->
    return unless typeof msg is 'string'
    return src.error '_no_handle'     unless u = src.handle
    return src.error '_no_vehicle'    unless o = u.vehicle
    s = u.db.loadout[v.tplName] || s = u.db.loadout[v.tplName] = {}
    s.name = o.name = msg

  NET.on 'inventory', (msg,src) ->
    return unless typeof msg is 'string'
    return src.error '_no_handle'     unless u = src.handle
    return src.error '_no_vehicle'    unless o = u.vehicle
    src.json inventory: switch msg
      when 'ship' then o.inventory || o.inventory = {}
      else u.db.inventory || u.db.inventory = {}
    null

  NET.on 'unlocks', (msg,src) ->
    return unless typeof msg is 'string'
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
      i = user.db.unlocks; if v = i[victim.tplName] then i[victim.tplName]++ else i[victim.tplName] = 1
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
    v.mount.map (user)->
      return unless user
      console.log '::dm', 'collect', user.db.nick, t.name
      i = user.db.unlocks
      if v = i[t.name] then i[t.name]++ else i[t.name] = 1
      null
    null

  Asteroid.autospawn max: ROIDS_MAX
  AI.autospawn max: DRONES_MAX if DRONES_ACTIVE

rules.client = ->

  NUU.on 'ship:spawn', (ship) ->
    ship.reset()

  NET.on 'stats', (v) -> for id, stat of v
    notice 5000, stat.name + " K: #{stat.k} D: #{stat.d}"

rules.stars = [
  [ 0,   Star,    'Sol',                 'orange05',              0,           $fixed ]
  [ 20,  Station, 'Hades Bootcamp',      'station-battlestation', 1000,        $orbit, 0 ]

  [ 1,   Planet,  'Mercury',             'A01',                   58000000,    $orbit, 0 ]
  [ 2,   Planet,  'Venus',               'A02',                   108000000,   $orbit, 0 ]

  [ 3,   Planet,  'Earth',               'M00',                   149600000,   $orbit, 0 ]
  [ 30,  Moon,    'Moon',                'moon-M01',              375000,      $orbit, 3, produces:Fe:true ]
  [ 31,  Station, 'UEG Agriculture-01',  'station-agriculture',   1000,        $orbit, 3 ]
  [ 32,  Station, 'UEG Battlestation-01','station-battlestation', 2000,        $orbit, 3 ]
  [ 33,  Station, 'UEG Commerce-01',     'station-commerce',      3000,        $orbit, 3 ]
  [ 34,  Station, 'UEG Commerce-02',     'station-commerce2',     4000,        $orbit, 3 ]
  [ 35,  Station, 'UEG Commerce-03',     'station-commerce3',     5000,        $orbit, 3 ]
  [ 36,  Station, 'UEG Cylinder-01',     'station-cylinder',      6000,        $orbit, 3 ]
  [ 37,  Station, 'UEG Fleetbase-01',    'station-fleetbase',     7000,        $orbit, 3 ]
  [ 38,  Station, 'UEG Fleetbase-02',    'station-fleetbase2',    11000,       $orbit, 3 ]
  [ 39,  Station, 'UEG Fleetbase-03',    'station-fleetbase3',    12000,       $orbit, 3 ]
  [ 40,  Station, 'UEG Powerplant-01',   'station-powerplant',    13000,       $orbit, 3 ]
  [ 41,  Station, 'UEG Shipyard-01',     'station-shipyard',      14000,       $orbit, 3 ]
  [ 42,  Station, 'UEG Shipyard-02',     'station-shipyard2',     15000,       $orbit, 3 ]

  [ 5,   Planet,  'Mars',                'K04',                   228000000,   $orbit, 0 ]

  [ 6,   Planet,  'Jupiter',             'J01',                   778500000,   $orbit, 0, produces:e:50 ]
  [ 60,  Moon,    "Metis",               'moon-M01',              127690,      $orbit, 6, i:7.1472222222 ]
  [ 61,  Moon,    "Adrastea",            'moon-I01',              128690,      $orbit, 6, i:7.2333333333 ]
  [ 62,  Moon,    "Amalthea",            'moon-P02',              181366,      $orbit, 6, i:12.0138888889 ]
  [ 63,  Moon,    "Thebe",               'moon-P00',              221889,      $orbit, 6, i:16.2305555556 ]
  [ 64,  Moon,    "Io",                  'M05',                   421700,      $orbit, 6, i:10120800, produces:farmland:true ]
  [ 65,  Moon,    "Europa",              'M02',                   671034,      $orbit, 6, i:16104816 ]
  [ 66,  Moon,    "Ganymede",            'A04',                   1070412,     $orbit, 6, i:25689888 ]
  [ 67,  Moon,    "Callisto",            'C00',                   1882709,     $orbit, 6, i:45185016 ]
  [ 68,  Moon,    "Themisto",            'moon-I01',              7393216,     $orbit, 6, i:177437184 ]
  [ 69,  Moon,    "Leda",                'moon-X00',              11187781,    $orbit, 6, i:268506744 ]
  [ 70,  Moon,    "Himalia",             'moon-P03',              11451971,    $orbit, 6, i:274847304 ]
  [ 71,  Moon,    "Lysithea",            'D06',                   11740560,    $orbit, 6, i:281773440 ]
  [ 72,  Moon,    "Elara",               'D06',                   11778034,    $orbit, 6, i:282672816 ]
  [ 73,  Moon,    "S/2000 J11",          'D07',                   12570424,    $orbit, 6, i:301690176 ]
  [ 74,  Moon,    "Carpo",               'D06',                   17144873,    $orbit, 6, i:411476952 ]
  [ 75,  Moon,    "S/2003 J12",          'D03',                   17739539,    $orbit, 6, i:425748936 ]
  [ 76,  Moon,    "Euporie",             'D04',                   19088434,    $orbit, 6, i:458122416 ]
  [ 77,  Moon,    "S/2003 J3",           'D04',                   19621780,    $orbit, 6, i:470922720 ]
  [ 78,  Moon,    "S/2003 J18",          'D04',                   19812577,    $orbit, 6, i:475501848 ]
  [ 79,  Moon,    "S/2011 J1",           'D03',                   20165290,    $orbit, 6, i:483726960 ]
  [ 80,  Moon,    "S/2010 J2",           'D03',                   20307150,    $orbit, 6, i:487371600 ]
  [ 81,  Moon,    "Thelxinoe",           'D04',                   20453753,    $orbit, 6, i:490890072 ]
  [ 82,  Moon,    "Euanthe",             'D06',                   20464854,    $orbit, 6, i:491156496 ]
  [ 83,  Moon,    "Helike",              'D07',                   20540266,    $orbit, 6, i:492966384 ]
  [ 84,  Moon,    "Orthosie",            'D04',                   20567971,    $orbit, 6, i:493631304 ]
  [ 85,  Moon,    "Iocaste",             'moon-A01',              20722566,    $orbit, 6, i:497341584 ]
  [ 86,  Moon,    "S/2003 J16",          'D04',                   20743779,    $orbit, 6, i:497850696 ]
  [ 87,  Moon,    "Praxidike",           'moon-A00',              20823948,    $orbit, 6, i:499774752 ]
  [ 88,  Moon,    "Harpalyke",           'D07',                   21063814,    $orbit, 6, i:505531536 ]
  [ 89,  Moon,    "Mneme",               'D04',                   21129786,    $orbit, 6, i:507114864 ]
  [ 90,  Moon,    "Hermippe",            'D07',                   21182086,    $orbit, 6, i:508370064 ]
  [ 91,  Moon,    "Thyone",              'D07',                   21405570,    $orbit, 6, i:513733680 ]
  [ 92,  Moon,    "Ananke",              'D06',                   640,         $orbit, 6, i:15369.12  ]
  [ 93,  Moon,    "Herse",               'D04',                   22134306,    $orbit, 6, i:531223344 ]
  [ 94,  Moon,    "Aitne",               'D06',                   22285161,    $orbit, 6, i:534843864 ]
  [ 95,  Moon,    "Kale",                'D04',                   22409207,    $orbit, 6, i:537820968 ]
  [ 96,  Moon,    "Taygete",             'moon-A01',              22438648,    $orbit, 6, i:538527552 ]
  [ 97,  Moon,    "S/2003 J19",          'D04',                   22709061,    $orbit, 6, i:545017464 ]
  [ 98,  Moon,    "Chaldene",            'D07',                   22713444,    $orbit, 6, i:545122656 ]
  [ 99,  Moon,    "S/2003 J15",          'D04',                   22720999,    $orbit, 6, i:545303976 ]
  [ 100, Moon,    "S/2003 J10",          'D04',                   22730813,    $orbit, 6, i:545539512 ]
  [ 101, Moon,    "S/2003 J23",          'D04',                   22739654,    $orbit, 6, i:545751696 ]
  [ 102, Moon,    "Erinome",             'D06',                   22986266,    $orbit, 6, i:551670384 ]
  [ 103, Moon,    "Aoede",               'D07',                   23044175,    $orbit, 6, i:553060200 ]
  [ 104, Moon,    "Kallichore",          'D04',                   23111823,    $orbit, 6, i:554683752 ]
  [ 105, Moon,    "Kalyke",              'moon-A01',              23180773,    $orbit, 6, i:556338552 ]
  [ 106, Moon,    "Carme",               'moon-M02',              23197992,    $orbit, 6, i:556751808 ]
  [ 107, Moon,    "Callirrhoe",          'moon-M03',              23214986,    $orbit, 6, i:557159664 ]
  [ 108, Moon,    "Eurydome",            'D06',                   23230858,    $orbit, 6, i:557540592 ]
  [ 109, Moon,    "S/2011 J2",           'D03',                   23329710,    $orbit, 6, i:559913040 ]
  [ 110, Moon,    "Pasithee",            'D04',                   23307318,    $orbit, 6, i:559375632 ]
  [ 111, Moon,    "S/2010 J1",           'D04',                   23314335,    $orbit, 6, i:559544040 ]
  [ 112, Moon,    "Kore",                'D04',                   23345093,    $orbit, 6, i:560282232 ]
  [ 113, Moon,    "Cyllene",             'D04',                   23396269,    $orbit, 6, i:561510456 ]
  [ 114, Moon,    "Eukelade",            'D07',                   23483694,    $orbit, 6, i:563608656 ]
  [ 115, Moon,    "S/2003 J4",           'D04',                   23570790,    $orbit, 6, i:565698960 ]
  [ 116, Moon,    "Pasiphae",            'D06',                   23609042,    $orbit, 6, i:566617008 ]
  [ 117, Moon,    "Hegemone",            'D06',                   23702511,    $orbit, 6, i:568860264 ]
  [ 118, Moon,    "Arche",               'D06',                   23717051,    $orbit, 6, i:569209224 ]
  [ 119, Moon,    "Isonoe",              'D07',                   23800647,    $orbit, 6, i:571215528 ]
  [ 120, Moon,    "S/2003 J9",           'D03',                   23857808,    $orbit, 6, i:572587392 ]
  [ 121, Moon,    "S/2003 J5",           'D07',                   23973926,    $orbit, 6, i:575374224 ]
  [ 122, Moon,    "Sinope",              'D03',                   24057865,    $orbit, 6, i:577388760 ]
  [ 123, Moon,    "Sponde",              'D04',                   24252627,    $orbit, 6, i:582063048 ]
  [ 124, Moon,    "Autonoe",             'D07',                   24264445,    $orbit, 6, i:582346680 ]
  [ 125, Moon,    "Megaclite",           'moon-A01',              24687239,    $orbit, 6, i:592493736 ]
  [ 126, Moon,    "S/2003 J2",           'D04',                   30290846,    $orbit, 6, i:726980304 ]

  [ 7,  Planet,   'Saturn',              'I07',                   1430000000,  $orbit, 0 ]
  [ 8,  Planet,   'Uranus',              'O04',                   2880000000,  $orbit, 0 ]
  [ 9,  Planet,   'Neptun',              'P04',                   4500000000,  $orbit, 0 ]
  [ 10, Planet,   'Pluto',               'D07',                   6500000000,  $orbit, 0 ]
  [ 12, Planet,   'Nibiru',              'station-sphere',        10000000000, $orbit, 0 ]]
