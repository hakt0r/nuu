###

  * c) 2007-2019 Sebastian Glaser <anx@ulzq.de>
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

# ██     ██ ██ ███    ██ ██████   ██████  ██     ██
# ██     ██ ██ ████   ██ ██   ██ ██    ██ ██     ██
# ██  █  ██ ██ ██ ██  ██ ██   ██ ██    ██ ██  █  ██
# ██ ███ ██ ██ ██  ██ ██ ██   ██ ██    ██ ██ ███ ██
#  ███ ███  ██ ██   ████ ██████   ██████   ███ ███

$public class Window
  constructor : (opts={}) ->
    Object.assign @, opts
    window[@name] = @ if @name
    $('body').append @$ = $ "<div class='window #{@name}'></div>"
    @$.append @head = $ "<header>#{@title}</header>" if @title
    @$.append @body = $ "<div></div>"
    $cue @show()
  raise:->
    @$.css "display", "initial"
    @visible = yes
  show:->
    @raise()
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

# ██      ██ ███████ ████████
# ██      ██ ██         ██
# ██      ██ ███████    ██
# ██      ██      ██    ██
# ███████ ██ ███████    ██

$public class ModalListWindow extends Window
  constructor:(opts)->
    super opts
    @$.addClass 'modal_list'
    if @fetch
      @body.append i = $ """<div class="list-item active"><label>..</label><span></span></div>"""
      i.on 'click', i[0].action = => @close()
      @body.append l = $ """<div class="list-item active"><label>..</label><span>[...]</span></div>"""
      @fetch (@subject)=>
        l.remove()
        @render key,val for key, val of @subject
    else if @subject
      @body.append i = $ """<div class="list-item active"><label>..</label><span></span></div>"""
      i.on 'click', i[0].action = => @close()
      @render key,val for key, val of @subject
    @$.find("*").addClass 'noselect'
    null
  getActive:-> @$.find('.list-item.active').first()[0] || false
  keyHandler:(evt,code)->
    list = @$.find('.list-item').toArray()
    cur = @$.find('.list-item.active').first()
    if cur.length is 0
      return unless cur = list[0]
      cur = $ cur
      cur.addClass 'active'
    index = list.indexOf cur[0]
    count = list.length
    switch code
      when @closeKey, 'Escape', 'aEscape'
        @close(); p = @
        p.close() while p = p.parent if code is 'aEscape'
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

# ███████ ██████  ██ ████████  ██████  ██████
# ██      ██   ██ ██    ██    ██    ██ ██   ██
# █████   ██   ██ ██    ██    ██    ██ ██████
# ██      ██   ██ ██    ██    ██    ██ ██   ██
# ███████ ██████  ██    ██     ██████  ██   ██

$obj.classes =
  ship:    default:[], template: Ship.blueprint
  station: default:[], template: Station.blueprint
  outfit:  default:[], template: {}
  gov: default:[],template:
    name:'UntitledGovernment'
    diplomacy:[]
    info:
      name:'Untitled Government'
      description:'This is fresh new Government'
  com: default:[],template:
    name:'UntitledCompany'
    diplomacy:[]
    info:
      name:'Untitled Company'
      description:'This is fresh new Company'
  skill: default:[],template:
    name:'UntitledSkill'
    level:1
    enables:{}
    stats:{}
    requiredItem:false
    info:
      name:'Untitled Skill'
      description:'This is fresh new Skill'
  dipl: default:[],template:{}

$obj.getName = (key,val)->
  name = key
  name = val.name      if val.name?
  name = val.info.name if val.info? and val.info.name?
  name

class $obj.tree extends ModalListWindow
  constructor:(opts={})->
    opts.name = 'editor'
    opts.title = 'Editor'
    opts.subject = Item.byClass
    for key, blueprint of $obj.classes when not Item.db[key]?
      Item.db[key] = blueprint.default
    super opts
    @body.prepend $ "<button>"
  render:(key,val) => switch typeof val
    when 'object'
      @body.append i = $ """<div class="list-item"><label>#{key}</label><span>[directory]</span></div>"""
      i[0].editorKey = key
      i[0].editorValue = val
      i.on 'click', i[0].action = => w = new $obj.BlueprintList
        blueprint:$obj.classes[key]
        name:@name+' '+key
        title:@title+':'+key
        subject:val
        parent:@
        closeKey:@closeKey

class $obj.BlueprintList extends ModalListWindow
  constructor:(opts={})->
    super opts
    @head.append @buttons = $ '<div class="buttons"></div>'
    @buttons.append add = $ "<button>n</button>"
    @buttons.append dup = $ "<button>c</button>"
    @buttons.append del = $ "<button>x</button>"
    add.click => do @add
    dup.click => do @duplicate
    del.click => do @remove
  add:->
    o = JSON.parse JSON.stringify @blueprint.template
    k = -1 + @subject.push o
    @render k,o
    @open k, o
  duplicate:->
    return unless c = @getActive()
    return if c.textContent is '..'
    o = JSON.parse JSON.stringify c.editorValue
    o.name =      o.name      + ' copy' if o.name
    o.info.name = o.info.name + ' copy' if o.info.name
    k = -1 + @subject.push o
    @render k,o
    @open o
  remove:->
    return unless c = @getActive()
    return if c.textContent is '..'
    delete @subject[c.editorKey]
    c.remove()
  open:(key,val)->
    name = $obj.getName key, val
    new $obj.editor
      parent:    @
      subject:   val
      name:      @name+'.'+key
      title:     @title+':'+name
      closeKey:  @closeKey
      blueprint: @blueprint
  render:(key,val)->
    return unless typeof val is 'object'
    name = $obj.getName key, val
    @body.append i = $ """<div class="list-item"><label>#{name}</label><span>[directory]</span></div>"""
    i.on 'click', i[0].action = => @open key, val
  keyHandler:(evt,code)->
    switch code
      when "KeyN" then @add()
      when "KeyC" then @duplicate()
      when "KeyX" then @remove()
      else ModalListWindow::keyHandler.call @,evt,code

class $obj.editor extends ModalListWindow
  constructor:(opts)->
    super opts
  render:(key,val) =>
    if @blueprint?.template?[key]?.match? and @blueprint.template[key].match /^sprite@/
      @body.append i = $ """<div class="list-item"><label>#{key}</label><span>#{val}</span></div>"""
      i.on 'click', i[0].action = => w = new SpriteSelector parent:@, item$:i, title:key, default:val, callback:(error,value)=>
        i.find('span').html if @subject[key] = val = value
    else switch typeof val
      when 'object'
        @body.append i = $ """<div class="list-item"><label>#{key}</label><span>[directory]</span></div>"""
        i.on 'click', i[0].action = => w = new $obj.editor
          name:@name+'_'+key
          title:@title+':'+name
          subject: val
          parent:@
          closeKey:@closeKey
      when 'number'
        @body.append i = $ """<div class="list-item"><label>#{key}</label><span>#{val}</span></div>"""
        i.on 'click', i[0].action = =>
          return if @editor
          new Number.editor parent:@, item$:i, title:key, default:val, callback:(error,value)=>
            i.find('span').html if @subject[key] = val = value
            NUU.saveSettings()
      when 'string'
        @body.append i = $ """<div class="list-item"><label>#{key}</label><span>#{val}</span></div>"""
        i.on 'click', i[0].action = =>
          return if @editor
          new String.editor parent:@, item$:i, title:key, default:val, callback:(error,value)=>
            i.find('span').html if @subject[key] = val = value
            NUU.saveSettings()
      when 'boolean'
        @body.append i = $ """<div class="list-item"><label>#{key}</label><span>#{if val then 'true' else '<span class="red">false</div>'}</span></div>"""
        i.on 'click', i[0].action = =>
          i.find('span').html if @subject[key] = val = not val then 'true' else '<span class="red">false</div>'
          NUU.saveSettings()

$public class SpriteSelector
  constructor:(opts)->
    Object.assign @, opts
    @item$.off 'click', @item$[0].action
    @item$.append @input$ = $ '<input>'
    @item$.append @body$ = $ """<div class="sprite-editor">"""
    @value$ = @item$.find 'span'
    @value$.css 'display','none'
    @input$.val @value$.text()
    @parent.editor = @
    @input$.focus()
    close = =>
      @value$.css 'display', 'unset'
      @input$.remove(); delete @parent.editor; Kbd.release @
      @body$.remove()
    Kbd.grab @,
      onkeyup:(e)=>
        switch e.key
          when "Escape" then close()
          when "Tab"
            @input$.val $('.sprite-select:not(.hidden)').first().find('.name').text()
            @input$.focus()
            setTimeout ( => @search() ), 0
          when "Enter"
            @value$.text @input$.val()
            @parent.subject[@title] = @input$.val()
            close()
          else
            e.allowDefault = true
            setTimeout ( => @search() ), 0
      onpaste:(e)-> console.log 'paste', e
      onkeydown:(e)->
        e.preventDefault() if e.key is "Tab"
    @subject = $meta
    @render()
  search:->
    s = @input$.val()
    l = @body$
    .find '.sprite-select'
    .toArray()
    l.forEach (v)->
      n = v.querySelector '.name'
      if      n? and n.innerText is s
        v.classList.remove 'hidden'
        v.classList.add    'selected'
      else if n? and n.innerText.match s
        v.classList.remove 'hidden'
        v.classList.remove 'selected'
      else
        v.classList.add    'hidden'
        v.classList.remove 'selected'
    return

SpriteSelector::render = -> requestAnimationFrame =>
  @body$.innerHTML = ''
  @renderSprite k for k,v of @subject
  @search()
  return

SpriteSelector::renderSprite = (key)->
  return if key.match /store$/
  return if key.match /comm$/
  return unless m = $meta[key]
  if m.height <= m.width
    xw = m.width  / m.cols
    xh = m.height / m.rows
    fh = xh * f = ( fw = 100 ) / xw
  # else
  @body$.append """
  <div class="sprite-select hidden">
    <span class= "frame" style="
      width:  #{fw}px;
      height: #{fh}px;
    ">
    <img src="build/gfx/#{key}.png"/ style="
      min-width:  #{fw*m.cols}px;
      min-height: #{fh*m.rows}px;
    ">
    </span>
    <span class="name">#{key}</span>
  </div>"""

class String.editor
  constructor:(opts)->
    Object.assign @, opts
    value$ = @item$.find 'span'
    value$.css 'display','none'
    @item$.append @input$ = $ '<input>'
    @input$.val value$.text()
    @input$.focus()
    @parent.editor = @
    Kbd.grab @,
      onkeyup:(e)=>
        switch e.key
          when "Escape"
            value$.css 'display', 'unset'
            @input$.remove(); delete @parent.editor; Kbd.release @
          when "Enter"
            value$.css 'display', 'unset'
            value$.text @input$.val()
            @parent.subject[@title] = @input$.val()
            @input$.remove(); delete @parent.editor; Kbd.release @
          else e.allowDefault = true
      onpaste:(e)-> console.log 'paste', e
      onkeydown:->

class Number.editor
  constructor:(opts)->
    Object.assign @, opts
    value$ = @item$.find 'span'
    value$.css 'display','none'
    @item$.append @input$ = $ '<input>'
    @input$.val parseFloat value$.text()
    @input$.focus()
    @parent.editor = @
    Kbd.grab @,
      onkeyup:(e)=>
        switch e.key
          when "Escape"
            value$.css 'display', 'unset'
            @input$.remove(); delete @parent.editor; Kbd.release @
          when "Enter"
            value$.css 'display', 'unset'
            value$.text @input$.val()
            @parent.subject[@title] = @input$.val()
            @input$.remove(); delete @parent.editor; Kbd.release @
          else e.allowDefault = true
      onpaste:(e)-> console.log 'paste', e
      onkeydown:->


# ██   ██ ███████ ██    ██ ██████  ██ ███    ██ ██████
# ██  ██  ██       ██  ██  ██   ██ ██ ████   ██ ██   ██
# █████   █████     ████   ██████  ██ ██ ██  ██ ██   ██
# ██  ██  ██         ██    ██   ██ ██ ██  ██ ██ ██   ██
# ██   ██ ███████    ██    ██████  ██ ██   ████ ██████

Window.KeyBinder = class KeyBinder extends ModalListWindow
  constructor: (opts)->
    super Object.assign opts,
     name: 'edit.string'
    @keyHandler = @capture
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

# ██   ██ ███████ ██      ██████
# ██   ██ ██      ██      ██   ██
# ███████ █████   ██      ██████
# ██   ██ ██      ██      ██
# ██   ██ ███████ ███████ ██

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
Kbd.macro 'settings', 'KeyL', 'Open Settings dialog',  ->
  return window.settings.close() if window.settings
  new $obj.editor name:'settings', title:'Settings', subject: NUU.settings, closeKey: 'KeyL'

#  █████  ██    ██ ████████ ██   ██
# ██   ██ ██    ██    ██    ██   ██
# ███████ ██    ██    ██    ███████
# ██   ██ ██    ██    ██    ██   ██
# ██   ██  ██████     ██    ██   ██

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
  NUU.testButton.remove() if NUU.testButton
  vt.$.prepend NUU.testButton = $ """<button>Demo</button>"""
  NUU.testButton.click demo
  demo = ->
    user = 'test'
    pass = 'test'
    NUU.testButton.remove() if NUU.testButton
    dologin()
  onkey = (e)->
    return true if e.altKey and e.code is 'KeyL' and new Window.About
    return true if e.altKey and e.code is 'KeyR' and NUU.loginPrompt()
    return true if e.altKey and e.code is 'KeyD' and demo()
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
  NUU.testButton.remove() if NUU.testButton
  vt.$.prepend NUU.testButton = $ """<button>Demo</button>"""
  NUU.testButton.click demo
  demo = ->
    user = 'test'
    pass = 'test'
    NUU.testButton.remove() if NUU.testButton
    dologin()
  onkey = (e)->
    return true if e.altKey and e.code is 'KeyL' and new Window.About
    return true if e.altKey and e.code is 'KeyR' and NUU.registerPrompt()
    return true if e.altKey and e.code is 'KeyC' and demo()
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
      VT100.rootPrompt yes
      vt.hide()
    ), 0
  vt.prompt override:yes, key:onkey, then:onuser, p:p_user
  true
