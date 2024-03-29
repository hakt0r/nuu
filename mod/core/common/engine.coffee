###

  * c) 2007-2022 Sebastian Glaser <anx@ulzq.de>
  * c) 2007-2022 flyc0r

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

# TIMING
# do ( -> # HACK: Date.now TODO: migrate to NUU.time()
# $static 'performance', require("perf_hooks").performance if isServer
# Date._now = Date.now
# Date.now = -> performance.timeOrigin + performance.now() )

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
  1e6 * Math.floor @time() / 1e6

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

$static '$version',      '0.4.74'

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
$static '$formation',    8
$static '$travel',       9

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
$static 'ceil',          Math.ceil
$static 'floor',         Math.floor
$static 'atan2',         Math.atan2
$static 'sqrt',          Math.sqrt
$static 'min',           Math.min
$static 'max',           Math.max
$static 'abs',           Math.abs
$static 'pow',           Math.pow
$static 'sin',           Math.sin
$static 'asin',          Math.asin
$static 'cos',           Math.cos
$static 'acos',          Math.acos
$static 'acosh',         Math.acosh
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
  segu = $v.norm seg
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
$v     .cross = $v.cross     2
$v       .mag = $v.mag       2
$v       .div = $v.div       2
$v      .dist = $v.dist      2
$v      .mult = $v.mult      2
$v     .limit = $v.limit     2
$v      .head = $v.heading   2
$v      .norm = $v.normalize 2
$v      .zero = [0,0]
$v       .one = [1,0]

$v      .smod = (a) -> a - floor( a / 360 ) * 360
$v    .reldeg = (dira,dirb) -> $v.smod( dira - dirb + 180 ) - 180
$v   .umod360 = (v)-> ((( v % 360 ) + 360 ) % 360 )
$v     .burnp = (h,t,a,v,p)-> accdt2b2=.5*a*t**2; [ p[0]+v[0]*t+h[0]*accdt2b2, p[1]+v[1]*t+h[1]*accdt2b2 ]
$v     .burnr = (h,t,a,v  )-> accdt2b2=.5*a*t**2; [ v[0]*t+h[0]*accdt2b2, v[1]*t+h[1]*accdt2b2 ]
$v     .burnv = (h,t,a,v  )-> at=a*t; [ v[0]+h[0]*at, v[1]+h[1]*at ]
$v   .rotateH = (a,h)-> [a[0]*h[0]-a[1]*h[1],a[0]*h[1]+a[1]*h[0]]
$v     .angle = (a,b)-> atan2($v.norm($v.cross(a.$,b)), $v.dot(a.$,b))

Object.defineProperty Array::, '$', get:-> do @slice

$static '$dist',         (s,o) -> sqrt(pow(s.x-o.x,2)+pow(s.y-o.y,2))
$static '$interval',     (i,f) -> setInterval f,i
$static '$timeout',      (i,f) -> setTimeout f,i

$static 'hdist', (m) ->
  if      m < 1e3 then (m      ).toFixed(0) + "px"
  else if m < 1e6 then (m / 1e3).toFixed(2) + "Kpx"
  else if m < 1e9 then (m / 1e6).toFixed(2) + "Mpx"
  else                 (m / 1e9).toFixed(2) + "Gpx"

$static 'hscale', (m) ->
  if      m < 1e3 then (m      ).toFixed(0)
  else if m < 1e6 then (m / 1e3).toFixed(2) + "K"
  else if m < 1e9 then (m / 1e6).toFixed(2) + "M"
  else                 (m / 1e9).toFixed(2) + "G"

$static 'htime', (t) ->
  s  = Math.floor t % 60
  m  = Math.floor t / 60 % 60
  h  = Math.floor t / 3.6e3
  d  = Math.floor t / 8.64e4
  y  = Math.floor t / 3.1536e7
  ky = Math.floor t / 3.1536e10
  vy = Math.floor t / 3.1536e13
  gy = Math.floor t / 3.1536e16
  if t < 60 then s + "s"
  else if t <     3600 then m + "m" + s + "s"
  else if t <    86400 then h + "h" + m + "m" + s + "s"
  else if t < 30758400 then d + "d " + h + ":" + m + ":" + s + "h"
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
  return if -1 is pos = a.indexOf v
  a.splice pos, 1

Array.random = (a) ->
  a[round random()*(a.length-1)]

Array.uniq = (a)->
  a.filter (v,i,s)-> v? and s.indexOf v is i

Array.empty = (a)->
  a.splice 0, a.length
  a

Array.pushUnique = (a,v)->
  a.push v unless a.includes v
  return

Array.fake = push:->

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

Object.defineProperty String::,k,get:(->@) for k in [ 'bold','underline','strikethrough','italic','inverse','grey','black','yellow','red','green','blue','white','cyan','magenta','greyBG','blackBG','yellowBG','redBG','greenBG','blueBG','whiteBG','cyanBG','magentaBG'] if isClient

Function::toInlineCode = ->
  source = @toString().trim().split('\n')
  source.pop()
  source.shift()
  source.join('\n')

console.colorDump = (opts={})->
  a = ( (' '+k+' ').red.inverse + '' + (' '+v.toString()+' ').white.inverse.bold for k,v of opts )
  a.join ''

$static 'rules', ->
  if isClient then rules.client() else rules.server()

$public class Singleton
  constructor:(opts)->
    Object.assign @, opts
    @init()
  init:->

$public class Deterministic
  constructor:(@seed)->
    @callCount = 0
    @current = Crypto.createHash('sha512').update(@seed).digest()
  double:->
    @round() if @current.length <= 8*@callCount
    d = @current.readDoubleLE 8*@callCount
    d = @current.reduce ( (i,v)-> ( ( v + i * PI ) % PI ) / PI ), d
    return @double @callCount++ if isNaN d
    @callCount++
    return d
  doubell:->
    r = 0
    r += @double(); r += @double(); r += @double(); r += @double(); r += @double(); r += @double()
    r / 6
  round:->
    @callCount = 0
    @current = Crypto.createHash('sha512').update(@current).digest()
    # console.log 'round', @current.toString('hex')
  element:(a)-> a[round @double() * ( a.length - 1 )]
