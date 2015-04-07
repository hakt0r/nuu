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

console.user = console.log

window.Notice = class Notice
  @queue : []
  constructor : (@msg,@timeout=1000) ->
    @timeout += Date.now()
  toString : -> @msg

setInterval ( =>
  n = Date.now()
  Notice.queue = Notice.queue.filter (e) -> e.timeout > n
), 100

console.real = console.log
console.log = (args...) ->
  notice 200, args.join ' '
  console.real.apply console, args

window.log = (args...) -> console.user args.join(' ')

window.notice = (timeout,msg) ->
  msg = [msg] if typeof msg is 'string'
  Notice.queue.push new Notice line, timeout for line in msg

class Window
  constructor : (opts={}) ->
    @[k] = v for k,v of opts
    $('body').append "<div class='window'><header>#{@title}</header><div></div></div>"
    @$ = $('body > div').last()
    @body = @$.find('div')
    @head = @$.find('header')
    @head.prepend '<img src="build/imag/screw.png">'
    @closeBtn = @head.find('img').last()
    @closeBtn.on 'click', =>
      @$.remove()

window.showSlots = ->
  w = new Window title : 'Equipment'

  #w.body.append i = new Image
  #i.src = VEHICLE.img.src
  mkslotsel = (button,type,slot) ->
    button.on 'click', ->
      w = new Window title:"Select: #{type} (#{slot.size})"
      collect = (list,size) ->
        r = []
        switch size
          when 'large'  then map = [list.large,list.medium,list.small]
          when 'medium' then map = [list.medium,list.small]
          when 'small'  then map = [list.small]
        for l in map
          r = r.concat Object.keys l
        return r
      list = collect(Item.byType[type],slot.size)
      for name in list
        tpl = Item.byName[name]
        w.body.append "<div><b>#{name}<b><br/></div>"
        x = w.body.find('div').last()
        for k,v of tpl.stats
          x.append "#{k}: #{v}<br/>"
        # load image
        x.prepend img = new Image
        img.width = 32; img.height = 32
        if (sp = Sprite.outfit[sprite = tpl.stats.gfx_store]) and sp.obj
          img.src = sp.obj.src
        else
          img.src = '/build/imag/loading.png'
          Sprite.outfit sprite, (i) -> img.src = i.src

  mkslot = (type,slot) ->
    e = slot.equip
    # console.log e
    x = $ "<span class='slot'>
      <span>
        <b>#{type}</b> <button>change</button><br/>
        slot: #{slot.size}<br/>
        <span class='equip'></span>
      </span>
    </span>"
    mkslotsel x.find('button'), type, slot
    if e
      x.find('.equip').append "
        #{e.name}<br/>
        size: #{e.stats.size}<br/>
        mass: #{e.stats.mass}"
      x.prepend img = new Image
      if (sp = Sprite.outfit[sprite = e.stats.gfx_store]) and sp.obj
        img.src = sp.obj.src
      else
        img.src = '/build/imag/loading.png'
        Sprite.outfit sprite, (i) -> img.src = i.src
    x.appendTo w.body
  for type, slots of VEHICLE.slots
    for id, slot of slots
      mkslot type, slot

Kbd.macro 'help', 'h', 'Show help', ->
  h = []
  for key, macro of Kbd.help
    h.push '<tr><td>' + key + "</td><td>" + Kbd.d10[macro] + '</td></tr>'
  about = $ """
    <div class="about">
      <h1>Keys:</h1>
      <table>
        #{h.join '\n'}
      </table>
      <div class="tabs" id="tabs">
        <a class="close" href="#">Close</a>
      </div>
    </div>
  """
  about.appendTo $ 'body'
  about.find('.close').on 'click', -> about.remove()
