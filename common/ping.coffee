class Mean
  constructor : -> @reset()
  reset : (v) ->
    @last = 0; @total = 0; @count = 0; @avrg = 0
  add : (v) ->
    @count++
    @last = v
    @total += v
    @avrg = @total / @count

$public class CommonRTPing extends Mean
  INTERVAL : 500

  lag    : new Mean
  trip   : new Mean
  skew   : new Mean
  delta  : new Mean
  error  : new Mean
  jitter : new Mean

  ringId : 0
  ringBf : [null,null,null,null,null,null,null,null,null,null]

  lastLocalTime : Date.now()
  lastRemoteTime : Date.now()

  constructor : ->
    super
    $static 'Ping', @

  reset : ->
    super
    @lag.reset()
    @trip.reset()
    @skew.reset()
    @delta.reset()
    @jitter.reset()
    @error.reset()

app.on 'protocol', -> new RTPing
