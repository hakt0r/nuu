###

  * c) 2007-2020 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2020 flyc0r

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

module.exports = (destinationFile,callback)->
  fs = require 'fs'
  o = '<ul class="libs">'
  d = JSON.parse fs.readFileSync 'package.json', 'utf8'
  for lib, data of TARGETS.client.contrib
    o += """
      <li><a target="_new" href="#{data.homepage}">#{data.name} (build/#{lib})</a><span class="version">master/git<span></li>
    """
  for k in fs.readdirSync 'node_modules'
    if fs.existsSync 'node_modules/' + k + '/package.json'
      rec = JSON.parse fs.readFileSync 'node_modules/' + k + '/package.json'
      v = rec.version
    else if d.dependencies[k] then v = d.dependencies[k]
    else continue
    o += """<li><a target="_new" href="https://www.npmjs.com/package/#{k}">#{k}</a>"""
    o += """<span class="version">#{v}</span>"""
    # o += """<span class="description">#{rec.description}</span>""" if rec.description
    o += "</li>"
  o += '</ul>'
  fs.writeFileSync destinationFile, o
  callback null
