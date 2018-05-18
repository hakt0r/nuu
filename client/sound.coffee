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

$public class Sound
  @on: false
  @autoload : ['afb_disengage.wav','afterburner.wav','autocannon.ogg',
    'bansheeexp.ogg','beam0.wav','beam_off0.wav','compression.ogg',
    'empexplode.ogg','engine.wav','explosion0.wav','explosion1.wav',
    'explosion2.wav','grenade.wav','grenadefire.ogg','hail.ogg',
    'hyperspace_engine.ogg','hyperspace_jump.ogg','hyperspace_powerdown.ogg',
    'hyperspace_powerup.ogg','hyperspace_powerupjump.ogg','ion.wav','jump.wav',
    'laser.wav','lrgexp0.ogg','mace.wav','mass.wav','medexp0.ogg','medexp1.ogg',
    'missile.wav','nav.wav','neutron.wav','plasma.wav','ripper.ogg','seeker.wav',
    'target.wav']

  @load : (path,callback) ->
    name = path.replace(/^.*\//,'')
    folder = path.replace(/\/[^\/]+$/,'').replace(/^.*\//,'')
    Cache.get path, (objURL) =>
      Sound[name] = soundManager.createSound id:name,url:objURL,autoLoad:true,autoPlay:false,volume:100
      callback null

  @init : (callback) ->
    soundManager.setup preferFlash: false, onready: ->
      list = []
      load = (path) -> list.push (cb) -> Sound.load(path,cb)
      Sound.defaults()
      for name in Sound.autoload
        load('sounds/' + name)
      async.parallel list, callback

  @defaults : ->
    NUU.on 'ship:hit', -> Sound['explosion1.wav'].play() if Sound.on
    NUU.on 'shot', -> Sound['laser.wav'].play() if Sound.on
