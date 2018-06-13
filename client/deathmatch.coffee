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

Window.MainMenu = class MainMenu extends ModalListWindow
  name: 'dbg_main'
  title: 'Main Menu'
  closeKey: 'KeyO'
  fetch: (done)-> done MainMenu.root
  render: (key,val)->
    @body.append entry = $ """
      <div class="list-item menu-item noselect">
      <label>#{val.name}</label>
      <span>#{val.description}</span>
      </div>"""
    null

Window.Ships = class DebugShipWindow extends ModalListWindow
  name: 'dbg_ship'
  title: 'Ships'
  subject: Item.byType.ship
  closeKey: 'sKeyS'
  # fetch:(done)->
  #   NET.json.write unlocks:''
  #   NET.once 'unlocks', (@filter)=>
  #     window.UNLOCKS = @filter
  #     done @subject
  render: (key,val)->
    Render.Ship.call @, key, val, @close.bind @ # if @filter[val.name]
    null

Window.SlotSelection = class SlotSelectionWindow extends ModalListWindow
  constructor: (@parent,@type,@slot) ->
    @title = "Select: #{@type} (#{@slot.size})"
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
    list = collect(Item.byType[@type],@slot.size)
    @addItem name for name in list
    @$.find('.list-item').first().addClass 'active'

  addItem:(name)->
    tpl = Item.byName[name]
    @body.append x = $ """<div class="list-item slot"><label>#{name}</label><span></span></div>"""
    l = x.find("span")
    l.append "#{k}: #{v}<br/>" for k,v of tpl.stats
    x.prepend img = new Image
    x.on 'click', x[0].action = =>
      NET.json.write modSlot: item:tpl.itemId, type:@type, slot:@slot.idx
      clear = => NET.removeListener 'modSlot', onsuccess; NET.removeListener 'e', onerror
      NET.on 'e',       onerror   = => clear(); @close()
      NET.on 'modSlot', onsuccess = => clear(); @close()
    img.width = 32; img.height = 32
    img.src = '/build/imag/loading.png'
    Cache.get '/build/outfit/store/' + ( tpl.info.gfx_store || tpl.sprite ) + '.png', (url)=> img.src = url

Window.Equipment = class EquipmentWindow extends ModalListWindow
  constructor: (@vehicle=VEHICLE)->
    super name:'equip', title:'Equipment'
    if typeof @vehicle is 'string'
      @vehicle = Item.byType.ship[@vehicle]
    for type, slots of @vehicle.slots
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

Window.Station = class DebugBuildWindow extends ModalListWindow
  name: 'dbg_build'
  title: 'Station'
  subject: Item.byType.station
  closeKey: 'aKeyS'
  render: (key,val)->
    Render.Station.call @,key, val, @close.bind @
    null

Kbd.macro 'main',   'KeyO',  'Show main menu',      -> new Window.MainMenu
Kbd.macro 'ships',  'cKeyS', 'Show ship menu',      -> new Window.Ships
Kbd.macro 'equip',  'aKeyS', 'Show equipment menu', -> new Window.Equipment
Kbd.macro 'build',  'sKeyS', 'Show build menu',     -> new Window.Station

Kbd.macro 'rename', 'F11',  'Rename ship', ->
  vt.prompt 'Shipname', (name) -> NET.json.write set:ship_name:name

Kbd.macro 'iff',    'F12',  'Add IFF-code', ->
  vt.prompt 'IFF-code', (name) -> NET.json.write set:iff:name

Render =
  Ship: (name,item,close)->
    sprite = item.sprite
    sprite = parent.sprite if item.extends and item.extends.match and ( item.extends isnt item.name ) and parent = Item.byName[item.extends]
    @body.append entry = $ """
      <div class="list-item select-ship">
      <label>#{item.name}</label>
      <div id="ship_select_#{name}" class="ship-select noselect">
        <img class="ship_comm" src="build/ship/#{sprite}/#{sprite}_comm.png"></img>
        <button class="switch">Switch</button>
        <button class="loadout">Loadout</button>
      </div>
      </div>"""
    bLoadout = entry.find 'button.loadout'
    bLoadout.click -> new EquipmentWindow item.name
    bSwitch = entry.find 'button.switch'
    bSwitch.click -> close NET.json.write switchShip: item.name
  Station: (name,item,close)->
    sprite = item::sprite
    @body.append entry = $ """
      <div class="list-item select-ship">
      <label>#{item.name}</label>
      <div id="ship_select_#{name}" class="ship-select noselect">
        <img class="ship_comm" src="build/stel/#{sprite}.png"></img>
        <button class="build">Build</button>
      </div>
      </div>"""
    bBuild = entry.find 'button.build'
    bBuild.click -> close NET.json.write build: item.name

MainMenu.root =
  build:    -> Kbd.macro.build
  shipyard: -> Kbd.macro.ships
  loadout:  -> Kbd.macro.equip
  help:     -> Kbd.macro.help
  settings: -> Kbd.macro.settings
