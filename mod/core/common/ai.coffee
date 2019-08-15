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

#  ██████  ██████  ███    ███ ███    ███  ██████  ███    ██
# ██      ██    ██ ████  ████ ████  ████ ██    ██ ████   ██
# ██      ██    ██ ██ ████ ██ ██ ████ ██ ██    ██ ██ ██  ██
# ██      ██    ██ ██  ██  ██ ██  ██  ██ ██    ██ ██  ██ ██
#  ██████  ██████  ██      ██ ██      ██  ██████  ██   ████

$public class AI extends Ship
  constructor: (opts={})->
    opts.flags    = -1
    strategy = opts.strategy; delete opts.strategy
    opts.stel     = opts.stel || AI.randomStellar()
    opts.tpl      = opts.tpl  || Item.byName.Drone.itemId
    opts.target   = opts.target || false
    opts.npc      = if opts.npc? then opts.npc else yes
    unless opts.state
      angl = random() * TAU
      dist = random() * 1000
      opts.state = {
        translate: no
        S: $moving
        relto: opts.stel
        v: [0,0]
        x: cos(angl) * dist
        y: sin(angl) * dist
        d: floor random() * 359 }
    super opts
    # console.log '::ai', "#{@name} at", opts.stel.name if debug
    @primarySlot = @slots.weapon[0]
    @primaryWeap = @slots.weapon[0].equip
    AI.list.push @
    @constructor.list.push @
    @changeStrategy strategy

  destructor:->
    $worker.remove @worker if @worker
    Array.remove AI.list, @
    Array.remove @constructor.list, @
    NET.operation.write @, 'remove'
    super()
    off

  onHit:->
  onHostility:->
  onShieldsDown:->
  onDisabled:-> @changeStrategy null
  onDestruct:-> @changeStrategy null

AI::hit = (src,wp) ->
  return if @destructing
  switch v = Weapon.impactLogic.call @, wp
    when Weapon.impactType.hit
      NUU.emit 'ship:hit', @, src, @shield, @armour
      NET.mods.write @, 'hit', @shield, @armour
      do @onHit
    when Weapon.impactType.shieldsDown
      NUU.emit 'ship:shieldsDown', @, src
      NET.mods.write @, 'shield', @shield, @armour
      do @onShieldsDown
    when Weapon.impactType.disabled
      NUU.emit 'ship:disabled', @, src
      NET.mods.write @, 'disabled', @shield, @armour
      do @onDisabled
    when Weapon.impactType.destroyed
      NUU.emit     'ship:destroyed', @, src
      NET.mods.write @, 'destroyed', 0, 0
      do @onDestruct if @onDestruct
  return

AI::changeStrategy = (strategy)->
  return if strategy is @strategy
  console.log 'strategy', @name, @strategy, '=>', strategy, @target?.name if @constructor.name is 'Drone' if @strategy if debug
  ( AI.worker[@strategy].remove @; delete @strategy ) if @strategy
  ( AI.worker[@strategy = strategy].add   @         ) if strategy?
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
AI.autospawn = -> $worker.push =>
  for Type in [Drone,Trader,Miner]
    drones = Type.list.length
    if drones < Type.max
      dt = Type.max - drones
      new Type for i in [0...dt/2]
    1000

AI.randomStellar = ->
  stel = Array.random Stellar.list.concat Station.list
  stel.update()
  stel

AI.register = (strategy,opts)->
  defaults = listKey:strategy,steer:no,inRange:no,outRange:no,onTarget:no,offTarget:no,getTarget:->
  opts = Object.assign defaults, opts
  AI.worker[strategy] = $worker.PauseList opts, (time)->
    @getTarget() unless @target
    return 10000 unless @target
    if @target.respawning or @target.destructing
      @target = null
      @getTarget()
      return 0
    if @state.S is $travel
      wait = max 0, @state.vec.absETA - NUU.time()
      # console.log @name, 'travel', htime wait/1000
      return wait
    @update time; @target.update time
    if ( inRange = @target.size * 10 > @dist @target ) isnt @lastInRange
      fnc = if inRange then 'inRange' else 'outRange'
      do @[fnc] if @[fnc]
      @lastInRange = inRange
    if ( onTarget = @target.size * 1.1 > @dist @target ) isnt @lastOnTarget
      fnc = if onTarget then 'onTarget' else 'offTarget'
      do @[fnc] if @[fnc]
      @lastOnTarget = onTarget
    @steer time if @target and @steer
    return

AI.steer = ->
  v = NavCom.steer  @, @target, 'pursue'
  v = NavCom.decide @, v
  v.wait_t = v.steer_t = 0 if v.approach_d < 10000
  switch v.recommend
    when "setdir"
      return 100 if @lastRecommend is 'setDir' and @lastDir is v.dir # and 2 < (abs(@lastDir)-abs(v.dir))
      @lastRecommend = v.recommend
      @lastThrottle = -1; @lastDir = v.dir
      NET.steer.write @, 0, round v.dir
      @onDecision v if @onDecision
      return @turnTime v.dir
    when "wait"
      @setState S:$moving if isServer and @state.S isnt $moving
      NET.state.write @, [no,no,no,no,no,no,no,no] if isClient
      @onDecision v if @onDecision if isClient
      return min 2000, max 0, v.wait_t
    when "execute"
      # console.log '::ai', "#{@name} at", @target.name if debug
      @onTarget v if @onTarget
      @lastDir = -1; @lastThrottle = -1
      @onDecision v if @onDecision
      return 1000
    when "burn"
      return 100 if @lastRecommend is 'burn' and @lastThrottle is v.setThrottle
      @lastRecommend = v.recommend
      @lastDir = -1; @lastThrottle = v.setThrottle
      NET.burn.write @, v.setThrottle
      @onDecision v if @onDecision
      return min 2000, max 0, v.steer_t
  return

AI.shootOutRange = ->
  return unless @fireFlag
  @fireFlag = no
  NET.weap.write 'ai', 1, @primarySlot, @, @target
  console.log 'stopShooting' if debug

AI.shootInRange = ->
  return if @fireFlag
  @fireFlag = yes
  NET.weap.write 'ai', 0, @primarySlot, @, @target
  console.log 'startShooting' if debug

AI.register 'approach',
  getTarget:->
    @target = Array.random Stellar.list
    console.log '::ai', "#{@name} to", @target.name if @target if debug
  onTarget:->
    console.log '::ai', "#{@name} at", @target.name if @target if debug
    @target = Array.random Stellar.list
    console.log '::ai', "#{@name} to", @target.name if @target if debug

# ██████  ██████   ██████  ███    ██ ███████
# ██   ██ ██   ██ ██    ██ ████   ██ ██
# ██   ██ ██████  ██    ██ ██ ██  ██ █████
# ██   ██ ██   ██ ██    ██ ██  ██ ██ ██
# ██████  ██   ██  ██████  ██   ████ ███████

$public class Drone extends AI
  constructor:(opts={})->
    opts.strategy = 'waitForUsers'
    opts.stel = Drone.randomStellar() unless opts.stel
    super opts
    @name = 'HKS/' + @id.toString 36
  @list:[]
  @randomStellar:->
    stel = $obj.byId[ Array.random [3] ]
    stel.update()
    stel

AI.register 'waitForUsers', getTarget:->
  if u = do @closestUser
    [closest,dist] = u
    if dist < 5000
      console.log '::ai', 'drone:select', closest.name, "@" + hdist dist if debug
      @target = closest
      @changeStrategy 'attackTarget'
      return
  return

AI.register 'attackTarget',
  steer: AI.steer
  inRange: AI.shootInRange
  outRange: AI.shootOutRange
  getTarget:->
    console.log '::ai', 'drone:targetDown', @target if debug
    @base = no
    @changeStrategy 'returnToBase'

AI.register 'returnToBase',
  onTarget:->
    return unless @target
    console.log '::ai', 'drone:arrivedAtBase', @target.name if debug
    @setState S:$moving, relto:@target, v:@target.v.slice()
    @target = null; @steer = no
    @changeStrategy 'waitForUsers'
  getTarget:->
    @lastInRange = @lastOnTarget = no
    unless @base = @homebase
      bases = [ $obj.byName.Earth , $obj.byName.Moon ]
      if bases.includes(@state.relto) and 1000 > @dist(@state.relto)
        console.log '::ai', 'drone:alreadyAtBase' if debug
        @steer = AI.steer
        @target = @base = @homebase
        return
      @base = @homebase = Array.random bases
    @target = @base
    console.log '::ai', 'drone:returnToBase', @target.name if debug
    if 1e6 > @dist @target
      @setState S:$travel, relto:@target
    else @steer = AI.steer
    return

# ███    ███ ██ ███    ██ ███████ ██████
# ████  ████ ██ ████   ██ ██      ██   ██
# ██ ████ ██ ██ ██ ██  ██ █████   ██████
# ██  ██  ██ ██ ██  ██ ██ ██      ██   ██
# ██      ██ ██ ██   ████ ███████ ██   ██

$public class Miner extends AI
  aiType: 'Miner'
  @list:[]
  constructor:(opts={})->
    opts.name = NameGen.civilian
    opts.strategy = opts.strategy || 'findNewAsteroid'
    opts.tpl = opts.tpl || Array.random Miner.ships
    super opts
    return

AI.register 'findNewAsteroid', getTarget:->
  return unless a = @closestAsteroid()
  [@target,dist] = a
  @setState S:$travel, relto:@target if dist > 2e3
  console.log @name, "miner:mined=>next", @target.name
  return

AI.register 'mine',
  steer: AI.steer
  inRange: AI.shootInRange
  outRange: AI.shootOutRange
  getTarget:->
    console.log @name, "miner:mined=>findNew"
    @changeStrategy 'findNewAsteroid'
    return

# ████████ ██████   █████  ██████  ███████ ██████
#    ██    ██   ██ ██   ██ ██   ██ ██      ██   ██
#    ██    ██████  ███████ ██   ██ █████   ██████
#    ██    ██   ██ ██   ██ ██   ██ ██      ██   ██
#    ██    ██   ██ ██   ██ ██████  ███████ ██   ██

$public class Trader extends AI
  aiType: 'Trader'
  @list:[]
  constructor:(opts={})->
    opts.name = NameGen.civilian
    opts.strategy = 'trade' # opts.strategy || 'trade'
    opts.tpl = opts.tpl || Array.random Trader.ships
    super opts
    @inventory = new Inventory data:{}, key:no
    @formationSlots = Ship.formation.wing.slice()
    @escort = ( for i in [0..floor random()*3]
      new Escort escortFor:@id, formVec:@formationSlots.shift() )
    return
  onHostility:->
    console.log @name, 'offended' if debug
    @onHostility = ->
    @changeStrategy 'escort:defend'
    e.changeStrategy 'escort:defend' for e in @escort
    return

AI.register 'trade',
  lostTarget:->
    @target = null
    @mission = false
    @changeStrategy 'trade'
    console.log '@trader', @name, 'lost mission target' if debug
  getTarget:->
    if @inventory.total is 0 or not @mission
      return unless r = Object.randomPair Economy.need
      [ item, dest ] = r
      return unless t = Object.randomPair dest
      [ dest, count ] = t
      return unless dest = $obj.byId[dest]
      return unless z = Array.random Economy.has item
      return unless source = Array.random z.list
      @mission = item:item, source:source, dest:dest, count:count, task:'pickup'
      @target = source
      @setState S:$travel, relto:@target
      console.log "#{@name} new mission: #{item} from #{source.zoneDomain} to #{dest.zoneDomain}", @mission if debug
    else
      # if debug
  onTarget:->
    if @land @target
      console.log '::ai', "#{@name} landManual".yellow, @target.name if @steer if debug
      console.log '::ai', "#{@name} landTravel".green, @target.name unless @steer if debug
      unless @mission
        @getTarget()
        return
      @changeStrategy @target = null
      tries = 0
      setTimeout ( waitForResources = =>
        switch @mission.task
          when 'pickup'
            m = @mission
            unless @mission.source.zone.inventory.give @inventory, m.item, m.count
              if ++tries is 3
                # console.log '::ai', "#{@name} missionFailed #{@landedAt.name}" # if debug
                return
              setTimeout waitForResources, 10000
              console.log '::ai', "#{@name} wait at #{@landedAt.zoneDomain}" if debug
              # console.log @mission.source.zone.inventory
              return
            m.task = 'deliver'
            console.log "pickup: #{m.item} from #{m.source.zoneDomain} to #{m.dest.zoneDomain}" if debug
            @launch()
            @target = @mission.dest
            @setState S:$travel, relto:@target
            @changeStrategy 'trade'
            # m = @mission; console.log "#{@name} bring: #{m.item} from #{m.source.zoneDomain} to #{m.dest.name}@#{m.dest.zoneDomain}"
          when 'deliver'
            m = @mission
            @inventory.give m.source.zone.inventory, m.item, m.count
            @inventory.data = {}
            console.log '::ai', "#{@name} delivered #{m.item} to #{@landedAt.zoneDomain}" if debug
            delete @mission
            setTimeout (=>
              @launch()
              @changeStrategy 'trade'
            ), random()*20000
          else console.log @mission
      ), 10000
    else
      @steer = AI.steer
      console.log '::ai;trader', "#{@name} landFailed".red, @target.name, @mission if debug
    return

# ███████ ███████  ██████  ██████  ██████  ████████
# ██      ██      ██      ██    ██ ██   ██    ██
# █████   ███████ ██      ██    ██ ██████     ██
# ██           ██ ██      ██    ██ ██   ██    ██
# ███████ ███████  ██████  ██████  ██   ██    ██

$public class Escort extends AI
  aiType: 'Escort'
  constructor:(opts={})->
    [x,y] = opts.formVec
    p = $obj.byId[opts.escortFor]; p.update()
    phi = p.d * RAD
    fx = 0 + x*cos(phi) - y*sin(phi)
    fy = 0 + x*sin(phi) + y*cos(phi)
    opts.name = NameGen.republicFighter
    opts.state = opts.state || S:$formation, x:fx, y:fy, d:p.d, v:p.v.slice(), relto:p, translate:no
    opts.tpl = opts.tpl || Array.random Escort.ships
    super opts
  onHostility:->
    @lock = no; @setState S:$moving
    console.log @name, 'offended'
    @onHostility = ->
    return unless p = $obj.byId[@escortFor]
    p.hostile = Array.uniq @hostile.concat p.hostile || []
    p.onHostility()
    @changeStrategy 'escort:defend'
    return

AI.register 'escort:defend',
  getTarget:->
    if @escortFor
      unless p = $obj.byId[@escortFor]
        console.log '::ai', "#{@name} going berserk" if debug
        @changeStrategy "attackTarget"
        return false
    else p = @
    if 0 is p.hostile.length
      console.log '::ai', "#{@name} my job here is done" if debug
      @changeStrategy null # 'escort:return'
      return false
    @target = p.hostile[0]
    console.log '::ai', "#{@name} Escort:Attack", @target.name if debug
    return @target
  inRange:->
    v = NavCom.aim @, @target
    console.log 'startShooting'
    NET.weap.write 'ai', 0, @primarySlot, @, @target
  outRange:->
    console.log 'stopShooting'
    NET.weap.write 'ai', 1, @primarySlot, @, @target

# ███████ ██   ██ ██ ██████  ███████
# ██      ██   ██ ██ ██   ██ ██
# ███████ ███████ ██ ██████  ███████
#      ██ ██   ██ ██ ██           ██
# ███████ ██   ██ ██ ██      ███████

Miner.ships = Trader.ships = Escort.ships = []

NUU.on 'init:items:done', ->
  Drone.ships = [
    Item.byName.Drone.itemId
    Item.byName.HeavyDrone.itemId
    Item.byName.Vigilance.itemId
  ]

  Miner.ships = [
    Item.byName.Mule.itemId
    Item.byName.Llama.itemId
    Item.byName.Admonisher.itemId
    Item.byName.EmpirePacifier.itemId
  ]

  # Pirate.ships = [
  #   Item.byName.Byakko.itemId
  #   Item.byName.Kestrel.itemId
  #   Item.byName.PirateKestrel.itemId
  # ]

  Trader.ships = [
    Item.byName.Byakko.itemId
    Item.byName.Hawking.itemId
    Item.byName.EmpireHawking.itemId
    Item.byName.Mule.itemId
    Item.byName.Rhino.itemId
    Item.byName.PirateRhino.itemId
    Item.byName.ProteronKahan.itemId
    Item.byName.ProteronWatson.itemId
    Item.byName.SiriusDivinity.itemId
    Item.byName.SiriusDogma.itemId
  ]

  Escort.ships = [
    Item.byName.Ancestor.itemId
    Item.byName.DvaeredPhalanx.itemId
    Item.byName.EmpirePacifier.itemId
    Item.byName.EmpireShark.itemId
    Item.byName.FLFVendetta.itemId
    Item.byName.Pacifier.itemId
    Item.byName.Koala.itemId
    Item.byName.Llama.itemId
    Item.byName.ProteronDerivative.itemId
    Item.byName.Quicksilver.itemId
    Item.byName.SiriusFidelity.itemId
    Item.byName.SiriusShaman.itemId
    Item.byName.Vendetta.itemId
  ]
