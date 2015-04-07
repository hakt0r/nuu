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

User = Db 'User',

  userState: {}

  fields:
    online: no
    nick: ''
    mail: ''
    pass: ''
    regtime: -> Date.now()/1000
    credits: 100

  exports: ->
    nick: nick
    mail: mail
    regtime: regtime
    credits: credits

  join: (src, user, pass) ->
    if ( userRec = User.get user )
      if userRec? and pass is userRec.pass
        src.handle = name: userRec.nick, user: user, ship: null, ping: {}
        vehicleType = 'Hawking'
        vehicleType = userRec.vehicle if userRec.vehicle?
        if @userState[userRec.id]?
          vehicle = @userState[userRec.id]
          console.log userRec.nick, 'rejoined', userRec.id
        else
          console.log userRec.nick, 'joined'.green, userRec.id, vehicleType
          vehicle = new Ship
            tpl: Ship.byName[vehicleType]
            state: S:$fixed
          vehicle.mount[0] = userRec.id
          vehicle.flags = String.fromCharCode 0
          @userState[userRec.id] = vehicle
        src.handle.vehicle = vehicle
        pid = NUU.players.push src.handle
        src.handle.id = --pid
        src.json 'user.login.success':
          user: userRec
          ship: vehicle
          mountid: 0
          objects: $obj.list
        NUU.jsoncast 'join': vehicle
        NUU.emit 'playerJoined', src.handle
      else
        console.log 'ws'.yellow, 'login'.red, util.inspect(userRec).red, pass.red
        src.json 'user.login.failed':'wrong_credentials'
    else
      userRec = User.create user, nick: user, pass: pass
      console.log 'User'.yellow, 'create'.red, util.inspect userRec
    null

  part: (user) ->

  bootstrap:
     anx:    nick: 'anx',    id:0, mail: 'anx@ulzq.de',      pass: 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e', regtime:'2009-11-07', state:3, credits: 47553836
     flyc0r: nick: 'flyc0r', id:1, mail: 'flyc0r@localhost', pass: 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e', regtime:'2009-11-07', state:1, credits: 15091366

NET.on 'login', (msg,src) -> User.join src, msg.user, msg.pass
