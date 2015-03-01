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

$obj.register class Asteroid extends $obj
  @interfaces: [$obj,Shootable,Debris,Asteroid]

  constructor: (opts) -> if opts then super else
    id = @size - 10
    id = '0' + id if id < 10
    r = 0.8 + random()/5
    phi = random()*TAU
    super
      sprite: 'asteroid-D' + id
      resource: []
      size: max 10, floor random() * 73
      state:
        S: $orbit
        orbit: sqrt(r) * cos(phi) * 7000000000
        relto: 0

  @autospawn: (opts={})-> $worker.push =>
    roids  = @list.length
    if roids < opts.max
      dt = opts.max - roids
      new Asteroid for i in [0...dt]
    1000
