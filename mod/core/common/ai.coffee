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

$public class AI extends Ship
  constructor: (opts={})->
    opts.flags = -1
    opts.strategy = opts.strategy || 'attackPlayers'
    opts.stel = opts.stel || AI.randomStellar()
    opts.tpl  = opts.tpl  || Item.byName.Drone.itemId
    opts.target = opts.target || false
    opts.npc  = if opts.npc? then opts.npc else yes
    opts.state = opts.state || {
      S: $moving
      m: [0,0]
      x: floor random() * 1000 - 500 + opts.stel.x
      y: floor random() * 1000 - 500 + opts.stel.y
      d: floor random() * 359 }
    super opts
    @name = 'HKS ' + @id.toString(2) + ' (' + @aiType + ')'
    console.log '::ai', "#{@name} at", opts.stel.name if debug
    @primarySlot = @slots.weapon[0]
    @primaryWeap = @slots.weapon[0].equip
    AI.list.push @
    @changeStrategy @strategy

  @destructor: ->
    $worker.remove @worker if @worker
    Array.remove AI.list, @
    NET.operation.write @, 'remove'
    super()
    off

AI::changeStrategy = (strategy)->
  console.log 'strategy', strategy
  AI.worker[@strategy].remove @ if @strategy
  if strategy?
    worker = AI.worker[strategy]
    @strategy = strategy
    worker.add @
  return @


AI::aiType       = 'ai'
AI::npc          = true
AI::fire         = no
AI::inRange      = no
AI::primarySlot  = null
AI::primaryWeap  = null
AI::autopilot    = null
AI::escortTarget = null

AI.worker = {}
AI.list = []
AI.autospawn = (opts={})-> $worker.push =>
  drones = @list.length
  if drones < opts.max
    dt = opts.max - drones
    new Trader for i in [0...dt/2]
    new Drone  for i in [0...dt/2]
  1000

AI.randomStellar = ->
  stel = $obj.byId[ Array.random Object.keys Stellar.byId ]
  stel.update()
  stel

AI.register = (opts)-> AI.worker[opts.strategy] = $worker.PauseList opts, (time)->
  @update time
  @getTarget() unless @target
  return 1000  unless @target
  v = NavCom.approach @, NavCom.steer @, @target, 'pursue'
  switch v.recommend
    when "setdir"
      return 1000 if @lastRecommend is 'setDir' and 2 < (abs(@lastDir)-abs(v.dir))
      @lastThrottle = -1; @lastDir = v.dir
      NET.steer.write @, 0, round v.dir
      return TICKi * @turnTime v.dir
    when "burn"
      return 1000 if @lastRecommend is 'burn' and @lastThrottle is v.throttle
      @lastDir = -1; @lastThrottle = v.throttle
      NET.burn.write @, v.throttle
    when "boost"
      return 1000 if @lastRecommend is 'boost' and @lastThrottle is v.throttle
      @lastDir = -1; @lastThrottle = v.throttle
      NET.burn.write @, 254
    when "retro"
      return 1000 if @lastRecommend is 'retro' and @lastThrottle is v.throttle
      @lastDir = -1; @lastThrottle = v.throttle
      NET.burn.write @, v.throttle
    when "wait"
      @onDecision v if isClient and @onDecision
      return 100
    when "execute"
      # console.log '::ai', "#{@name} at", @target.name if debug
      @onTarget v if @onTarget
      @lastDir = -1; @lastThrottle = -1; @target = null; return 1000
  @lastRecommend = v.recommend
  @onDecision v if @onDecision
  return 0

AI.register
  strategy: 'approach'
  getTarget: ->
    @target = Stellar.byId[ Array.random Object.keys Stellar.byId ]
    console.log '::ai', "#{@name} to", @target.name if @target if debug
  onTarget: ->
    console.log '::ai', "#{@name} at", @target.name if @target if debug
    @target = Stellar.byId[ Array.random Object.keys Stellar.byId ]
    console.log '::ai', "#{@name} to", @target.name if @target if debug

AI.register
  strategy: 'attackPlayers'
  onTarget: ->
    v = NavCom.aim @, @target
    if v.fire and not @fire
      @fire = true
      NET.weap.write 'ai', 0, @primarySlot, @, @target
    else if @fire and not v.fire
      @fire = false
      NET.weap.write 'ai', 1, @primarySlot, @, @target
  getTarget: ->
    @target = null
    return unless NUU.users.length > 0
    closest = null
    closestDist = Infinity
    for p in NUU.users
      continue unless p.vehicle
      if ( closestDist > d = $dist(@,p.vehicle) ) and ( not p.vehicle.destructing ) and ( abs(d) < 1000000 )
        closestDist = d
        closest =  p.vehicle
    return @target = null if closestDist > 5000
    console.log '::ai', 'Drone SELECTED', closestDist if debug
    @target = closest
    null

AI.register strategy: 'escort', getTarget: ->
  if target = $obj.byId[@escortFor]
    console.log '::ai', "#{@name} Escorting", target.name if debug
    return @target = target unless target.hostile.length > 0 or target.destructing
    return @target if @target and not @target.destructing
    @target = target.hostile[0]
    console.log '::ai', "#{@name} Escort:Attack", @target.name if debug
    return @target
  @changeStrategy 'attackPlayers'
  console.log '::ai', "#{@name} going berserk" if debug
  false

$public class Drone extends AI
  constructor:(opts={})->
    opts.stel = Drone.randomStellar() unless opts.stel
    super opts
  @randomStellar:->
    stel = $obj.byId[ Array.random [3] ]
    stel.update()
    stel

$public class Miner extends AI
  aiType: 'Miner'
  constructor:(opts={})->
    opts.strategy = opts.strategy || 'approach'
    opts.tpl = opts.tpl || Array.random Miner.ships
    super opts
    return

$public class Trader extends AI
  aiType: 'Trader'
  constructor:(opts={})->
    opts.strategy = opts.strategy || 'approach'
    opts.tpl = opts.tpl || Array.random Trader.ships
    super opts
    # @escort = ( for i in [0..floor random()*3]
    #   new Escort escortFor:@id, state:@state.clone() )
    return

$public class Escort extends AI
  aiType: 'Escort'
  constructor:(opts={})->
    opts.strategy = opts.strategy || 'escort'
    opts.tpl = opts.tpl || Array.random Trader.ships
    super opts

Miner.ships = [];
Trader.ships = [];

NUU.on 'init:items:done', ->
  Miner.ships = [
    Item.byName.Mule.itemId
    Item.byName.Llama.itemId
  ]
  Trader.ships = [
    Item.byName.Kestrel.itemId
    Item.byName.Byakko.itemId
    Item.byName.Hawking.itemId
    Item.byName.Mule.itemId
    Item.byName.Llama.itemId
    Item.byName.ProteronWatson.itemId
    Item.byName.Quicksilver.itemId
    Item.byName.Rhino.itemId
    # Item.byName.Schroedinger.itemId
    Item.byName.SoromidArx.itemId
    Item.byName.ZalekDemon.itemId
  ]
