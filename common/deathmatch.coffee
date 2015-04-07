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

DRONES_ACTIVE = yes
DRONES_MAX    = 1
ROIDS_MAX     = 100

rules.server = ->
  rules.stats = stats = {}

  NUU.on 'playerJoined', (p) ->
    stats[p.vehicle.id] = name : p.name, k:0, d:0
    console.log 'new player', p.name, stats

  NUU.on 'playerLeft', (p) ->
    delete stats[p.vehicle.id]

  NUU.on 'ship:hit', (ship,src) ->
    NET.mods.write ship, 'hit', ship.shield, ship.armour

  NUU.on 'ship:destroyed', (victim,perp) ->
    NET.mods.write victim, 'destroyed', victim.id
    if victim.npc is yes then $timeout 10000, ->
      victim.dropLoot()
      victim.destructor()
    else
      stats[victim.id].d++
      console.log victim.name.red, stats[victim.id].d
      $timeout 10000, ->
        victim.dropLoot()
        victim.respawn()
    unless perp.npc is yes
      stats[perp.id].k++
      console.log perp.name.green, stats[perp.id].k
    NUU.jsoncast stats: stats

  Asteroid.autospawn max: ROIDS_MAX
  Drone.autospawn max: DRONES_MAX if DRONES_ACTIVE

rules.client = ->

  NUU.on 'ship:spawn', (ship) ->
    ship.reset()

  NET.on 'stats', (v) -> for id, stat of v
    notice 5000, stat.name + " K: #{stat.k} D: #{stat.d}"

rules.stars = [
  [ 0,   'Sol',                 'yellow02',              0,           $fixed ]
  [ 20,  'Hades Bootcamp',      'station-battlestation', 1000000,     $orbit, 0 ]

  [ 1,   'Mercury',             'A01',                   58000000,    $orbit, 0 ]
  [ 2,   'Venus',               'A02',                   108000000,   $orbit, 0 ]

  [ 3,   'Earth',               'M00',                   149600000,   $orbit, 0 ]
  [ 30,  'Moon',                'moon-M01',              375000,      $orbit, 3 ]
  [ 31,  'UEG Agriculture-01',  'station-agriculture',   400,         $orbit, 3 ]
  [ 32,  'UEG Battlestation-01','station-battlestation', 500,         $orbit, 3 ]
  [ 33,  'UEG Commerce-01',     'station-commerce',      600,         $orbit, 3 ]
  [ 34,  'UEG Commerce-02',     'station-commerce2',     700,         $orbit, 3 ]
  [ 35,  'UEG Commerce-03',     'station-commerce3',     800,         $orbit, 3 ]
  [ 36,  'UEG Cylinder-01',     'station-cylinder',      900,         $orbit, 3 ]
  [ 37,  'UEG Fleetbase-01',    'station-fleetbase',     1000,        $orbit, 3 ]
  [ 38,  'UEG Fleetbase-02',    'station-fleetbase2',    1100,        $orbit, 3 ]
  [ 39,  'UEG Fleetbase-03',    'station-fleetbase3',    1200,        $orbit, 3 ]
  [ 40,  'UEG Powerplant-01',   'station-powerplant',    1300,        $orbit, 3 ]
  [ 41,  'UEG Shipyard-01',     'station-shipyard',      1400,        $orbit, 3 ]
  [ 42,  'UEG Shipyard-02',     'station-shipyard2',     1500,        $orbit, 3 ]

  [ 5,   'Mars',                'K04',                   228000000,   $orbit, 0 ]

  [ 6,   'Jupiter',             'J01',                   778500000,   $orbit, 0 ]
  [ 60,  "Metis",               'moon-M01',              127690,      $orbit, 6, 7.1472222222 ]
  [ 61,  "Adrastea",            'moon-I01',              128690,      $orbit, 6, 7.2333333333 ]
  [ 62,  "Amalthea",            'moon-P02',              181366,      $orbit, 6, 12.0138888889 ]
  [ 63,  "Thebe",               'moon-P00',              221889,      $orbit, 6, 16.2305555556 ]
  [ 64,  "Io",                  'M05',                   421700,      $orbit, 6, 10120800 ]
  [ 65,  "Europa",              'M02',                   671034,      $orbit, 6, 16104816 ]
  [ 66,  "Ganymede",            'A04',                   1070412,     $orbit, 6, 25689888 ]
  [ 67,  "Callisto",            'C00',                   1882709,     $orbit, 6, 45185016 ]
  [ 68,  "Themisto",            'moon-I01',              7393216,     $orbit, 6, 177437184 ]
  [ 69,  "Leda",                'moon-X00',              11187781,    $orbit, 6, 268506744 ]
  [ 70,  "Himalia",             'moon-P03',              11451971,    $orbit, 6, 274847304 ]
  [ 71,  "Lysithea",            'D06',                   11740560,    $orbit, 6, 281773440 ]
  [ 72,  "Elara",               'D06',                   11778034,    $orbit, 6, 282672816 ]
  [ 73,  "S/2000 J11",          'D07',                   12570424,    $orbit, 6, 301690176 ]
  [ 74,  "Carpo",               'D06',                   17144873,    $orbit, 6, 411476952 ]
  [ 75,  "S/2003 J12",          'D03',                   17739539,    $orbit, 6, 425748936 ]
  [ 76,  "Euporie",             'D04',                   19088434,    $orbit, 6, 458122416 ]
  [ 77,  "S/2003 J3",           'D04',                   19621780,    $orbit, 6, 470922720 ]
  [ 78,  "S/2003 J18",          'D04',                   19812577,    $orbit, 6, 475501848 ]
  [ 79,  "S/2011 J1",           'D03',                   20155290,    $orbit, 6, 483726960 ]
  [ 80,  "S/2010 J2",           'D03',                   20307150,    $orbit, 6, 487371600 ]
  [ 81,  "Thelxinoe",           'D04',                   20453753,    $orbit, 6, 490890072 ]
  [ 82,  "Euanthe",             'D06',                   20464854,    $orbit, 6, 491156496 ]
  [ 83,  "Helike",              'D07',                   20540266,    $orbit, 6, 492966384 ]
  [ 84,  "Orthosie",            'D04',                   20567971,    $orbit, 6, 493631304 ]
  [ 85,  "Iocaste",             'moon-A01',              20722566,    $orbit, 6, 497341584 ]
  [ 86,  "S/2003 J16",          'D04',                   20743779,    $orbit, 6, 497850696 ]
  [ 87,  "Praxidike",           'moon-A00',              20823948,    $orbit, 6, 499774752 ]
  [ 88,  "Harpalyke",           'D07',                   21063814,    $orbit, 6, 505531536 ]
  [ 89,  "Mneme",               'D04',                   21129786,    $orbit, 6, 507114864 ]
  [ 90,  "Hermippe",            'D07',                   21182086,    $orbit, 6, 508370064 ]
  [ 91,  "Thyone",              'D07',                   21405570,    $orbit, 6, 513733680 ]
  [ 92,  "Ananke",              'D06',                   640,         $orbit, 6, 15369.12  ]
  [ 93,  "Herse",               'D04',                   22134306,    $orbit, 6, 531223344 ]
  [ 94,  "Aitne",               'D06',                   22285161,    $orbit, 6, 534843864 ]
  [ 95,  "Kale",                'D04',                   22409207,    $orbit, 6, 537820968 ]
  [ 96,  "Taygete",             'moon-A01',              22438648,    $orbit, 6, 538527552 ]
  [ 97,  "S/2003 J19",          'D04',                   22709061,    $orbit, 6, 545017464 ]
  [ 98,  "Chaldene",            'D07',                   22713444,    $orbit, 6, 545122656 ]
  [ 99,  "S/2003 J15",          'D04',                   22720999,    $orbit, 6, 545303976 ]
  [ 100, "S/2003 J10",          'D04',                   22730813,    $orbit, 6, 545539512 ]
  [ 101, "S/2003 J23",          'D04',                   22739654,    $orbit, 6, 545751696 ]
  [ 102, "Erinome",             'D06',                   22986266,    $orbit, 6, 551670384 ]
  [ 103, "Aoede",               'D07',                   23044175,    $orbit, 6, 553060200 ]
  [ 104, "Kallichore",          'D04',                   23111823,    $orbit, 6, 554683752 ]
  [ 105, "Kalyke",              'moon-A01',              23180773,    $orbit, 6, 556338552 ]
  [ 106, "Carme",               'moon-M02',              23197992,    $orbit, 6, 556751808 ]
  [ 107, "Callirrhoe",          'moon-M03',              23214986,    $orbit, 6, 557159664 ]
  [ 108, "Eurydome",            'D06',                   23230858,    $orbit, 6, 557540592 ]
  [ 109, "S/2011 J2",           'D03',                   23329710,    $orbit, 6, 559913040 ]
  [ 110, "Pasithee",            'D04',                   23307318,    $orbit, 6, 559375632 ]
  [ 111, "S/2010 J1",           'D04',                   23314335,    $orbit, 6, 559544040 ]
  [ 112, "Kore",                'D04',                   23345093,    $orbit, 6, 560282232 ]
  [ 113, "Cyllene",             'D04',                   23396269,    $orbit, 6, 561510456 ]
  [ 114, "Eukelade",            'D07',                   23483694,    $orbit, 6, 563608656 ]
  [ 115, "S/2003 J4",           'D04',                   23570790,    $orbit, 6, 565698960 ]
  [ 116, "Pasiphae",            'D06',                   23609042,    $orbit, 6, 566617008 ]
  [ 117, "Hegemone",            'D06',                   23702511,    $orbit, 6, 568860264 ]
  [ 118, "Arche",               'D06',                   23717051,    $orbit, 6, 569209224 ]
  [ 119, "Isonoe",              'D07',                   23800647,    $orbit, 6, 571215528 ]
  [ 120, "S/2003 J9",           'D03',                   23857808,    $orbit, 6, 572587392 ]
  [ 121, "S/2003 J5",           'D07',                   23973926,    $orbit, 6, 575374224 ]
  [ 122, "Sinope",              'D03',                   24057865,    $orbit, 6, 577388760 ]
  [ 123, "Sponde",              'D04',                   24252627,    $orbit, 6, 582063048 ]
  [ 124, "Autonoe",             'D07',                   24264445,    $orbit, 6, 582346680 ]
  [ 125, "Megaclite",           'moon-A01',              24687239,    $orbit, 6, 592493736 ]
  [ 126, "S/2003 J2",           'D04',                   30290846,    $orbit, 6, 726980304 ]

  [ 7,  'Saturn',               'I07',                   1430000000,  $orbit, 0 ]
  [ 8,  'Uranus',               'O04',                   2880000000,  $orbit, 0 ]
  [ 9,  'Neptun',               'P04',                   4500000000,  $orbit, 0 ]
  [ 10, 'Pluto',                'D07',                   6500000000,  $orbit, 0 ]
  [ 12, 'Nibiru',               'station-sphere',        10000000000, $orbit, 0 ]]
