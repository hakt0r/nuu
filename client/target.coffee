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

Sprite.gameLayer 'target',
  width: 150
  height: 150
  id : 0
  type : 0
  scale : 100
  active : true
  draw : (c) ->
    wd = 150; hg = 150; hw = 75; hh = 75
    c.strokeStyle = "black"
    c.font = "10px monospace"
    return -> if (s = NUU.target) isnt null
      pl = NUU.player.vehicle
      px = Math.floor pl.x
      py = Math.floor pl.y

      s.ap_dir = Math.round((360 + (Math.atan2((s.x - px), (-s.y - py)) / Math.PI) * 180) % 360)
      s.ap_dist = s.pdist
      s.ap_eta = Math.round( s.ap_dist / (Math.sqrt( Math.pow(pl.mx,2) + Math.pow(pl.my,2) ) / 0.04))

      img = s.img
      img = s.img_comm if s.img_comm
      srcwd = img.naturalWidth

      c.fillStyle = 'black'; c.fillRect 0,0,wd,wd
      c.strokeStyle = 'red'; c.strokeWidth = 3.0; c.strokeRect 0,0,wd,wd

      c.drawImage img, 0, 0, srcwd, srcwd, 0, 0, 150, 150

      list = []
      list.push "name: #{s.name}"
      list.push "ds:  #{hdist s.ap_dist}"
      list.push "eta: #{htime(s.ap_eta)}"
      for i of list
        c.fillStyle = "red"
        c.strokeText list[i], 5, 5 + 16 + i * 16
        c.fillText   list[i], 5, 5 + 16 + i * 16