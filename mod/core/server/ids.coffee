
# ██████   ██████   ██████  ██
# ██   ██ ██    ██ ██    ██ ██
# ██████  ██    ██ ██    ██ ██
# ██      ██    ██ ██    ██ ██
# ██       ██████   ██████  ███████

$public class IdPool
  empty: 0x00
  full:  0xFF
  constructor:(opts)->
    Object.assign @,opts
    @length   = 0
    @lastFree = 0
    @s = if @s? then @s else $id.getRange @max
    @u = new Uint8Array @max/8
    # @f = new Set
    $id[@name] = @
    $id.pools.push @
    # console.log "pool(#{@name}:#{@s}:#{@max}) get:#{@lastFree}".bold.inverse
  take:(obj)->
    obj.pool = @
    id = obj.id - @s
    @u[byteNum = floor id/8] = byte = @u[byteNum] + ( 1 << bit = id - byteNum*8 )
    @lastFree = byteNum unless byte is @full
    @length++
    # console.log "pool(#{@name}:#{@s}:#{@lastFree}:#{@max}) take(#{byteNum}:#{bit}:#{id}) byte(#{byte.toString 2})"
  free:(id)->
    bit = ( id = id - @s ) - 8*byteNum = floor id/8
    #console.log "pool(#{@name}:#{@s}:#{@lastFree}:#{@max}) free(#{byteNum}:#{bit}:#{id}) byte(#{@u[byteNum].toString 2})".red
    @u[byteNum] = byte = @u[byteNum] ^ ( 1 << bit )
    # @f.add byteNum
    @length--
    # console.log "pool(#{@name}:#{@s}:#{@lastFree}:#{@max}) free(#{byteNum}:#{bit}:#{id}) byte(#{byte.toString 2})".yellow
  getBlock:->
    c = @max; f = @full; l = @lastFree || 0
    return p for i in [0..@max] when f isnt @u[p = l + i % c]
    throw new Error 'Pool out of Bocks'
  get:(obj)->
    # console.log "pool(#{@name}:#{@s}:#{@max}) get:#{@u[@lastFree].toString 2}".bold.inverse.red
    byte = b unless 0xFF is b = @u[byteNum = @lastFree]
    byte = b unless 0xFF is b = @u[byteNum = @getBlock()] unless byte?
    throw new Error 'Pool out of Ids' unless byte?
    for bit in [0..7] when 0 is ( byte & ( 1 << bit ) )
      obj.id = id = @s + byteNum*8 + bit
      @take obj
      # console.log "pool(#{@name}:#{@s}:#{@lastFree}:#{@max}) get(#{byteNum}:#{bit}:#{id}) byte(#{byte.toString 2})"
      return
    throw new Error 'Pool out of Ideas, also this should not happen... o0'

new class IdManager
  reserved: new Map
  lastId:   0
  maxId:    0xFFFF
  pools:    []
  constructor:->
    $static '$id', @
    new IdPool name:'eternal', max:10000
    new IdPool name:'dynamic', max:20000
  getRange:->
    l = 0
    l = max l, pool.s + pool.max for pool in @pools
    l
  free:(list)->
    list = list.sort (a,b)-> a-b
  reserve:(obj,max,key='_'+obj.id)->
    @[key] = new IdPool
    id      = @lastId + 1
    @lastId = @lastId + max
    @reserved.set obj, max
