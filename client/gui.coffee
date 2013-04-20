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

window.log = (args...) -> console.user args.join(' ')

window.notice = (timeout,msg) ->
  msg = [msg] if typeof msg is 'string'
  Notice.queue.push new Notice line, timeout for line in msg

window.hdist = (m) ->
  if m < 1000 then            (m).toFixed(0) + " px"
  else if m < 1000000 then    (m / 1000).toFixed(2) + " Kpx"
  else if m < 1000000000 then (m / 1000000).toFixed(2) + " Mpx"
  else                        (m / 1000000000).toFixed(2) + " Gpx"

window.htime = (t) ->
  s  = Math.floor(t % 60)
  m  = Math.floor(t / 60 % 60)
  h  = Math.floor(t / 60 / 60)
  d  = Math.floor(t / 60 / 60 / 24)
  y  = Math.floor(t / 60 / 60 / 24 / 365)
  ky = Math.floor(t / 60 / 60 / 24 / 365 / 1000)
  my = Math.floor(t / 60 / 60 / 24 / 365 / 1000 / 1000)
  gy = Math.floor(t / 60 / 60 / 24 / 365 / 1000 / 1000 / 1000)
  if t < 60 then s + "s"
  else if t < 60 * 60 then m + "m" + s + "s"
  else if t < 60 * 60 * 24 then h + "h" + m + "m" + s + "s"
  else if t < 60 * 60 * 24 * 356 then d + "d " + h + ":" + m + ":" + s + "h"
  else t.toFixed 0

class Window
  constructor : (opts={}) ->
    @[k] = v for k,v of opts
    $('body').append "<div class='window'><header>#{@title}</header><div></div></div>"
    @$ = $('body > div').last()
    @body = @$.find('div')
    @head = @$.find('header')
    @head.prepend '<img src="var/imag/screw.png">'
    @closeBtn = @head.find('img').last()
    @closeBtn.on 'click', =>
      @$.remove()

window.showSlots = ->
  w = new Window title : 'Equipment'

  #w.body.append i = new Image
  #i.src = NUU.vehicle.img.src
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
        for k,v of tpl.specific
          x.append "#{k}: #{v}<br/>"
        # load image
        x.prepend img = new Image
        img.width = 32; img.height = 32
        if (sp = Sprite.outfit[sprite = tpl.general.gfx_store]) and sp.obj
          img.src = sp.obj.src
        else
          img.src = Sprite.imag.loading.src
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
        size: #{e.general.size}<br/>
        mass: #{e.general.mass}"
      x.prepend img = new Image
      if (sp = Sprite.outfit[sprite = e.general.gfx_store]) and sp.obj
        img.src = sp.obj.src
      else
        img.src = Sprite.imag.loading.src
        Sprite.outfit sprite, (i) -> img.src = i.src
    x.appendTo w.body
  for type, slots of NUU.vehicle.slots
    for id, slot of slots
      mkslot type, slot