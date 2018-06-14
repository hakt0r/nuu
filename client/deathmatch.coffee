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
      <span>#{val.description||''}</span>
      </div>"""
    entry[0].action = val
    null
MainMenu.root =
  help:     -> do Kbd.macro.help
  license:  -> do Kbd.macro.license
  settings: -> do Kbd.macro.settings

Window.DockingMenu = class DockingMenu extends ModalListWindow
  name: 'dock'
  closeKey: 'KeyQ'
  constructor:(@stel)->
    super title: 'Docked to ' + @stel.name
  fetch: (done)-> done DockingMenu.root
  render: (key,val)->
    @body.append entry = $ """
      <div class="list-item menu-item noselect">
      <label>#{val.name}</label>
      <span>#{val.description||''}</span>
      </div>"""
    entry[0].action = val
    null
DockingMenu.root =
  shipyard: -> do Kbd.macro.ships
  loadout:  -> do Kbd.macro.equip
  undock:   ->
    do Kbd.macro.launch
    @close()
    null

Window.Ships = class Shipyard extends ModalListWindow
  name: 'ship'
  title: 'Ships'
  subject: Item.byType.ship
  closeKey: 'sKeyS'
  fetch:(done)->
    NET.queryJSON unlocks:'', (@filter)=>
      window.UNLOCKS = @filter
      done @subject
    null
  render: (key,val)->
    Render.Ship.call @, key, val, @close.bind @ if @filter[val.name]
    null

Window.SlotSelection = class SlotSelectionWindow extends ModalListWindow
  constructor: (@parent,@type,@slot) ->
    super name:'slots', title:"Select: #{@type} (#{@slot.size})"
  fetch: (done)->
    collect = (list,size) =>
      r = []
      r = r.concat Object.keys l for l in switch size
        when 'large'  then [list.large,list.medium,list.small]
        when 'medium' then [list.medium,list.small]
        when 'small'  then [list.small]
      return r.filter (i)=> @unlocks[i]?
    NET.queryJSON unlocks:'', (@unlocks)=>
      done collect Item.byType[@type], @slot.size if @unlocks
      @close() unless @unlocks
    null

  render:(idx,name)->
    @body.append x = $ """
      <div class="list-item slot"><label>#{name}</label><span></span></div>
    """
    tpl = Item.byName[name]
    l = x.find("span")
    l.append "#{k}: #{v}<br/>" for k,v of tpl.stats
    x.prepend img = new Image
    x.on 'click', x[0].action = =>
      NET.queryJSON modSlot: item:tpl.itemId, type:@type, slot:@slot.idx, (data)=>
        do @close
        @parent.changeSlot data if data
      null
    img.width = 32; img.height = 32
    img.src = '/build/imag/loading.png'
    Cache.get '/build/outfit/store/' + ( tpl.info.gfx_store || tpl.sprite ) + '.png', (url)=> img.src = url

Window.Loadout = class Loadout extends ModalListWindow
  constructor: (@vehicle=VEHICLE)->
    @vehicle = Item.byType.ship[@vehicle] if typeof @vehicle is 'string'
    @subject = @vehicle.slots
    super name:'equip', title:'Loadout for ' + @vehicle.name
  render: (type,slots) ->
    @body.append """
      <div class="list-header">#{type} (#{slots.length + 1})</div>"""
    @renderSlot type, id, slot for id, slot of slots
    null
  renderSlot: (type,id,slot) ->
    readableType = (type,size)->
      readableType.icon[size] + readableType.icon[type]
    readableType.icon = weapon:"✛", utility:"⚒", structure: "⛨", small:"S", medium:"M", large:"L"
    @body.append x = $ """
    <div id="slot_#{type}_#{id}" class="list-item slot">
      <label>#{readableType type, slot.size}: </label>
      <span class='equip'></span>
    </div>"""
    x.on 'click', x[0].action = @slotSelection type, slot
    return unless e = slot.equip
    x.find('label').append ' ' + Weapon.guiName e
    x.find('.equip').append "
      size: #{e.size}<br/>
      mass: #{e.stats.mass}"
    x.prepend img = new Image
    img.src = '/build/imag/loading.png'
    Cache.get '/build/outfit/store/' + ( e.info.gfx_store || e.sprite ) + '.png', (url)=> img.src = url
    return x
  slotSelection: (type,slot) -> =>
    new Window.SlotSelection @, type, slot
  changeSlot: (data) ->
    console.log 'changeSlot', data
    type = data.type; id = data.slot
    slot = @subject[type][id]
    @vehicle.modSlot type, slot, data.item
    old = $ "#slot_#{type}_#{id}"
    old.replaceWith @renderSlot type, id, slot
    true

Kbd.macro 'main',      'KeyO', 'Main Menu',     -> new Window.MainMenu
Kbd.macro 'dockMenu', 'aKeyO', 'Facility Menu', -> new Window.DockingMenu o if o = VEHICLE.landedAt
Kbd.macro 'ships',       null, 'Shipyard',      -> new Window.Ships VEHICLE.landedAt?
Kbd.macro 'equip',       null, 'Loadout',       -> new Window.Loadout VEHICLE,

Kbd.macro 'rename', 'F11',  'Rename ship', ->
  vt.prompt 'Shipname', (name) -> NET.json.write set:ship_name:name

Kbd.macro 'iff',    'F12',  'Add IFF-code', ->
  vt.prompt 'IFF-code', (name) -> NET.json.write set:iff:name

Render =
  Ship: (name,item,close)->
    sprite = item.sprite
    sprite = parent.sprite if item.extends and item.extends.match and ( item.extends isnt item.name ) and parent = Item.byName[item.extends]
    @body.append entry = $ """
      <div id="ship_select_#{name}" class="list-item ship-select noselect">
      <label>#{item.name}</label>
        <img class="ship_comm" src="build/ship/#{sprite}/#{sprite}_comm.png"></img>
        <button class="switch">Switch</button>
        <button class="loadout">Loadout</button>
      </div>"""
    bLoadout = entry.find 'button.loadout'
    bLoadout.click -> new Loadout item.name
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
