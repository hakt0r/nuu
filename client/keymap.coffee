###

  * c) 2007-2015 Sebastian Glaser <anx@ulzq.de>
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

ON = 'on'; OFF = 'off'

class Autopilot
  macro : =>
    if @interval?
      clearInterval @interval
      delete @interval
    else
      p = NUU.player
      v = NUU.vehicle
      t = NUU.target
      @interval = setInterval ( ->
        old = v.flags
        vec = NavCom.autopilot(v,t)
        NET.state.write(v,v.flags = vec.flags) if old isnt vec.flags
      ), 50

class MouseInput
  state : off
  check : undefined
  event : x:0, y:0
  proxy : x:0, y:0, d:0
  update : (evt) =>
    e = @event; p = @proxy
    e.x = evt.offsetX
    e.y = evt.offsetY
    p.x = Sprite.hwidth
    p.y = Sprite.hheight
    @reset() if @check?
    @check = setInterval @callback(NUU.vehicle,p), TICK
  reset : =>
    clearInterval @check
    delete @check
  callback : (v,p) => =>
    p.d = v.d
    [turn,left] = NUU.turnTo p, @event
    @reset() unless turn
    NET.state.write v, [ v.accel, no, v.right = turn and not left, v.left = left, no, no, no, no]
  macro : =>
    @state = not @state
    action = if @state then ON else OFF
    $('canvas')[action] 'mousemove', @update

  null

class Keyboard extends EventEmitter
  kmap : { "/":191,"capslock":20,"+":109, "-":107, "-":107, ",":188, ".":190, bksp:8, tab:9, return:13, ' ':32, esc:27, left:37, up:38, right:39, down:40, del:46, 0:48, 1:49, 2:50, 3:51, 4:52, 5:53, 6:54, 7:55, 8:56, 9:57, a:65, b:66, c:67, d:68, e:69, f:70, g:71, h:72, i:73, j:74, k:75, l:76, m:77, n:78, o:79, p:80, q:81, r:82, s:83, t:84, u:85, v:86, w:87, x:88, y:89, z:90 }

  default_map :
    'S/' :   'about'
    "+" :    'scanPlus'
    "-" :    'scanMinus'
    esc :    'console'
    " " :    'primaryTrigger'
    u :      'secondaryTrigger'
    return : 'console'
    capslock : 'mouseturn'
    w :      'accel'
    Sw :     'boost'
    s :      'retro'
    a :      'steerLeft'
    Sa :     'autopilot'
    d :      'steerRight'
    y :      'targetNext'
    g :      'targetPrev'
    Sy :     'targetClassNext'
    Sg :     'targetClassPrev'
    i :      'weapNext'
    o :      'weapPrev'
    Si :     'weapNextSec'
    So :     'weapPrevSec'
    l :      'land'
    Sm :     'launch'
    m :      'orbit'
    h :      'help'
 
  _up : {}
  _dn : {}
  mmap : {}
  help : {}
  state : {}
  rmap : {}

  constructor : ->
    Kbd = @

    if navigator.appVersion.match(/WebKit/g)?
      @layout = "mac/webkit"
      @kmap["+"] = 187; @kmap["-"] = 189
    else if navigator.appName.match(/Netscape/g)? and navigator.appVersion.match(/Macintosh/g)?
      @layout = "mac/mozilla"
    else if navigator.appName.match(/Netscape/g)? and navigator.appVersion.match(/X11/g)?
      @layout = "unix/mozilla"

    sendAction = => NET.state.write(NUU.vehicle,[
      @state[@mmap["accel"]],
      @state[@mmap["retro"]],
      @state[@mmap["steerRight"]],
      @state[@mmap["steerLeft"]],
      @state[@mmap["boost"]],
      0,0,0])

    @cmap = {}
    @cmap[v] = k for k,v of @kmap
    @macro[macro] = up : sendAction, dn : sendAction for macro in ["accel","retro","steerRight","steerLeft","boost"]
    @bind key, macro for key, macro of @default_map

  macro :

    about: ->
      about = $ """
        <div class="about">
          <div class="tabs" id="tabs">
            <a class="tabbtn" href="#game">Game</a>
            <a class="tabbtn" href="#node">Libraries</a>
            <a class="tabbtn" href="#artwork">Artwork</a>
            <a class="tabbtn" href="#sounds">Sounds</a>
            <a class="close"  href="#">Close</a>
          </div>
          <div class="tab" id="game">
            <img src="/build/imag/nuulogo.png">
            <p/><ul>
              <li>c) 2007-2015 Sebastian Glaser <anx@ulzq.de></li>
              <li>c) 2007-2008 flyc0r</li>
            </ul>

            <p/>The nuu project intends to use all the asset files according to
            their respective licenses.

            <p/>nuu currently uses the graphics and sound assets of the excellent
            naev project, which in turn are partly attributable to the
            Vega Strike project.

            <p/>All assets are downloaded from their source repo to the contrib
            folder during the build process and LICENSE information is copied
            to the build directory as well as bein made available in the
            client's about screen and the server splash.
          </div>
          <div class="tab" id="node" data-src="/build/node_packages.html"></div>
          <div class="tab pre" id="artwork" data-src="/build/ARTWORK_LICENSE.txt"></div>
          <div class="tab pre" id="sounds"  data-src="/build/SOUND_LICENSE.txt"></div>
        </div>
      """
      about.appendTo $ 'body'
      about.find('.close').on 'click', -> about.remove()
      tabs = about.find '.tab'
      tabs.each (k,i) -> if (src = $(i).attr 'data-src' )
        $.get src, (data,s,x) -> $(i).html data
      activate = (name) ->
        tabs.css 'display', 'none'
        $('#'+name.replace(/.*#/,'')).css 'display', 'block'
      btns = about.find '.tabbtn'
      btns.on 'click', -> activate @href
      activate '#game'

    autopilot : (new Autopilot).macro

    launch : ->
      t = NUU.target
      NET.dock.write(t,'launch')

    orbit : ->
      t = NUU.target
      NET.dock.write(t,'orbit')

    help : ->
      h = ['Help:']
      for key, macro of Kbd.help
        h.push '\t' + key + ": " + Kbd.d10[macro]
      console.user h.join '\n'
      vt.focus()

    mouseturn : (new MouseInput).macro

    weapNext : ->
      p = NUU.player; s = p.primary; o = s.id; primary = yes
      p.vehicle.nextWeap(p)
      # NET.weap.write('select',primary,s.slot.id) unless o is s.id
    weapPrev : ->
      p = NUU.player; s = p.primary; o = s.id; primary = yes
      p.vehicle.prevWeap(p)
      # NET.weap.write('select',primary,s.slot.id) unless o is s.id
    weapNextSec : ->
      p = NUU.player; s = p.secondary; o = s.id; primary = no
      p.vehicle.nextWeap(p,'secondary')
      # NET.weap.write('select',primary,s.slot.id) unless o is s.id
    weapPrevSec : ->
      p = NUU.player; s = p.secondary; o = s.id; primary = no
      p.vehicle.prevWeap(p,'secondary')
      # NET.weap.write('select',primary,s.slot.id) unless o is s.id

    primaryTrigger :
      dn : ->
        p = NUU.player; s = p.primary.id; t = NUU.target.id
        NET.weap.write('trigger',yes,s,t)
      up : ->
        p = NUU.player; s = p.primary.id
        NET.weap.write('release',yes,s)

    secondaryTrigger :
      dn : ->
        p = NUU.player; s = p.secondary.id; t = NUU.target.id
        NET.weap.write('trigger',no,s,t)
      up : ->
        p = NUU.player; s = p.secondary.id
        NET.weap.write('release',no,s)

    targetClassNext : ->
      list = [Ship.byId,Stellar.byId,Debris.byId]
      NUU.targetId = 0
      NUU.targetClass = Math.min(++NUU.targetClass,list.length-1)
    targetClassPrev : ->
      list = [Ship.byId,Stellar.byId,Debris.byId]
      NUU.targetId = 0
      NUU.targetClass = Math.max(--NUU.targetClass,0)
    targetNext : ->
      list = [Ship.byId,Stellar.byId,Debris.byId]
      cl = list[NUU.targetClass]
      list = Object.keys(cl)
      NUU.targetId = id = Math.min(++NUU.targetId,list.length-1)
      NUU.target = cl[list[id]]
      NUU.emit 'newTarget', NUU.target
    targetPrev : ->
      list = [Ship.byId,Stellar.byId,Debris.byId]
      cl = list[NUU.targetClass]
      NUU.targetId = id = Math.max(--NUU.targetId,0)
      list = Object.keys(cl)
      NUU.target = cl[list[id]]
      NUU.emit 'newTarget', NUU.target

    console : ->
      vt.prompt 'nuu #', (text) ->
        console.user eval(text).toString()

    scanPlus : ->  Sprite.scanner.scale = Sprite.scanner.scale / 2
    scanMinus : -> Sprite.scanner.scale = Sprite.scanner.scale * 2

  __dn : (e) =>
    code = e.keyCode
    code = 'S'+code if e.shiftKey
    macro = @rmap[code]
    return if @state[code] is true
    notice 100, "d[#{code}]:#{macro}"
    @state[code] = true
    @_dn[macro](e) if @_dn[macro]?
    e.preventDefault()

  __up : (e) =>
    code = e.keyCode
    code = 'S'+code if e.shiftKey
    macro = @rmap[code]
    return if @state[code] is false
    notice 100, "u[#{code}]:#{macro}"
    @state[code] = false
    @_up[macro](e) if @_up[macro]?
    e.preventDefault()

  bind : (key,macro,opt) =>
    opt = @macro[macro] unless opt?
    opt = up : opt if typeof opt is 'function'
    unless opt?
      console.log 'misbind', key, macro, opt
      return
    @_up[macro] = opt.up if opt.up?
    @_dn[macro] = opt.dn if opt.dn?
    if key.match /S/
      keyCode = 'S' + @kmap[key.replace /^S/, '']
    else keyCode = @kmap[key]
    @mmap[macro] = keyCode
    @state[keyCode] = off
    @rmap[keyCode] = macro
    @help[key] = macro

  focus : =>
    $(window).on 'keydown', @__dn
    $(window).on 'keyup', @__up

  unfocus : =>
    $(window).off 'keydown', @__dn
    $(window).off 'keyup', @__up

  d10 :
    about:            "Show about / License"
    help:             "Show help"
    execute:          "Execute something"
    primaryTrigger:   "Fire primary"
    primaryPrev:      "Primary prev weapon"
    primaryNext:      "Primary next weapon"
    scondaryPrev:     "Secondary prev weapon"
    scondaryNext:     "Secondary next weapon"
    secondaryTrigger: "Fire secondary"
    accel:            "Accelerate"
    retro:            "Decellerate"
    steerLeft:        "Turn left"
    steerRight:       "Turn right"
    autopilot:        "Turn to target"
    targetNext:       "Next ship"
    targetPrev:       "Prev ship"
    stellarNext:      "Next stellar"
    stellarPrev:      "Prev stellar"
    hostNext:         "Next hostile"
    hostPrev:         "Prev hostile"
    escape:           "Exit something"
    booster:          "Boost"
    consO:            "Console"
    consC:            "Console script"
    scanPlus:         "Zoom scanner in"
    scanMinus:        "Zoom scanner out"
    land:             "Land"
    dock:             "Dock"
    orbit:            "Orbit"
    toolbar:          "Toolbar"
    inventory:        "Inventory"
    outfit:           "Outfit (slot selection)"
    map:              "Show map"

window.Kbd = new Keyboard