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

debug = off

$public class Engine extends CommonEngine
  threads : ['manouver','move','accelerate']
  frame : 0
  target : null
  targetId : 0
  targetClass : 0

  constructor : (callback) ->
    console.log 'Engine'
    super

    new VT100
    console.user 'Welcome to NUU'

    @time = Ping.remoteTime
    rules @
    window.Cache = new FSCache =>
      console.log 'cache:initialized'
      async.parallel [
        (cb) => Sprite.init => cb null
        (cb) => $.ajax('/build/objects.json').success (result) =>
          Item.init result
          cb null
        (cb) => Sound.init => cb null
      ], =>
        if debug then $timeout 500, => NET.login 'anx', sha512(''), =>
          vt.unfocus()
          callback null if callback
        else @loginPrompt()

  loginPrompt : -> vt.prompt 'Login', (user) =>
    return @loginPrompt() if user is null
    vt.prompt 'Password', (pass) =>
      return @loginPrompt() if pass is null
      NET.login user, sha512(pass), (success) =>
        return @loginPrompt() unless success

  sync : (opts, callback) =>
    console.log 'NUU.sync'
    objectToClassName = [ Ship,Stellar,Asteroid ]
    sid = opts.shipid
    for list, type in opts.objects
      className = objectToClassName[type]
      new className(o) for id, o of list
    @vehicle = v = $obj.byId[sid]
    @player  = p =
      vehicle : v,
      primary : {id:0},
      secondary : {id:0}
    Sprite.start opts, =>
      v.sx = v.sy = v.psx = v.psy = 0
      # Sprite.resize()
      @start callback

  start : (callback) =>
    super
    @thread 'animation', TICK, AnimatedSprite.shift
    @thread 'ping',      500,  Ping.send
    @emit   'start'
    callback null if callback

  stop : =>
    $(window).removeListener 'resize', Sprite.resize
    clearInterval @[thread].run for thread in @threads
