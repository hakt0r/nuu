###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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

module.exports = (destinationFile,callback)->
  cp     = require 'child_process'
  ref    = cp.execSync('git log --pretty=format:"%H"').toString('utf8').split('\n')
  msg    = cp.execSync('git log --pretty=format:"%s"').toString('utf8').split('\n')
  date   = cp.execSync('git log --pretty=format:"%d"').toString('utf8').split('\n')
  author = cp.execSync('git log --pretty=format:"%a"').toString('utf8').split('\n')
  head = ref[0]
  release = {}; current = null
  adds = msg
    .filter (i,k,s)-> not i.match /^[0-9]+\.[0-9]+\.[0-9]+/
    .filter (i,k,s)-> k is s.indexOf i
  msg  .map (i,k,s)-> if i.match /^[0-9]+\.[0-9]+\.[0-9]+/
    release[v = i.substr 0,6] = x = v: v
    x.m = i.substr(6).replace(/     /g,'\n     ')
    x.a = author[v]
    x.d = date[v]
    unless current
      current = x
      if adds.length > 0
        x.v += '+'
        x.m += '\n     ' + adds.join(' (from master)\n     ') + ' (from master)'
      x.m = x.m.split('\n').sort( (a,b)->
        a.charCodeAt(5) - b.charCodeAt(5) ).join('\n').substr(6)
  current.git = head
  fs.writeFileSync path.join(path.dirname(destinationFile),'release.json'), JSON.stringify current
  callback null
  # console.log head, current.v, current.m
  # for k,v of release
  # process.exit 1
  # callback null
