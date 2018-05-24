###

  This file was ported from express-ws@3.0.0
    https://github.com/HenningM/express-ws

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2008 flyc0r

  Port for NUU:
    Sebastian Glaser <anx@ulzq.de>

  Original Author:
    Henning Morud <henning@morud.org>

  Contributors:
    Jesús Leganés Combarro <piranna@gmail.com>
    Sven Slootweg <admin@cryto.net>
    Andrew Phillips <theasp@gmail.com>
    Nicholas Schell <nschell@gmail.com>
    Max Truxa <dev@maxtruxa.com>
    Kræn Hansen <mail@kraenhansen.dk>

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

ws = require 'ws'
http = require 'http'
express = require 'express'

addWsMethod = (target) ->
  target.ws = addWsRoute unless target.ws?
  return target

addWsRoute = (route, middlewares...) ->
  wrappedMiddlewares = middlewares.map wrapMiddleware
  wsRoute = websocketUrl route
  this.get.apply this, [wsRoute].concat wrappedMiddlewares
  return @

trailingSlash = (string) ->
  string =+ '/' if '/' isnt string.charAt string.length - 1
  string

wrapMiddleware = (middleware) -> (req, res, next) ->
  if req.ws != null and req.ws != undefined
    req.wsHandled = true
    try middleware req.ws, req, next
    catch err then next err
  else next()

websocketUrl = (url)->
  return "#{trailingSlash(url)}.websocket" if -1 is url.indexOf '?'
  [baseUrl, query] = url.split '?'
  return "#{trailingSlash(baseUrl)}.websocket?#{query}"

wsServer = null
$static '$websocket',  (app,httpServer,options={}) ->
  server = httpServer
  unless server?
    server = http.createServer app
    app.listen = server.listen.bind server
  addWsMethod app
  addWsMethod express.Router unless options.leaveRouterUntouched
  wsOptions = options.wsOptions || {}
  wsOptions.server = server
  wsServer = $websocket.server = new ws.Server wsOptions
  wsServer.on 'connection', (socket,request)->
    request = socket.upgradeReq if socket.updateReq?
    request.ws = socket
    request.wsHandled = false
    request.url = websocketUrl request.url
    dummyResponse = new http.ServerResponse request
    dummyResponse.writeHead = writeHead = (statusCode) ->
      socket.close() if statusCode > 200
    app.handle request, dummyResponse, -> socket.close() unless request.wsHandled
    app.ws "/nuu", (c, req) ->
      console.log 'ws'.yellow, 'connection'.grey
      c.json = (msg) -> c.send NET.JSON + JSON.stringify msg
      c.on "message", NET.route c
      c.on "error", (e) -> console.log 'ws'.yellow, 'error'.red, e
      # lag and jitter emulation # c.on "message", (msg) -> setTimeout (-> NET.route(c)(msg)), 100 # + Math.floor Math.random() * 40
      null
    null
    app

NUU.bincast = (data,origin) ->
  wsServer.clients.forEach (c) ->
    try c.send data catch error then wsServer.clients.delete c
    null
  null

NUU.nearcast = NUU.bincast = (data,o) -> wsServer.clients.forEach (c) ->
  if o? and c.handle? and c.handle.vehicle? and o isnt c.handle.vehicle
    v = c.handle.vehicle
    return unless ( abs abs(v.x) - abs(o.x) ) < 5000 and ( abs abs(v.y) - abs(o.y) ) < 5000
  try c.send data catch error then wsServer.clients.delete c
  null

NUU.jsoncast = (data) ->
  data = NET.JSON + JSON.stringify data
  wsServer.clients.forEach (c) ->
    try c.send data catch error then wsServer.clients.delete c
    null
  null

NUU.jsoncastTo = (v,data) ->
  return unless v.inhabited
  data = NET.JSON + JSON.stringify data
  v.mount.map (i)-> if i and i.sock
    console.log 'jsoncastTo', v.id, data
    try i.sock.send data catch error then wsServer.clients.delete i.sock
  null