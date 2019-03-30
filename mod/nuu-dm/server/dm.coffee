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

  Miner.max  = 100
  Trader.max = 200
  Drone.max  = 100

  AI.autospawn() if DRONES_ACTIVE

  NUU.emit 'rules', rules

rules.dm.stars = [
  [ 0,   Star,    'Sol',                 'orange05',              0,           $fixed ]
  [ 1,   Planet,  'Mercury',             'A01',                   58000000,    $orbit, 0 ]
  [ 2,   Planet,  'Venus',               'A02',                   108000000,   $orbit, 0 ]
  [ 3,   Planet,  'Earth',               'M00',                   149600000,   $orbit, 0, provides:{O2:1000,H20:1000,Pu:10,Fe:100,Farmland:1000},occupiedBy:{gov:'AI',level:15} ]
  [ 4,   Moon,    'Moon',                'moon-M01',              375000,      $orbit, 3, provides:{Fe:1000,H3:1000},occupiedBy:{gov:'US',level:6} ]
  [ 5,   Planet,  'Mars',                'K04',                   228000000,   $orbit, 0, provides:{Fe:1000,H3:1000},occupiedBy:gov:'US',level:9 ]
  [ 6,   Planet,  'Jupiter',             'J01',                   778500000,   $orbit, 0, provides:{e:50,H:1000,H2:500,H3:30,CH4:1,H20:1,NH3:1,Si:1,Ne:1},orbits:[640,1280,1920,2560],occupiedBy:{gov:'US',level:20} ]
  [ 7,   Planet,  'Saturn',              'I07',                   1430000000,  $orbit, 0 ]
  [ 8,   Planet,  'Uranus',              'O04',                   2880000000,  $orbit, 0 ]
  [ 9,   Planet,  'Neptun',              'P04',                   4500000000,  $orbit, 0 ]
  [ 10,  Planet,  'Pluto',               'D07',                   6500000000,  $orbit, 0 ]

  [ 11,  Station, 'Serenity',            'station-battlestation', 1000,        $orbit, 0, template:'Fortress' ]
  [ 12,  Station, 'Nibiru',              'station-sphere',        10000000000, $orbit, 0, template:'Outpost' ]
  [ 13,  Planet,  'Testa'     ,          'A01',                   2300000,     $orbit, 0 ]

  [ 20,  Moon,    'Phobos',              'D04',                   9380,        $orbit, 5, i:0]
  [ 21,  Moon,    'Deimos',              'D04',                   23460,       $orbit, 5, i:0]

  [ 30,  Moon,    'Ananke',              'D06',                   640,         $orbit, 6, i:15369.12 ]
  [ 31,  Moon,    'Metis',               'moon-M01',              127690,      $orbit, 6, i:7.1472222222 ]
  [ 32,  Moon,    'Adrastea',            'moon-I01',              128690,      $orbit, 6, i:7.2333333333 ]
  [ 33,  Moon,    'Amalthea',            'moon-P02',              181366,      $orbit, 6, i:12.0138888889 ]
  [ 34,  Moon,    'Thebe',               'moon-P00',              221889,      $orbit, 6, i:16.2305555556 ]
  [ 35,  Moon,    'Io',                  'M05',                   421700,      $orbit, 6, i:10120800,provides:{Farmland:1000,H2O:1000,Fe:100,O2:100},occupiedBy:{gov:'US',level:10} ]
  [ 36,  Moon,    'Europa',              'M02',                   671034,      $orbit, 6, i:16104816,provides:{Fe:1000},occupiedBy:{gov:'US',level:15} ]
  [ 37,  Moon,    'Ganymede',            'A04',                   1070412,     $orbit, 6, i:25689888,provides:{Fe:1000},occupiedBy:{gov:'US',level:10} ]
  [ 38,  Moon,    'Callisto',            'C00',                   1882709,     $orbit, 6, i:45185016 ]
  [ 39,  Moon,    'Themisto',            'moon-I01',              7393216,     $orbit, 6, i:177437184 ]
  [ 40,  Moon,    'Leda',                'moon-X00',              11187781,    $orbit, 6, i:268506744 ]
  [ 41,  Moon,    'Himalia',             'moon-P03',              11451971,    $orbit, 6, i:274847304 ]
  [ 42,  Moon,    'Lysithea',            'D06',                   11740560,    $orbit, 6, i:281773440 ]
  [ 43,  Moon,    'Elara',               'D06',                   11778034,    $orbit, 6, i:282672816 ]
  [ 44,  Moon,    'S/2000 J11',          'D07',                   12570424,    $orbit, 6, i:301690176 ]
  [ 45,  Moon,    'Carpo',               'D06',                   17144873,    $orbit, 6, i:411476952 ]
  [ 46,  Moon,    'S/2003 J12',          'D03',                   17739539,    $orbit, 6, i:425748936 ]
  [ 47,  Moon,    'Euporie',             'D04',                   19088434,    $orbit, 6, i:458122416 ]
  [ 48,  Moon,    'S/2003 J3',           'D04',                   19621780,    $orbit, 6, i:470922720 ]
  [ 49,  Moon,    'S/2003 J18',          'D04',                   19812577,    $orbit, 6, i:475501848 ]
  [ 50,  Moon,    'S/2011 J1',           'D03',                   20165290,    $orbit, 6, i:483726960 ]
  [ 51,  Moon,    'S/2010 J2',           'D03',                   20307150,    $orbit, 6, i:487371600 ]
  [ 52,  Moon,    'Thelxinoe',           'D04',                   20453753,    $orbit, 6, i:490890072 ]
  [ 53,  Moon,    'Euanthe',             'D06',                   20464854,    $orbit, 6, i:491156496 ]
  [ 54,  Moon,    'Helike',              'D07',                   20540266,    $orbit, 6, i:492966384 ]
  [ 55,  Moon,    'Orthosie',            'D04',                   20567971,    $orbit, 6, i:493631304 ]
  [ 56,  Moon,    'Iocaste',             'moon-A01',              20722566,    $orbit, 6, i:497341584 ]
  [ 57,  Moon,    'S/2003 J16',          'D04',                   20743779,    $orbit, 6, i:497850696 ]
  [ 58,  Moon,    'Praxidike',           'moon-A00',              20823948,    $orbit, 6, i:499774752 ]
  [ 59,  Moon,    'Harpalyke',           'D07',                   21063814,    $orbit, 6, i:505531536 ]
  [ 60,  Moon,    'Mneme',               'D04',                   21129786,    $orbit, 6, i:507114864 ]
  [ 61,  Moon,    'Hermippe',            'D07',                   21182086,    $orbit, 6, i:508370064 ]
  [ 62,  Moon,    'Thyone',              'D07',                   21405570,    $orbit, 6, i:513733680 ]
  [ 64,  Moon,    'Herse',               'D04',                   22134306,    $orbit, 6, i:531223344 ]
  [ 65,  Moon,    'Aitne',               'D06',                   22285161,    $orbit, 6, i:534843864 ]
  [ 66,  Moon,    'Kale',                'D04',                   22409207,    $orbit, 6, i:537820968 ]
  [ 67,  Moon,    'Taygete',             'moon-A01',              22438648,    $orbit, 6, i:538527552 ]
  [ 68,  Moon,    'S/2003 J19',          'D04',                   22709061,    $orbit, 6, i:545017464 ]
  [ 69,  Moon,    'Chaldene',            'D07',                   22713444,    $orbit, 6, i:545122656 ]
  [ 70,  Moon,    'S/2003 J15',          'D04',                   22720999,    $orbit, 6, i:545303976 ]
  [ 71,  Moon,    'S/2003 J10',          'D04',                   22730813,    $orbit, 6, i:545539512 ]
  [ 72,  Moon,    'S/2003 J23',          'D04',                   22739654,    $orbit, 6, i:545751696 ]
  [ 73,  Moon,    'Erinome',             'D06',                   22986266,    $orbit, 6, i:551670384 ]
  [ 74,  Moon,    'Aoede',               'D07',                   23044175,    $orbit, 6, i:553060200 ]
  [ 75,  Moon,    'Kallichore',          'D04',                   23111823,    $orbit, 6, i:554683752 ]
  [ 76,  Moon,    'Kalyke',              'moon-A01',              23180773,    $orbit, 6, i:556338552 ]
  [ 77,  Moon,    'Carme',               'moon-M02',              23197992,    $orbit, 6, i:556751808 ]
  [ 78,  Moon,    'Callirrhoe',          'moon-M03',              23214986,    $orbit, 6, i:557159664 ]
  [ 79,  Moon,    'Eurydome',            'D06',                   23230858,    $orbit, 6, i:557540592 ]
  [ 80,  Moon,    'S/2011 J2',           'D03',                   23329710,    $orbit, 6, i:559913040 ]
  [ 81,  Moon,    'Pasithee',            'D04',                   23307318,    $orbit, 6, i:559375632 ]
  [ 82,  Moon,    'S/2010 J1',           'D04',                   23314335,    $orbit, 6, i:559544040 ]
  [ 83,  Moon,    'Kore',                'D04',                   23345093,    $orbit, 6, i:560282232 ]
  [ 84,  Moon,    'Cyllene',             'D04',                   23396269,    $orbit, 6, i:561510456 ]
  [ 85,  Moon,    'Eukelade',            'D07',                   23483694,    $orbit, 6, i:563608656 ]
  [ 86,  Moon,    'S/2003 J4',           'D04',                   23570790,    $orbit, 6, i:565698960 ]
  [ 87,  Moon,    'Pasiphae',            'D06',                   23609042,    $orbit, 6, i:566617008 ]
  [ 88,  Moon,    'Hegemone',            'D06',                   23702511,    $orbit, 6, i:568860264 ]
  [ 89,  Moon,    'Arche',               'D06',                   23717051,    $orbit, 6, i:569209224 ]
  [ 90,  Moon,    'Isonoe',              'D07',                   23800647,    $orbit, 6, i:571215528 ]
  [ 91,  Moon,    'S/2003 J9',           'D03',                   23857808,    $orbit, 6, i:572587392 ]
  [ 92,  Moon,    'S/2003 J5',           'D07',                   23973926,    $orbit, 6, i:575374224 ]
  [ 93,  Moon,    'Sinope',              'D03',                   24057865,    $orbit, 6, i:577388760 ]
  [ 94,  Moon,    'Sponde',              'D04',                   24252627,    $orbit, 6, i:582063048 ]
  [ 95,  Moon,    'Autonoe',             'D07',                   24264445,    $orbit, 6, i:582346680 ]
  [ 96,  Moon,    'Megaclite',           'moon-A01',              24687239,    $orbit, 6, i:592493736 ]
  [ 97,  Moon,    'S/2003 J2',           'D04',                   30290846,    $orbit, 6, i:726980304 ]

  [ 100, Moon,    'Mimas',               'D01',                   185540,      $orbit, 7, i:0]
  [ 101, Moon,    'Enceladus',           'D05',                   238040,      $orbit, 7, i:0]
  [ 102, Moon,    'Tethys',              'D05',                   294670,      $orbit, 7, i:0]
  [ 103, Moon,    'Dione',               'D05',                   377420,      $orbit, 7, i:0]
  [ 104, Moon,    'Rhea',                'D05',                   527070,      $orbit, 7, i:0]
  [ 105, Moon,    'Titan',               'D04',                   1221870,     $orbit, 7, i:0]
  [ 106, Moon,    'Hyperion',            'D01',                   1500880,     $orbit, 7, i:0]
  [ 107, Moon,    'Iapetus',             'D02',                   3560840,     $orbit, 7, i:0]
  [ 108, Moon,    'Phoebe',              'D02',                   12947780,    $orbit, 7, i:0]
  [ 109, Moon,    'Janus',               'D02',                   151460,      $orbit, 7, i:0]
  [ 110, Moon,    'Epimetheus',          'D05',                   151410,      $orbit, 7, i:0]
  [ 111, Moon,    'Helene',              'D04',                   377420,      $orbit, 7, i:0]
  [ 112, Moon,    'Telesto',             'D04',                   294710,      $orbit, 7, i:0]
  [ 113, Moon,    'Calypso',             'D05',                   294710,      $orbit, 7, i:0]
  [ 114, Moon,    'Atlas',               'D02',                   137670,      $orbit, 7, i:0]
  [ 115, Moon,    'Prometheus',          'D05',                   139380,      $orbit, 7, i:0]
  [ 116, Moon,    'Pandora',             'D04',                   141720,      $orbit, 7, i:0]
  [ 117, Moon,    'Pan',                 'D03',                   133580,      $orbit, 7, i:0]
  [ 118, Moon,    'Ymir',                'D05',                   23140400,    $orbit, 7, i:0]
  [ 119, Moon,    'Paaliaq',             'D04',                   15200000,    $orbit, 7, i:0]
  [ 120, Moon,    'Tarvos',              'D05',                   17983000,    $orbit, 7, i:0]
  [ 121, Moon,    'Ijiraq',              'D02',                   11124000,    $orbit, 7, i:0]
  [ 122, Moon,    'Suttungr',            'D01',                   19459000,    $orbit, 7, i:0]
  [ 123, Moon,    'Kiviuq',              'D01',                   11110000,    $orbit, 7, i:0]
  [ 124, Moon,    'Mundilfari',          'D02',                   18628000,    $orbit, 7, i:0]
  [ 125, Moon,    'Albiorix',            'D04',                   16182000,    $orbit, 7, i:0]
  [ 126, Moon,    'Skathi',              'D02',                   15540000,    $orbit, 7, i:0]
  [ 127, Moon,    'Erriapus',            'D03',                   17343000,    $orbit, 7, i:0]
  [ 128, Moon,    'Siarnaq',             'D01',                   18015400,    $orbit, 7, i:0]
  [ 129, Moon,    'Thrymr',              'D05',                   20314000,    $orbit, 7, i:0]
  [ 130, Moon,    'Narvi',               'D03',                   19007000,    $orbit, 7, i:0]
  [ 131, Moon,    'Methone',             'D01',                   194440,      $orbit, 7, i:0]
  [ 132, Moon,    'Pallene',             'D04',                   212280,      $orbit, 7, i:0]
  [ 133, Moon,    'Polydeuces',          'D03',                   377200,      $orbit, 7, i:0]
  [ 134, Moon,    'Daphnis',             'D02',                   136500,      $orbit, 7, i:0]
  [ 135, Moon,    'Aegir',               'D05',                   20751000,    $orbit, 7, i:0]
  [ 136, Moon,    'Bebhionn',            'D01',                   17119000,    $orbit, 7, i:0]
  [ 137, Moon,    'Bergelmir',           'D03',                   19336000,    $orbit, 7, i:0]
  [ 138, Moon,    'Bestla',              'D04',                   20192000,    $orbit, 7, i:0]
  [ 139, Moon,    'Farbauti',            'D05',                   20377000,    $orbit, 7, i:0]
  [ 140, Moon,    'Fenrir',              'D01',                   22454000,    $orbit, 7, i:0]
  [ 141, Moon,    'Fornjot',             'D03',                   25146000,    $orbit, 7, i:0]
  [ 142, Moon,    'Hati',                'D03',                   19846000,    $orbit, 7, i:0]
  [ 143, Moon,    'Hyrrokkin',           'D01',                   18437000,    $orbit, 7, i:0]
  [ 144, Moon,    'Kari',                'D05',                   22089000,    $orbit, 7, i:0]
  [ 145, Moon,    'Loge',                'D04',                   23058000,    $orbit, 7, i:0]
  [ 146, Moon,    'Skoll',               'D01',                   17665000,    $orbit, 7, i:0]
  [ 147, Moon,    'Surtur',              'D05',                   22704000,    $orbit, 7, i:0]
  [ 148, Moon,    'Anthe',               'D01',                   197700,      $orbit, 7, i:0]
  [ 149, Moon,    'Jarnsaxa',            'D05',                   18811000,    $orbit, 7, i:0]
  [ 150, Moon,    'Greip',               'D03',                   18206000,    $orbit, 7, i:0]
  [ 151, Moon,    'Tarqeq',              'D02',                   18009000,    $orbit, 7, i:0]
  [ 152, Moon,    'Aegaeon',             'D03',                   167500,      $orbit, 7, i:0]
  [ 153, Moon,    'S/2004 S 7',          'D05',                   20999000,    $orbit, 7, i:0]
  [ 154, Moon,    'S/2004 S 12',         'D03',                   19878000,    $orbit, 7, i:0]
  [ 155, Moon,    'S/2004 S 13',         'D04',                   18404000,    $orbit, 7, i:0]
  [ 156, Moon,    'S/2004 S 17',         'D05',                   19447000,    $orbit, 7, i:0]
  [ 157, Moon,    'S/2006 S 1',          'D01',                   18790000,    $orbit, 7, i:0]
  [ 158, Moon,    'S/2006 S 3',          'D04',                   22096000,    $orbit, 7, i:0]
  [ 159, Moon,    'S/2007 S 2',          'D01',                   16725000,    $orbit, 7, i:0]
  [ 160, Moon,    'S/2007 S 3',          'D05',                   18975000,    $orbit, 7, i:0]
  [ 161, Moon,    'S/2009 S 1',          'D01',                   117000,      $orbit, 7, i:0]

  [ 170, Moon,    'Ariel',               'D03',                   190900,      $orbit, 8, i:0]
  [ 171, Moon,    'Umbriel',             'D01',                   266000,      $orbit, 8, i:0]
  [ 172, Moon,    'Titania',             'D05',                   436300,      $orbit, 8, i:0]
  [ 173, Moon,    'Oberon',              'D05',                   583500,      $orbit, 8, i:0]
  [ 174, Moon,    'Miranda',             'D02',                   129900,      $orbit, 8, i:0]
  [ 175, Moon,    'Cordelia',            'D01',                   49800,       $orbit, 8, i:0]
  [ 176, Moon,    'Ophelia',             'D04',                   53800,       $orbit, 8, i:0]
  [ 177, Moon,    'Bianca',              'D05',                   59200,       $orbit, 8, i:0]
  [ 178, Moon,    'Cressida',            'D02',                   61800,       $orbit, 8, i:0]
  [ 179, Moon,    'Desdemona',           'D01',                   62700,       $orbit, 8, i:0]
  [ 180, Moon,    'Juliet',              'D05',                   64400,       $orbit, 8, i:0]
  [ 181, Moon,    'Portia',              'D01',                   66100,       $orbit, 8, i:0]
  [ 182, Moon,    'Rosalind',            'D01',                   69900,       $orbit, 8, i:0]
  [ 183, Moon,    'Belinda',             'D01',                   75300,       $orbit, 8, i:0]
  [ 184, Moon,    'Puck',                'D04',                   86000,       $orbit, 8, i:0]
  [ 185, Moon,    'Caliban',             'D03',                   7231100,     $orbit, 8, i:0]
  [ 186, Moon,    'Sycorax',             'D05',                   12179400,    $orbit, 8, i:0]
  [ 187, Moon,    'Prospero',            'D01',                   16256000,    $orbit, 8, i:0]
  [ 188, Moon,    'Setebos',             'D04',                   17418000,    $orbit, 8, i:0]
  [ 189, Moon,    'Stephano',            'D04',                   8004000,     $orbit, 8, i:0]
  [ 190, Moon,    'Trinculo',            'D03',                   8504000,     $orbit, 8, i:0]
  [ 191, Moon,    'Francisco',           'D01',                   4276000,     $orbit, 8, i:0]
  [ 192, Moon,    'Margaret',            'D01',                   14345000,    $orbit, 8, i:0]
  [ 193, Moon,    'Ferdinand',           'D02',                   20901000,    $orbit, 8, i:0]
  [ 194, Moon,    'Perdita',             'D02',                   76417,       $orbit, 8, i:0]
  [ 195, Moon,    'Mab',                 'D05',                   97736,       $orbit, 8, i:0]
  [ 196, Moon,    'Cupid',               'D02',                   74392,       $orbit, 8, i:0]
  [ 197, Moon,    'Triton',              'D02',                   354800,      $orbit, 8, i:0]
  [ 198, Moon,    'Nereid',              'D05',                   5513820,     $orbit, 8, i:0]
  [ 199, Moon,    'Naiad',               'D03',                   48224,       $orbit, 8, i:0]
  [ 200, Moon,    'Thalassa',            'D02',                   50075,       $orbit, 8, i:0]
  [ 201, Moon,    'Despina',             'D05',                   52526,       $orbit, 8, i:0]
  [ 202, Moon,    'Galatea',             'D05',                   61953,       $orbit, 8, i:0]
  [ 203, Moon,    'Larissa',             'D04',                   73548,       $orbit, 8, i:0]
  [ 204, Moon,    'Proteus',             'D01',                   117647,      $orbit, 8, i:0]
  [ 205, Moon,    'Halimede',            'D04',                   15728000,    $orbit, 8, i:0]
  [ 206, Moon,    'Psamathe',            'D04',                   46695000,    $orbit, 8, i:0]
  [ 207, Moon,    'Sao',                 'D04',                   22422000,    $orbit, 8, i:0]
  [ 208, Moon,    'Laomedeia',           'D05',                   23571000,    $orbit, 8, i:0]
  [ 209, Moon,    'Neso',                'D02',                   48387000,    $orbit, 8, i:0]
  [ 210, Moon,    'Hippocamp',           'D01',                   105283,      $orbit, 8, i:0]

  [ 220, Moon,    'Charon',              'D01',                   19591,       $orbit, 10,i:0]
  [ 221, Moon,    'Nix',                 'D02',                   48671,       $orbit, 10,i:0]
  [ 222, Moon,    'Hydra',               'D01',                   64698,       $orbit, 10,i:0]
  [ 223, Moon,    'Kerberos',            'D01',                   57729,       $orbit, 10,i:0]
  [ 224, Moon,    'Styx',                'D02',                   42393,       $orbit, 10,i:0]]

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
