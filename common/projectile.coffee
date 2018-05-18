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

###
  this creates the game model, not an instance of a shot
  think of it as a factory
###

prjId = 0

class Projectile
  id: null
  src: null
  weap: null
  target: null
  ms: null
  tt: null
  m: null
  x: null
  y: null
  sx: null
  sy: null

Weapon.Projectile = ->
  @cooldown = 1000
  @release = $void
  @trigger = (src,vehicle,slot,target)=>
    if @release isnt $void
      console.log 'emergency-release trigger'
      do @release
    @release = =>
      console.log 'do-release' if debug
      fire.stop = true
      @release = $void
    detector = (v) => =>
      if v.tt < TIME
        Array.remove Weapon.proj, v
        v = null
        return off
      ticks = (TIME - v.ms) / TICK
      v.x = floor(v.sx + v.m[0] * ticks)
      v.y = floor(v.sy + v.m[1] * ticks)
      if $dist(v,target) < target.size
        target.hit(vehicle,v.weap) unless isClient
        Array.remove Weapon.proj, v
        return off
      null
    @release.fire = fire = =>
      return off if fire.stop
      vehicle.update()
      Weapon.proj.push v = new Projectile
      d = vehicle.d / RAD
      cs = cos(d)
      sn = sin(d)
      v.id     = prjId++
      v.src    = vehicle
      v.weap   = slot.equip
      v.target = target
      v.ms     = TIME
      v.tt     = TIME + ttl
      v.m      = [ vehicle.m[0] + cs * spt, vehicle.m[1] + sn * spt ]
      v.x = v.sx = floor vehicle.x # + slot.x * cs - slot.x * sn;
      v.y = v.sy = floor vehicle.y # + slot.y * sn + slot.y * cs;
      $worker.push detector v
      NUU.emit 'shot', v
      Weapon.hostility vehicle, target
      @cooldown
    ttl = @stats.range / @stats.speed * 1000
    spt = @stats.speed / TICK
    $worker.push fire
