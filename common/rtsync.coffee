###
  ## NUU # drake
###

class CommonRTSync extends EventEmitter
  VERSION_SELF : "RTSync v1.0-dev-65"
  VERSION_COMP : "RTSync v1.0-dev-65"
  resolve  : {}

  setFlags : (a) ->
    c = 0
    c += Math.pow(2,k) for k,v of a when v
    c

  getFlags : (c) ->
    a = []
    a.push(if c >> i is 1 then (c -= Math.pow(2,i); true) else false) for i in [7..0]
    a.reverse()
  
  define : (name,opts={}) ->
    lower = name.toLowerCase()
    unless @[name]?
      c = @define.index++
      @[name] = s = String.fromCharCode c
      @[lower] = {}
      @[lower+'Code'] = c
    for k,v of opts
      @[lower][k] = (
        if v? and (typeof v is 'object') and (v.client? or v.server?)
          if isClient and v.client? then v.client
          else if v.server?         then v.server
        else @[lower][k] = v )
    @resolve[@[lower+'Code']] = @[lower].read if @[lower].read?

  route : (ctx,src) =>
    res = @resolve
    (msg) =>
      msg = new Buffer msg, 'binary'
      fnc = res[msg[0]]
      fnc.call @, msg, ctx if fnc?

  bind : (name,fnc) -> @resolve[@[name]] = fnc

  constructor : ->
    $static 'NET', @
    @define.index = 1
    @define 'NOOP'
    @define 'JSON',
      read : server : (msg,src) =>
        msg = JSON.parse msg.slice(1).toString('utf8')
        for k, v of msg
          console.log 'NET.json<', k, v
          @emit k, v, src
      write : client : (msg) =>
        console.log 'NET.json>', msg
        @send @JSON + JSON.stringify msg
    app.emit 'protocol'

$public CommonRTSync
$static 'RTSync', CommonRTSync
