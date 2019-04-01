###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2018 flyc0r

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

# LANG-CONSTANTS
$static '$void', ->

# Extend NUU/NET (GLUE OBJECTs:)
if isServer
  NUU[k] = v for k,v of EventEmitter::; EventEmitter.call NUU
  NET[k] = v for k,v of EventEmitter::; EventEmitter.call NET

NUU.$target = (o)->
  return h if h = o.client || o.common if isClient
  return h if h = o.server || o.common if isServer

NET.register = (k,o)-> NET.on k, NUU.$target o

NUU.init = $void

NUU.time = Date.now
NUU.timePrefix = ->
  1000000 * Math.floor @time() / 1000000

NUU.threadList = {}
NUU.thread = (name,time,fnc) ->
  @threadList[name] = setInterval fnc, time

NUU.start = (callback) ->
  console.log ':nuu', 'engine'.green, @tstart = @time()
  @emit 'start'
  callback null if callback
  null

NUU.stop = ->
  clearInterval i for k,i of @threadList
  null

$static '$version',      '0.4.73'

# ENGINE CONSTANTS
$static 'Speed',
  ofLight: C  = 299792.458 # px/s
  max:     CC = C / 100 # 10C cuz youknow :D C is far too slow :D
  maxi:    1 / CC

$static 'TICK',          15 # worker resolution in ms

# ENGINE VARIABLES
$static 'OX',            0 # global delta
$static 'OY',            0 # global delta

# STATES
$static '$fixed',        0
$static '$fixedTo',      1
$static '$moving',       2
$static '$burn',         3
$static '$turn',         4
$static '$turnTo',       5
$static '$steer',        6
$static '$orbit',        7
$static '$travel',       8

# MATH-CONSTANTS
$static 'PI',            Math.PI
$static 'PIi',           1 / PI
$static 'PIcent',        PI  / 100
$static 'TAU',           PI * 2
$static 'TAUi',          1 / TAU
$static 'TAUcent',       TAU / 100
$static 'RAD',           180 / PI
$static 'DAR',           PI  / 180
$static 'RADi',          1 / RAD
$static 'DARi',          1 / DAR

# MATH
$static 'floor',         Math.floor
$static 'atan2',         Math.atan2
$static 'sqrt',          Math.sqrt
$static 'min',           Math.min
$static 'max',           Math.max
$static 'abs',           Math.abs
$static 'pow',           Math.pow
$static 'sin',           Math.sin
$static 'cos',           Math.cos
$static 'tan',           Math.tan
$static 'random',        Math.random
$static 'round',         Math.round
$static 'sec',           Math.sec = (v)-> 1 / cos v
$static 'csc',           Math.csc = (v)-> 1 / sin v

Math.nextPow2 = (v)->
  v += v is  0; --v
  v |= v >>> 1; v |= v >>> 2; v |= v >>> 4; v |= v >>> 8; v |= v >>> 16
  return v + 1

Math.linear = (a,b)->
  return `a==0?(b==0?[]:[0]):[-b/a]`

Math.quadratic = (a,b,c)->
  if      0 is a then Math.linear b,c
  else if 0 > ( s = ( p = b / a ) / 2 * p / 2 - ( q = c / a ) )
       [ [-p / 2,   sr = Math.sqrt -s], [-p / 2, -sr ] ]
  else [  -p / 2 + ( sr = Math.sqrt s ), -p / 2 - sr ]

Math.lineCircleCollideInf = (a, b, c, r) ->
  # @FUNCTION Math.lineCircleCollideInf
  # @SOURCE   Mathematics Stack Exchange
  # @AUTHOR   qwr (https://math.stackexchange.com/users/122489/qwr)
  # @TITLE    Check if line intersects with circles perimeter
  # @URL      https://math.stackexchange.com/q/2035466 (version: 2016-11-29)
  x1 = a[0]-c[0]; y1 = a[1]-c[1]
  x2 = b[0]-c[0]; y2 = b[1]-c[1]
  dr_squared = (x2 - x1)**2 + (y2 - y1)**2
  D = x1*y2 - x2*y1
  return r**2 * dr_squared > D**2

Math.lineCircleCollide = (a, b, c, r) ->
  closest = a.slice()
  seg     = b.slice()
  ptr     = c.slice()
  $v.sub seg, a
  $v.sub ptr, a
  segu = $v.normalize seg
  prl  = $v.dot ptr, segu
  if prl > $v.dist a, b then closest = b.slice()
  else if prl > 0 then $v.add closest, $v.mult(segu,prl)
  dist = $v.dist c, closest
  dist < r

$static 'scaleLog', Math.scaleLog = (val,minp=0,maxp=Speed.max,minv=0,maxv=50)->
  minv = Math.log minv; maxv = Math.log maxv
  return Math.exp minv + ((maxv-minv)/(maxp-minp)) * ( abs(val) - minp )

$static 'rdec3', (n)->
  (if n < 0 then '-' else '') + ('000' + abs round n).substr -3

$static 'sha512', (str) ->
  Crypto.createHash('sha512').update(str).digest 'hex'

# VECTORMATH
$v       .sub = $v.sub       2
$v       .add = $v.add       2
$v       .dot = $v.dot       2
$v       .mag = $v.mag       2
$v      .dist = $v.dist      2
$v      .mult = $v.mult      2
$v     .limit = $v.limit     2
$v   .heading = $v.heading   2
$v .normalize = $v.normalize 2
$v      .zero = [0,0]
$v      .smod = (a) -> a - floor( a / 360 ) * 360
$v    .reldeg = (dira,dirb) -> $v.smod( dira - dirb + 180 ) - 180
$v   .umod360 = (v)-> ((( v % 360 ) + 360 ) % 360 )

$static '$dist',         (s,o) -> sqrt(pow(s.x-o.x,2)+pow(s.y-o.y,2))
$static '$interval',     (i,f) -> setInterval f,i
$static '$timeout',      (i,f) -> setTimeout f,i

$static 'hdist', (m) ->
  if m < 1000 then            (m).toFixed(0) + "px"
  else if m < 1000000 then    (m / 1000).toFixed(2) + "Kpx"
  else if m < 1000000000 then (m / 1000000).toFixed(2) + "Mpx"
  else                        (m / 1000000000).toFixed(2) + "Gpx"

$static 'htime', (t) ->
  s  = Math.floor(t % 60)
  m  = Math.floor(t / 60 % 60)
  h  = Math.floor(t / 60 / 60)
  d  = Math.floor(t / 60 / 60 / 24)
  y  = Math.floor(t / 60 / 60 / 24 / 365)
  ky = Math.floor(t / 60 / 60 / 24 / 365 / 1000)
  vy = Math.floor(t / 60 / 60 / 24 / 365 / 1000 / 1000)
  gy = Math.floor(t / 60 / 60 / 24 / 365 / 1000 / 1000 / 1000)
  if t < 60 then s + "s"
  else if t < 60 * 60 then m + "m" + s + "s"
  else if t < 60 * 60 * 24 then h + "h" + m + "m" + s + "s"
  else if t < 60 * 60 * 24 * 356 then d + "d " + h + ":" + m + ":" + s + "h"
  else t.toFixed 0

if debug
  Speed.bost *= 10
  Speed.boost = 30

$static '$abstract', (name,opts)->
  $static "$" + name, f = (object,mods={})->
    Object.assign object::, opts, mods
    object
  f.properties = opts
  f

$public class Mean
  constructor : -> @reset()
  reset : (v) ->
    @last = 0; @total = 0; @count = 0; @avrg = 0
  add : (v) ->
    @count++
    @last = v
    @total += v
    @avrg = @total / @count

Array.remove = (a,v) ->
  return if pos = a.indexOf v
  a.splice pos, 1

Array.random = (a) ->
  a[round random()*(a.length-1)]

Array.uniq = (a)->
  a.filter (v,i,s)-> v? and s.indexOf v is i

Array.empty = (a)->
  a.pop() while a.length > 0
  a

Array.pushUnique = (a,v)->
  a.push v unless a.includes v
  return

Object.empty = (o)->
  delete o[k] for k of o
  o

Object.reducedMapToArray = (o,c,a)->
  v for k, v of o when ( v = c k, v, o )?

Object.randomPair = (o)->
  return null unless k = Array.random Object.keys o
  [k,o[k]]

String.random = (length) ->
  text = ''; i = 0
  text += String.fromCharCode floor 80 + 36 * random() while i++ < length
  text

String.filename = (p)->
  p.replace(/.*\//, '').replace(/\..*/,'')

console.colorDump = (opts={})->
  a = ( (' '+k+' ').red.inverse + '' + (' '+v.toString()+' ').white.inverse.bold for k,v of opts )
  a.join ''

$static 'rules', ->
  if isClient then rules.client() else rules.server()

$public class Deterministic
  constructor:(@seed)->
    @callCount = 0
    @current = Crypto.createHash('sha512').update(@seed).digest()
  double:->
    ++@callCount
    @current = Crypto.createHash('sha512').update(@current).digest()
    @current.reduce (i,v=0)-> ( ( v + i * PI ) % PI ) / PI
  element:(a)-> a[round @double() * ( a.length - 1 )]
