###
  ## NUU # drake
###

freeId = []
lastId = 0

class $obj
  @byId : {}

  state : 0
  x : 0
  y : 0
  size : 0
  threads : []
  update : ->

  constructor : (opts={}) ->
    @stateRec = t:null,d:null,x:null,y:null,mx:null,my:null
    if opts.tpl then @[k] = v for k,v of Item.tpl[opts.tpl]
    @[k] = v for k,v of opts
    unless @id?
      @id = if freeId.length is 0 then lastId++ else freeId.shift()
    else lastId = max(lastId,@id+1)
    $obj.byId[@id] = @

  destructor : ->
    delete $obj.byId[@id]
    freeId.push @id
    # delete $obj[stateToKey[@state]][@id]

  dist : (o) -> sqrt(pow(abs(o.x-@x),2)-pow(abs(o.y-@y),2))

class CommonEngine extends EventEmitter
  time : Date.now
  threadList : {}
  players : {}
  constructor : ->
    console.log 'CommonEngine'
    $static 'NUU', @
    $static 'NET', new RTSync
    $worker.push Weapon.projectileDamage
    $worker.push Weapon.beamDamage
  start : ->
    console.log 'engine'.yellow, 'start'.green, @tstart = Date.now()
  stop : -> clearInterval i for k,i of @threadList
  thread : (name,time,fnc) -> @threadList[name] = setInterval fnc, time

$public CommonEngine, $obj