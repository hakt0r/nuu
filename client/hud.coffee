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

Sprite.gameLayer 'hud', draw : (c) ->
  pi = Math.PI; tau = pi * 2
  picent = pi / 100
  taucent = tau / 100

  wd = hg = hw = hh = 0; _win = $ window
  _resize = ->
    c.canvas.width =  wd = _win.width();  hw = wd / 2
    c.canvas.height = hg = _win.height(); hh = hg / 2
  _win.on 'resize', _resize; _resize()
  
  c.font = "10px monospace"

  return ->
    p = NUU.player; pl = p.vehicle
    radius = pl.size / 2 + 10


    c.clearRect 0, 0, wd, hg
    c.lineWidth = 5
    c.strokeStyle = "blue";   c.beginPath(); c.arc(hw,hh,radius+5,(   (Math.min(99.99,pl.shield))*taucent),0,true);c.stroke()
    c.strokeStyle = "yellow"; c.beginPath(); c.arc(hw,hh,radius  ,(   (Math.min(99.99,pl.armor)) *taucent),0,true);c.stroke()
    c.strokeStyle = "red";    c.beginPath(); c.arc(hw,hh,radius-5,(   (Math.min(99.99,pl.energy))*picent),0,true); c.stroke()
    c.strokeStyle = "green";  c.beginPath(); c.arc(hw,hh,radius-5,(pi+(Math.min(99.99,pl.fuel))*picent),tau,true); c.stroke()
    c.globalAlpha = 1

    # SLOTS
    c.fillStyle = "green";  c.beginPath();
    unless NUU.target is null
      cid = NUU.targetClass
      list = ['ship','stel','roid']
      c.fillText("#{list[cid]}:[#{NUU.target.id}]#{NUU.target.name}", hw + pl.size/2 + 20, hh - 32)
    c.fillText 'none', hw + pl.size/2 + 20, hh - 16
    c.fillText "[#{p.primary.id}]   #{p.primary.slot.name}",   hw + pl.size/2 + 20, hh          if p.primary.slot?
    c.fillText "[#{p.secondary.id}] #{p.secondary.slot.name}", hw + pl.size/2 + 20, hh + 16  if p.secondary.slot?
    c.fillText 'empty', hw + pl.size/2 + 20, hh + 32

    # DIR
    c.strokeWidth = 0.5
    c.lineWidth = 2
    c.strokeStyle = "yellow"
    dir = ((pl.d + 180) % 360) / RAD
    c.beginPath()
    c.moveTo hw - Math.cos(dir) * radius, hh - Math.sin(dir) * radius
    c.lineTo hw - Math.cos(dir) * radius * 1.1, hh - Math.sin(dir) * radius * 1.1
    c.closePath()
    c.stroke()

    # SPEED
    c.strokeStyle = "red"
    c.beginPath()
    c.moveTo hw, hh
    c.lineTo hw + pl.mx, hh + pl.my
    c.closePath()
    c.stroke()

    # TARGET
    if (s = NUU.target)
      dir = ((pl.targetDir + 180) % 360) / RAD
      size  = parseInt(s.size)
      hsize = size / 2

      px = Math.floor pl.x
      py = Math.floor pl.y
      dx = Math.floor px * -1 + hw
      dy = Math.floor py * -1 + hh      
      ox = s.x + dx
      oy = s.y + dy
      fx = s.x - (size / 2)
      fy = s.y - (size / 2)

      c.lineWidth = 5
      c.strokeStyle = "blue";   c.beginPath(); c.arc(ox,oy,hsize+5,(   (Math.min(99.99,s.shield))*taucent),0,true);c.stroke()
      c.strokeStyle = "yellow"; c.beginPath(); c.arc(ox,oy,hsize  ,(   (Math.min(99.99,s.armor)) *taucent),0,true);c.stroke()

      c.globalAlpha = ((if s.ap_dist > 5000 then 0.2 else 1 - (s.ap_dist / 5000 * 0.8)))
      c.beginPath(); c.moveTo hw, hh; c.lineTo ox, oy; c.closePath()
      c.strokeStyle = "yellow"; c.stroke()
      c.globalAlpha = 0.1
      c.beginPath(); c.arc ox, oy, hsize * 1.1, 0, TAU, true; c.closePath()
      c.stroke()
      
      c.beginPath(); c.moveTo hw, hh; c.lineTo hw + s.mx, hh + s.my; c.closePath()
      c.lineWidth = 1
      c.fillStyle = "yellow"
      c.strokeStyle = "blue"
      c.stroke()

      c.globalAlpha = 1
      c.strokeWidth = 0.5
      c.lineWidth   = 1
      c.strokeStyle = "red"

      c.beginPath()
      c.moveTo hw - Math.cos(dir) * radius, hh - Math.sin(dir) * radius
      c.lineTo hw - Math.cos(dir) * radius * 1.3, hh - Math.sin(dir) * radius * 1.3
      c.closePath(); c.stroke()