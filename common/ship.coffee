
class Ship extends $obj
  @byId : {}
  @byTpl : {}
  @byName : {}

  d : 0
  mx : 0
  my : 0
  iff : ''
  name : ''
  accel : no
  retro : no
  right : no
  left : no

  thrust : 0.1
  turn : 10.0
  type : 0
  cargo : 10

  reactorOut : 10.0
  cap : 100
  capMax : 100

  armor : 100
  shield : 100
  shieldMax : 100
  shieldRegen : 0.1

  fuel : 100

  sprite : 'shuttle'
  size : 32
  cols : 18
  rows : 6
  count : 108

  mount : []
  inventory : []
  slot : []

  loadAssets: (callback) ->
    @img = Sprite.imag.loading
    url = ( name = @sprite ) + '/' + name
    url = url.replace(/_.*/,'')+'/'+name if name.match /_/
    console.log 'load_assets', name, url
    async.parallel [
      (cb) =>
        Sprite.load 'ship', name, url, (img) =>
          @img = img
          @size = ( img.naturalWidth - ( img.naturalWidth % @cols ) ) / @cols
          @count = @cols * @rows
          Sprite.update(@)
          cb null
      (cb) =>
        Sprite.load 'ship',name+'_comm',url+'_comm', (img) =>
          Sprite.lastload = img # for splash progress
          @img_comm = img
          cb null
      (cb) =>
        Sprite.load 'ship',name+'_engine',url+'_engine', (img) =>
          @img_engine = img
          cb null
    ], callback

  constructor : (opts) ->
    super opts
    @slots = _.clone @slots
    @loadAssets(->) if isClient
    console.log "Ship", @id
    State.change @, fixed
    # register with engine
    Ship.byId[@id] = @

    @mockSystems()
    @updateMods()
    $worker.push Ship.model @

  mockSystems: -> # equip fake waepons for development
    Mock = 
      weapon :
        large : Object.keys Item.byType.weapon.large
        medium : Object.keys Item.byType.weapon.medium
        small : Object.keys Item.byType.weapon.small
      utility :
        large : Object.keys Item.byType.utility.large
        medium : Object.keys Item.byType.utility.medium
        small : Object.keys Item.byType.utility.small
      structure :
        large : Object.keys Item.byType.structure.large
        medium : Object.keys Item.byType.structure.medium
        small : Object.keys Item.byType.structure.small
    for k,slt of @slots.weapon when not slt.equip?
      slt.equip = new Weapon(Mock.weapon[slt.size].shift())
    for k,slt of @slots.structure when not slt.equip?
      if slt.default then slt.equip = new Outfit(slt.default)
      #else slt.equip = new Outfit(Mock.structure[slt.size].shift())
    for k,slt of @slots.utility when not slt.equip?
      if slt.default then slt.equip = new Outfit(slt.default)
      #else slt.equip = new Outfit(Mock.utility[slt.size].shift())

  updateMods: -> # calculate mods
    @mods = {}
    @mass = 0
    for type of @slots
      for idx of @slots[type]
        slot = @slots[type][idx]
        item = slot.equip
        if item
          @mass += item.general.mass
          unless type is 'weapon'
            for k,v of item.specific when k isnt 'turret'
              if @mods[k] then @[k] += v
              else @[k] = v
              @mods[k] = true

    # apply mods
    map =
      thrust :      @thrust_mod || 100
      turn :        @turn_mod   || 100
      shield :      @shield_mod || 100
      shieldMax :   @shield_mod || 100
      shieldRegen : @shield_mod || 100
    @[k] += @[k] * ( v / 100 ) for k,v of map

    # scale model values
    @fuel   = @fuel   * 1000
    @turn   = @turn   / 10
    @thrust = @thrust / 100
    null

  nextWeap : (player,trigger='primary') ->
    ws = player.vehicle.slots.weapon
    tg = player[trigger]
    tg.id   = min(++tg.id,ws.length-1)
    tg.slot = ws[tg.id].equip

  prevWeap : (player,trigger='primary') ->
    ws = player.vehicle.slots.weapon
    tg = player[trigger]
    tg.id = max(--tg.id,0)
    tg.slot = ws[tg.id].equip

  hit : (src,wp) ->
    return if @destructing
    NUU.emit 'hitTarget', @, src
    NUU.emit 'hitTarget', @id, src.id
    dmg = wp.specific.damage
    if @shield > 0
      @shield -= dmg.penetrate * 4
      if @shield < 0
        @armor += @shield
        @armor -= dmg.physical
        @shield = 0
        NUU.emit 'shieldDown', @, src
        NUU.emit 'shieldDown', @id, src.id
      else if @armor > 75
        @armor -= dmg.physical
    else
      @armor -= dmg.penetrate
      @armor -= dmg.physical
    if @armor < 25 and @disabled > 10
      NUU.emit 'targetDisabled', @, src
      NUU.emit 'targetDisabled', @id, src.id
    else if @armor < 0
      @armor = 0
      @shield = 0
      @shieldRegen = 0
      @destructing = true
      NUU.emit 'targetDestroyed', @, src
      NUU.emit 'targetDestroyed', @id, src.id

  toJSON : -> return {
    tpl   : @tpl
    id    : @id
    d     : @d
    x     : @x
    y     : @y
    ms    : @ms
    msd   : @msd
    msx   : @msx
    msy   : @msy
    state : @state }

  @model : (s) ->
    add = null
    return ->
      s.cap = min(s.cap + s.reactorOut,s.capMax)
      add = min(s.shield+min(s.shieldRegen,s.cap),s.shieldMax) - s.shield
      s.shield += add; s.cap -= add
      null

$public Ship