
$public class URPlayer
  @byId : {}
  @nextid : 0
  credits : 0
  constructor : ->
    URPlayer.byId[@id = URPlayer.nextid++] = @

$public class URUnit
  @nextid : 0
  @byId : {}
  @byPos : {}
  @byPlayer : {}

  @tpl :
    byType : u : {}, b : {}
    bld: type: 'u', name:'Builder',  icon: 'left', cost: 80,   hp:5,   size:1.5, range:1,dps:1,tps:1,color:'#FF0',actions:['move','attack','build','repair'],build:['brk','trt']
    wrk: type: 'u', name:'Worker',   icon: 'left', cost: 150,  hp:2,   size:1.5, range:1,dps:1,tps:1,color:'#FF0',actions:['move','mine','repair']
    inf: type: 'u', name:'Infantry', icon: 'left', cost: 100,  hp:20,  size:1,   range:5,dps:5,tps:2,color:'#0F0',actions:['attack','move']
    inf: type: 'u', name:'Tank',     icon: 'left', cost: 1000, hp:300, size:2,   range:15,dps:50,tps:4,color:'#0F0',actions:['attack','move']
    brk: type: 'b', name:'Barraks',  icon: 'left', cost: 2000, hp:500, size:10,  color:'#F22', actions:['build','setrelay'], build: ['inf','bld','wrk']
    trt: type: 'b', name:'Turret',   icon: 'left', cost: 500,  hp:100, size:8,   color:'#F22', actions:['attack']

  selected : no

  constructor : (opts={}) ->

    @order = (o='wait',rec={}) =>
      # if rec.force
      @order.c.cancel() if @order.c and @order.c.cancel
      @order.q = []
      done = (success) =>
        console.log @id, o, 'done', rec, rec
        delete Control.worker.list[@id]
        rec.success() if rec.success
        @order.q.shift().start() if @order.q.length > 0
        name : 0
        target : target = rec.target
      rec.start = start = =>
        console.log @id, o, rec
        Control.worker.list[@id] = @
        @order.c = rec
        @[o](rec,done)
      if @order.q.length is 0 then start()
      else @order.q.push rec

    {x,y,tpl,@owner} = opts
    @owner = Control.player unless @owner
    URUnit.byId[@id = URUnit.nextid++] = @
    URUnit.byPlayer[@owner.id] = @
    @setpos(x,y)
    @tpl = URUnit.tpl[tpl||'bld']
    if @tpl.type is "u" then @unit()
    else @building()

  unit : ->
    @hp = @tpl.hp
    @order 'wait', force: yes

  building : ->
    @hp = 0
    @operational = 0

  setpos : (x,y) ->
    sector = x+"x"+y
    if URUnit.byPos[(oldsector = @x+'x'+@y)] and URUnit.byPos[oldsector][@id]
      delete URUnit.byPos[oldsector][@id]
      if Object.keys(URUnit.byPos[oldsector]) is 0
        delete URUnit.byPos[oldsector]
    @x = x; @y = y
    URUnit.byPos[sector] = {} unless URUnit.byPos[sector]
    URUnit.byPos[sector][@id] = @


  wait : (order,callback) -> callback true

  repair : (order,callback) ->
    target = order.target
    order.cancel = => delete @work
    @move order, (success) =>
      return callback false unless success
      @work = =>
        target.hp += 1
        if target.hp > target.tpl.hp
          target.hp = target.tpl.hp
          delete @work
          callback true


  attack : (order,callback) ->
    target = order.target
    inrange = =>
      order.cancel = => delete @work
      @work = =>
        target.hp -= @tpl.dps / 1000 * 33
        if target.hp < 0
          target.hp = 0
          callback true
    order.onwaypoint = =>
      if @distTo(target.x,target.y) <= @tpl.range
        order.cancel()
        inrange()
    @move order, (result) =>
      return callback false unless result
      inrange()

  move : (order,callback) ->
    return unless @tpl.tps
    done = =>
      @setpos(@moverec.x,@moverec.y)
      @moverec = null
      order.cancel = null
      callback true if callback
    waypoint = =>
      if @path.length > 0
        {x,y} = @path.shift()
        @setpos(@moverec.x,@moverec.y) if @moverec
        @moverec =
          x : x
          y : y
          eta : eta = 1 / @tpl.tps
          start : Date.now()
          timer : setTimeout waypoint, eta * 1000
        order.cancel = =>
          console.log 'cancel'
          @setpos(@moverec.x,@moverec.y)
          order.cancel = null
          clearTimeout @moverec.timer
        order.onwaypoint() if order.onwaypoint
      else done()
    {x,y} = order
    {target:{x,y}} = order unless x > 0 and y > 0
    try
      graph = new Graph(Map.walkmap(),diagonal:yes,heuristic:astar.heuristics.diagonal)
      start = graph.grid[@x][@y]
      end = graph.grid[x][y]
      @path = astar.search(graph,start,end)
      console.log @path
      waypoint()
    catch e
      callback false

  distTo : (x,y) -> Math.sqrt (dx=@x-x)*dx+(dy=@y-y)*dy

  render : (ctx,x,y,scale,sb2,now) ->
    if @moverec
      seconds_passed = (now - @moverec.start) / 1000
      completed = Math.min( seconds_passed / @moverec.eta, 1 )
      movex = completed * (@moverec.x - @x) * scale
      movey = completed * (@moverec.y - @y) * scale
    else movex = movey = 0
    sx = x * scale + movex + sb2
    sy = y * scale + movey + sb2
    ss = scale/10*@tpl.size
    s2 = ss * 2
    if @selected is true
      ctx.fillStyle = "#F00"
    else ctx.fillStyle = "#FF0"
    ctx.beginPath()
    ctx.arc sx,sy,ss,0,Math.PI*2
    ctx.fill()
    ctx.strokeStyle = "solid 1px #000"
    ctx.strokeRect sx-ss,sy-ss-5,s2,3
    ctx.fillStyle = "#F00"
    ctx.fillRect   sx-ss,sy-ss-5,s2,3
    ctx.fillStyle = "#0F0"
    ctx.fillRect   sx-ss,sy-ss-5,Math.round((@hp/@tpl.hp)*s2),3
    ctx.fillStyle = "#000"
    ctx.fillText   sx-ss,sy-ss,@hp+'/'+@tpl.hp

URUnit.tpl.byType[v.type][k] = v for k,v of URUnit.tpl when v.type?
