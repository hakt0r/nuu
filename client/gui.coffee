###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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

NUU.symbol = Launcher:'➜➤', Beam:'⌇', Projectile:'•', turret: '⦿', helm:'☸', passenger:'♿'

Weapon.guiSymbol = (e,u)->
  s = NUU.symbol[e.extends||e] || ''
  s = if s.length is 1 then s else if e.type is 'fighter bay' then s[1] else s[0]
  s += NUU.symbol.turret if e.turret
  s = s + '☢' if e.name and e.name.match 'Cheaters'
  s = if u then "[#{s}:#{u}]" else "[#{s}]"
  s

Weapon.guiName = (e)->
  s = Weapon.guiSymbol e
  n = e.name
  n = n.replace 'FighterBay', ''
  n = n.replace 'Beam', ''
  n = n.replace 'Launcher', ''
  n = n.replace 'Turret', ''
  n = n.replace 'Cannon', ''
  n = n.replace 'Cheaters', '' if n.match 'Cheaters'
  n = n.replace /.*Systems/, ''
  while m = n.match /([^ ])([A-Z][a-z])/
    n = n.replace m[0], m[1] + ' ' + m[2]
  return n.trim() + s

console.user = console.log
console.real = console.log

console.log = (args...) ->
  notice 200, args.join ' '
  console.real.apply console, args

window.log = (args...) ->
  console.log.apply console, ['$'].concat args.slice()
  console.user args.join(' ')

window.Notice = class Notice
  @queue : []
  constructor : (@msg,@timeout=1000) ->
    @timeout += Date.now()
  toString : -> @msg

setInterval ( =>
  n = Date.now()
  Notice.queue = Notice.queue.filter (e) -> e.timeout > n
), 100

window.notice = (timeout,msg) ->
  msg = [msg] if typeof msg is 'string'
  Notice.queue.push new Notice line, timeout for line in msg
  null

$public class Window
  constructor : (opts={}) ->
    Object.assign @, opts
    window[@name] = @ if @name
    $('body').append @$ = $ "<div class='window'></div>"
    @$.append @head = $ "<header>#{@title}</header>" if @title
    @$.append @body = $ "<div></div>"
    $cue @show()
  show:->
    @$.css "display", "initial"
    @visible = yes
    @focus()
    @
  close:->
    do @unfocus
    @$.remove()
    delete window[@name] if @name
    @
  hide:->
    do @unfocus
    @$.css "display", "none"; @visible = no; @
  toggle:-> do @[if @visible then 'hide' else 'show']; @
  focus:->
    Kbd.grab @,
      onkeyup:   @keyHandler
      onkeydown: @keyDownHandler
      onpaste:   @pasteHandler
    return @
  unfocus:-> Kbd.release @; @
  keyHandler: (evt,code)=>
    switch code
      when @closeKey, 'Escape'
        @close();
        evt.preventDefault()
        return false
    true

Window.About = class AboutWindow extends Window
  title: 'About NUU / License'
  closeKey:'aKeyH'
  constructor:->
    super
    @$.addClass 'about full'
    @$.append $ """
      <div class="tabs" id="tabs">
        <a class="tabbtn" href="#game">Game</a>
        <a class="tabbtn" href="#node">Libraries</a>
        <a class="tabbtn" href="#artwork">Artwork</a>
        <a class="tabbtn" href="#sounds">Sounds</a>
        <a class="close"  href="#">Close</a>
      </div>
      <div class="tab" id="game">
        <img src="/build/imag/logo_2018_2.svg">
        <p><ul class="copyrights">
          <li>c) 2007-2018 Sebastian Glaser <anx@ulzq.de></li>
          <li>c) 2007-2018 flyc0r</li>
        </ul></p>

        <p class="desc">The nuu project intends to use all the asset files
        according to their respective licenses.</p>

        <p class="desc">nuu currently uses the graphics and sound assets of
        the excellent naev project, which in turn are partly attributable to the
        Vega Strike project.</p>

        <p class="desc">All assets are downloaded from their source repo to
        the contrib folder during the build process and LICENSE information is
        copied to the build directory as well as being made available in the
        client's about screen and the server splash.</p>
      </div>
      <div class="tab" id="node" data-src="/build/node_packages.html"></div>
      <div class="tab" id="artwork" data-src="/build/ARTWORK_LICENSE.html"></div>
      <div class="tab" id="sounds"  data-src="/build/SOUND_LICENSE.html"></div>
    """
    @$.find('.close').on 'click', => @close()
    @tabs = @$.find '.tab'
    @tabs.each (k,i) =>
      src = $(i).attr 'data-src'
      console.log src
      return unless src
      $.get src, (data,s,x) => $(i).html data
    btns = @$.find '.tabbtn'
    w = @
    btns.on 'click', -> w.activate @href
    @activate '#game'
  activate: (name) ->
    @tabs.css 'display', 'none'
    name = name.replace(/.*#/,'')
    console.log name
    $('#'+name).css 'display', 'block'


$public class ModalListWindow extends Window
  constructor:(opts)->
    super opts
    @$.addClass 'modal_list'
    if @fetch
      @body.append i = $ """<div class="list-item active"><label>..</label><span>[up one level]</span></div>"""
      i.on 'click', i[0].action = => @close()
      @body.append l = $ """<div class="list-item active"><label>..</label><span>[loading...]</span></div>"""
      @fetch (@subject)=>
        l.remove()
        @render key,val for key, val of @subject
    else if @subject
      @body.append i = $ """<div class="list-item active"><label>..</label><span>[up one level]</span></div>"""
      i.on 'click', i[0].action = => @close()
      @render key,val for key, val of @subject
    @$.find("*").addClass 'noselect'
    null
  keyHandler: (evt,code)=>
    list = @$.find('.list-item').toArray()
    cur = @$.find('.list-item.active').first()
    if cur.length is 0
      cur.addClass 'active'
      cur = $ list.first()
    index = list.indexOf cur[0]
    count = list.length
    switch code
      when @closeKey, 'Escape'
        @close(); p = @
        p.close() while p = p.parent
      when 'Enter'     then cur[0].action.call @ if cur[0].action
      when 'PageUp'    then next = $ list.shift()
      when 'PageDown'  then next = $ list.pop()
      when 'ArrowUp'   then next = $ list[( count + index - 1 ) % count]
      when 'ArrowDown' then next = $ list[( index + 1 ) % count]
      when 'ArrowLeft','ArrowRight'
        cb = cur.find 'button.active'
        return 'nocur' if cb.length is 0
        lb = cur.find('button').toArray()
        ix = lb.indexOf cb[0]
        ct = lb.length
        ad = if code is 'ArrowLeft' then -1 else 1
        nx = $ lb[( ct + ix + ad ) % ct]
        cur.find('button').removeClass 'active'
        nx.addClass 'active'; cur[0].action = => nx.first().click()
    return unless next
    $(list).removeClass 'active'
    next.addClass 'active'
    nt = next.position().top
    pt = next.parent().scrollTop()
    next.parent()[0].scrollTo top: pt + nt
    return if 0 is ( btns = next.find 'button' ).length
    next.parent().find('button').removeClass 'active'
    btns.first().addClass 'active'; next[0].action = => btns.first().click()


class Object.editor extends ModalListWindow
  render:(key,val) => switch typeof val
    when 'object'
      @body.append i = $ """<div class="list-item"><label>#{key}</label><span>[directory]</span></div>"""
      i.on 'click', i[0].action = => w = new Object.editor name:@name+'.'+key, title:'Settings:'+key, subject: val, parent: @, closeKey: @closeKey
    when 'string'
      @body.append i = $ """<div class="list-item"><label>#{key}</label><span>#{val}</span></div>"""
      i.on 'click', i[0].action = => new String.editor parent:@ title:key, default:val, callback:(error,value)=>
        i.find('span').html if @subject[key] = val = value
        NUU.saveSettings()
    when 'boolean'
      @body.append i = $ """<div class="list-item"><label>#{key}</label><span>#{if val then 'true' else '<span class="red">false</div>'}</span></div>"""
      i.on 'click', i[0].action = =>
        i.find('span').html if @subject[key] = val = not val then 'true' else '<span class="red">false</div>'
        NUU.saveSettings()

Window.KeyBinder = class KeyBinder extends ModalListWindow
  constructor: (opts)->
    @name = 'edit.string'
    @keyHandler = @capture
    super opts
    @$.css 'bottom', 'initial'
    @body.addClass 'big_fat'
    @body.html @default
  confirm: (evt,code)->
    if code is "Enter"
      return unless @value
      do @close
      return @callback null, @value
    else if code is "Escape"
      do @close
      return @callback null, @default
  capture: (evt,code)->
    return do @close if code is 'Escape'
    @body.html @value = code + '<br/>Escape | Enter'
    @unfocus(); @keyHandler = @confirm.bind @; @focus()

Window.Help = class HelpWindow extends ModalListWindow
  name: 'help'
  title: 'Help'
  subject: Kbd.help
  closeKey: 'KeyH'
  render: (key,val)->
    renderKey = key.replace(/^s/,'shift-').replace(/^a/,'alt-').replace(/^c/,'ctrl-')
    @body.append i = $ """<div class="list-item"><label>#{Kbd.d10[val]}</label><span>#{renderKey}</span></div>"""
    i.on 'click', i[0].action = =>
      @unfocus()
      new Window.KeyBinder parent: @, title:"Press Key for "  + Kbd.d10[val], default:key, callback:(error,value)=>
        i.find('span').html key = value
        NUU.settings.bind = NUU.settings.bind || {}
        NUU.settings.bind[val] = key
        NUU.saveSettings()
        Kbd.bind key, val
        @focus()

Kbd.macro 'help',     'KeyH', 'Show help',             -> new Window.Help
Kbd.macro 'about',   'aKeyH', 'Show about / license',  -> new Window.About
Kbd.macro 'settings', 'KeyL', 'Open Settings dialog',  ->
  return window.settings.close() if window.settings
  new Object.editor name:'settings', title:'Settings', subject: NUU.settings, closeKey: 'KeyL'



NUU.passPrompt = (prompt,callback)->
  onpass = (pass) =>
    vt.stars = no
    return true if pass is null and @passPrompt prompt,callback
    return true if true is callback pass
    false
  vt.prompt stars:yes, p:prompt, then:onpass
  true

NUU.registerPrompt = ->
  user = pass1 = pass2 = null
  p_user = 'Register (<i style="color:green">Username</i>)'
  p_pas1 = '         (<i style="color:yellow">Password</i>)'
  p_pas2 = '         (   <i style="color:yellow">Again</i>)'
  onkey = (e)->
    return true if e.altKey and e.code is 'KeyL' and new Window.About
    return true if e.altKey and e.code is 'KeyR' and NUU.loginPrompt()
    false
  onuser = (u)->
    user = u
    return true if user is null and NUU.registerPrompt()
    NUU.passPrompt p_pas1, onpass1
    true
  onpass1 = (p)->
    pass1 = p
    NUU.passPrompt p_pas2, onpass2
    true
  onpass2 = (p)->
    return true if pass1 isnt p and NUU.registerPrompt()
    pass2 = p
    setTimeout onpasswordsmatch, 0
    false
  onpasswordsmatch = ->
    vt.status 'Register', '<i style="color:yellow">Registering</i> <i style="color:red">'+user+'</i>'
    NET.register user, pass1, onregister
  onregister = (success)->
    return vt.hide() if true is success
    vt.status 'Register', '<i style="color:red">Name is taken.</i>'
    NUU.registerPrompt()
  vt.prompt override:yes, p:p_user, key:onkey, then:onuser
  true

NUU.loginPrompt = ->
  user = pass = null
  p_user = '<i style="color:green">    User</i>'
  p_pass = '<i style="color:green">Password</i>'
  onkey = (e)->
    return true if e.altKey and e.code is 'KeyL' and new Window.About
    return true if e.altKey and e.code is 'KeyR' and NUU.registerPrompt()
    false
  onuser = (u)=>
    return true if ( user = u ) is null and NUU.loginPrompt()
    NUU.passPrompt p_pass, onpass
    true
  onpass = (p) =>
    pass = p
    vt.promptQuery = null
    setTimeout dologin, 0
    false
  dologin = =>
    vt.status 'Login', 'Opening connnection...'
    vt.show()
    NET.login user, pass, onlogin
  onlogin = (success) =>
    return NUU.loginPrompt() unless success
    setTimeout ( ->
      vt.status 'NUU', 'ready'
      vt.hide()
    ), 500
  vt.prompt override:yes, key:onkey, then:onuser, p:p_user

  true
