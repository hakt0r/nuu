###

  * c) 2007-2018 Sebastian Glaser <anx@ulzq.de>
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

$public class Window
  constructor : (opts={}) ->
    @[k] = v for k,v of opts
    window[@name] = @ if @name
    $('body').append @$ = $ "<div class='window'></div>"
    @$.append @head = $ "<header>#{@title}</header>"
    @$.append @body = $ "<div></div>"
    $cue @show()
  show:->
    @$.css "display", "initial"
    @visible = yes
  close:->
    @$.remove()
    delete window[@name] if @name
  hide:->
    @$.css "display", "none"
    @visible = no
  toggle:-> do @[if @visible then 'hide' else 'show']

$public class ModalListWindow extends Window
  constructor:(opts)->
    super opts
    @$.addClass 'modal_list'
    if @subject
      do =>
        @body.append i = $ """<div class="list-item active"><label>..</label><span>[up one level]</span></div>"""
        i.on 'click', i[0].action = => @close()
      @render key,val for key, val of @subject
    @$.find("*").addClass 'noselect'
    @parent.unfocus() if @parent
    @focus()
    null
  keyHandler: (evt)=>
    key = evt.code
    list = @$.find('.list-item')
    cur = @$.find('.list-item.active').first()
    if cur.length is 0
      cur.addClass 'active'
      cur = $ list.first()
    switch key
      when @closeKey, 'Escape'
        @close(); p = @
        p.close() while p = p.parent
      when 'Enter'
        do cur[0].action if cur[0].action
      when 'PageUp' then next = list.first(); list.removeClass 'active'; next.addClass 'active'
      when 'PageDown' then next = list.last();  list.removeClass 'active'; next.addClass 'active'
      when 'ArrowUp'
        next = if cur[0] is list.first()[0] then list.last() else cur.prev()
        list.removeClass 'active'; next.addClass 'active'; cur = next
      when 'ArrowDown'
        next = if cur[0] is list.last()[0] then list.first() else cur.next()
        list.removeClass 'active'; next.addClass 'active'; cur = next
  unfocus: -> window.removeEventListener 'keyup', @keyHandler; @
  focus: -> Kbd.unfocus window.addEventListener 'keyup', @keyHandler; @
  close:-> @unfocus(); ( if @parent then @parent.focus() else Kbd.focus() ); super
  hide:->  @unfocus(); ( if @parent then @parent.focus() else Kbd.focus() ); super

Window.SlotSelection = class SlotSelectionWindow extends ModalListWindow
  constructor: (@parent,type,slot) ->
    @title = "Select: #{type} (#{slot.size})"
    super name:'slots', title:'Slot selection'
    collect = (list,size) =>
      r = []
      switch size
        when 'large'  then map = [list.large,list.medium,list.small]
        when 'medium' then map = [list.medium,list.small]
        when 'small'  then map = [list.small]
      for l in map
        r = r.concat Object.keys l
      return r
    list = collect(Item.byType[type],slot.size)
    @addItem name for name in list
    @$.find('.list-item').first().addClass 'active'

  addItem:(name)->
    tpl = Item.byName[name]
    @body.append x = $ """<div class="list-item slot"><label>#{name}</label><span></span></div>"""
    l = x.find("span")
    l.append "#{k}: #{v}<br/>" for k,v of tpl.stats
    x.prepend img = new Image
    img.width = 32; img.height = 32
    img.src = '/build/imag/loading.png'
    Cache.get '/build/outfit/store/' + ( tpl.info.gfx_store || tpl.sprite ) + '.png', (url)=> img.src = url

Window.Equipment = class EquipmentWindow extends ModalListWindow
  constructor: ->
    super name:'equip', title:'Equipment'
    for type, slots of VEHICLE.slots
      for id, slot of slots
        @mkslot type, slot
    @$.find('.list-item').first().addClass 'active'

  mkslotsel: (type,slot) -> =>
    new Window.SlotSelection @, type, slot

  mkslot: (type,slot) ->
    x = $ """
    <div class="list-item slot">
      <label>#{type} (#{slot.size})</label>
      <span class='equip'></span>
    </div>"""
    x.on 'click', x[0].action = @mkslotsel type, slot
    if e = slot.equip
      x.find('.equip').append "
        #{e.name}<br/>
        size: #{e.size}<br/>
        mass: #{e.stats.mass}"
      x.prepend img = new Image
      img.src = '/build/imag/loading.png'
      Cache.get '/build/outfit/store/' + ( e.info.gfx_store || e.sprite ) + '.png', (url)=> img.src = url
    x.appendTo @body

class Object.editor extends ModalListWindow
  render:(key,val) => switch typeof val
    when 'object'
      @body.append i = $ """<div class="list-item"><label>#{key}</label><span>[directory]</span></div>"""
      i.on 'click', i[0].action = => w = new Object.editor name:@name+'.'+key, title:'Settings:'+key, subject: val, parent: @, closeKey: @closeKey
    when 'string'
      @body.append i = $ """<div class="list-item"><label>#{key}</label><span>#{val}</span></div>"""
      i.on 'click', i[0].action = => new String.editor parent:@ title:key, default:val, callback:(error,value)=>
        i.find('span').html if @subject[key] = val = value
        app.saveSettings()
    when 'boolean'
      @body.append i = $ """<div class="list-item"><label>#{key}</label><span>#{if val then 'true' else '<span class="red">false</div>'}</span></div>"""
      i.on 'click', i[0].action = =>
        i.find('span').html if @subject[key] = val = not val then 'true' else '<span class="red">false</div>'
        app.saveSettings()

Window.KeyBinder = class KeyBinder extends ModalListWindow
  constructor: (opts)->
    @name = 'edit.string'
    @keyHandler = @capture
    super opts
    @$.css 'bottom', 'initial'
    @body.addClass 'big_fat'
    @body.html @default
  confirm: (evt)->
    key = evt.code
    if key is "Enter"
      return unless @value
      do @close
      return @callback null, @value
    else if key is "Escape"
      do @close
      return @callback null, @default
  capture: (evt)->
    key = evt.code
    key = 'c' + key if evt.controlKey
    key = 'a' + key if evt.altKey
    key = 's' + key if evt.shiftKey
    key = 'm' + key if evt.metaKey
    return do @close if key is 'Escape'
    @body.html @value = key + '<br/>Escape | Enter'
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
        app.settings.bind = app.settings.bind || {}
        app.settings.bind[val] = key
        app.saveSettings()
        Kbd.bind key, val
        @focus()

Kbd.macro 'help',     'KeyH', 'Show help',             -> new Window.Help
Kbd.macro 'equip',    'KeyK', 'Show equipment screen', -> new Window.Equipment
Kbd.macro 'settings', 'KeyL', 'Open Settings dialog',  ->
  return window.settings.close() if window.settings
  new Object.editor name:'settings', title:'Settings', subject: app.settings, closeKey: 'KeyL'
