###
  :)
###

fs   = require 'fs'
xml  = require 'xml2json'
path = require 'path'
np   = path.join path.dirname(__dirname), 'contrib', 'naev-master', 'dat'
nu   = path.join path.dirname(__dirname), 'build'

ship = []
outf = []
src   = {}
wait  = {}
first = {}

readDir  = (dir,call) -> call f for f in fs.readdirSync dir
parseDir = (dir,call) -> for f in fs.readdirSync dir
  txt = fs.readFileSync dir + f, 'utf8'
  d = JSON.parse(xml.toJson(txt))
  call f,d

readShip = (f,d) ->
  d = d.ship
  d.className = d.name.replace(/[^a-zA-Z]/g,'')
  d.extends = if d.base_type isnt d.name then d.base_type else 'Ship'
  delete d.base_type
  src[d.className] = d
  delete d.GUI
  d[k] = v for k,v of d.characteristics
  delete d.characteristics
  d[k] = v for k,v of d.stats
  delete d.stats
  d[k] = v for k,v of d.health
  delete d.health
  for t,slots of d.slots
    for k,v of slots
      if v.$t
        v.default = v.$t.replace(/[^a-zA-Z]/g,'')
        delete v.$t
  delete d.mission if d.mission?
  if d.GFX?
    if d.GFX.sx?
      d.cols = d.GFX.sx
      d.rows = d.GFX.sy
      d.sprite = d.GFX.$t
    else
      d.cols = 8
      d.rows = 8
      d.sprite = d.GFX
    delete d.GFX
  ship.push d

readOutfit = (f,d) ->
  d =  d.outfit
  d.className = d.name.replace(/[^a-zA-Z]/g,'')
  t =  d.specific.type
  return if t is 'map'
  if t.match(/bolt/) then d.extends = 'Projectile'
  else if t.match(/beam/) then d.extends = 'Beam'
  else if t.match(/launcher/) then d.extends = 'Launcher'
  else if d.className.match(/Bay$/) then d.extends = 'Bay'
  else d.extends = 'Outfit'
  d.specific.turret = t.match('turret') isnt null
  delete d.specific.type
  if typeof d.specific.range is 'object'
    d.specific.range = d.specific.range
    d.specific.blowup = d.specific.range.blowup
    d.specific.range = d.specific.range.$t
  src[d.className] = d
  outf.push d

parseDir np + '/ships/', readShip
readDir np + '/outfits/', (folder) ->
  parseDir np + '/outfits/'+folder+'/', readOutfit

# renderOutfit(v,out) for k,v of src

console.log JSON.stringify ship : ship, outf : outf
