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
  xml  = require 'xml2json'
  path = require 'path'
  np   = path.join NUUWD, 'contrib', 'naev-master', 'dat'
  nu   = path.join NUUWD, 'build'

  ship  = []
  outf  = []
  src   = {}
  wait  = {}
  first = {}
  meta  = {}

  readDir  = (dir,call) -> call f for f in fs.readdirSync dir
  parseDir = (dir,call) -> for f in fs.readdirSync dir
    txt = fs.readFileSync dir + f, 'utf8'
    d = parseNumbers JSON.parse(xml.toJson(txt))
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
    delete d.fx unless Object.keys(d.fx).length > 0

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
    className = d.name.clearItemName()
    d.extends = if d.base_type isnt d.name then d.base_type else 'Ship'; delete d.base_type
    src[className] = d

    delete d.GUI     if d.GUI
    delete d.mission if d.mission

    for t,slots of d.slots
      d.slots[t] = [slots] unless Array.isArray slots
      for k,v of slots when v.$t
        v.default = v.$t.clearItemName()
        delete v.$t

    if d.GFX?
      if d.GFX.sx?
        meta[sprite = d.GFX.$t] = cols:d.GFX.sx,rows:d.GFX.sy
      else meta[sprite = d.GFX] = cols:8,rows:8
      meta[sprite+'_engine'] = meta[sprite]
      delete d.GFX

    d.type = 'ship'
    flatten d
    d.sprite = sprite
    d.stats[k] = v for k,v of d.characteristics; delete d.characteristics
    d.stats[k] = v for k,v of d.health;          delete d.health

    d.name = className
    ship.push d

  ###
    Outfit conversion
  ###

  readOutfit = (f,d) ->
    d = d.outfit
    src[className = d.name.clearItemName()] = d
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
    d.name = className
    outf.push d

  parseDir np + '/ships/', readShip
  readDir np + '/outfits/', (folder) ->
    parseDir np + '/outfits/'+folder+'/', readOutfit

  fs.writeFileSync destinationFile, JSON.stringify ship : ship, outf : outf

  ###
    update metadata
  ###

  list = {}
  read = (dir)-> for file in fs.readdirSync dir
    p = dir + '/' + file
    if fs.statSync(p).isDirectory()
     read p; continue
    continue unless file.match /\.(png|jpg|gif)$/
    f = path.basename(p).replace(/\..*$/,'')
    n = if p.match('/store/') then f + '_store' else f
    s = fast_image_size p
    r = meta[ k = path.basename(p).replace(/\..*?$/,'') ] || {}
    d = if null is ( p.match('/stel/') || p.match('/imag/') ) then 6 else 1
    r.cols = r.cols || d
    r.rows = r.rows || d
    unless r.width
      r.width  = s.width
      r.height = s.height
    r.size   = Math.floor Math.max r.width / r.cols, r.height / r.rows
    r.radius = Math.floor r.size / 2
    # console.log '@', n, r
    list[n] = r
  read 'build'
  fs.writeFileSync path.join( NUUWD,'build','imag','sprites_naev.json' ), JSON.stringify parseNumbers list

  callback null
