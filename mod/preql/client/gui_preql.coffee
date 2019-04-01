
window.win = $(window) if window?

$ NUU.init = ->
  SpriteSurface::animate = ->
  window.Map = new URMap 333, 333, 1337
  new URControl
  Kbd.focus()


URMap::render = (force=no)->
  @tx = Math.ceil win.w / @scale
  @ty = Math.ceil win.h / @scale
  @map(force)
  @units()
  @hud()
  @minimap(force)

URMap::map = (force)->
  canvas = $ '<canvas>'
  canvas.css position: "absolute", top: "0px", left: "0px", width: "100%", height: "100%"
  canvas.appendTo $('body')
  ctx = canvas[0].getContext '2d'
  # Hook onto resize
  resize = =>
    canvas[0].height = win.h = win.height()
    canvas[0].width  = win.w = win.width()
    @map.dirty = true
  resize(); win.on 'resize', resize
  # Replace by renderer
  @map = (force)=>
    return unless force or @map.dirty; @map.dirty = no
    ctx.fillStyle = '#000'
    ctx.fillRect 0,0,win.w,win.h
    ox = @x
    oy = @y
    ow = ox + Math.min(@w,Math.ceil(win.width()/@scale))
    oh = oy + Math.min(@h,Math.ceil(win.height()/@scale))
    for x in [ox..ow]
      for y in [oy..oh]
        val = (h = @height[idx = x+y*@w]).toString(16)
        val = "0"+val if h < 16
        sx = -@x*@scale+x*@scale
        sy = -@y*@scale+y*@scale
        ctx.fillStyle = (
          if h > 100 then '#'+val+val+val
          else if h > 54
            '#00'+val+"00"
          else if h > 49 then '#'+val+val+'00'
          else '#0000'+val )
        ctx.fillRect sx,sy,@scale,@scale
    null
  @map()

URMap::units = ->
  canvas = $ '<canvas>'
  canvas.css position: "absolute", top: "0px", left: "0px", width: "100%", height: "100%"
  canvas.appendTo $('body')
  ctx = canvas[0].getContext '2d'
  # Hook onto resize
  resize = =>
    canvas[0].height = win.h = win.height()
    canvas[0].width  = win.w = win.width()
  resize(); win.on 'resize', resize
  # Replace by renderer
  @units = =>
    ctx.clearRect 0,0,win.w,win.h
    ox = @x
    oy = @y
    ow = ox + Math.min(@w,Math.ceil(win.width()/@scale))
    oh = oy + Math.min(@h,Math.ceil(win.height()/@scale))
    sb2 = @scale / 2
    now = Date.now()
    for k,u of URUnit.byId
      u.render(ctx,u.x-@x,u.y-@y,@scale,sb2,now)
    null

URMap::hud = ->
  @clickface = canvas = $ '<canvas>'
  canvas.css position: "absolute", top: "0px", left: "0px", width: "100%", height: "100%"
  canvas.appendTo $('body')
  ctx = canvas[0].getContext '2d'
  # Hook onto resize
  resize = =>
    canvas[0].height = win.h = win.height()
    canvas[0].width  = win.w = win.width()
  resize(); win.on 'resize', resize
  # Replace by renderer
  @hud = render = =>
    ctx.clearRect 0,0,win.width(),win.height()
    {drag, start:{x:mstx,y:msty},pos:{x:vx,y:vy}} = Control.mouse
    if Control.build? and (i = Control.build.instance)
      i.render ctx,vx-@x,vy-@y,@scale,@scale/2
    else if drag
      ctx.fillStyle = 'rgba(0,255,255,0.3)'
      # console.log mstx, vx, msty, vy
      ctx.fillRect (mstx)*@scale, (msty)*@scale, (vx-mstx)*@scale, (vy-msty)*@scale
    else
      # ctx.fillStyle = '#FFF'
      # ctx.fillText "c{#{@x}:#{@y}:#{@scale}}", 10, 20
      ctx.fillStyle = 'rgba(0,0,180,0.3)'
      ctx.fillRect (vx-@x)*@scale,(vy-@y)*@scale,@scale,@scale

URMap::minimap = ->
  frame = $ '<div>'
  frame.css position: "absolute", top: "0px", right: "0px", width: "100px", height: "100px"
  frame.appendTo $('body')
  canvas = $ '<canvas>'
  canvas.css position: "absolute", top: "0px", right: "0px", width: "100%", height: "100%"
  canvas.appendTo frame
  canvas[0].width  = @w
  canvas[0].height = @h
  ctx = canvas[0].getContext '2d'
  box = $ '<div>'
  box.css position: "absolute", top: "0px", left: "0px", width: "25px", height: "25px", border: "solid 1px red"
  box.appendTo frame
  # Draw minimap
  for x in [0..@w]
    for y in [0..@h]
      val = (h = @height[idx = x+y*@w]).toString(16)
      val = "0"+val if h < 16
      ctx.fillStyle = (
        if     h > 100 then '#'+val+val+val
        else if h > 54 then '#00'+val+"00"
        else if h > 49 then '#'+val+val+'00'
        else '#0000'+val )
      ctx.fillRect x,y,1,1
  # Replace by renderer
  @minimap = resize = (force)=>
    return unless force
    wbw = do frame.width  / @w
    hbh = do frame.height / @h
    wbs = do win.width    / @scale
    hbs = do win.height   / @scale
    box.css
      top:    Math.max(0 ,Math.floor( @y * ( frame.width()  / @w ) - 1)) + 'px'
      left:   Math.floor( @x * ( frame.height() / @h ) - 1) + 'px'
      width:  Math.min( do frame.width  - 2, Math.floor wbw * wbs ) + 'px'
      height: Math.min( do frame.height - 2, Math.floor hbh * hbs ) + 'px'
  resize(); win.on 'resize', resize.bind @, true

URMap::up      = => @y = Math.max(0,                    @y - Math.floor(1/@scale*100) ); @render yes
URMap::down    = => @y = Math.min(Math.floor(@h - @ty), @y + Math.floor(1/@scale*100) ); @render yes
URMap::left    = => @x = Math.max(0,                    @x - Math.floor(1/@scale*100) ); @render yes
URMap::right   = => @x = Math.min(Math.floor(@w - @tx), @x + Math.floor(1/@scale*100) ); @render yes
URMap::zoomin  = => @scale = Math.min(128,              @scale * 2);                     @render yes
URMap::zoomout = => @scale = Math.max(1,                @scale / 2);                     @render yes

Kbd.bind 'Space',    'mapcenter', dn: Map.debug
Kbd.bind 'ArrowUp',      'mapup', dn: ( -> Map.up.interval    = setInterval(Map.up,100) ),    up: ( -> clearInterval Map.up.interval )
Kbd.bind 'ArrowDown',    'mapdn', dn: ( -> Map.down.interval  = setInterval(Map.down,100) ),  up: ( -> clearInterval Map.down.interval )
Kbd.bind 'ArrowLeft',    'maple', dn: ( -> Map.left.interval  = setInterval(Map.left,100) ),  up: ( -> clearInterval Map.left.interval )
Kbd.bind 'ArrowRight',   'maprg', dn: ( -> Map.right.interval = setInterval(Map.right,100) ), up: ( -> clearInterval Map.right.interval )
Kbd.bind 'KeyPlus',      'mapzi', dn: Map.zoomin
Kbd.bind 'KeyMinus',     'mapzo', dn: Map.zoomout

#setInterval render, 500

window.URMenu = class URMenu
  @instance : null
  @stack : []
  @reset : -> i.frame.remove() for i in URMenu.stack.concat [URMenu.instance] when i?; URMenu.instance = null; URMenu.stack = []
  @close : -> URMenu.instance.frame.remove() if URMenu.instance; URMenu.instance = URMenu.stack.pop()
  constructor : ->
    URMenu.stack.push URMenu.instance if URMenu.instance
    URMenu.instance = @
    @frame = $ '<div class=menu>'
    @frame.css position: 'fixed', bottom: '0px', left: '25%', width: '50%', background: 'rgba(0,0,0,0.3)'
    @frame.appendTo $('body')
  add : (i,c,icon,hotkey) ->
    if hotkey
      o = i.toLowerCase().indexOf(hotkey)
      i = i.substr(0,o) + "<b>" + hotkey + "</b>" + i.substr(o+1)
    @frame.append btn = $ "<button class=menu_item>#{i}</button>"
    btn.prepend '<div class="icon left">' if icon
    btn.on 'click', c

window.URActionMenu = class URActionMenu extends URMenu
  constructor : (group) ->
    super()
    @group = group
    f = (a) => (e) => Control[a+'_action'](@group)
    actions = {}
    shortcuts = esc : -> URMenu.close(); Kbd.hotkey()
    actions[a] = yes for a in i.tpl.actions when not actions[a]? for i in @group
    for a of actions
      for l,c of a when not shortcuts[c]?
        shortcuts[c] = f(a)
        break
      @add a, f(a), null, c
    Kbd.hotkey shortcuts

window.URBuildMenu = class URBuildMenu extends URMenu
  constructor: (group)->
    super()
    @group = group
    end = -> URMenu.close(); Kbd.hotkey()
    build = {}
    shortcuts = esc : end
    f = (a) => (e) => end Control.build_unit(@group,a)
    for i in @group when i.tpl.build
      for a in i.tpl.build when not build[a]?
        for c in a when not shortcuts[c]?
          shortcuts[c] = f(a)
          break
        @add URUnit.tpl[a].name, f(a), i.tpl.icon, c
        build[a] = yes
    Kbd.hotkey shortcuts

  hotkey: (keys={})->
    @hotkey.keys = keys
    Kbd.release 'hotkeys'
    if if @hotkey.keys
      Kbd.grab 'hotkeys', =>
        if @hotkey.keys[@cmap[code]]
          @hotkey.keys[@cmap[code]] e
        null
    null

$public class URControl extends EventEmitter

  repair_action : (group)-> @selectPos (x,y)->
    break for k,t of URUnit.byPos[x+'x'+y]
    if t then for u in group
      u.order 'repair', target:t
  attack_action : (group)-> @selectPos (x,y)->
    break for k,t of URUnit.byPos[x+'x'+y]
    if t then for u in group
      u.order 'attack', target:t
  move_action  : (group) -> @selectPos (x,y) -> u.order 'move', x:x,y:y for u in group
  build_action : (group) -> new URBuildMenu group
  build_done : ->
    (i = @build).instance.setpos(@mouse.pos.x,@mouse.pos.y)
    ins = i.instance
    delete ins.placing
    if ins.tpl.type is "u"
      delete ins.building
    else if @build.group
      u.order 'repair', target:ins for u in @build.group when u.tpl.build? and u.tpl.build.indexOf i.item isnt -1
    @build = null
  build_unit : (group,tpl) ->
    @build = item : tpl, group : group, instance : i = new URUnit x:-1,y:-1,tpl:tpl,owner:@player
    i.placing  = yes
    i.building = yes

  selection : []

  mouse :
    drag : no
    start : x:0,y:0
    pos : x:0,y:0

  constructor : ->
    super()
    window.Control = @
    @selectbox = $ '<div>'
    @selectbox.css position: 'absolute', top: '100px', right: '0px', width: '100px', background: 'rgba(0,0,0,0.3)'
    @selectbox.appendTo $('body')
    @selectbox.html 'no selection'
    Map.clickface.on 'contextmenu', (e) ->
      e.preventDefault()
      true
    Map.clickface.on 'mouseup', @mouseup
    Map.clickface.on 'mousedown', @mousedown
    Map.clickface.on 'mousemove', @mousemove
    $(window).bind 'mousewheel', @scroll

    @worker = =>
      u.work() for k,u of @worker.list when u.work
      # Map.units()
    @worker.list = {}
    @worker.timer = setInterval @worker, 33

    @player = new URPlayer
    @build_unit null,'bld'

    # rulset stuff
    @zombie = new URPlayer

  selectPos : (callback) ->
    @selectPos.callback = callback

  scroll : (e) =>
    if e.originalEvent.wheelDelta > 0
      do Map.zoomin
    else do Map.zoomout

  # Hook mouse
  mousedown : (e) =>
    if e.which is 1
      Map.clickface.off 'mousemove', @mousemove
      Map.clickface.on  'mousemove', @mousemove_down
      Map.hud()
    else if e.which is 3
      e.preventDefault()
    false

  mousemove_down : (e) =>
    vx = Map.x + e.clientX / Map.scale
    vy = Map.y + e.clientY / Map.scale
    @mouse.pos.x = Math.ceil vx
    @mouse.pos.y = Math.ceil vy
    if not @mouse.drag
      Map.clickface.off 'mouseup', @mouseup
      Map.clickface.on  'mouseup', @mouseup_drag
      @mouse.drag = yes
      @mouse.start.x = Math.floor vx
      @mouse.start.y = Math.floor vy
    Map.hud()

  mouseup_drag : (e) =>
    Map.clickface.off 'mousemove', @mousemove_down
    Map.clickface.off 'mouseup', @mouseup_drag
    Map.clickface.on 'mouseup', @mouseup
    Map.clickface.on 'mousemove', @mousemove
    @mouse.drag = no
    for x in [@mouse.start.x..@mouse.pos.x]
      for y in [@mouse.start.y..@mouse.pos.y]
        for k,u of URUnit.byPos[x+"x"+y] when not u.selected
          @selection.push u
    @update_selection()
    Map.render()

  mouseup : (e) =>
    move = =>
      dest = x:@mouse.pos.x, y:@mouse.pos.y
      u.order 'move', dest for k,u of @selection
    Map.clickface.off 'mousemove', @mousemove_down
    Map.clickface.on  'mousemove', @mousemove
    @mouse.pos.x = Math.floor(Map.x + e.clientX / Map.scale)
    @mouse.pos.y = Math.floor(Map.y + e.clientY / Map.scale)
    if e.shiftKey or e.which is 3 then move()
    else if e.ctrlKey then @unselect_all()
    else if @build then @build_done()
    else if @selectPos.callback
      @unselect_all() unless e.shiftKey
      @selectPos.callback @mouse.pos.x,@mouse.pos.y
      @selectPos.callback = null
    else
      @unselect_all()
      if (s = URUnit.byPos[@mouse.pos.x+'x'+@mouse.pos.y])
        @selection.push u for k,u of s
        @update_selection()
    Map.render()

  mousemove : (e) =>
    @mouse.pos.x = Math.floor(Map.x + e.clientX / Map.scale)
    @mouse.pos.y = Math.floor(Map.y + e.clientY / Map.scale)
    Map.render()

  unselect_all : =>
    URMenu.reset()
    u.selected = no for k,u in @selection
    @selection = []
    @update_selection()

  update_selection : =>
    @selectbox.html ''
    for k,u of @selection
      u.selected = yes
      @selectbox.append u.tpl.name + '(' + Math.round(u.hp) + ')<br/>'
    new URActionMenu @selection
