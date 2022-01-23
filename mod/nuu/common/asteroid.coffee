
#  █████  ███████ ████████ ███████ ██████   ██████  ██ ██████
# ██   ██ ██         ██    ██      ██   ██ ██    ██ ██ ██   ██
# ███████ ███████    ██    █████   ██████  ██    ██ ██ ██   ██
# ██   ██      ██    ██    ██      ██   ██ ██    ██ ██ ██   ██
# ██   ██ ███████    ██    ███████ ██   ██  ██████  ██ ██████

# belt = Array.random [5.0325e8,5.984e+9]

$obj.register class Asteroid extends $obj
  @interfaces: [$obj,Shootable,Debris,Asteroid]
  constructor: (opts)->
    opts.sprite = 'asteroid-D' + ( opts.size - 10 ).toString().padStart 2,'0'
    super opts
    @armour = @armourMax = 10 * @size
  toJSON:-> undefined

Asteroid::virtual = yes if isServer

$obj.register class Asteroid.Belt extends $obj
  bigMass:yes
  @interfaces: [$obj,Stellar]
  constructor: (opts={})->
    opts = Object.assign {
      seed: 'asdasdas213'
      belt:  5.0325e8 # 5.984e+9
      width: 1e8
      count: 1000
    }, opts
    opts.parent = $obj.byId[opts.parent] if isClient
    opts.state = opts.state || State.orbit.relto opts.parent, opts.belt, 1
    super opts
    unless @base
      @ids = new IdPool name:@name, max:@count unless @ids?
      @base = @ids.s
    @noise = new Deterministic @seed
    @list = new Array @count
    for i in [0..@count]
      oo = @belt - @width/2 + @width*@noise.doubell()
      @list[i] = new Asteroid
        resource: ( Element.deterministic @noise for j in [0...5])
        state:    State.orbit.relto @parent, oo, 1, TAU * @noise.double()
        size:     max 10, floor @noise.double() * 73
        belt:     @
        id:       @base + i
        name:     @name + '-' + ( @base + i )
    $obj.select @list if isClient
  loadAssets:->
  toJSON:-> id:@id,key:@key,state:@state,seed:@seed,base:@base,count:@count,belt:@belt,width:@width,name:@name,parent:@parent.id

$obj::closestAsteroid = ->
  return no unless Asteroid.list.length > 0
  closest = null; dist = Infinity
  for p in Asteroid.list
    continue if p.destructing
    if dist > d = abs $dist @,p
      closest = p
      dist = d
  return [closest,dist]

return if isClient

Asteroid.autospawn = (opts={})->
  NUU.on 'start', ->
    center = $obj.byId[0]
    roids = [
      { name:"Asteroid Belt",         parent:center,             belt:4.0325e8, width:3e8,     count:2000 }
      { name:"Kuyper Belt",           parent:center,             belt:5.984e9,  width:2.992e9, count:5000 }
      { name:"D Ring",                parent:$obj.byName.Saturn, belt:78315,    width:7610,    count:500 }
      { name:"C Ring",                parent:$obj.byName.Saturn, belt:100671,   width:17342,   count:500 }
      { name:"B Ring",                parent:$obj.byName.Saturn, belt:130370,   width:25580,   count:500 }
      { name:"Cassini Division",	    parent:$obj.byName.Saturn, belt:124465,   width:4590,    count:500 }
      { name:"A ring",	              parent:$obj.byName.Saturn, belt:144077,   width:14605,   count:500 }
      { name:"Roche Division",	      parent:$obj.byName.Saturn, belt:140682,   width:2605,    count:500 }
      { name:"F Ring",	              parent:$obj.byName.Saturn, belt:139930,   width:500,     count:500 }
      { name:"Janus/Epimetheus Ring", parent:$obj.byName.Saturn, belt:156500,   width:5000,    count:1000 }
      { name:"G Ring",	              parent:$obj.byName.Saturn, belt:179500,   width:9000,    count:1000 }
      { name:"Methone Ring Arc",	    parent:$obj.byName.Saturn, belt:194230,   width:500,     count:1000, arc:PI/2 }
      { name:"Anthe Ring Arc",  	    parent:$obj.byName.Saturn, belt:197665,   width:500,     count:1000, arc:PI/2 }
      { name:"Pallene Ring",	        parent:$obj.byName.Saturn, belt:214750,   width:2500,    count:1000 }
      { name:"E Ring",                parent:$obj.byName.Saturn, belt:630000,   width:300000,  count:1000 }
      { name:"Phoebe Ring",           parent:$obj.byName.Saturn, belt:4500000,  width:9000000, count:1000 }]
    new Asteroid.Belt o for o in roids
    return
  $worker.push =>
    # roids  = @list.length
    # if roids < opts.max
    #   dt = opts.max - roids
    #   new Asteroid for i in [0...dt]
    1000
  return

$obj.register class Asteroid.Fragment extends $obj
  @interfaces: [$obj,Shootable,Debris,Asteroid]
  ttlFinal:    true
  localObject: true
  constructor: (opts)->
    console.log 'fragment'
    opts.sprite = 'asteroid-D' + ( opts.size - 10 ).toString().padStart 2, '0'
    opts.ttl = NUU.time() + 60000
    super opts
    @armour = @armourMax = 10 * @size
  toJSON:-> id:@id, key:@key, hostile:@hostile, resource:@resource, state:@state, size:@size, ttl:@ttl

Asteroid::hit = (perp,weapon)->
  return if @destructing
  return unless dmg = weapon.stats.physical
  @armour = max 0, @armour - dmg
  NET.mods.write @, ( if @armour is 0 then 'destroyed' else 'hit' ), 0, @armour
  return unless @armour is 0
  if @resource.length > 1 then for r in @resource
    @update()
    console.log @v
    fragment = new Asteroid
      toJSON:-> id:@id, key:@key, hostile:@hostile, resource:@resource, state:@state, size:@size, ttl:@ttl
      virtual: false
      hostile: []
      resource: [r]
      size: size = max 10, floor random() * @size / 2
      state: S:$moving, x:@x, y:@y, v: [ @v[0] - .02 + random() * .04, @v[1] - .02 + random() * .04 ]
    Weapon.hostility perp, fragment
  else
    NUU.emit 'asteroid:destroyed', perp, @resource
    console.log "mined fragment"
  @destructor()
  null
