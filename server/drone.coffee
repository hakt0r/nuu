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

$public class AI extends Ship
  constructor: (opts={})->
    @flags = -1
    opts.strategy = opts.strategy || 'attackPlayers'
    opts.stel = opts.stel || AI.randomStellar()
    opts.tpl  = opts.tpl  || Item.byName.Drone.itemId
    opts.target = opts.target || false
    opts.npc  = if opts.npc? then opts.npc else yes
    opts.state = opts.state || {
      S: $moving
      x: floor random() * 1000 - 500 + opts.stel.x
      y: floor random() * 1000 - 500 + opts.stel.y
      d: floor random() * 359 }
    super opts
    @name = @aiType + "[##{@id}]"
    console.log '::ai', "#{@name} at", opts.stel.name if debug
    @primarySlot = @slots.weapon[0]
    @primaryWeap = @slots.weapon[0].equip
    AI.list.push @
    @changeStrategy()

AI::changeStrategy = (strategy)->
  @strategy = strategy   if strategy?
  $worker.remove @worker if @worker
  $worker.push   @worker = @[@strategy].bind @

AI::destructor = ->
  $worker.remove @worker if @worker
  Array.remove AI.list, @
  NET.operation.write @, 'remove'
  super
  off

AI::aiType       = 'ai'
AI::npc          = true
AI::fire         = no
AI::inRange      = no
AI::primarySlot  = null
AI::primaryWeap  = null
AI::autopilot    = null
AI::escortTarget = null

AI::attackPlayers = ->
  do @update
  @attackPlayersTarget() if not @target or @target.destructing
  return 1000            unless @target
  if @inRange = abs(distance = $dist(@,@target)) < 150
    v = NavCom.steer @, @target, 'aim'
    if v.fire and not @fire
      NET.weap.write('ai',0,@primarySlot,@,@target)
    else if @fire and not v.fire
      NET.weap.write('ai',1,@primarySlot,@,@target)
  else v = NavCom.approach @, ( NavCom.steer @, @target, 'pursue' )
  { turn, turnLeft, @accel, @boost, @retro, @fire } = v
  @left = turnLeft
  @right = turn and not turnLeft
  do @changeState if ( @flags isnt v.flags ) or v.setDir
  33

AI::attackPlayersTarget = ->
  @target = null
  return unless NUU.users.length > 0
  closest = null
  closestDist = Infinity
  for p in NUU.users
    if ( closestDist > d = $dist(@,p.vehicle) ) and ( not p.vehicle.destructing ) and ( abs(d) < 1000000 )
      closestDist = d
      closest =  p.vehicle
  return @target = null if closestDist > 5000
  console.log '::ai', 'Drone SELECTED', closestDist if debug
  @target = closest
  null

AI::approach = ->
  do @update
  do @approachTarget unless @target
  return 1000        unless @target
  if @inRange = abs(distance = $dist(@,@target)) < 150
    console.log '::ai', "#{@name} at", @target.name if debug
    @target = null
    return 10000
  # else if @state.S isnt $travel
  #   @setState S:$travel, from:@state, to:@target
  v = NavCom.approach @, ( NavCom.steer @, @target, 'pursue' )
  { turn, turnLeft, @accel, @boost, @retro, @fire } = v
  @left = turnLeft
  @right = turn and not turnLeft
  if ( @flags isnt v.flags ) or v.setDir
    do @changeState
    return 0
  return 1000

AI::approachTarget = ->
  @target = Stellar.byId[ Array.random Object.keys Stellar.byId ]
  console.log '::ai', "#{@name} to", @target.name if @target if debug

AI::escort = ->
  do @update
  @escortTarget() if not @target or @target.destructing or ( @target.hostile and @target.hostile.length > 0 )
  return 1000     unless @target
  if @inRange = abs(distance = $dist(@,@target)) < 150
    console.log '::ai', "#{@name} reached", @target.name if debug
    return 250
  v = NavCom.approach @, ( NavCom.steer @, @target, 'pursue' )
  { turn, turnLeft, @accel, @boost, @retro, @fire } = v
  @left = turnLeft
  @right = turn and not turnLeft
  do @changeState if ( @flags isnt v.flags ) or v.setDir
  null

AI::escortTarget = ->
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

AI.list = []
AI.autospawn = (opts={})-> $worker.push =>
  drones = @list.length
  if drones < opts.max
    dt = opts.max - drones
    new Trader for i in [0...dt/2]
    new AI     for i in [0...dt/2]
  1000

AI.randomStellar = ->
  stel = $obj.byId[ Array.random Object.keys Stellar.byId ]
  stel.update()
  stel

$public class Trader extends AI
  aiType: 'Trader'
  constructor:(opts={})->
    opts.strategy = opts.strategy || 'approach'
    opts.tpl = opts.tpl || Array.random Trader.ships
    super opts
    @escort = ( for i in [0..floor random()*3]
      new Escort escortFor:@id, state:@state.toJSON() )
    return

$public class Escort extends AI
  aiType: 'Escort'
  constructor:(opts={})->
    opts.strategy = opts.strategy || 'escort'
    opts.tpl = opts.tpl || Array.random Trader.ships
    super opts

Trader.ships = []; NUU.on 'init:items:done', ->
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
