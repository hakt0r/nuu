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

parseNumbers = (o)->
  for k,v of o when v?
    if v.match and v.match /^-?[.0-9]+$/
      o[k] = if -1 is v.indexOf '.' then parseInt(v) else parseFloat v
    else if typeof v is 'object'
      parseNumbers v
  o

String::clearItemName = -> @replace /[^a-zA-Z]/g , ''

module.exports = (destinationFile,callback)->
  fs   = require 'fs'
  xml  = require 'x2js'
  path = require 'path'
  np   = path.join GAME_DIR, 'contrib', 'naev-master', 'dat'
  nu   = path.join GAME_DIR, 'build'

  ship  = []
  outf  = []
  src   = {}
  wait  = {}
  first = {}
  meta  = {}

  readDir  = (dir,call) -> call f for f in fs.readdirSync dir
  parseDir = (dir,call) -> for f in fs.readdirSync dir
    txt = fs.readFileSync dir + f, 'utf8'
    x = new xml
    d = parseNumbers x.xml2js txt
    call f,d

  flatten = (d) ->
    # join specific and general into stats
    specific = d.specific; delete d.specific
    general  = d.general;  delete d.general

    d.stats  = {}
    d.info   = {}
    d.stats[k] = v for k,v of specific
    d.stats[k] = v for k,v of general

    # from root to info
    for k in ['license','fabricator','name','price','description'] when d[k]?
      d.info[k] = d[k]
      delete d[k]

    # from stats to info
    for k in ['description','gfx_store','price','name','license'] when d.stats[k]?
      d.info[k] = d.stats[k]
      delete d.stats[k]

    # from stats.damage to stats
    if d.stats.damage?
      d.stats[k] = v for k,v of d.stats.damage
      delete d.stats.damage

    # from stats.range to stats
    if d.stats.range?
      d.stats[k] = v for k,v of d.stats.range
      delete d.stats.range

    # from stats to root
    for k in ['size','turret','slot','type'] when d.stats[k]?
      d[k] = d.stats[k]
      delete d.stats[k]

    # from stats to sprite
    d.fx = {}
    for k in ['gfx','gfx_end','spfx_armour','spfx_shield','sound','sound_hit','sound_off'] when d.stats[k]?
      d.fx[k] = d.stats[k]
      delete d.stats[k]
    d.fx.sound = d.sound; delete d.sound
    if d.fx.gfx
      d.sprite = d.fx.gfx
      delete d.fx.gfx

    delete d.fx.sound if d.fx? and not d.fx.sound
    unless Object.keys(d.fx).length > 0
      delete d.fx

    if not d.sprite and ( p = d ).type is 'ship'
      while p = src[p.extends]
        if p.sprite?
          d.sprite = p.sprite; break
        else console.log '\\', p.name, p.sprite?, d.sprite
    return d

  ###
    Ship conversion
  ###

  readShip = (f,d) ->
    d = d.ship
    d.name = d._name; delete d._name
    className = d.name.clearItemName()
    d.extends = if d.base_type isnt d.name then d.base_type else 'Ship'
    src[className] = d

    delete d.base_type
    delete d.GUI     if d.GUI
    delete d.mission if d.mission
    for t,slots of d.slots
      d.slots[t] = [slots] unless Array.isArray slots
      for k,v of slots
        slots[k] = n = {}
        if v.__text
          n.default = v.__text.clearItemName()
          delete v.__text
        for kk,vv of v
          n[kk.replace /^_+/, ''] = vv
    if d.GFX?
      if d.GFX._sx?
        meta[sprite = d.GFX.__text] = cols:d.GFX._sx,rows:d.GFX._sy
      else meta[sprite = d.GFX] = cols:8,rows:8
      meta[sprite+'_engine'] = meta[sprite]
      delete d.GFX

    d.type = 'ship'
    flatten d
    d.sprite = sprite
    d.stats[k] = v for k,v of d.characteristics; delete d.characteristics
    d.stats[k] = v for k,v of d.health;          delete d.health
    d.name = className

    d.class = 'ship'
    ship.push d

  ###
    Outfit conversion
  ###

  readOutfit = (f,d) ->
    d = d.outfit
    d.name = d._name; delete d._name
    src[className = d.name.clearItemName()] = d
    try d.specific.type  = d.specific._type;  delete d.specific._type
    try d.specific.group = d.specific._group; delete d.specific._group
    t = d.specific.type
    d.specific.turret = t.match('turret') isnt null
    if      ['license','map','localmap','gui'].indexOf(t)           isnt -1 then return
    else if ['bolt','turret bolt'].indexOf(t)                       isnt -1 then d.extends = 'Projectile'
    else if ['beam','turret beam'].indexOf(t)                       isnt -1 then d.extends = 'Beam'
    else if ['missile','fighter','ammo'].indexOf(t)                 isnt -1 then d.extends = 'Ammo'
    else if ['launcher','turret launcher','fighter bay'].indexOf(t) isnt -1 then d.extends = 'Launcher'
    else d.extends = 'Outfit'
    d.type = 'outfit'
    flatten d
    d.stats.ship = d.stats.ship.clearItemName() if d.stats and d.stats.ship
    d.stats.ammo = d.stats.ammo.clearItemName() if d.stats and d.stats.ammo
    try d.stats.blowup   = d.stats._blowup;   delete d.stats._blowup
    d.name = className
    d.class = 'outfit'
    if typeof d.slot is 'object'
      d.prop = d.slot._prop
      d.slot = d.slot.__text
    meta[d.sprite] = 'outf' unless meta[d.sprite]?
    outf.push d

  parseDir np + '/ships/', readShip
  readDir np + '/outfits/', (folder) ->
    parseDir np + '/outfits/'+folder+'/', readOutfit

  fs.writeFileSync destinationFile, JSON.stringify ship.concat outf

  ###
    update metadata
  ###
  anim = ['cargo','debris0','debris1','debris2','debris3','debris4','debris5','empm','emps','expl2','expl','expm2','expm','exps','plam2','plam','plas2','plas','shim','shis']

  list = {}
  read = (dir)-> for file in fs.readdirSync dir
    p = dir + '/' + file
    if fs.statSync(p).isDirectory()
     read p; continue
    continue unless file.match /\.(png|jpg|gif)$/
    f = path.basename(p).replace(/\..*$/,'')
    n = if p.match('/store/') then f + '_store' else f
    s = fast_image_size p
    k = path.basename(p).replace(/\..*?$/,'')
    d = if null is ( p.match('/gfx/') || p.match('/imag/') ) then 6 else 1
    r = meta[k] || {}
    if r is 'outf' or -1 isnt anim.indexOf k
      d = 6
      r = {}
    r.cols = r.cols || d
    r.rows = r.rows || d
    unless r.width
      r.width  = s.width
      r.height = s.height
    r.size   = Math.floor Math.max r.width / r.cols, r.height / r.rows
    r.radius = Math.floor r.size / 2
    # console.log '@', p, n, r if p.match /cargo/
    list[n] = r
  read 'build'
  fs.writeFileSync path.join( GAME_DIR,'build','imag','sprites_naev.json' ), JSON.stringify parseNumbers list

  callback null
